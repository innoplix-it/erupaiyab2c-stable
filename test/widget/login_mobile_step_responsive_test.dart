// Responsive coverage for the reworked Signup/Login mobile-number step.
//
// Uses the canonical `responsiveTestScreenSizes` matrix from
// test/helpers/responsive_test_sizes.dart - the device list is never
// duplicated here.

import 'package:e_rupaiya/constants/app_colors.dart';
import 'package:e_rupaiya/constants/file_constants.dart';
import 'package:e_rupaiya/features/auth/components/auth_mobile_step.dart';
import 'package:e_rupaiya/features/auth/components/auth_step_parts.dart';
import 'package:e_rupaiya/widgets/custom_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/responsive_test_sizes.dart';

const Color _disabledFill = Color(0xFFA1A1AA);
const Color _enabledFill = Color(0xFFDD5428);

Future<void> _pumpMobileStep(
  WidgetTester tester, {
  required Size size,
  double textScale = 1.0,
  double keyboardInset = 0,
  EdgeInsets padding = EdgeInsets.zero,
  TextEditingController? controller,
  bool consent = false,
  ValueChanged<bool>? onConsentChanged,
  VoidCallback? onContinue,
}) async {
  const dpr = 2.0;
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = size * dpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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
              body: AuthMobileStep(
                controller: controller ?? TextEditingController(text: ''),
                isConsentAllowed: consent,
                onConsentChanged: onConsentChanged ?? (_) {},
                onContinue: onContinue,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 120));
}

Color? _continueFill(WidgetTester tester) => tester
    .widget<CustomElevatedButton>(find.byType(CustomElevatedButton))
    .backgroundColor;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('mobile step renders without overflow across shared sizes', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpMobileStep(tester, size: size);
        expect(tester.takeException(), isNull);

        expect(find.text('eRupaiya'), findsOneWidget);
        expect(find.text('Welcome to eRupaiya'), findsOneWidget);
        expect(
          find.text('Enter your mobile number to continue.'),
          findsOneWidget,
        );
        expect(find.text('Mobile Number'), findsOneWidget);
        expect(find.text('+91'), findsOneWidget);
        expect(
          find.text('enter 10 digit mobile number'),
          findsOneWidget,
        );
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byType(Checkbox), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);
      });
    }
  });

  group('consent row: space above and checkbox aligned with the text', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpMobileStep(tester, size: size);
        expect(tester.takeException(), isNull);

        final field = tester.getRect(find.byType(AuthMobileField));
        final row =
            tester.getRect(find.byKey(const ValueKey('auth-consent-row')));
        final expectedGap = (size.height * 22 / 690).clamp(18.0, 30.0);
        expect(row.top - field.bottom, moreOrLessEquals(expectedGap));

        final box = tester.getRect(find.byType(Checkbox));
        final text = tester.getRect(find.byType(Wrap));
        expect(box.center.dy, moreOrLessEquals(text.center.dy, epsilon: 0.5));
        expect(box.right, lessThan(text.left));
        expect(text.right, lessThanOrEqualTo(size.width));
        expect(find.text('by continuing, I agree to'), findsOneWidget);
        expect(find.text('terms of use policy'), findsOneWidget);
        expect(find.text('privacy policy'), findsOneWidget);
      });
    }
  });

  group('consent row: space above and checkbox aligned with the text', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpMobileStep(tester, size: size);
        expect(tester.takeException(), isNull);

        final field = tester.getRect(find.byType(AuthMobileField));
        final row =
            tester.getRect(find.byKey(const ValueKey('auth-consent-row')));
        final expectedGap = (size.height * 22 / 690).clamp(18.0, 30.0);
        expect(row.top - field.bottom, moreOrLessEquals(expectedGap));

        final box = tester.getRect(find.byType(Checkbox));
        final text = tester.getRect(find.byType(Wrap));
        expect(box.center.dy, moreOrLessEquals(text.center.dy, epsilon: 0.5));
        expect(box.right, lessThan(text.left));
        expect(text.right, lessThanOrEqualTo(size.width));
        expect(find.text('by continuing, I agree to'), findsOneWidget);
        expect(find.text('terms of use policy'), findsOneWidget);
        expect(find.text('privacy policy'), findsOneWidget);
      });
    }
  });

  group('primary controls stay inside the viewport', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpMobileStep(tester, size: size);
        final screen = size;

        for (final finder in [
          find.text('Welcome to eRupaiya'),
          find.text('Mobile Number'),
          find.text('Continue'),
        ]) {
          final rect = tester.getRect(finder);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(screen.width));
        }

        // The CTA is pinned to the bottom of the available space and must
        // never be pushed off screen.
        expect(
          tester.getRect(find.text('Continue')).bottom,
          lessThanOrEqualTo(screen.height),
        );
      });
    }
  });

  group('keyboard-open layout across shared sizes', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('keyboard at ${size.width}x${size.height}', (tester) async {
        await _pumpMobileStep(
          tester,
          size: size,
          keyboardInset: size.height * 0.4,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Continue'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
        final screenBottom = size.height - (size.height * 0.4);
        expect(
          tester.getRect(find.text('Continue')).bottom,
          lessThanOrEqualTo(screenBottom + 1),
        );
      });
    }
  });

  group('safe-area padding is respected across shared sizes', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpMobileStep(
          tester,
          size: size,
          padding: const EdgeInsets.only(top: 47, bottom: 34),
        );
        expect(tester.takeException(), isNull);
        // The first content row sits below the status-bar inset rather than
        // under it.
        expect(
          tester.getRect(find.text('eRupaiya')).top,
          greaterThanOrEqualTo(47),
        );
        // Continue stays clear of the home-indicator inset.
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
          await _pumpMobileStep(tester, size: size, textScale: scale);
          expect(tester.takeException(), isNull);
          final button = tester.getRect(find.byType(CustomElevatedButton));
          expect(button.left, greaterThanOrEqualTo(0));
          expect(button.right, lessThanOrEqualTo(size.width));
          expect(button.bottom, lessThanOrEqualTo(size.height));
          expect(find.text('Mobile Number'), findsOneWidget);
        });
      }
    }
  });

  group('text scaling', () {
    for (final scale in const [1.0, 1.3]) {
      testWidgets('scale $scale stays overflow-free', (tester) async {
        await _pumpMobileStep(
          tester,
          size: const Size(360, 640),
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Continue'), findsOneWidget);
      });
    }
  });

  group('Continue button fill follows the existing enablement rule', () {
    testWidgets('fill tracks canContinue and consent still gates it',
        (tester) async {
      final controller = TextEditingController(text: '1234567890');

      // 10 digits but no consent -> still disabled, exactly as before.
      await _pumpMobileStep(
        tester,
        size: const Size(360, 690),
        controller: controller,
        consent: false,
        onContinue: () {},
      );
      expect(_continueFill(tester), _disabledFill,
          reason: 'consent must keep gating the button');

      // 10 digits + consent -> brand fill.
      await _pumpMobileStep(
        tester,
        size: const Size(360, 690),
        controller: controller,
        consent: true,
        onContinue: () {},
      );
      expect(_continueFill(tester), _enabledFill);
      expect(_continueFill(tester), AppColors.primary);

      // Dropping below 10 digits restores the disabled appearance.
      controller.text = '123456789';
      await tester.pump();
      expect(_continueFill(tester), _disabledFill);
    });

    testWidgets('an empty field is disabled even with consent', (tester) async {
      await _pumpMobileStep(
        tester,
        size: const Size(360, 690),
        controller: TextEditingController(text: ''),
        consent: true,
        onContinue: () {},
      );
      expect(_continueFill(tester), _disabledFill);
    });

    testWidgets('a null callback disables the button even when ready',
        (tester) async {
      // Mirrors the original `onContinue != null` term of canContinue, which
      // login_view drives from authState.isSubmitting.
      await _pumpMobileStep(
        tester,
        size: const Size(360, 690),
        controller: TextEditingController(text: '1234567890'),
        consent: true,
        onContinue: null,
      );
      expect(_continueFill(tester), _disabledFill);
    });

    testWidgets('label style and pill size match the Figma spec',
        (tester) async {
      await _pumpMobileStep(tester, size: const Size(360, 690));
      final button = tester
          .widget<CustomElevatedButton>(find.byType(CustomElevatedButton));
      final style = button.labelStyle!;

      expect(button.label, 'Continue');
      expect(button.uppercaseLabel, isFalse);
      expect(style.fontFamily, 'Plus Jakarta Sans');
      expect(style.fontWeight, FontWeight.w500);
      expect(style.color, Colors.white);
      expect(style.height, 1);
      expect(style.letterSpacing, 0);
      // 12px taken through the project scaling convention, not a raw literal.
      expect(style.fontSize, 12.sp);
      // The CTA is content-driven: no fixed height is imposed on the shared
      // button, so the label can never clip when text scale grows. It renders at
      // Material's 48dp tap target, which the widget's 28.r radius turns into a
      // full capsule (radius > half the height) on every device.
      expect(button.height, isNull);
      final rendered = tester.getRect(find.byType(CustomElevatedButton));
      expect(rendered.height, greaterThanOrEqualTo(40),
          reason: 'must stay a comfortable touch target');
      // Side gutters come from the footer padding, not a hardcoded width.
      expect(rendered.left, greaterThanOrEqualTo(0));
      expect(rendered.right, lessThanOrEqualTo(360));
    });
  });

  group('mobile number input contract', () {
    testWidgets('digits only', (tester) async {
      final controller = TextEditingController(text: '');
      await _pumpMobileStep(tester,
          size: const Size(360, 690), controller: controller);

      await tester.enterText(find.byType(TextField), 'abc12def34');
      await tester.pump();
      expect(controller.text, '1234');
    });

    testWidgets('paste behaviour is unchanged from GreyTextFormField',
        (tester) async {
      final controller = TextEditingController(text: '');
      await _pumpMobileStep(tester,
          size: const Size(360, 690), controller: controller);

      // digitsOnly + LengthLimiting(10) - the same pair GreyTextFormField
      // applies - so a country-code prefixed paste keeps its leading 91. This
      // is the pre-existing behaviour and is deliberately left untouched.
      await tester.enterText(find.byType(TextField), '+91 98765 43210');
      await tester.pump();
      expect(controller.text, '9198765432');
      expect(controller.text.length, 10);
    });

    testWidgets('over-long paste is truncated to 10 digits', (tester) async {
      final controller = TextEditingController(text: '');
      await _pumpMobileStep(tester,
          size: const Size(360, 690), controller: controller);

      await tester.enterText(find.byType(TextField), '9876543210999');
      await tester.pump();
      expect(controller.text, '9876543210');
      expect(controller.text.length, 10);
    });

    testWidgets('editing in the middle keeps the cap', (tester) async {
      final controller = TextEditingController(text: '9876543210');
      await _pumpMobileStep(tester,
          size: const Size(360, 690), controller: controller);

      await tester.enterText(find.byType(TextField), '98765043210');
      await tester.pump();
      expect(controller.text.length, lessThanOrEqualTo(10));
    });
  });

  group('submission wiring', () {
    testWidgets('Continue fires only with 10 digits and consent',
        (tester) async {
      var calls = 0;
      final controller = TextEditingController(text: '123456789');
      await _pumpMobileStep(
        tester,
        size: const Size(360, 690),
        controller: controller,
        consent: false,
        onContinue: () => calls++,
      );

      await tester.tap(find.text('Continue'), warnIfMissed: false);
      await tester.pump();
      expect(calls, 0, reason: 'a 9-digit number must not submit');

      controller.text = '1234567890';
      await tester.pump();
      await tester.tap(find.text('Continue'), warnIfMissed: false);
      await tester.pump();
      expect(calls, 0, reason: 'consent is still required to submit');

      await _pumpMobileStep(
        tester,
        size: const Size(360, 690),
        controller: TextEditingController(text: '1234567890'),
        consent: true,
        onContinue: () => calls++,
      );
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(calls, 1);
    });

    testWidgets('consent changes reach the parent', (tester) async {
      bool? received;
      await _pumpMobileStep(
        tester,
        size: const Size(360, 690),
        consent: false,
        onConsentChanged: (value) => received = value,
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(received, isTrue);
    });
  });

  group('typography', () {
    testWidgets('subtitle is italic and everything is Plus Jakarta Sans',
        (tester) async {
      await _pumpMobileStep(tester, size: const Size(360, 690));

      final subtitle = tester.widget<Text>(
        find.text('Enter your mobile number to continue.'),
      );
      expect(subtitle.style!.fontStyle, FontStyle.italic);
      expect(subtitle.style!.fontFamily, 'Plus Jakarta Sans');

      final heading = tester.widget<Text>(find.text('Welcome to eRupaiya'));
      expect(heading.style!.fontFamily, 'Plus Jakarta Sans');
      expect(heading.style!.fontWeight, FontWeight.w500);

      // Wordmark: plain text now, no ™ superscript floating over the final 'a'.
      final wordmark = tester.widget<Text>(find.text('eRupaiya'));
      expect(wordmark.style!.fontFamily, 'Plus Jakarta Sans');
      expect(wordmark.style!.fontWeight, FontWeight.w500);
      // TM superscript sits after the wordmark, raised, and never over the 'a'.
      final tm = find.text('TM');
      expect(tm, findsOneWidget);
      expect(tester.widget<Text>(tm).style!.fontFamily, 'Plus Jakarta Sans');
      final wordmarkRect = tester.getRect(find.text('eRupaiya'));
      final tmRect = tester.getRect(tm);
      expect(tmRect.left, greaterThanOrEqualTo(wordmarkRect.right));
      expect(tmRect.center.dy, lessThan(wordmarkRect.center.dy));

      // The client's eRupaiya monogram, not the cursive-e splash artwork.
      final brandMarks = tester
          .widgetList<Image>(find.byType(Image))
          .where((image) => (image.image as AssetImage)
              .assetName
              .contains(FileConstants.erupaiyaLogo))
          .toList();
      expect(brandMarks, hasLength(1),
          reason: 'brand row must render the eRupaiya logo asset');

      final label = tester.widget<Text>(find.text('Mobile Number'));
      expect(label.style!.fontFamily, 'Plus Jakarta Sans');
      expect(label.style!.fontWeight, FontWeight.w500);

      final prefix = tester.widget<Text>(find.text('+91'));
      expect(prefix.style!.fontFamily, 'Plus Jakarta Sans');

      // The digits the user types.
      final typed = tester.widget<TextField>(find.byType(TextField));
      expect(typed.style!.fontFamily, 'Plus Jakarta Sans');
      expect(typed.style!.fontWeight, FontWeight.w500);

      final hint = tester.widget<Text>(
        find.text('enter 10 digit mobile number'),
      );
      expect(hint.style!.fontFamily, 'Plus Jakarta Sans');

      final consent = tester.widget<Text>(
        find.text('by continuing, I agree to'),
      );
      expect(consent.style!.fontFamily, 'Plus Jakarta Sans');
    });

    testWidgets('consent copy matches Figma and keeps the checkbox in front',
        (tester) async {
      await _pumpMobileStep(tester, size: const Size(360, 690));

      // Old device-data wording is gone.
      expect(
        find.text('Allow E-Rupaiya to access your information and collect '
            'data from your device'),
        findsNothing,
      );
      expect(find.textContaining('to access your information'), findsNothing);

      // Figma line, in order, with the checkbox still leading it.
      expect(find.text('by continuing, I agree to'), findsOneWidget);
      expect(find.text('&'), findsOneWidget);
      final terms = tester.widget<Text>(find.text('terms of use policy'));
      final privacy = tester.widget<Text>(find.text('privacy policy'));
      expect(terms.style!.decoration, TextDecoration.underline);
      expect(privacy.style!.decoration, TextDecoration.underline);
      expect(
        tester.getRect(find.byType(Checkbox)).left,
        lessThan(tester.getRect(find.text('by continuing, I agree to')).left),
        reason: 'checkbox sits before the consent text',
      );
      // The old screen had no back affordance and this one must not gain one.
      expect(find.byTooltip('Back'), findsNothing);
    });
  });
}
