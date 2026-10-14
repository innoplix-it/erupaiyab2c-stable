// Coverage for the Figma Reset MPIN screen (ResetMpinView) and the Lock
// screen layout (AuthAppLockStep, rendered by AppLockView).
//
// Uses the canonical `responsiveTestScreenSizes` matrix from
// test/helpers/responsive_test_sizes.dart - the device list is never
// duplicated here.

import 'package:e_rupaiya/features/auth/components/auth_app_lock_step.dart';
import 'package:e_rupaiya/features/auth/controllers/auth_controller.dart';
import 'package:e_rupaiya/features/auth/models/auth_state.dart';
import 'package:e_rupaiya/features/auth/repositories/auth_repository.dart';
import 'package:e_rupaiya/features/auth/views/reset_mpin_view.dart';
import 'package:e_rupaiya/widgets/custom_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pinput/pinput.dart';

import '../helpers/responsive_test_sizes.dart';

const _smsChannel = MethodChannel('sms_autofill');

class _MockAuthRepository extends Mock implements AuthRepository {}

class _FakeAuthController extends AuthController {
  _FakeAuthController()
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

  int otpRequests = 0;
  final forgotCalls = <(String, String)>[];

  @override
  Future<String?> requestForgotPinOtp({String? mobile}) async {
    otpRequests++;
    return 'OTP sent';
  }

  @override
  Future<String?> forgotPin({
    required String otp,
    required String pin,
    String? mobile,
  }) async {
    forgotCalls.add((otp, pin));
    return 'MPIN reset';
  }
}

void _setSize(WidgetTester tester, Size size) {
  const dpr = 2.0;
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = size * dpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _screenUtil({
  required Widget Function(BuildContext) builder,
  double textScale = 1.0,
  double keyboardInset = 0,
  EdgeInsets padding = EdgeInsets.zero,
}) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    minTextAdapt: true,
    splitScreenMode: true,
    fontSizeResolver: FontSizeResolvers.radius,
    builder: (context, _) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        padding: padding,
        viewInsets: EdgeInsets.only(bottom: keyboardInset),
      ),
      child: builder(context),
    ),
  );
}

Future<(_FakeAuthController, GoRouter)> _pumpReset(
  WidgetTester tester, {
  Size size = const Size(360, 690),
  double textScale = 1.0,
  double keyboardInset = 0,
  EdgeInsets padding = EdgeInsets.zero,
}) async {
  _setSize(tester, size);
  final controller = _FakeAuthController();
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: Text('HOME')),
      ),
      GoRoute(
        path: '/reset',
        builder: (_, __) => const ResetMpinView(mobile: '9876543210'),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith((ref) => controller)],
      child: _screenUtil(
        textScale: textScale,
        keyboardInset: keyboardInset,
        padding: padding,
        builder: (_) => MaterialApp.router(routerConfig: router),
      ),
    ),
  );
  router.push('/reset');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return (controller, router);
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
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

Future<(List<String>, List<int>)> _pumpLock(
  WidgetTester tester, {
  Size size = const Size(360, 690),
  double textScale = 1.0,
  bool showFingerprint = true,
}) async {
  _setSize(tester, size);
  final completed = <String>[];
  final taps = <int>[];
  final pinController = TextEditingController();
  final focusNode = FocusNode();
  addTearDown(pinController.dispose);
  addTearDown(focusNode.dispose);

  await tester.pumpWidget(
    _screenUtil(
      textScale: textScale,
      builder: (_) => MaterialApp(
        home: Scaffold(
          body: AuthAppLockStep(
            pinController: pinController,
            pinFocusNode: focusNode,
            onPinCompleted: completed.add,
            onForgotPin: () => taps.add(0),
            showFingerprint: showFingerprint,
            onFingerprint: () => taps.add(1),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  return (completed, taps);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_smsChannel, (call) async {
      if (call.method == 'getAppSignature') return 'test-signature';
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_smsChannel, null);
  });

  group('Reset MPIN renders without overflow across shared sizes', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpReset(tester, size: size);
        expect(tester.takeException(), isNull);
        expect(_pinputs, findsNWidgets(3));
        expect(
          find.descendant(
            of: _pinputs.first,
            matching: find.byType(AnimatedContainer),
          ),
          findsNWidgets(6),
        );
        expect(tester.getRect(find.text('Show').first).right,
            lessThanOrEqualTo(size.width));
        await _unmount(tester);
      });
    }
  });

  group('Reset MPIN keeps Verify above the keyboard', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        final inset = size.height * 0.4;
        await _pumpReset(tester, size: size, keyboardInset: inset);
        expect(tester.takeException(), isNull);
        final rect = tester.getRect(find.byType(CustomElevatedButton));
        expect(rect.bottom, lessThanOrEqualTo(size.height - inset));
        await _unmount(tester);
      });
    }
  });

  group('Reset MPIN respects safe-area insets across shared sizes', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpReset(
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
        await _unmount(tester);
      });
    }
  });

  group('Reset MPIN supported text scales across shared sizes', () {
    for (final scale in const [0.85, 1.15]) {
      for (final size in responsiveTestScreenSizes) {
        testWidgets('${size.width}x${size.height} @${scale}x', (tester) async {
          await _pumpReset(tester, size: size, textScale: scale);
          expect(tester.takeException(), isNull);
          expect(_pinputs, findsNWidgets(3));
          expect(tester.getRect(find.text('Show').first).right,
              lessThanOrEqualTo(size.width));
          expect(tester.getRect(find.byType(CustomElevatedButton)).bottom,
              lessThanOrEqualTo(size.height));
          await _unmount(tester);
        });
      }
    }
  });

  group('Lock screen supported text scales across shared sizes', () {
    for (final scale in const [0.85, 1.15]) {
      for (final size in responsiveTestScreenSizes) {
        testWidgets('${size.width}x${size.height} @${scale}x', (tester) async {
          await _pumpLock(tester, size: size, textScale: scale);
          expect(tester.takeException(), isNull);
          expect(
            find.descendant(
              of: _pinputs,
              matching: find.byType(AnimatedContainer),
            ),
            findsNWidgets(4),
          );
          expect(tester.getRect(find.text('Forget PIN')).right,
              lessThanOrEqualTo(size.width));
        });
      }
    }
  });

  testWidgets('Reset MPIN large text scale does not overflow', (tester) async {
    await _pumpReset(tester, size: const Size(320, 568), textScale: 1.6);
    expect(tester.takeException(), isNull);
    await _unmount(tester);
  });

  testWidgets('Reset MPIN shows the Figma copy in Plus Jakarta Sans',
      (tester) async {
    await _pumpReset(tester);
    for (final label in [
      'Reset MPIN',
      'Set a 4 digit MPIN to secure your eRupaiya wallet.',
      'Enter OTP',
      'Create New Pin',
      'Confirm New Pin',
    ]) {
      expect(
        tester.widget<Text>(find.text(label)).style!.fontFamily,
        'Plus Jakarta Sans',
      );
    }
    expect(find.text('01:00'), findsOneWidget);
    expect(find.text('Verify'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('Reset MPIN requests the OTP once on open', (tester) async {
    final (controller, _) = await _pumpReset(tester);
    expect(controller.otpRequests, 1);
    await _unmount(tester);
  });

  testWidgets('Verify stays disabled until OTP and both PINs are complete',
      (tester) async {
    final (controller, _) = await _pumpReset(tester);
    expect(_verify(tester).onPressed, isNull);
    await _enter(tester, 0, '123456');
    await _enter(tester, 1, '1234');
    expect(_verify(tester).onPressed, isNull);
    expect(controller.forgotCalls, isEmpty);
    await _unmount(tester);
  });

  testWidgets('mismatched PINs show the existing error without an API call',
      (tester) async {
    final (controller, _) = await _pumpReset(tester);
    await _enter(tester, 0, '123456');
    await _enter(tester, 1, '1234');
    await _enter(tester, 2, '4321');
    expect(find.text('MPIN does not match.'), findsOneWidget);
    expect(controller.forgotCalls, isEmpty);
    await _unmount(tester);
  });

  testWidgets('matching PINs reset once and pop back', (tester) async {
    final (controller, _) = await _pumpReset(tester);
    await _enter(tester, 0, '123456');
    await _enter(tester, 1, '1234');
    await _enter(tester, 2, '1234');
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.forgotCalls, [('123456', '1234')]);
    expect(find.text('HOME'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('Reset MPIN back arrow pops', (tester) async {
    await _pumpReset(tester);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('HOME'), findsOneWidget);
    await _unmount(tester);
  });

  group('Lock screen renders without overflow across shared sizes', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpLock(tester, size: size);
        expect(tester.takeException(), isNull);
        expect(
          find.descendant(
            of: _pinputs,
            matching: find.byType(AnimatedContainer),
          ),
          findsNWidgets(4),
        );
        expect(tester.getRect(find.text('Forget PIN')).right,
            lessThanOrEqualTo(size.width));
      });
    }
  });

  group('Lock screen fingerprint uses MediaQuery width sizing', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpLock(tester, size: size);
        expect(tester.takeException(), isNull);
        final expected = (size.width * 74 / 360).clamp(60.0, 110.0);
        final fingerprint = tester.getSize(find.byType(SvgPicture));
        expect(fingerprint.width, closeTo(expected, 0.01));
        expect(fingerprint.height, closeTo(expected, 0.01));
        expect(tester.getRect(find.text('Use Fingerprint Instead')).right,
            lessThanOrEqualTo(size.width));
      });
    }
  });

  testWidgets('Lock screen large text scale does not overflow', (tester) async {
    await _pumpLock(tester, size: const Size(320, 568), textScale: 1.6);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lock screen shows the Figma copy and fingerprint button',
      (tester) async {
    await _pumpLock(tester);
    for (final label in [
      'Please enter your security pin',
      'Enter Pin',
      'Forget PIN',
      'Use Fingerprint Instead',
    ]) {
      expect(
        tester.widget<Text>(find.text(label)).style!.fontFamily,
        'Plus Jakarta Sans',
      );
    }
    final fingerprint = find.byType(SvgPicture);
    expect(fingerprint, findsOneWidget);
    expect(tester.getSize(fingerprint), const Size(74, 74));
  });

  testWidgets('Show / Forget PIN row uses the shared Figma sizes',
      (tester) async {
    await _pumpLock(tester);
    for (final label in ['Show', 'Forget PIN']) {
      final style = tester.widget<Text>(find.text(label)).style!;
      expect(style.fontSize, closeTo(12, 0.01));
      expect(style.fontWeight, FontWeight.w500);
    }
    expect(
      tester.widget<Text>(find.text('Forget PIN')).style!.decoration,
      TextDecoration.underline,
    );
    expect(
      tester.getSize(find.byIcon(Icons.visibility_off_outlined)),
      const Size(17, 17),
    );
  });

  testWidgets('action rows cap very large system text at 1.3x', (tester) async {
    await _pumpLock(tester, size: const Size(320, 568), textScale: 2.0);
    expect(tester.takeException(), isNull);
    final scaler = MediaQuery.textScalerOf(tester.element(find.text('Show')));
    expect(scaler.scale(12), closeTo(12 * 1.3, 0.01));
    expect(
      tester.getSize(find.byIcon(Icons.visibility_off_outlined)).width,
      closeTo(17.r * 1.3, 0.01),
    );
  });

  testWidgets('Reset MPIN timer row uses the shared Figma sizes',
      (tester) async {
    await _pumpReset(tester);
    for (final label in ['01:00', 'Resend']) {
      expect(
        tester.widget<Text>(find.text(label)).style!.fontSize,
        closeTo(12, 0.01),
      );
    }
    await _unmount(tester);
  });

  testWidgets('fingerprint is hidden without biometrics', (tester) async {
    await _pumpLock(tester, showFingerprint: false);
    expect(find.text('Use Fingerprint Instead'), findsNothing);
  });

  testWidgets('Lock screen forwards PIN, Forget PIN and fingerprint taps',
      (tester) async {
    final (completed, taps) = await _pumpLock(tester);
    await _enter(tester, 0, '1234');
    expect(completed, ['1234']);
    expect(find.text('*'), findsNWidgets(4));

    await tester.tap(find.text('Show'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.text('Forget PIN'));
    await tester.tap(find.text('Use Fingerprint Instead'));
    expect(taps, [0, 1]);
  });
}
