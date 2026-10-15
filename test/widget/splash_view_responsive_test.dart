// Responsive coverage for SplashView.
//
// Uses the canonical `responsiveTestScreenSizes` matrix from
// test/helpers/responsive_test_sizes.dart - the device list is never
// duplicated here. No Figma reference exists for this screen, so these tests
// check layout safety and the existing navigation only.

import 'package:e_rupaiya/constants/file_constants.dart';
import 'package:e_rupaiya/constants/routes_constant.dart';
import 'package:e_rupaiya/features/auth/controllers/auth_controller.dart';
import 'package:e_rupaiya/features/auth/models/auth_state.dart';
import 'package:e_rupaiya/features/auth/repositories/auth_repository.dart';
import 'package:e_rupaiya/features/auth/views/splash_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/responsive_test_sizes.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _FakeAuthController extends AuthController {
  _FakeAuthController({required bool isLoading})
      : super(
          repository: _MockAuthRepository(),
          shouldCheckInitialAuth: false,
        ) {
    state = AuthState(
      isAuthenticated: false,
      hasTemporaryAccess: false,
      isLoading: isLoading,
      isSubmitting: false,
    );
  }
}

Future<void> _pumpSplash(
  WidgetTester tester, {
  Size size = const Size(360, 690),
  EdgeInsets padding = EdgeInsets.zero,
  bool authLoading = true,
  Duration duration = const Duration(seconds: 30),
}) async {
  const dpr = 2.0;
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = size * dpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: RouteConstants.splash,
    routes: [
      GoRoute(
        path: RouteConstants.splash,
        builder: (_, __) => SplashView(duration: duration),
      ),
      GoRoute(
        path: RouteConstants.login,
        builder: (_, __) => const Scaffold(body: Text('LOGIN')),
      ),
      GoRoute(
        path: RouteConstants.home,
        builder: (_, __) => const Scaffold(body: Text('HOME')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          (ref) => _FakeAuthController(isLoading: authLoading),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        fontSizeResolver: FontSizeResolvers.radius,
        builder: (context, _) => MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: padding,
              viewPadding: padding,
            ),
            child: child!,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Disposes the splash so its duration and hard-timeout timers are cancelled.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

Finder get _partnerLogo => find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName ==
              FileConstants.bharatConnectColor,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Splash renders without overflow across shared sizes', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpSplash(tester, size: size);
        expect(tester.takeException(), isNull);

        final lottie = tester.getRect(find.byType(Lottie));
        expect(lottie.left, greaterThanOrEqualTo(0));
        expect(lottie.right, lessThanOrEqualTo(size.width));
        // The hero animation scales with the screen height, as designed.
        expect(lottie.height, closeTo(96.h, 0.01));

        final partner = tester.getRect(_partnerLogo);
        expect(partner.height, closeTo(28.h, 0.01));
        expect(partner.right, lessThanOrEqualTo(size.width));
        expect(partner.bottom, lessThanOrEqualTo(size.height));
        expect(partner.top, greaterThan(lottie.bottom));
        await _unmount(tester);
      });
    }
  });

  group('Splash respects safe-area insets across shared sizes', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpSplash(
          tester,
          size: size,
          padding: const EdgeInsets.only(top: 47, bottom: 34),
        );
        expect(tester.takeException(), isNull);
        expect(
            tester.getRect(find.byType(Lottie)).top, greaterThanOrEqualTo(47));
        expect(tester.getRect(_partnerLogo).bottom,
            lessThanOrEqualTo(size.height - 34));
        await _unmount(tester);
      });
    }
  });

  testWidgets('waits on splash while auth is still loading', (tester) async {
    await _pumpSplash(
      tester,
      duration: const Duration(milliseconds: 100),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SplashView), findsOneWidget);
    expect(find.text('LOGIN'), findsNothing);
    await _unmount(tester);
  });

  testWidgets('goes to login once the timer ends and auth resolved',
      (tester) async {
    await _pumpSplash(
      tester,
      authLoading: false,
      duration: const Duration(milliseconds: 100),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(find.text('LOGIN'), findsOneWidget);
    await _unmount(tester);
  });
}
