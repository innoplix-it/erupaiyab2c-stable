import 'package:e_rupaiya/features/auth/components/auth_mobile_step.dart';
import 'package:e_rupaiya/features/auth/components/auth_pin_step.dart';
import 'package:e_rupaiya/features/auth/components/otp_verify_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (_, __) => MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthKeyboardOnOpen', () {
    testWidgets('AuthMobileStep does not autofocus the mobile field',
        (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(() {
        controller.dispose();
        focusNode.dispose();
      });

      await tester.pumpWidget(
        _wrap(
          AuthMobileStep(
            controller: controller,
            focusNode: focusNode,
            onContinue: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Closed Figma layout first — keyboard opens only when user taps.
      expect(focusNode.hasFocus, isFalse);
    });

    testWidgets('AuthPinStep autofocuses the PIN field', (tester) async {
      final mobileController = TextEditingController(text: '9876543210');
      final pinController = TextEditingController();
      final pinFocusNode = FocusNode();
      addTearDown(() {
        mobileController.dispose();
        pinController.dispose();
        pinFocusNode.dispose();
      });

      await tester.pumpWidget(
        _wrap(
          AuthPinStep(
            mobileController: mobileController,
            pinController: pinController,
            pinFocusNode: pinFocusNode,
            pinLength: 4,
            onContinue: () {},
            onForgotPin: () {},
            onEditMobile: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(pinFocusNode.hasFocus, isTrue);
    });

    testWidgets('OtpVerifyStep autofocuses the OTP field', (tester) async {
      final otpController = TextEditingController();
      final otpFocusNode = FocusNode();
      addTearDown(() {
        otpController.dispose();
        otpFocusNode.dispose();
      });

      await tester.pumpWidget(
        _wrap(
          OtpVerifyStep(
            otpLength: 6,
            otpController: otpController,
            otpFocusNode: otpFocusNode,
            phoneNumber: '9876543210',
            label: 'OTP',
            timerText: '00:30',
            canResend: false,
            onResend: () {},
            onVerify: () {},
            onBack: () {},
            onChangeNumber: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(otpFocusNode.hasFocus, isTrue);
    });
  });
}
