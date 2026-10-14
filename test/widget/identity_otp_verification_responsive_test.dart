// Coverage for the mobile + email OTP verification screen (temporary block
// and new device flows), restyled to the Reset MPIN Figma layout.
//
// Uses the canonical `responsiveTestScreenSizes` matrix from
// test/helpers/responsive_test_sizes.dart - the device list is never
// duplicated here.

import 'package:e_rupaiya/config/temporary_block_debug_config.dart';
import 'package:e_rupaiya/features/auth/components/auth_code_fields.dart';
import 'package:e_rupaiya/features/auth/components/auth_identity_otp_step.dart';
import 'package:e_rupaiya/features/auth/controllers/auth_controller.dart';
import 'package:e_rupaiya/features/auth/models/auth_state.dart';
import 'package:e_rupaiya/features/auth/models/otp_verification_args.dart';
import 'package:e_rupaiya/features/auth/repositories/auth_repository.dart';
import 'package:e_rupaiya/features/auth/views/otp_verification_view.dart';
import 'package:e_rupaiya/widgets/custom_elevated_button.dart';
import 'package:e_rupaiya/widgets/k_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pinput/pinput.dart';

import '../helpers/responsive_test_sizes.dart';

const _otpLength = 6;
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

  int sendRecoveryCalls = 0;
  final sendDeviceCalls = <String>[];
  final recoveryVerifyCalls = <(String, String)>[];
  final deviceVerifyCalls = <(String, String, String)>[];

  @override
  Future<String?> sendAccountRecoveryOtp() async {
    sendRecoveryCalls++;
    return 'OTP sent';
  }

  @override
  Future<bool> verifyAccountRecoveryOtp({
    required String mobileOtp,
    required String emailOtp,
  }) async {
    recoveryVerifyCalls.add((mobileOtp, emailOtp));
    // Failing keeps the test on this screen instead of navigating away.
    return false;
  }

  @override
  Future<String?> sendDeviceOtp({required String verificationId}) async {
    sendDeviceCalls.add(verificationId);
    return 'OTP sent';
  }

  @override
  Future<String?> verifyDeviceOtp({
    required String verificationId,
    required String mobileOtp,
    required String emailOtp,
  }) async {
    deviceVerifyCalls.add((verificationId, mobileOtp, emailOtp));
    // No success route is configured, so a non-null result stays here.
    return 'verified';
  }
}

Future<_FakeAuthController> _pumpView(
  WidgetTester tester, {
  Size size = const Size(360, 690),
  double textScale = 1.0,
  double keyboardInset = 0,
  EdgeInsets padding = EdgeInsets.zero,
  TemporaryBlockFlowType flowType = TemporaryBlockFlowType.noKyc,
}) async {
  const dpr = 2.0;
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = size * dpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final controller = _FakeAuthController();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith((ref) => controller)],
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        fontSizeResolver: FontSizeResolvers.radius,
        builder: (context, _) => MaterialApp(
          navigatorKey: navigatorKey,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              padding: padding,
              viewPadding: padding,
              viewInsets: EdgeInsets.only(bottom: keyboardInset),
            ),
            child: child!,
          ),
          home: OtpVerificationView(
            args: OtpVerificationArgs(
              heading: 'Verify Identity',
              temporaryBlockFlowType: flowType,
              deviceVerificationId: 'device-42',
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return controller;
}

/// Disposes the view so its countdown timers are cancelled before the test
/// ends.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

Finder get _pinputs => find.byType(Pinput);

/// Lets the wrong-OTP snackbar finish its auto-dismiss timer.
Future<void> _drainSnackbar(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 5));

Finder _boxesOf(int field) => find.descendant(
      of: _pinputs.at(field),
      matching: find.byType(AnimatedContainer),
    );

Future<void> _enterOtp(WidgetTester tester, int field, String text) async {
  await tester.enterText(
    find.descendant(
        of: _pinputs.at(field), matching: find.byType(EditableText)),
    text,
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _tapVerify(WidgetTester tester) async {
  await tester.tap(find.byType(CustomElevatedButton));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void _expectFieldsInside(WidgetTester tester, Size size) {
  expect(_pinputs, findsNWidgets(2));
  for (final field in [0, 1]) {
    final boxes = _boxesOf(field);
    expect(boxes, findsNWidgets(_otpLength));
    expect(tester.getRect(boxes.first).left, greaterThanOrEqualTo(0));
    expect(tester.getRect(boxes.last).right, lessThanOrEqualTo(size.width));
  }
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

  group('renders the Reset MPIN style layout across shared sizes', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpView(tester, size: size);
        expect(tester.takeException(), isNull);
        expect(find.byType(AuthIdentityOtpStep), findsOneWidget);
        expect(find.text('Mobile OTP'), findsOneWidget);
        expect(find.text('Email OTP'), findsOneWidget);
        _expectFieldsInside(tester, size);
        expect(
          tester.getRect(find.byType(CustomElevatedButton)).bottom,
          lessThanOrEqualTo(size.height),
        );
        await _unmount(tester);
      });
    }
  });

  group('OTP boxes use MediaQuery width sizing', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpView(tester, size: size);
        for (final field in [0, 1]) {
          final box = tester.getSize(_boxesOf(field).first);
          expect(
            box.height,
            closeTo((size.width * 47 / 360).clamp(36.0, 70.0), 0.01),
          );
          expect(
            box.width,
            lessThanOrEqualTo(
              (size.width * 58 / 360).clamp(44.0, 86.0) + 0.01,
            ),
          );
        }
        await _unmount(tester);
      });
    }
  });

  group('keyboard open keeps Verify above the keyboard', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        final inset = size.height * 0.4;
        await _pumpView(tester, size: size, keyboardInset: inset);
        expect(tester.takeException(), isNull);
        expect(
          tester.getRect(find.byType(CustomElevatedButton)).bottom,
          lessThanOrEqualTo(size.height - inset),
        );
        await _unmount(tester);
      });
    }
  });

  group('safe-area insets are respected across shared sizes', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpView(
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

  group('supported text scales across shared sizes', () {
    for (final scale in const [0.85, 1.15]) {
      for (final size in responsiveTestScreenSizes) {
        testWidgets('${size.width}x${size.height} @${scale}x', (tester) async {
          await _pumpView(tester, size: size, textScale: scale);
          expect(tester.takeException(), isNull);
          _expectFieldsInside(tester, size);
          expect(
            tester.getRect(find.byType(CustomElevatedButton)).bottom,
            lessThanOrEqualTo(size.height),
          );
          await _unmount(tester);
        });
      }
    }
  });

  testWidgets('sends the OTPs once when the screen opens', (tester) async {
    final controller = await _pumpView(tester);
    expect(controller.sendRecoveryCalls, 1);
    await _unmount(tester);
  });

  testWidgets('incomplete OTPs show the existing error and never verify',
      (tester) async {
    final controller = await _pumpView(tester);
    await _enterOtp(tester, 0, '123456');
    await _enterOtp(tester, 1, '654');
    await _tapVerify(tester);
    expect(find.text('Please enter both 6-digit OTPs.'), findsOneWidget);
    expect(controller.recoveryVerifyCalls, isEmpty);
    await _unmount(tester);
  });

  testWidgets('verifies the mobile and email OTPs typed in the boxes',
      (tester) async {
    final controller = await _pumpView(tester);
    await _enterOtp(tester, 0, '123456');
    await _enterOtp(tester, 1, '654321');
    await _tapVerify(tester);
    expect(controller.recoveryVerifyCalls, [('123456', '654321')]);
    // The fake rejects the OTPs, so the wrong-OTP feedback must show under
    // both OTP rows, between the timer and Resend.
    expect(
      find.descendant(
        of: find.byType(AuthOtpTimerRow),
        matching: find.text('Please enter a valid OTP'),
      ),
      findsNWidgets(2),
    );
    expect(find.text('Please enter a valid OTP'), findsNWidgets(2));
    await _drainSnackbar(tester);
    await _unmount(tester);
  });

  testWidgets('editing after a delete sends the corrected OTP', (tester) async {
    final controller = await _pumpView(tester);
    await _enterOtp(tester, 0, '123456');
    await _enterOtp(tester, 0, '1234');
    await _enterOtp(tester, 0, '123499');
    await _enterOtp(tester, 1, '000111');
    await _tapVerify(tester);
    expect(controller.recoveryVerifyCalls, [('123499', '000111')]);
    await _drainSnackbar(tester);
    await _unmount(tester);
  });

  testWidgets('device verification flow passes the verification id',
      (tester) async {
    final controller = await _pumpView(
      tester,
      flowType: TemporaryBlockFlowType.deviceVerification,
    );
    expect(controller.sendDeviceCalls, ['device-42']);
    await _enterOtp(tester, 0, '111222');
    await _enterOtp(tester, 1, '333444');
    await _tapVerify(tester);
    expect(controller.deviceVerifyCalls, [('device-42', '111222', '333444')]);
    await _unmount(tester);
  });

  testWidgets('both timers count down as mm:ss and Resend waits',
      (tester) async {
    final controller = await _pumpView(tester);
    expect(find.text('01:00'), findsNWidgets(2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:59'), findsNWidgets(2));

    await tester.tap(find.text('Resend').first);
    await tester.pump();
    expect(controller.sendRecoveryCalls, 1);

    await tester.pump(const Duration(seconds: 59));
    expect(find.text('00:00'), findsNWidgets(2));
    await tester.tap(find.text('Resend').first);
    await tester.pump();
    expect(controller.sendRecoveryCalls, 2);
    expect(find.text('01:00'), findsNWidgets(2));
    // Lets the resend snackbar finish its auto-dismiss timer.
    await tester.pump(const Duration(seconds: 3));
    await _unmount(tester);
  });

  testWidgets('uses the Reset MPIN typography', (tester) async {
    await _pumpView(tester);
    final title = tester.widget<Text>(find.text('Verify Identity')).style!;
    expect(title.fontFamily, 'Plus Jakarta Sans');
    expect(title.fontWeight, FontWeight.w500);
    expect(title.fontSize, closeTo(18, 0.01));
    for (final label in ['Mobile OTP', 'Email OTP']) {
      final style = tester.widget<Text>(find.text(label)).style!;
      expect(style.fontFamily, 'Plus Jakarta Sans');
      expect(style.fontWeight, FontWeight.w500);
      expect(style.fontSize, closeTo(12, 0.01));
    }
    expect(find.text('Verify & Continue'), findsOneWidget);
    await _unmount(tester);
  });
}
