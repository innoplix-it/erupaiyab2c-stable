// Responsive coverage for OtpSuccessView.
//
// Uses the canonical `responsiveTestScreenSizes` matrix from
// test/helpers/responsive_test_sizes.dart - the device list is never
// duplicated here. No Figma reference exists for this screen, so these tests
// check layout safety and the existing redirect only.

import 'package:e_rupaiya/constants/routes_constant.dart';
import 'package:e_rupaiya/features/auth/views/otp_success_view.dart';
import 'package:e_rupaiya/widgets/custom_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../helpers/responsive_test_sizes.dart';

Future<void> _pumpOtpSuccess(
  WidgetTester tester, {
  Size size = const Size(360, 690),
  double textScale = 1.0,
  EdgeInsets padding = EdgeInsets.zero,
}) async {
  const dpr = 2.0;
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = size * dpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: RouteConstants.otpSuccess,
    routes: [
      GoRoute(
        path: RouteConstants.otpSuccess,
        builder: (_, __) => const OtpSuccessView(),
      ),
      GoRoute(
        path: RouteConstants.addPin,
        builder: (_, __) => const Scaffold(body: Text('ADD PIN')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        fontSizeResolver: FontSizeResolvers.radius,
        builder: (context, _) => MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
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
}

/// Disposes the view so its redirect countdown is cancelled.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

/// Short phones scroll, so each element is scrolled into view before it is
/// checked against the screen edges.
Future<void> _expectReachableOnScreen(
  WidgetTester tester,
  Size size, {
  double bottomInset = 0,
}) async {
  for (final finder in [
    find.text('OTP Verified Successfully'),
    find.text('Protect your account and keep every transaction secure.'),
    find.byType(CustomElevatedButton),
  ]) {
    await tester.ensureVisible(finder);
    await tester.pump();
    final rect = tester.getRect(finder);
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(size.width));
    expect(rect.bottom, lessThanOrEqualTo(size.height - bottomInset + 0.01));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OTP success renders without overflow across shared sizes', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpOtpSuccess(tester, size: size);
        expect(tester.takeException(), isNull);
        await _expectReachableOnScreen(tester, size);

        // The info icon must stay inside its circle on every device.
        final avatar = tester.getRect(find.byType(CircleAvatar));
        final iconSize =
            tester.widget<Icon>(find.byIcon(Icons.info_outline)).size!;
        expect(iconSize, lessThanOrEqualTo(avatar.width));
        expect(avatar.width, closeTo(avatar.height, 0.01));
        await _unmount(tester);
      });
    }
  });

  group('OTP success respects safe-area insets across shared sizes', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpOtpSuccess(
          tester,
          size: size,
          padding: const EdgeInsets.only(top: 47, bottom: 34),
        );
        expect(tester.takeException(), isNull);
        expect(
            tester.getRect(find.byType(Image)).top, greaterThanOrEqualTo(47));
        await _expectReachableOnScreen(tester, size, bottomInset: 34);
        await _unmount(tester);
      });
    }
  });

  group('OTP success supported text scales across shared sizes', () {
    for (final scale in const [0.85, 1.15]) {
      for (final size in responsiveTestScreenSizes) {
        testWidgets('${size.width}x${size.height} @${scale}x', (tester) async {
          await _pumpOtpSuccess(tester, size: size, textScale: scale);
          expect(tester.takeException(), isNull);
          await _expectReachableOnScreen(tester, size);
          await _unmount(tester);
        });
      }
    }
  });

  testWidgets('on regular phones the CTA stays pinned to the bottom',
      (tester) async {
    for (final size in const [Size(360, 690), Size(412, 915)]) {
      await _pumpOtpSuccess(tester, size: size);
      expect(
        tester.getRect(find.byType(CustomElevatedButton)).bottom,
        closeTo(size.height - 24.h, 0.5),
      );
      await _unmount(tester);
    }
  });

  testWidgets('counts down and redirects to Create MPIN after 5 seconds',
      (tester) async {
    await _pumpOtpSuccess(tester);
    expect(find.text('Redirecting in 5 sec'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Redirecting in 4 sec'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    expect(find.text('ADD PIN'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('Secure app goes to Create MPIN', (tester) async {
    await _pumpOtpSuccess(tester);
    await tester.tap(find.byType(CustomElevatedButton));
    await tester.pump();
    await tester.pump();
    expect(find.text('ADD PIN'), findsOneWidget);
    await _unmount(tester);
  });
}
