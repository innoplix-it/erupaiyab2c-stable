// Coverage for the restyled Verify OTP screen (standard login flow).
//
// Uses the canonical `responsiveTestScreenSizes` matrix from
// test/helpers/responsive_test_sizes.dart - the device list is never
// duplicated here.

import 'package:e_rupaiya/features/auth/components/auth_code_fields.dart';
import 'package:e_rupaiya/features/auth/components/otp_verify_step.dart';
import 'package:e_rupaiya/features/auth/controllers/auth_controller.dart';
import 'package:e_rupaiya/features/auth/models/auth_flow.dart';
import 'package:e_rupaiya/features/auth/models/auth_state.dart';
import 'package:e_rupaiya/features/auth/models/otp_verification_args.dart';
import 'package:e_rupaiya/features/auth/repositories/auth_repository.dart';
import 'package:e_rupaiya/features/auth/views/otp_verification_view.dart';
import 'package:e_rupaiya/widgets/custom_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pinput/pinput.dart';

import '../helpers/responsive_test_sizes.dart';

const _otpLength = 4;
const _focusedBorder = Color(0xFF71717A);
const _disabledFill = Color(0xFFA1A1AA);
const _enabledFill = Color(0xFFDD5428);
const _smsChannel = MethodChannel('sms_autofill');

class _MockAuthRepository extends Mock implements AuthRepository {}

class _FakeAuthController extends AuthController {
  _FakeAuthController({String? pendingMobile, String? errorMessage})
      : super(
          repository: _MockAuthRepository(),
          shouldCheckInitialAuth: false,
        ) {
    state = AuthState(
      isAuthenticated: false,
      hasTemporaryAccess: true,
      isLoading: false,
      isSubmitting: false,
      pendingMobile: pendingMobile,
      errorMessage: errorMessage,
    );
  }

  final verifyCalls = <String>[];
  final resendCalls = <String>[];

  @override
  Future<bool> verifyOtp({required String otp, String? mobile}) async {
    verifyCalls.add(otp);
    // Failing keeps the test on this screen instead of navigating away.
    return false;
  }

  @override
  Future<AuthFlow?> checkLogin({required String mobile}) async {
    resendCalls.add(mobile);
    return AuthFlow.login;
  }
}

Future<_FakeAuthController> _pumpOtpView(
  WidgetTester tester, {
  Size size = const Size(360, 690),
  double textScale = 1.0,
  double keyboardInset = 0,
  EdgeInsets padding = EdgeInsets.zero,
  String? phoneNumber = '9876543210',
  String? pendingMobile,
  String? errorMessage,
}) async {
  const dpr = 2.0;
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = size * dpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final controller = _FakeAuthController(
    pendingMobile: pendingMobile,
    errorMessage: errorMessage,
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authControllerProvider.overrideWith((ref) => controller)],
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        fontSizeResolver: FontSizeResolvers.radius,
        builder: (context, _) => MaterialApp(
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
            args: OtpVerificationArgs(phoneNumber: phoneNumber),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return controller;
}

/// Disposes the view so its countdown timer is cancelled before the test ends.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

TextEditingController _otpController(WidgetTester tester) =>
    tester.widget<Pinput>(find.byType(Pinput)).controller!;

Future<void> _typeOtp(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(EditableText), text);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

List<AnimatedContainer> _boxes(WidgetTester tester) => tester
    .widgetList<AnimatedContainer>(
      find.descendant(
        of: find.byType(Pinput),
        matching: find.byType(AnimatedContainer),
      ),
    )
    .toList();

Color _borderColor(AnimatedContainer box) =>
    ((box.decoration! as BoxDecoration).border! as Border).top.color;

int _focusedIndex(WidgetTester tester) =>
    _boxes(tester).indexWhere((b) => _borderColor(b) == _focusedBorder);

CustomElevatedButton _verifyButton(WidgetTester tester) =>
    tester.widget<CustomElevatedButton>(find.byType(CustomElevatedButton));

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

  group('renders all 4 OTP boxes without overflow across shared sizes', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpOtpView(tester, size: size);
        expect(tester.takeException(), isNull);

        final boxes = find.descendant(
          of: find.byType(Pinput),
          matching: find.byType(AnimatedContainer),
        );
        expect(boxes, findsNWidgets(_otpLength));
        for (var i = 0; i < _otpLength; i++) {
          final rect = tester.getRect(boxes.at(i));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(size.width));
          expect(rect.width, greaterThan(20));
        }
        final verifyRect = tester.getRect(find.byType(CustomElevatedButton));
        expect(verifyRect.bottom, lessThanOrEqualTo(size.height));
        await _unmount(tester);
      });
    }
  });

  group('OTP boxes and Verify use MediaQuery width sizing', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpOtpView(tester, size: size);
        expect(tester.takeException(), isNull);
        final boxes = find.descendant(
          of: find.byType(Pinput),
          matching: find.byType(AnimatedContainer),
        );
        final box = tester.getSize(boxes.first);
        expect(
          box.height,
          closeTo((size.width * 47 / 360).clamp(36.0, 70.0), 0.01),
        );
        expect(
          box.width,
          lessThanOrEqualTo((size.width * 58 / 360).clamp(44.0, 86.0) + 0.01),
        );
        expect(
          tester.getSize(find.byType(CustomElevatedButton)).height,
          closeTo((size.width * 48 / 360).clamp(40.0, 56.0), 0.01),
        );
        await _unmount(tester);
      });
    }
  });

  group('keyboard open keeps Verify above the keyboard', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        final inset = size.height * 0.4;
        await _pumpOtpView(tester, size: size, keyboardInset: inset);
        expect(tester.takeException(), isNull);
        final verifyRect = tester.getRect(find.byType(CustomElevatedButton));
        expect(verifyRect.bottom, lessThanOrEqualTo(size.height - inset));
        await _unmount(tester);
      });
    }
  });

  group('safe-area insets are respected across shared sizes', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpOtpView(
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
          await _pumpOtpView(tester, size: size, textScale: scale);
          expect(tester.takeException(), isNull);
          final boxes = find.descendant(
            of: find.byType(Pinput),
            matching: find.byType(AnimatedContainer),
          );
          expect(boxes, findsNWidgets(_otpLength));
          expect(tester.getRect(boxes.last).right,
              lessThanOrEqualTo(size.width));
          expect(tester.getRect(find.byType(CustomElevatedButton)).bottom,
              lessThanOrEqualTo(size.height));
          await _unmount(tester);
        });
      }
    }
  });

  group('large text scale and safe-area insets do not overflow', () {
    for (final size in const [Size(280, 653), Size(320, 480), Size(360, 690)]) {
      testWidgets('${size.width}x${size.height} @1.6x', (tester) async {
        await _pumpOtpView(
          tester,
          size: size,
          textScale: 1.6,
          padding: const EdgeInsets.only(top: 44, bottom: 34),
        );
        expect(tester.takeException(), isNull);
        await _unmount(tester);
      });
    }
  });

  testWidgets('shows the mobile number from route arguments', (tester) async {
    await _pumpOtpView(tester, phoneNumber: '9123456780');
    expect(
      find.textContaining('9123456780', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('8055851234', findRichText: true),
      findsNothing,
    );
    await _unmount(tester);
  });

  testWidgets('falls back to the pending mobile in auth state', (tester) async {
    await _pumpOtpView(
      tester,
      phoneNumber: null,
      pendingMobile: '9000011111',
    );
    expect(
      find.textContaining('9000011111', findRichText: true),
      findsOneWidget,
    );
    await _unmount(tester);
  });

  testWidgets('accepts digits only', (tester) async {
    await _pumpOtpView(tester);
    await _typeOtp(tester, '1a2-b3');
    expect(_otpController(tester).text, '123');
    await _unmount(tester);
  });

  testWidgets('focus moves forward on entry and back on delete',
      (tester) async {
    await _pumpOtpView(tester);
    expect(_focusedIndex(tester), 0);

    await _typeOtp(tester, '12');
    expect(_focusedIndex(tester), 2);
    expect(_borderColor(_boxes(tester)[0]), _disabledFill);

    await _typeOtp(tester, '1');
    expect(_focusedIndex(tester), 1);
    await _unmount(tester);
  });

  testWidgets('Verify stays disabled until all 4 digits are entered',
      (tester) async {
    final controller = await _pumpOtpView(tester);
    expect(_verifyButton(tester).onPressed, isNull);
    expect(_verifyButton(tester).backgroundColor, _disabledFill);

    await _typeOtp(tester, '123');
    expect(_verifyButton(tester).onPressed, isNull);
    expect(controller.verifyCalls, isEmpty);

    // The failing fake verify puts the field in its error state; clearing the
    // error by editing re-enables the button for a manual retry.
    await _typeOtp(tester, '1234');
    expect(controller.verifyCalls, ['1234']);
    await _typeOtp(tester, '123');
    await _typeOtp(tester, '1235');
    expect(_verifyButton(tester).onPressed, isNotNull);
    expect(_verifyButton(tester).backgroundColor, _enabledFill);
    await _unmount(tester);
  });

  testWidgets('completing the OTP verifies exactly once', (tester) async {
    final controller = await _pumpOtpView(tester);
    await _typeOtp(tester, '1234');
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.verifyCalls, ['1234']);
    await _unmount(tester);
  });

  testWidgets('pasting a full code fills every box and verifies once',
      (tester) async {
    final controller = await _pumpOtpView(tester);
    await _typeOtp(tester, '9876');
    expect(_otpController(tester).text, '9876');
    expect(find.text('9'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(controller.verifyCalls, ['9876']);
    await _unmount(tester);
  });

  testWidgets('SMS autofill populates the boxes and verifies once',
      (tester) async {
    final controller = await _pumpOtpView(tester);
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      _smsChannel.name,
      _smsChannel.codec.encodeMethodCall(
        const MethodCall('smscode', '2468'),
      ),
      (_) {},
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(_otpController(tester).text, '2468');
    expect(controller.verifyCalls, ['2468']);
    await _unmount(tester);
  });

  testWidgets('verification failure shows the error message', (tester) async {
    await _pumpOtpView(tester, errorMessage: 'Invalid OTP');
    await _typeOtp(tester, '1111');
    // Shown under the boxes, between the timer and Resend.
    expect(
      find.descendant(
        of: find.byType(AuthOtpTimerRow),
        matching: find.text('Please enter a valid OTP'),
      ),
      findsOneWidget,
    );
    expect(
      _boxes(tester).every((b) => _borderColor(b) == Colors.red),
      isTrue,
    );
    await _unmount(tester);
  });

  testWidgets('timer counts down and Resend waits for the cooldown',
      (tester) async {
    final controller = await _pumpOtpView(tester);
    expect(find.text('01:00'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:59'), findsOneWidget);

    await tester.tap(find.text('Resend'));
    await tester.pump();
    expect(controller.resendCalls, isEmpty);

    await tester.pump(const Duration(seconds: 59));
    expect(find.text('00:00'), findsOneWidget);

    await tester.tap(find.text('Resend'));
    await tester.pump();
    expect(controller.resendCalls, ['9876543210']);
    expect(find.text('01:00'), findsOneWidget);

    await tester.tap(find.text('Resend'));
    await tester.pump();
    expect(controller.resendCalls, hasLength(1));
    await _unmount(tester);
  });

  testWidgets('submitting state shows Verifying and disables the button',
      (tester) async {
    final controller = await _pumpOtpView(tester);
    await _typeOtp(tester, '123');
    controller.state = controller.state.copyWith(isSubmitting: true);
    await tester.pump();
    expect(find.text('Verifying...'), findsOneWidget);
    expect(_verifyButton(tester).isLoading, isTrue);
    controller.state = controller.state.copyWith(isSubmitting: false);
    await _unmount(tester);
  });

  testWidgets('uses Plus Jakarta Sans and the Figma Resend style',
      (tester) async {
    await _pumpOtpView(tester);
    final resend = tester.widget<Text>(find.text('Resend'));
    expect(resend.style!.fontFamily, 'Plus Jakarta Sans');
    expect(resend.style!.fontWeight, FontWeight.w500);
    expect(resend.style!.fontSize, closeTo(12, 0.01));
    expect(
      tester.widget<Text>(find.text('01:00')).style!.fontSize,
      closeTo(12, 0.01),
    );
    expect(resend.style!.height, 1);

    for (final label in ['Verify OTP', 'Enter OTP', '01:00']) {
      final style = tester.widget<Text>(find.text(label)).style!;
      expect(style.fontFamily, 'Plus Jakarta Sans');
      expect(style.fontWeight, FontWeight.w500);
      expect(style.letterSpacing, 0);
      expect(style.height, isNotNull);
    }

    final subtitle = tester
        .widget<Text>(
          find.byWidgetPredicate((w) => w is Text && w.textSpan != null),
        )
        .textSpan! as TextSpan;
    final spans = subtitle.children!.cast<TextSpan>();
    final number = spans.firstWhere((s) => s.text == '9876543210 ');
    final change = spans.firstWhere((s) => s.text == 'Change');
    expect(number.style!.fontWeight, FontWeight.w600);
    expect(change.style!.fontWeight, FontWeight.w500);
    for (final span in spans) {
      expect(span.style!.fontFamily, 'Plus Jakarta Sans');
      expect(span.style!.fontSize, isNotNull);
      expect(span.style!.letterSpacing, 0);
    }

    // Timer/Resend icons only (marquee background has its own SVGs).
    final icons = tester
        .widgetList<SvgPicture>(find.descendant(
          of: find.byType(AuthOtpTimerRow),
          matching: find.byType(SvgPicture),
        ))
        .toList();
    expect(icons, hasLength(2));
    // Shared row: clock 11.5x13, resend 18x18.
    // Ranges absorb the sub-pixel .r scale instead of pinning raw pixels.
    final timerSize = tester.getSize(find.byWidget(icons[0]));
    final resendSize = tester.getSize(find.byWidget(icons[1]));
    expect(timerSize.width, inInclusiveRange(11, 12));
    expect(timerSize.height, inInclusiveRange(12.5, 13.5));
    expect(resendSize.width, inInclusiveRange(17.5, 18.5));
    expect(resendSize.height, inInclusiveRange(17.5, 18.5));
    await _unmount(tester);
  });
}
