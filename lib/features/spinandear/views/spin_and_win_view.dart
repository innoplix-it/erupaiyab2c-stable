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
import '../../../utils/error_message_utils.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/k_dialog.dart';
import '../../home/controllers/home_tab_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../components/spin_result_popup.dart';
import '../components/spin_wheel.dart';
import '../controllers/spin_options_controller.dart';
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

    final isSpinning = useState(false);
    final isExitDialogOpen = useState(false);

    final spinOptionsState = ref.watch(spinOptionsControllerProvider);

    final rng = useMemoized(() => math.Random());
    final targetRotation = useState(0.0);
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 2800),
    );
    final animation = useMemoized(
      () => CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
      [controller],
    );
    final animValue = useAnimation(animation);
    final spinRepository = useMemoized(() => SpinRepository());

    // Fetch profile on mount
    useEffect(() {
      Future.microtask(() async {
        if (profile == null) {
          profileController.fetchProfile();
        }
      });
      return null;
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

      final currentRewards = rewards;
      final targetIndex = rng.nextInt(currentRewards.length);
      final anglePerSlice = (2 * math.pi) / currentRewards.length;
      final targetAngle =
          (currentRewards.length - targetIndex) * anglePerSlice -
              anglePerSlice / 2;
      final extraTurns = 5 + rng.nextInt(3);
      targetRotation.value = (extraTurns * 2 * math.pi) + targetAngle;
      await controller.forward(from: 0);

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
      final result = await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Exit spin',
        barrierColor: Colors.black.withOpacity(0.45),
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          return Center(
            child: _SpinExitDialog(
              onWait: () => Navigator.of(dialogContext).pop(false),
              onExit: () => Navigator.of(dialogContext).pop(true),
            ),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      );
      isExitDialogOpen.value = false;
      return result ?? false;
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
            // Figma: the wheel is 320px inside a 440px-wide frame (~0.727 of
            // the viewport). Derive it from the available width so the same
            // proportion is preserved on every device. Clamp by height for
            // short screens and cap so it never grows past the ~320 reference
            // on large/tablet widths. This is a pure structural width ratio
            // (MediaQuery/LayoutBuilder) — deliberately NOT `320.w`, because
            // the 360 design width makes `.w` scale UP past Figma on >=412
            // devices.
            final wheelSize = math.min(
              constraints.maxWidth * 0.72,
              math.min(constraints.maxHeight * 0.42, 340.0),
            );
            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: const ColoredBox(color: Color(0xDB000000)),
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
                            horizontal: 20.w,
                            vertical: 10.h,
                          ),
                          decoration: BoxDecoration(
                            // Figma pill background: #4E2512 @ 60% (99 alpha).
                            color: const Color(0x994E2512),
                            borderRadius: BorderRadius.circular(90.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
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
                              SizedBox(width: 8.w),
                              // Figma badge: dark circle (#2D0B00) with the
                              // API value in gold (#D3A30E). The supplied SVG
                              // bakes a literal "1" into its path, so the
                              // count is rendered as live text in that same
                              // badge style to stay dynamic.
                              Container(
                                width: 18.r,
                                height: 18.r,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2D0B00),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$totalSpins',
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
                                                  rotation:
                                                      targetRotation.value *
                                                          animValue,
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
                        SizedBox(
                          width: math.min(constraints.maxWidth * 0.62, 220.w),
                          height: 46.h,
                          child: ElevatedButton(
                            onPressed: (isSpinning.value) ? null : handleSpin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDD5428),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(90.r),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              isSpinning.value
                                  ? 'Spinning...'
                                  : 'Spin The Wheel',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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

class _SpinExitDialog extends StatefulWidget {
  const _SpinExitDialog({
    required this.onWait,
    required this.onExit,
  });

  final VoidCallback onWait;
  final VoidCallback onExit;

  @override
  State<_SpinExitDialog> createState() => _SpinExitDialogState();
}

class _SpinExitDialogState extends State<_SpinExitDialog>
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
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final shimmer = _controller.value * 3 - 1;
          return Container(
            width: 320.w,
            padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 16.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.r),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1F5E60),
                  Color(0xFF2B7D7F),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.28),
                  blurRadius: 28.r,
                  offset: Offset(0.w, 16.h),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24.r),
                    child: ShaderMask(
                      shaderCallback: (rect) {
                        return LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.05),
                            Colors.white.withOpacity(0.22),
                            Colors.white.withOpacity(0.05),
                          ],
                          stops: const [0.2, 0.5, 0.8],
                          begin: const Alignment(-1, -0.2),
                          end: const Alignment(1, 0.2),
                          transform: _SpinShimmerTransform(shimmer),
                        ).createShader(rect);
                      },
                      blendMode: BlendMode.srcATop,
                      child: Container(color: Colors.white.withOpacity(0.04)),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 56.r,
                      width: 56.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                        ),
                      ),
                      child: Icon(
                        Icons.casino_outlined,
                        color: Colors.white,
                        size: 28.r,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Wheel is Spinning',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Leaving now may lose your reward.\nWant to exit anyway?',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.88),
                            height: 1.4,
                          ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onWait,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18.r),
                              ),
                            ),
                            child: const Text('Wait'),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: widget.onExit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0B5E5A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18.r),
                              ),
                            ),
                            child: const Text('Exit Anyway'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
