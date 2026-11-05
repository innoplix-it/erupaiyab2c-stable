import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'features/profile/controllers/theme_mode_controller.dart';
import 'features/developer_mode/controllers/developer_mode_guard.dart';
import 'features/educationFees/widgets/tutor_request_notification_listener.dart';

import 'router.dart';
import 'services/app_lock_service.dart';
import 'services/in_app_update_service.dart';
import 'services/location_service.dart';
import 'services/logger_service.dart';
import 'services/navigation_interaction_lock.dart';
import 'services/push_notification_service.dart';
import 'services/screen_security_service.dart';
import 'widgets/app_snackbar.dart';
import 'widgets/k_dialog.dart' show navigatorKey;

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  DeveloperModeGuard.instance.recheck();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );

  Future.microtask(() async {
    try {
      await PushNotificationService.initialize(requestPermissions: false);
    } catch (e, stackTrace) {
      logger.error(
        'Push notification initialization failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
    try {
      await LocationService.initialize(requestPermission: false);
    } catch (e, stackTrace) {
      logger.error(
        'Location service initialization failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  });
}

class MyApp extends HookConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeControllerProvider);
    final appLockService = ref.read(appLockServiceProvider);
    final navigationInteractionLock =
    ref.watch(navigationInteractionLockProvider);
    useListenable(navigationInteractionLock);
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FlutterNativeSplash.remove();
      });
      return null;
    }, const []);
    useEffect(() {
      Future.microtask(() {
        InAppUpdateService.checkForImmediateUpdate();
      });
      return null;
    }, const []);
    useEffect(() {
      appLockService.init();
      ScreenSecurityService.initialize();
      return appLockService.dispose;
    }, const []);
    useEffect(() {
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
      ]);
      return null;
    }, const []);
    useEffect(() {
      final lifecycleListener = AppLifecycleListener(
        onResume: () => DeveloperModeGuard.instance.recheckIfLocked(),
      );
      return lifecycleListener.dispose;
    }, const []);
    useEffect(() {
      // CHANGED: mark UI ready only after the first frame, when the router
      // and navigator are attached, so queued notification taps can navigate.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        logger.info(
          'NAVIGATOR_KEY_ATTACHED: ${navigatorKey.currentState != null}',
        );
        PushNotificationService.markUiReady();
      });
      return null;
    }, const []);
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      ensureScreenSize: true,
      fontSizeResolver: FontSizeResolvers.radius,
      builder: (context, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          builder: (context, widget) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: mediaQuery.textScaler.clamp(
                  minScaleFactor: 0.85,
                  maxScaleFactor: 1.15,
                ),
              ),
              child: TutorRequestNotificationListener(
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (_) => appLockService.onUserActivity(),
                  child: Stack(
                    children: [
                      widget ?? const SizedBox.shrink(),
                      if (navigationInteractionLock.isLocked)
                        const Positioned.fill(
                          child: AbsorbPointer(
                            absorbing: true,
                            child: ColoredBox(color: Colors.transparent),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
          scaffoldMessengerKey: AppSnackbar.messengerKey,
          title: 'eRupaiya',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: const Color.fromARGB(255, 203, 137, 115)),
            textTheme: GoogleFonts.plusJakartaSansTextTheme(
              ThemeData.light().textTheme,
            ),
            primaryTextTheme: GoogleFonts.plusJakartaSansTextTheme(
              ThemeData.light().primaryTextTheme,
            ),
            fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
            extensions: const [
              SkeletonizerConfigData(),
            ],
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            textTheme: GoogleFonts.plusJakartaSansTextTheme(
              ThemeData.dark().textTheme,
            ),
            primaryTextTheme: GoogleFonts.plusJakartaSansTextTheme(
              ThemeData.dark().primaryTextTheme,
            ),
            fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
            extensions: const [
              SkeletonizerConfigData.dark(),
            ],
          ),
          themeMode: themeMode,
          routerConfig: router,
        );
      },
    );
  }
}