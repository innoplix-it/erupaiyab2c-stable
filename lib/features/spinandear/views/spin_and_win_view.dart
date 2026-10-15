// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../constants/app_error_messages.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../utils/error_message_utils.dart';
import '../../../widgets/app_confirm_popup.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/k_dialog.dart';
import '../../home/controllers/home_tab_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../components/spin_result_popup.dart';
import '../components/spin_wheel.dart';
import '../controllers/spin_options_controller.dart';
import '../helpers/spin_sound_controller.dart';
import '../models/spin_reward.dart';
import '../repositories/spin_repository.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Figma order after the coin slices: Surprise, Extra Spin, Jackpot, Better Luck.
const _staticRewards = [
  SpinReward(label: 'Surprise', type: SpinRewardType.surprise),
  SpinReward(label: 'Extra Spin 🔄', type: SpinRewardType.extraSpin),
  SpinReward(label: 'Jackpot Spin 🎉', type: SpinRewardType.jackpot),
  SpinReward(label: 'Better Luck 😂', type: SpinRewardType.betterLuck),
];

/// The gold `star.json` sparkle with a blink: it continuously scales down
/// and back up (pulse). Purely decorative, so it never absorbs taps.
class _BlinkingStar extends HookWidget {
  const _BlinkingStar({
    required this.size,
    this.duration = const Duration(milliseconds: 900),
  });

  final double size;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(duration: duration)
      ..repeat(reverse: true);
    return IgnorePointer(
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.6, end: 1.15).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeInOut),
        ),
        child: Lottie.asset(
          'assets/lottie/star.json',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class SpinAndWinView extends HookConsumerWidget {
  const SpinAndWinView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final profileController = ref.read(profileControllerProvider.notifier);
    final profile = profileState.profile;

    final totalSpins = profile?.normalSpinRemaining ?? 0;
    final hasZeroSpins = profile != null && profile.normalSpinRemaining <= 0;

    final isSpinning = useState(false);
    final isExitDialogOpen = useState(false);
    // Subtle press feedback for the "Try Tomorrow" (no spins left) button.
    final tryTomorrowScale = useState(1.0);

    final spinOptionsState = ref.watch(spinOptionsControllerProvider);
    // Use the provider so tests can inject a fake via ProviderScope.overrides.
    final spinRepository = ref.read(spinRepositoryProvider);

    final spinPath = useState<SpinCuePath?>(null);
    final controller = useAnimationController(
      duration: kSpinWheelDuration,
    );
    final animValue = useAnimation(controller);

    final rng = useMemoized(() => math.Random());

    // "Try Tomorrow" (zero spins left): navigate to Home via the existing
    // GoRouter pattern with a quick scale-down; navigation is not delayed.
    void handleTryTomorrow() {
      tryTomorrowScale.value = 0.96;
      context.go(RouteConstants.home);
      // Restore so the button looks normal if the user returns here.
      Future.delayed(const Duration(milliseconds: 120), () {
        if (context.mounted) tryTomorrowScale.value = 1.0;
      });
    }

    // Fetch profile on mount and preload the popup cue so the OS audio engine
    // has it buffered before the wheel stops. The preload is fire-and-forget;
    // any platform error is swallowed inside SpinSoundController.preloadPopup.
    useEffect(() {
      Future.microtask(() async {
        if (profile == null) {
          profileController.fetchProfile();
        }
        // Warm both cues so neither waits on loading when it is played.
        await SpinSoundController.preloadSpin();
        await SpinSoundController.preloadPopup();
      });
      // Release the spin cue's player with the screen.
      return SpinSoundController.dispose;
    }, const []);

    Future<void> handleSpin() async {
      final rewards = _buildRewards(spinOptionsState.options);
      if (isSpinning.value) return;
      if (totalSpins == 0) {
        // No spins left — route to the new Figma result popup instead of the
        // old "All spins used!" dialog.
        KDialog.instance.openDialog(
          barrierColor: const Color(0xDB000000),
          dialog: SpinResultPopup(
            reward: const SpinReward(
              label: 'Better Luck',
              type: SpinRewardType.betterLuck,
            ),
            onPrimaryTap: () async {},
          ),
        );
        return;
      }
      if (rewards.isEmpty) return;
      isSpinning.value = true;

      // Start the wheel cue exactly once, and turn the wheel as soon as it is
      // playing; the wheel is keyframed on the cue's clicks (SpinCuePath) and
      // settles on the reward as the last click rings out (kSpinWheelDuration).
      await SpinSoundController.playOnSpin().timeout(
        SpinSoundController.cueStartTimeout,
        onTimeout: () {},
      );
      // Start the wheel at the cue's real playhead, not at 0, so each click
      // is heard on its slice change rather than up to a slice late.
      final cuePlayhead = await SpinSoundController.spinCuePlayhead();
      if (!context.mounted) return;

      final currentRewards = rewards;
      final targetIndex = rng.nextInt(currentRewards.length);
      final anglePerSlice = (2 * math.pi) / currentRewards.length;
      final targetAngle =
          (currentRewards.length - targetIndex) * anglePerSlice -
              anglePerSlice / 2;
      // Continue from where the previous spin rested instead of snapping
      // back to 0.
      spinPath.value = SpinCuePath.plan(
        start: (spinPath.value?.end ?? 0) % (2 * math.pi),
        targetAngle: targetAngle,
        sliceCount: currentRewards.length,
      );
      await controller.forward(
        from: (cuePlayhead ?? Duration.zero).inMicroseconds /
            kSpinWheelDuration.inMicroseconds,
      );

      final reward = currentRewards[targetIndex];

      try {
        // NOTE: confirm with backend that 'surprise' is an accepted spinType.
        final spinType = reward.type == SpinRewardType.betterLuck
            ? 'better_luck'
            : reward.type == SpinRewardType.jackpot
                ? 'jackpot'
                : reward.type == SpinRewardType.extraSpin
                    ? 'extra'
                    : reward.type == SpinRewardType.surprise
                        ? 'surprise'
                        : 'normal';

        await spinRepository.recordSpin(
          spinType: spinType,
        );

        // Always refresh spin count from API after spinning (including extra spin)
        await profileController.fetchProfile();
      } catch (error) {
        AppSnackbar.show(
          ErrorMessageUtils.from(
            error,
            fallback: AppErrorMessages.generic,
          ),
          type: AppSnackbarType.error,
        );
      }

      if (isExitDialogOpen.value && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(false);
        isExitDialogOpen.value = false;
      }

      // Fired in the same statement as the dialog so the result cue starts on
      // the popup's first frame rather than after its animation settles.
      SpinSoundController.playOnPopup();

      KDialog.instance.openDialog(
        barrierColor: const Color(0xDB000000),
        dialog: SpinResultPopup(
          reward: reward,
          onPrimaryTap: () async {
            await profileController.fetchProfile();
            final error =
                ref.read(profileControllerProvider).errorMessage?.trim();
            if (error != null && error.isNotEmpty && context.mounted) {
              AppSnackbar.show(
                error,
                type: AppSnackbarType.error,
              );
            }
          },
        ),
      );

      isSpinning.value = false;
    }

    Future<bool> showExitDuringSpinDialog() async {
      isExitDialogOpen.value = true;
      final result = await showAppConfirmPopup(
        context: context,
        icon: Icons.casino_outlined,
        title: 'Wheel is Spinning',
        message: 'Leaving now may lose your reward.\nWant to exit anyway?',
        confirmLabel: 'Exit Anyway',
        cancelLabel: 'Wait',
      );
      isExitDialogOpen.value = false;
      return result;
    }

    Future<bool> handleBackNavigation() async {
      final navigator = Navigator.of(context);

      if (isSpinning.value) {
        final shouldExit = await showExitDuringSpinDialog();
        if (!shouldExit) return false;
      }

      if (navigator.canPop()) return true;

      ref.read(homeTabControllerProvider).jumpToTab(0);
      return false;
    }

    return WillPopScope(
      onWillPop: handleBackNavigation,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final wheelSize = math.min(
              constraints.maxWidth * 0.72,
              math.min(constraints.maxHeight * 0.42, 340.0),
            );
            final outerHorizontalPadding = 12.w;
            final badgeSpacing = 6.w;
            final badgeHorizontalPadding = totalSpins >= 1000 ? 4.w : 5.w;
            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: const ColoredBox(color: Color(0xD3000000)),
                  ),
                ),
                // Decorative sunburst glow over the dark scrim, behind content.
                Positioned.fill(
                  child: IgnorePointer(
                    child: Image.asset(
                      'assets/images/png/sunburst.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            const Spacer(),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () async {
                                final ok = await handleBackNavigation();
                                if (!context.mounted || !ok) return;
                                context.pop();
                              },
                              child: Padding(
                                padding: EdgeInsets.all(6.r),
                                child: SvgPicture.asset(
                                  FileConstants.spinCloseSvg,
                                  width: 40.r,
                                  height: 40.r,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 28.h),
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFFF39207),
                                  Color(0xFFB44623),
                                ],
                              ).createShader(bounds),
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 4.h),
                                child: Text(
                                  'Spin To Win',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 32.sp,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            // Figma: big sparkle sits just right of the "n"
                            // of "Win", a little above the text line.
                            Positioned(
                              top: -26.h,
                              right: -46.w,
                              child: _BlinkingStar(size: 40.r),
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: math.min(
                              constraints.maxWidth * 0.82,
                              300.w,
                            ),
                          ),
                          child: Text(
                            'And add more points to your\nwallet to use in real',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              height: 20 / 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: outerHorizontalPadding,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            // Figma pill background: #4E2512 @ 60% (99 alpha).
                            color: const Color(0x994E2512),
                            borderRadius: BorderRadius.circular(90.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Daily Spin Remaining',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                  height: 1.0,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: badgeSpacing),
                              Container(
                                constraints: BoxConstraints(
                                  minWidth: 18.r,
                                  minHeight: 18.r,
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: badgeHorizontalPadding,
                                  vertical: 1.h,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2D0B00),
                                  borderRadius: BorderRadius.circular(90.r),
                                ),
                                child: Text(
                                  '$totalSpins',
                                  maxLines: 1,
                                  softWrap: false,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    height: 1.0,
                                    color: const Color(0xFFD3A30E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Expanded(
                          child: Align(
                            alignment: const Alignment(0, -0.15),
                            // Defensive: shrink the wheel if the Expanded
                            // region is shorter than wheelSize on small /
                            // large-inset devices. No-op when there is room.
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: SizedBox(
                                width: wheelSize,
                                height: wheelSize,
                                child: Stack(
                                  alignment: Alignment.center,
                                  clipBehavior: Clip.none,
                                  children: [
                                    SizedBox(
                                      width: wheelSize,
                                      height: wheelSize,
                                      child: spinOptionsState.isLoading
                                          ? _SpinWheelShimmer(size: wheelSize)
                                          : spinOptionsState.errorMessage !=
                                                  null
                                              ? Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.error_outline,
                                                      color: Colors.white,
                                                      size: 40.r,
                                                    ),
                                                    SizedBox(height: 8.h),
                                                    Text(
                                                      'Failed to load.\nPlease try again.',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: Colors.white,
                                                          ),
                                                    ),
                                                    SizedBox(height: 10.h),
                                                    TextButton(
                                                      onPressed: () => ref
                                                          .read(
                                                            spinOptionsControllerProvider
                                                                .notifier,
                                                          )
                                                          .fetchSpinOptions(),
                                                      child: const Text(
                                                        'Retry',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : SpinWheel(
                                                  rewards: _buildRewards(
                                                      spinOptionsState.options),
                                                  rotation: spinPath.value
                                                          ?.rotationAt(
                                                        animValue *
                                                            kSpinWheelDuration
                                                                .inMilliseconds,
                                                      ) ??
                                                      0,
                                                  size: wheelSize,
                                                ),
                                    ),
                                    // Figma: second sparkle at upper-left of wheel.
                                    Positioned(
                                      top: wheelSize * -0.04,
                                      left: wheelSize * 0.06,
                                      child: _BlinkingStar(
                                        size: 36.r,
                                        duration: const Duration(
                                          milliseconds: 1100,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Center(
                          child: AnimatedScale(
                            scale: tryTomorrowScale.value,
                            duration: const Duration(milliseconds: 110),
                            curve: Curves.easeOut,
                            child: SizedBox(
                              width:
                                  math.min(constraints.maxWidth * 0.56, 200.w),
                              height: 42.h,
                              child: ElevatedButton(
                                onPressed: hasZeroSpins
                                    ? handleTryTomorrow
                                    : (isSpinning.value ? null : handleSpin),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDD5428),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      const Color(0xFFDD5428),
                                  disabledForegroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(90.r),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  hasZeroSpins
                                      ? 'Try Tomorrow'
                                      : isSpinning.value
                                          ? 'Spinning...'
                                          : 'Spin The Wheel',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          'You have $totalSpins free spin'
                          '${totalSpins == 1 ? '' : 's'} left today.',
                          textAlign: TextAlign.center,
                          // Reduced by 2: 18 -> 16.
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                        // Bigger bottom gap lifts the button + text upward.
                        SizedBox(height: 50.h),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

List<SpinReward> _buildRewards(Map<String, List<int>> options) {
  final normalValues = [...(options['Normal'] ?? const <int>[])]..sort();
  // Force exactly 4 coin slices → total always 8 (4 coins + 4 static).
  // This removes the extra slice that appeared when API sent >4 values.
  final coinValues = normalValues.take(4).toList();
  final coinRewards = coinValues
      .map(
        (v) => SpinReward(
          label: '$v E-Coins',
          type: SpinRewardType.coins,
          coins: v,
        ),
      )
      .toList();
  return [...coinRewards, ..._staticRewards];
}

class _SpinWheelShimmer extends StatefulWidget {
  const _SpinWheelShimmer({required this.size});

  final double size;

  @override
  State<_SpinWheelShimmer> createState() => _SpinWheelShimmerState();
}

class _SpinWheelShimmerState extends State<_SpinWheelShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = _controller.value * 3 - 1;
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              colors: [
                Colors.white.withOpacity(0.18),
                Colors.white.withOpacity(0.5),
                Colors.white.withOpacity(0.18),
              ],
              stops: const [0.25, 0.5, 0.75],
              begin: const Alignment(-1, -0.3),
              end: const Alignment(1, 0.3),
              transform: _SpinShimmerTransform(value),
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: Container(
            height: widget.size,
            width: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.25),
            ),
          ),
        );
      },
    );
  }
}

class _SpinShimmerTransform extends GradientTransform {
  const _SpinShimmerTransform(this.slidePercent);

  final double slidePercent;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}
