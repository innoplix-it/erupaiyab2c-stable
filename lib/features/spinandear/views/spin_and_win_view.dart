// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../../constants/app_error_messages.dart';
import '../../../constants/file_constants.dart';
import '../../../utils/error_message_utils.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/k_dialog.dart';
import '../../home/controllers/home_tab_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../components/spin_result_dialog.dart';
import '../components/spin_wheel.dart';
import '../controllers/spin_options_controller.dart';
import '../models/spin_reward.dart';
import '../repositories/spin_repository.dart';

const _staticRewards = [
  SpinReward(label: 'Better Luck\nNext Time', type: SpinRewardType.betterLuck),
  SpinReward(label: 'Extra Spin', type: SpinRewardType.extraSpin),
  SpinReward(label: 'Jackpot Spin', type: SpinRewardType.jackpot),
];

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
        await showGeneralDialog<void>(
          context: context,
          barrierDismissible: true,
          barrierLabel: 'No spins left',
          barrierColor: Colors.black.withOpacity(0.55),
          transitionDuration: const Duration(milliseconds: 220),
          pageBuilder: (dialogContext, animation, secondaryAnimation) {
            return Center(
              child: _NoSpinsLeftDialog(
                onClose: () => Navigator.of(dialogContext).pop(),
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
        final spinType = reward.type == SpinRewardType.betterLuck
            ? 'better_luck'
            : reward.type == SpinRewardType.jackpot
                ? 'jackpot'
                : reward.type == SpinRewardType.extraSpin
                    ? 'extra'
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
        dialog: SpinResultDialog(
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

      // If spinning, confirm first.
      if (isSpinning.value) {
        final shouldExit = await showExitDuringSpinDialog();
        if (!shouldExit) return false;
      }

      // If this screen was pushed on top of another route, pop back.
      if (navigator.canPop()) return true;

      // If this screen is hosted inside the persistent bottom tab view,
      // switch back to Home tab instead of exiting the app.
      ref.read(homeTabControllerProvider).jumpToTab(0);
      return false;
    }

    return WillPopScope(
      onWillPop: handleBackNavigation,
      child: Scaffold(
        backgroundColor: const Color(0xFF255E60),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final wheelSize = math.min(constraints.maxWidth * 0.72, 280.0);
            return Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF2F6E70),
                          Color(0xFF1E5153),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -20,
                  bottom: -20,
                  left: -20,
                  right: -20,
                  child: Image.asset(
                    FileConstants.spinRewardGif,
                    fit: BoxFit.cover,
                    width: constraints.maxWidth + 40,
                    color: const Color(0xFF387C80).withOpacity(0.35),
                    colorBlendMode: BlendMode.srcATop,
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () async {
                                final ok = await handleBackNavigation();
                                if (!context.mounted || !ok) return;
                                context.pop();
                              },
                            ),
                            const Spacer(),
                            Container(
                              height: 36,
                              width: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.16),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.help_outline,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Spin The Wheel',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'And Add More Points To Your Wallet',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    height: 1.4,
                                  ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            'Daily Spin Remaining $totalSpins',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Expanded(
                          child: Center(
                            child: SizedBox(
                              width: wheelSize * 1.3,
                              height: wheelSize * 1.3,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: wheelSize,
                                    height: wheelSize,
                                    child: spinOptionsState.isLoading
                                        ? _SpinWheelShimmer(size: wheelSize)
                                        : spinOptionsState.errorMessage != null
                                            ? Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.error_outline,
                                                    color: Colors.white,
                                                    size: 40,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Failed to load.\nPlease try again.',
                                                    textAlign: TextAlign.center,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: Colors.white,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 10),
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
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : SpinWheel(
                                                rewards: _buildRewards(
                                                    spinOptionsState.options),
                                                rotation: targetRotation.value *
                                                    animValue,
                                                size: wheelSize,
                                              ),
                                  ),
                                  // Positioned.fill(
                                  //   child: Image.asset(
                                  //     FileConstants.spinBlast,
                                  //     fit: BoxFit.fill,
                                  //   ),
                                  // ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: constraints.maxWidth * 0.55,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: (isSpinning.value) ? null : handleSpin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0B5E5A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              isSpinning.value ? 'Spinning...' : 'Spin Now',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'You have $totalSpins free spin'
                          '${totalSpins == 1 ? '' : 's'} left today.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                        ),
                        const SizedBox(height: 12),
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
  final normalValues = options['Normal'] ?? const <int>[];
  final coinRewards = normalValues
      .map(
        (v) => SpinReward(
          label: '${v}E-Coins',
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

class _NoSpinsLeftDialog extends StatelessWidget {
  const _NoSpinsLeftDialog({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 0.75,
                    child: Lottie.asset(
                      'assets/lottie/spin_rays.json',
                      repeat: true,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  Container(
                    height: 62,
                    width: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF3FAF9),
                      border: Border.all(color: const Color(0xFFBFE7E2)),
                    ),
                    child: const Icon(
                      Icons.hourglass_bottom_rounded,
                      color: Color(0xFF0B5E5A),
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'All spins used!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0B5E5A),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\u2019ve finished today\u2019s free spins.\nCome back tomorrow for more chances to win.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black.withOpacity(0.7),
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B5E5A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Got it',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
            width: 320,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
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
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
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
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                        ),
                      ),
                      child: const Icon(
                        Icons.casino_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Wheel is Spinning',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Leaving now may lose your reward.\nWant to exit anyway?',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.88),
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 16),
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
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text('Wait'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: widget.onExit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0B5E5A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
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
