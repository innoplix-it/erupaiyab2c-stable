// Coverage for the Figma Create MPIN screen (PinSetupView).
//
// Uses the canonical `responsiveTestScreenSizes` matrix from
// test/helpers/responsive_test_sizes.dart - the device list is never
// duplicated here.

import 'package:e_rupaiya/constants/routes_constant.dart';
import 'package:e_rupaiya/features/auth/controllers/auth_controller.dart';
import 'package:e_rupaiya/features/auth/models/auth_state.dart';
import 'package:e_rupaiya/features/auth/repositories/auth_repository.dart';
import 'package:e_rupaiya/features/auth/views/pin_setup_view.dart';
import 'package:e_rupaiya/widgets/custom_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pinput/pinput.dart';

import '../helpers/responsive_test_sizes.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _FakeAuthController extends AuthController {
  _FakeAuthController({this.result})
      : super(
          repository: _MockAuthRepository(),
          shouldCheckInitialAuth: false,
        ) {
    state = const AuthState(
      isAuthenticated: false,
      hasTemporaryAccess: true,
      isLoading: false,
      isSubmitting: false,
    );
  }

  final String? result;
  final setPinCalls = <String>[];

  @override
  Future<String?> setPin({required String pin, String? mobile}) async {
    setPinCalls.add(pin);
    return result;
  }
}

Future<_FakeAuthController> _pump(
  WidgetTester tester, {
  Size size = const Size(360, 690),
  double textScale = 1.0,
  double keyboardInset = 0,
  EdgeInsets padding = EdgeInsets.zero,
  String? setPinResult,
}) async {
  const dpr = 2.0;
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = size * dpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final controller = _FakeAuthController(result: setPinResult);
  final router = GoRouter(
    initialLocation: RouteConstants.addPin,
    routes: [
      GoRoute(
        path: RouteConstants.addPin,
        builder: (_, __) => const PinSetupView(),
      ),
      GoRoute(
        path: RouteConstants.login,
        builder: (_, __) => const Scaffold(body: Text('LOGIN')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith((ref) => controller)],
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
              viewInsets: EdgeInsets.only(bottom: keyboardInset),
            ),
            child: child!,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return controller;
}

Finder get _pinputs => find.byType(Pinput);

Future<void> _enter(WidgetTester tester, int row, String text) async {
  await tester.enterText(
    find.descendant(of: _pinputs.at(row), matching: find.byType(EditableText)),
    text,
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

CustomElevatedButton _verify(WidgetTester tester) =>
    tester.widget<CustomElevatedButton>(find.byType(CustomElevatedButton));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Create MPIN renders without overflow across shared sizes', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pump(tester, size: size);
        expect(tester.takeException(), isNull);
        expect(_pinputs, findsNWidgets(2));
        final boxes = find.descendant(
          of: _pinputs.first,
          matching: find.byType(AnimatedContainer),
        );
        expect(boxes, findsNWidgets(4));
        expect(tester.getRect(find.text('Show').first).right,
            lessThanOrEqualTo(size.width));
      });
    }
  });

  group('keyboard open keeps Verify above the keyboard', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        final inset = size.height * 0.4;
        await _pump(tester, size: size, keyboardInset: inset);
        expect(tester.takeException(), isNull);
        final rect = tester.getRect(find.byType(CustomElevatedButton));
        expect(rect.bottom, lessThanOrEqualTo(size.height - inset));
      });
    }
  });

  group('safe-area insets are respected across shared sizes', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pump(
          tester,
          size: size,
          padding: const EdgeInsets.only(top: 47, bottom: 34),
        );
        expect(tester.takeException(), isNull);
        expect(
          tester.getRect(find.byIcon(Icons.arrow_back)).top,
          greaterThanOrEqualTo(47),
        );
        expect(
          tester.getRect(find.byType(CustomElevatedButton)).bottom,
          lessThanOrEqualTo(size.height - 34),
        );
      });
    }
  });

  group('supported text scales across shared sizes', () {
    for (final scale in const [0.85, 1.15]) {
      for (final size in responsiveTestScreenSizes) {
        testWidgets('${size.width}x${size.height} @${scale}x', (tester) async {
          await _pump(tester, size: size, textScale: scale);
          expect(tester.takeException(), isNull);
          expect(_pinputs, findsNWidgets(2));
          expect(tester.getRect(find.text('Show').first).right,
              lessThanOrEqualTo(size.width));
          expect(tester.getRect(find.byType(CustomElevatedButton)).bottom,
              lessThanOrEqualTo(size.height));
        });
      }
    }
  });

  testWidgets('large text scale does not overflow', (tester) async {
    await _pump(tester, size: const Size(320, 568), textScale: 1.6);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses Plus Jakarta Sans for the Figma copy', (tester) async {
    await _pump(tester);
    for (final label in [
      'Create MPIN',
      'Set a 4 digit MPIN to secure your eRupaiya wallet.',
      'Add New Pin',
      'Confirm Pin',
    ]) {
      expect(
        tester.widget<Text>(find.text(label)).style!.fontFamily,
        'Plus Jakarta Sans',
      );
    }
  });

  testWidgets('each row masks with * and toggles Show/Hide on its own',
      (tester) async {
    await _pump(tester);
    await _enter(tester, 0, '12');
    expect(find.text('*'), findsNWidgets(2));

    await tester.tap(find.text('Show').first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Hide'), findsOneWidget);
    expect(find.text('Show'), findsOneWidget);
  });

  testWidgets('Verify is disabled until both PINs have 4 digits',
      (tester) async {
    final controller = await _pump(tester);
    expect(_verify(tester).onPressed, isNull);

    await _enter(tester, 0, '1234');
    expect(_verify(tester).onPressed, isNull);
    expect(controller.setPinCalls, isEmpty);

    await _enter(tester, 1, '123');
    expect(_verify(tester).onPressed, isNull);
  });

  testWidgets('mismatched PINs show the existing error without an API call',
      (tester) async {
    final controller = await _pump(tester);
    await _enter(tester, 0, '1234');
    await _enter(tester, 1, '4321');
    expect(find.text('MPIN does not match.'), findsOneWidget);
    expect(controller.setPinCalls, isEmpty);
  });

  testWidgets(
      'matching PINs set the MPIN once, show success for 2s, then login',
      (tester) async {
    final controller = await _pump(tester, setPinResult: 'MPIN set');
    await _enter(tester, 0, '1234');
    await _enter(tester, 1, '1234');
    expect(controller.setPinCalls, ['1234']);

    expect(find.text('MPIN Generated Successfully'), findsOneWidget);
    expect(find.text('LOGIN'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('LOGIN'), findsNothing);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('LOGIN'), findsOneWidget);
    expect(controller.setPinCalls, hasLength(1));
  });

  testWidgets('success screen matches the Figma text spec', (tester) async {
    await _pump(tester, setPinResult: 'MPIN set');
    await _enter(tester, 0, '1234');
    await _enter(tester, 1, '1234');

    final title =
        tester.widget<Text>(find.text('MPIN Generated Successfully')).style!;
    expect(title.fontFamily, 'Plus Jakarta Sans');
    expect(title.fontSize, closeTo(15, 0.01));
    expect(title.color, const Color(0xFF000000));

    final message = tester
        .widget<Text>(
          find.text('Set a 4 digit MPIN to secure your eRupaiya wallet.'),
        )
        .style!;
    expect(message.fontFamily, 'Plus Jakarta Sans');
    expect(message.fontSize, closeTo(10, 0.01));
    expect(message.color, const Color(0xFF52525B));

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(tester.getSize(find.byType(SvgPicture)), const Size(80, 80));
    await tester.pump(const Duration(seconds: 3));
  });

  group('success screen renders without overflow across shared sizes', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pump(tester, size: size, setPinResult: 'MPIN set');
        await _enter(tester, 0, '1234');
        await _enter(tester, 1, '1234');
        expect(tester.takeException(), isNull);
        expect(find.text('MPIN Generated Successfully'), findsOneWidget);
        await tester.pump(const Duration(seconds: 3));
      });
    }
  });

  testWidgets('success back arrow goes straight to login', (tester) async {
    await _pump(tester, setPinResult: 'MPIN set');
    await _enter(tester, 0, '1234');
    await _enter(tester, 1, '1234');
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('LOGIN'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('back goes to login when there is nothing to pop',
      (tester) async {
    await _pump(tester);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('LOGIN'), findsOneWidget);
  });
}
