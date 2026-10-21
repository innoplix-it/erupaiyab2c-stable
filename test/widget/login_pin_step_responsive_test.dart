// Coverage for the Figma login PIN step (registered number -> Enter Pin).
//
// Uses the canonical `responsiveTestScreenSizes` matrix from
// test/helpers/responsive_test_sizes.dart - the device list is never
// duplicated here.

import 'package:e_rupaiya/features/auth/components/auth_pin_step.dart';
import 'package:e_rupaiya/features/auth/components/auth_step_parts.dart';
import 'package:e_rupaiya/widgets/custom_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinput/pinput.dart';

import '../helpers/responsive_test_sizes.dart';

const _pinLength = 4;
const _pinBorder = Color(0xFFDD5428);
// Figma login Continue disabled fill (matches AuthMobileStep / AuthPinStep).
const _disabledFill = Color(0xFFE3E3E6);

class _Calls {
  int continueTaps = 0;
  int forgotTaps = 0;
  int editTaps = 0;
}

Future<(_Calls, TextEditingController)> _pumpPinStep(
  WidgetTester tester, {
  Size size = const Size(360, 690),
  double textScale = 1.0,
  double keyboardInset = 0,
  EdgeInsets padding = EdgeInsets.zero,
  bool isLoading = false,
}) async {
  const dpr = 2.0;
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = size * dpr;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboardInset);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);

  final calls = _Calls();
  final pinController = TextEditingController();
  final focusNode = FocusNode();
  addTearDown(pinController.dispose);
  addTearDown(focusNode.dispose);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      fontSizeResolver: FontSizeResolvers.radius,
      builder: (context, _) => MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              padding: padding,
              viewInsets: EdgeInsets.only(bottom: keyboardInset),
            ),
            child: Scaffold(
              resizeToAvoidBottomInset: true,
              body: AuthPinStep(
                mobileController: TextEditingController(text: '9876543210'),
                pinController: pinController,
                pinFocusNode: focusNode,
                pinLength: _pinLength,
                isLoading: isLoading,
                onContinue: () => calls.continueTaps++,
                onForgotPin: () => calls.forgotTaps++,
                onEditMobile: () => calls.editTaps++,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return (calls, pinController);
}

Future<void> _typePin(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(EditableText).last, text);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Finder get _pinBoxes => find.descendant(
      of: find.byType(Pinput),
      matching: find.byType(AnimatedContainer),
    );

CustomElevatedButton _continue(WidgetTester tester) =>
    tester.widget<CustomElevatedButton>(find.byType(CustomElevatedButton));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PIN step renders 4 boxes without overflow across shared sizes', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpPinStep(tester, size: size);
        expect(tester.takeException(), isNull);
        expect(_pinBoxes, findsNWidgets(_pinLength));
        for (var i = 0; i < _pinLength; i++) {
          final rect = tester.getRect(_pinBoxes.at(i));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(size.width));
        }
      });
    }
  });

  group('PIN boxes use MediaQuery width sizing', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpPinStep(tester, size: size);
        final box = tester.getSize(_pinBoxes.first);
        expect(
          box.height,
          closeTo((size.width * 48 / 360).clamp(36.0, 72.0), 0.01),
        );
        expect(
          box.width,
          lessThanOrEqualTo((size.width * 93 / 360).clamp(64.0, 140.0) + 0.01),
        );
      });
    }
  });

  group('keyboard open keeps Continue above the keyboard', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        final inset = size.height * 0.4;
        await _pumpPinStep(tester, size: size, keyboardInset: inset);
        expect(tester.takeException(), isNull);
        final rect = tester.getRect(find.byType(CustomElevatedButton));
        expect(rect.bottom, lessThanOrEqualTo(size.height - inset));
      });
    }
  });

  group('safe-area insets are respected across shared sizes', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpPinStep(
          tester,
          size: size,
          padding: const EdgeInsets.only(top: 47, bottom: 34),
        );
        expect(tester.takeException(), isNull);
        expect(
          tester.getRect(find.text('Welcome to eRupaiya')).top,
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
          await _pumpPinStep(tester, size: size, textScale: scale);
          expect(tester.takeException(), isNull);
          expect(_pinBoxes, findsNWidgets(_pinLength));
          expect(tester.getRect(find.text('Forget PIN')).right,
              lessThanOrEqualTo(size.width));
          expect(tester.getRect(find.byType(CustomElevatedButton)).bottom,
              lessThanOrEqualTo(size.height));
        });
      }
    }
  });

  testWidgets('large text scale does not overflow', (tester) async {
    await _pumpPinStep(tester, size: const Size(320, 568), textScale: 1.6);
    expect(tester.takeException(), isNull);
  });

  testWidgets('boxes use the Figma card style', (tester) async {
    await _pumpPinStep(tester);
    final box = tester.widget<AnimatedContainer>(_pinBoxes.at(1));
    final decoration = box.decoration! as BoxDecoration;
    expect(decoration.color, Colors.white);
    expect(decoration.borderRadius, BorderRadius.circular(12.r));
    expect((decoration.border! as Border).top.color, _pinBorder);
    expect(decoration.boxShadow, hasLength(4));
  });

  testWidgets('PIN is masked with * and Show reveals it', (tester) async {
    await _pumpPinStep(tester);
    await _typePin(tester, '12');
    expect(find.text('*'), findsNWidgets(2));
    expect(find.text('1'), findsNothing);

    await tester.tap(find.text('Show'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Hide'), findsOneWidget);
  });

  testWidgets('accepts digits only', (tester) async {
    final (_, pin) = await _pumpPinStep(tester);
    await _typePin(tester, '1a-2');
    expect(pin.text, '12');
  });

  testWidgets('Continue is disabled until 4 digits, then logs in once',
      (tester) async {
    final (calls, _) = await _pumpPinStep(tester);
    expect(_continue(tester).onPressed, isNull);
    expect(_continue(tester).backgroundColor, _disabledFill);

    await _typePin(tester, '123');
    expect(_continue(tester).onPressed, isNull);
    expect(calls.continueTaps, 0);

    await _typePin(tester, '1234');
    expect(calls.continueTaps, 1);
    expect(_continue(tester).onPressed, isNotNull);
  });

  testWidgets('Forget PIN and the mobile field use their callbacks',
      (tester) async {
    final (calls, _) = await _pumpPinStep(tester);
    await tester.tap(find.text('Forget PIN'));
    await tester.tap(find.text('9876543210'));
    await tester.pump();
    expect(calls.forgotTaps, 1);
    expect(calls.editTaps, 1);
  });

  testWidgets('loading state disables Continue', (tester) async {
    await _pumpPinStep(tester, isLoading: true);
    expect(_continue(tester).isLoading, isTrue);
    expect(_continue(tester).onPressed, isNull);
  });
}
