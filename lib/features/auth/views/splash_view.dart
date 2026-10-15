import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../config/app_env.dart';
import '../../home/controllers/home_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/auth_controller.dart';
import '../../../services/logger_service.dart';

class SplashView extends HookConsumerWidget {
  const SplashView({super.key, this.duration = const Duration(seconds: 3)});

  final Duration duration;

  static void _debugLog(String message) {
    if (!AppEnv.enableLogs || !kDebugMode) return;
    debugPrint(message);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final timerDone = useState(false);
    final partnerAssetsReady = useState(false);
    final didPrefetch = useRef(false);
    final hardTimeoutDone = useState(false);

    // Start a one-shot timer that fires after the splash duration.
    // Avoid decoding GIF frames here; it can slow down first launch.
    useEffect(() {
      Timer? timer;
      timer = Timer(duration, () => timerDone.value = true);
      return () {
        timer?.cancel();
      };
    }, [duration]);

    // Hard timeout: if auth never resolves on some devices (e.g. keystore/secure
    // storage blocks), still move forward instead of looping splash forever.
    useEffect(() {
      final timer = Timer(const Duration(seconds: 8), () {
        hardTimeoutDone.value = true;
      });
      return timer.cancel;
    }, const []);

    useEffect(() {
      var isActive = true;
      Future<void> preload() async {
        try {
          if (!context.mounted) return;
          await precacheImage(
            AssetImage(FileConstants.bharatConnectColor),
            context,
          );
        } catch (e, stackTrace) {
          logger.error('Failed to preload splash assets', error: e, stackTrace: stackTrace);
          // Ignore preload errors; show immediately.
        }
        if (isActive) {
          partnerAssetsReady.value = true;
        }
      }

      preload();
      return () {
        isActive = false;
      };
    }, []);

    // Navigate only after the timer is done AND auth has resolved.
    useEffect(() {
      final canNavigate = timerDone.value && !authState.isLoading;
      if (!canNavigate && !hardTimeoutDone.value) return;
      if (authState.isLoading && hardTimeoutDone.value) {
        _debugLog(
          'Splash hard timeout hit; auth still loading. Navigating to Login as fallback.',
        );
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        if (!authState.isLoading && authState.isAuthenticated) {
          context.go(RouteConstants.home);
        } else {
          context.go(RouteConstants.login);
        }
      });
      return null;
    }, [
      timerDone.value,
      hardTimeoutDone.value,
      authState.isLoading,
      authState.isAuthenticated
    ]);

    // Prefetch home + profile as soon as auth resolves, so Home opens instantly
    // with cached content and refreshes quietly in the background.
    useEffect(() {
      if (authState.isLoading) return null;
      if (!authState.isAuthenticated) return null;
      if (didPrefetch.value) return null;
      didPrefetch.value = true;
      Future.microtask(() {
        ref.read(homeControllerProvider.notifier).fetchQuickActionsIfNeeded();
        ref
            .read(homeControllerProvider.notifier)
            .fetchAllQuickActionsIfNeeded();
        ref.read(profileControllerProvider.notifier).fetchProfileIfNeeded();
      });
      return null;
    }, [authState.isLoading, authState.isAuthenticated]);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Center logo + app name
            Center(
              child: Column(
                // mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                        // color:
                        //     Color.fromARGB(255, 229, 100, 1), // light orange tint
                        // shape: BoxShape.circle,
                        ),
                    child: Lottie.asset(
                      FileConstants.splashLottie,
                      height: 96.h,
                      fit: BoxFit.contain,
                      repeat: true,
                      animate: true,
                      frameRate: FrameRate.max,
                      errorBuilder: (context, error, stackTrace) {
                        _debugLog(
                          'Splash lottie failed: ${FileConstants.splashLottie} error=$error',
                        );
                        if (kDebugMode || kReleaseMode) {
                          _debugLog(stackTrace.toString());
                        }
                        return Center(
                          child: Icon(
                            Icons.car_crash,
                            size: 28.sp,
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                        );
                      },
                    ),
                  ),
                  // SizedBox(height: 16.h),
                  // Text(
                  //   'e-rupaiya',
                  //   style: TextStyle(
                  //     fontSize: 22.sp,
                  //     fontWeight: FontWeight.w600,
                  //     color: const Color(0xFF333333),
                  //     letterSpacing: 0.5,
                  //   ),
                  // ),
                ],
              ),
            ),
            const Spacer(),
            // Digital Partners section
            Padding(
              padding: EdgeInsets.only(bottom: 32.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedOpacity(
                    opacity: partnerAssetsReady.value ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      children: [
                        // Text(
                        //   'Powered by',
                        //   style: TextStyle(
                        //     fontSize: 13.sp,
                        //     fontWeight: FontWeight.w400,
                        //     color: const Color(0xFF666666),
                        //   ),
                        // ),
                        // SizedBox(height: 12.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              FileConstants.bharatConnectColor,
                              height: 28.h,
                              fit: BoxFit.contain,
                            ),
                            // SizedBox(width: 24.w),
                            // Image.asset(
                            //   FileConstants.upi,
                            //   height: 28.h,
                            //   fit: BoxFit.contain,
                            // ),
                            // SizedBox(width: 24.w),
                            // Image.asset(
                            //   FileConstants.npci,
                            //   height: 28.h,
                            //   fit: BoxFit.contain,
                            // ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
