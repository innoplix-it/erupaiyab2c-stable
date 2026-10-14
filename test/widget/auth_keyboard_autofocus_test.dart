// Every authentication input screen must open with its first field focused
// and the keyboard visible. Uses the canonical `responsiveTestScreenSizes`
// matrix from test/helpers/responsive_test_sizes.dart.

import 'package:e_rupaiya/features/auth/components/auth_app_lock_step.dart';
import 'package:e_rupaiya/features/auth/components/auth_identity_otp_step.dart';
import 'package:e_rupaiya/features/auth/components/auth_mobile_step.dart';
import 'package:e_rupaiya/features/auth/components/auth_mpin_setup_step.dart';
import 'package:e_rupaiya/features/auth/components/auth_pin_step.dart';
import 'package:e_rupaiya/features/auth/components/auth_reset_mpin_step.dart';
import 'package:e_rupaiya/features/auth/components/auth_step_parts.dart';
import 'package:e_rupaiya/features/auth/components/otp_verify_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinput/pinput.dart';

import '../helpers/responsive_test_sizes.dart';

void _noop() {}

/// Builds a screen and returns the focus node expected to hold focus.
typedef _ScreenBuilder = (Widget, FocusNode) Function();

final Map<String, _ScreenBuilder> _screens = {
  'Login mobile': () {
    final node = FocusNode();
    return (
      AuthMobileStep(
        controller: TextEditingController(),
        focusNode: node,
        onContinue: _noop,
        isConsentAllowed: false,
        onConsentChanged: (_) {},
      ),
      node,
    );
  },
  'Login PIN': () {
    final node = FocusNode();
    return (
      AuthPinStep(
        mobileController: TextEditingController(text: '9876543210'),
        pinController: TextEditingController(),
        pinFocusNode: node,
        pinLength: 4,
        onContinue: _noop,
        onForgotPin: _noop,
        onEditMobile: _noop,
      ),
      node,
    );
  },
  'Verify OTP': () {
    final node = FocusNode();
    return (
      OtpVerifyStep(
        otpLength: 6,
        otpController: TextEditingController(),
        otpFocusNode: node,
        phoneNumber: '9876543210',
        label: 'Enter OTP',
        timerText: '01:00',
        canResend: false,
        onResend: _noop,
        onVerify: null,
        onBack: _noop,
        onChangeNumber: _noop,
      ),
      node,
    );
  },
  'Mobile + Email OTP': () {
    final node = FocusNode();
    return (
      AuthIdentityOtpStep(
        title: 'Verify Identity',
        description: 'Enter both OTPs',
        otpLength: 6,
        mobileOtpController: TextEditingController(),
        emailOtpController: TextEditingController(),
        mobileOtpFocusNode: node,
        emailOtpFocusNode: FocusNode(),
        mobileTimerText: '01:00',
        emailTimerText: '01:00',
        canResendMobile: false,
        canResendEmail: false,
        onResendMobile: _noop,
        onResendEmail: _noop,
        onVerify: _noop,
        onBack: _noop,
        buttonLabel: 'Verify & Continue',
      ),
      node,
    );
  },
  'Create MPIN': () {
    final node = FocusNode();
    return (
      AuthMpinSetupStep(
        newPinController: TextEditingController(),
        confirmPinController: TextEditingController(),
        newPinFocusNode: node,
        confirmPinFocusNode: FocusNode(),
        onBack: _noop,
        onSubmit: _noop,
      ),
      node,
    );
  },
  'Reset MPIN': () {
    final node = FocusNode();
    return (
      AuthResetMpinStep(
        otpLength: 6,
        otpController: TextEditingController(),
        newPinController: TextEditingController(),
        confirmPinController: TextEditingController(),
        otpFocusNode: node,
        timerText: '01:00',
        canResend: false,
        onResend: _noop,
        onVerify: _noop,
        onBack: _noop,
      ),
      node,
    );
  },
  'App lock': () {
    final node = FocusNode();
    return (
      AuthAppLockStep(
        pinController: TextEditingController(),
        pinFocusNode: node,
        onPinCompleted: (_) {},
        onForgotPin: _noop,
      ),
      node,
    );
  },
};

/// Screens whose code boxes are disabled while a request runs. Returns the
/// autofocus node and, where present, a second code field's node.
typedef _BusyScreenBuilder = (Widget, FocusNode, FocusNode?) Function(
  ValueNotifier<bool> busy,
);

Widget _whenBusy(
  ValueNotifier<bool> busy,
  Widget Function(bool busy) builder,
) =>
    ValueListenableBuilder<bool>(
      valueListenable: busy,
      builder: (_, value, __) => builder(value),
    );

final Map<String, _BusyScreenBuilder> _busyScreens = {
  'Login PIN': (busy) {
    final node = FocusNode();
    final mobile = TextEditingController(text: '9876543210');
    final pin = TextEditingController();
    return (
      _whenBusy(
        busy,
        (value) => AuthPinStep(
          mobileController: mobile,
          pinController: pin,
          pinFocusNode: node,
          pinLength: 4,
          isLoading: value,
          onContinue: _noop,
          onForgotPin: _noop,
          onEditMobile: _noop,
        ),
      ),
      node,
      null,
    );
  },
  'Mobile + Email OTP': (busy) {
    final node = FocusNode();
    final email = FocusNode();
    final mobileOtp = TextEditingController();
    final emailOtp = TextEditingController();
    return (
      _whenBusy(
        busy,
        (value) => AuthIdentityOtpStep(
          title: 'Verify Identity',
          description: 'Enter both OTPs',
          otpLength: 6,
          mobileOtpController: mobileOtp,
          emailOtpController: emailOtp,
          mobileOtpFocusNode: node,
          emailOtpFocusNode: email,
          mobileTimerText: '01:00',
          emailTimerText: '01:00',
          canResendMobile: false,
          canResendEmail: false,
          onResendMobile: _noop,
          onResendEmail: _noop,
          onVerify: _noop,
          onBack: _noop,
          buttonLabel: 'Verify & Continue',
          isSubmitting: value,
        ),
      ),
      node,
      email,
    );
  },
  'Create MPIN': (busy) {
    final node = FocusNode();
    final confirm = FocusNode();
    final newPin = TextEditingController();
    final confirmPin = TextEditingController();
    return (
      _whenBusy(
        busy,
        (value) => AuthMpinSetupStep(
          newPinController: newPin,
          confirmPinController: confirmPin,
          newPinFocusNode: node,
          confirmPinFocusNode: confirm,
          onBack: _noop,
          onSubmit: _noop,
          isSubmitting: value,
        ),
      ),
      node,
      confirm,
    );
  },
  'Reset MPIN': (busy) {
    final node = FocusNode();
    final newPinNode = FocusNode();
    final otp = TextEditingController();
    final newPin = TextEditingController();
    final confirmPin = TextEditingController();
    return (
      _whenBusy(
        busy,
        (value) => AuthResetMpinStep(
          otpLength: 6,
          otpController: otp,
          newPinController: newPin,
          confirmPinController: confirmPin,
          otpFocusNode: node,
          newPinFocusNode: newPinNode,
          timerText: '01:00',
          canResend: false,
          onResend: _noop,
          onVerify: _noop,
          onBack: _noop,
          isSubmitting: value,
        ),
      ),
      node,
      newPinNode,
    );
  },
  'App lock': (busy) {
    final node = FocusNode();
    final pin = TextEditingController();
    return (
      _whenBusy(
        busy,
        (value) => AuthAppLockStep(
          pinController: pin,
          pinFocusNode: node,
          onPinCompleted: (_) {},
          onForgotPin: _noop,
          enabled: !value,
        ),
      ),
      node,
      null,
    );
  },
};

Future<void> _pump(WidgetTester tester, Widget screen, Size size) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = size * 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,

      fontSizeResolver: FontSizeResolvers.radius,
      builder: (_, __) => MaterialApp(home: Scaffold(body: screen)),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

bool _sentShow(WidgetTester tester) =>
    tester.testTextInput.log.any((call) => call.method == 'TextInput.show');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final MapEntry(key: name, value: build) in _screens.entries) {
    group('$name opens with the keyboard', () {
      for (final size in responsiveTestScreenSizes) {
        testWidgets('${size.width}x${size.height}', (tester) async {
          final (screen, node) = build();
          await _pump(tester, screen, size);
          expect(tester.takeException(), isNull);
          expect(node.hasFocus, isTrue, reason: 'first field focused');
          expect(tester.testTextInput.isVisible, isTrue);
          expect(_sentShow(tester), isTrue);
        });
      }
    });
  }

  testWidgets('showAuthKeyboard reopens the keyboard on a focused field',
      (tester) async {
    final (screen, node) = _screens['App lock']!();
    await _pump(tester, screen, const Size(390, 844));
    expect(node.hasFocus, isTrue);

    // A system sheet hides the keyboard while the field keeps focus.
    tester.testTextInput.log.clear();
    node.requestFocus();
    await tester.pump();
    expect(_sentShow(tester), isFalse);

    showAuthKeyboard(node);
    await tester.pump();
    expect(node.hasFocus, isTrue);
    expect(_sentShow(tester), isTrue);
  });

  // Sending, resending or verifying a code disables the boxes, which drops
  // focus and closes the keyboard; it must come back once they re-enable.
  for (final MapEntry(key: name, value: build) in _busyScreens.entries) {
    group('$name reopens the keyboard after a request', () {
      for (final size in responsiveTestScreenSizes) {
        testWidgets('${size.width}x${size.height}', (tester) async {
          final busy = ValueNotifier(false);
          addTearDown(busy.dispose);
          final (screen, node, _) = build(busy);
          await _pump(tester, screen, size);
          expect(node.hasFocus, isTrue);

          busy.value = true;
          await tester.pump();
          expect(node.hasFocus, isFalse, reason: 'disabled boxes lose focus');

          tester.testTextInput.log.clear();
          busy.value = false;
          await tester.pump();
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(node.hasFocus, isTrue);
          expect(_sentShow(tester), isTrue);
        });
      }
    });
  }

  testWidgets('focus returns to the field the user was typing in',
      (tester) async {
    for (final MapEntry(key: name, value: build) in _busyScreens.entries) {
      final busy = ValueNotifier(false);
      final (screen, first, second) = build(busy);
      if (second == null) {
        busy.dispose();
        continue;
      }
      await _pump(tester, screen, const Size(390, 844));
      second.requestFocus();
      await tester.pump();
      expect(second.hasFocus, isTrue, reason: name);

      busy.value = true;
      await tester.pump();
      busy.value = false;
      await tester.pump();
      await tester.pump();
      expect(second.hasFocus, isTrue, reason: name);
      expect(first.hasFocus, isFalse, reason: name);
      await tester.pumpWidget(const SizedBox.shrink());
      busy.dispose();
    }
  });

  testWidgets('a dialog on top keeps the keyboard closed', (tester) async {
    final busy = ValueNotifier(false);
    addTearDown(busy.dispose);
    final (screen, node, _) = _busyScreens['Mobile + Email OTP']!(busy);
    await _pump(tester, screen, const Size(390, 844));
    busy.value = true;
    await tester.pump();
    showDialog<void>(
      context: tester.element(find.byType(AuthIdentityOtpStep)),
      builder: (_) => const AlertDialog(content: Text('Verified')),
    );
    await tester.pump();
    busy.value = false;
    await tester.pump();
    await tester.pump();
    expect(node.hasFocus, isFalse);
  });

  testWidgets('non-autofocus boxes do not open the keyboard', (tester) async {
    await _pump(
      tester,
      Pinput(controller: TextEditingController(), length: 4),
      const Size(390, 844),
    );
    expect(tester.testTextInput.isVisible, isFalse);
    expect(_sentShow(tester), isFalse);
  });
}
