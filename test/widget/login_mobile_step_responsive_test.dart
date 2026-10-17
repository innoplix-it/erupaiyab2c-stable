import 'dart:math' as math;

import 'package:e_rupaiya/features/auth/components/auth_mobile_step.dart';
import 'package:e_rupaiya/features/auth/components/login_services_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/responsive_test_sizes.dart';

/// Required portrait sizes from the shared matrix (no duplicate size list).
final _loginRequiredSizes = responsiveTestScreenSizes.where((s) {
  for (final required in const <Size>[
    Size(320, 568),
    Size(360, 640),
    Size(360, 690),
    Size(360, 800),
    Size(375, 812),
    Size(390, 844),
    Size(412, 915),
    Size(440, 956),
    Size(458, 1024),
  ]) {
    if (s.width == required.width && s.height == required.height) {
      return true;
    }
  }
  return false;
}).toList();

/// Figma px -> dp factor (mirrors AuthMobileStep.scaleFor: width / 440).
double _k(Size size) => math.min(1.1, math.max(0.72, size.width / 440));

Future<void> _pumpStep(
  WidgetTester tester, {
  required Widget home,
  Size size = const Size(360, 690),
  double textScale = 1.0,
  double viewInsetBottom = 0,
}) async {
  final view = tester.view;
  view.physicalSize = size;
  view.devicePixelRatio = 1.0;
  view.padding = FakeViewPadding.zero;
  view.viewInsets = FakeViewPadding(bottom: viewInsetBottom);
  addTearDown(view.resetPhysicalSize);
  addTearDown(view.resetDevicePixelRatio);
  addTearDown(view.resetPadding);
  addTearDown(view.resetViewInsets);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) {
        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(path: '/', builder: (_, __) => home),
            GoRoute(
              path: '/terms-privacy',
              builder: (_, __) => const Scaffold(body: Text('Terms')),
            ),
            GoRoute(
              path: '/privacy-policy',
              builder: (_, __) => const Scaffold(body: Text('Privacy')),
            ),
          ],
        );
        return MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
            viewInsets: EdgeInsets.only(bottom: viewInsetBottom),
          ),
          child: MaterialApp.router(routerConfig: router),
        );
      },
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthMobileStep responsive layout', () {
    testWidgets('keeps core Figma actions and branding across phone sizes',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      expect(_loginRequiredSizes, hasLength(9));

      for (final size in _loginRequiredSizes) {
        await _pumpStep(
          tester,
          size: size,
          home: Scaffold(
            resizeToAvoidBottomInset: true,
            body: AuthMobileStep(
              controller: controller,
              isLoading: false,
              onContinue: () {},
            ),
          ),
        );

        expect(find.byType(LoginServicesSlider), findsOneWidget);
        expect(find.text('Pay Bills & Earn'), findsOneWidget);
        expect(
          find.text('Enter your mobile number to continue.'),
          findsOneWidget,
        );
        expect(find.text('Mobile Number'), findsOneWidget);
        expect(find.text('+91'), findsOneWidget);
        expect(find.text('Enter 10 Digit Mobile Number'), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);
        expect(find.textContaining('By continuing, you agree'), findsOneWidget);
        expect(find.text('Terms of Use'), findsOneWidget);
        expect(find.text('Privacy Policy'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('closed: Terms/Privacy keep the Figma gap to the bottom edge',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      const size = Size(360, 690);
      await _pumpStep(
        tester,
        size: size,
        home: Scaffold(
          body: AuthMobileStep(
            controller: controller,
            isLoading: false,
            onContinue: () {},
          ),
        ),
      );

      final termsBottom = tester.getBottomLeft(find.text('Privacy Policy')).dy;
      final gap = size.height - termsBottom;
      // Figma: ~40 (home indicator included).
      expect(gap, greaterThanOrEqualTo(36));
      expect(gap, lessThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    });

    testWidgets('supports text scaling on required sizes', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      for (final size in _loginRequiredSizes) {
        for (final scale in const [1.0, 1.3]) {
          await _pumpStep(
            tester,
            size: size,
            textScale: scale,
            home: Scaffold(
              body: AuthMobileStep(
                controller: controller,
                isLoading: false,
                onContinue: () {},
              ),
            ),
          );

          expect(find.text('Pay Bills & Earn'), findsOneWidget);
          expect(find.text('Continue'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      }
    });

    testWidgets('keyboard open: faded compact slider sits behind the form',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      // Simulate Scaffold resizeToAvoidBottomInset + keyboard-open flag.
      const shrunk = Size(360, 410);
      await _pumpStep(
        tester,
        size: shrunk,
        viewInsetBottom: 1,
        home: Scaffold(
          resizeToAvoidBottomInset: true,
          body: AuthMobileStep(
            controller: controller,
            isLoading: false,
            onContinue: () {},
          ),
        ),
      );
      // Let the crossfade / gradient animations finish.
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Pay Bills & Earn'), findsOneWidget);
      expect(find.text('Mobile Number'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Terms of Use'), findsOneWidget);
      expect(find.byType(LoginServicesSlider), findsOneWidget);

      // Compact Figma rows use full labels.
      expect(find.text('Electricity Bill'), findsWidgets);
      expect(find.text('Mobile Recharge'), findsWidgets);

      // 2 compact rows: 117/428 tiles, 19/428 gap.
      final slider = tester.widget<LoginServicesSlider>(
        find.byType(LoginServicesSlider),
      );
      expect(slider.compact, isTrue);
      expect(slider.rowCount, 2);

      final sliderSize = tester.getSize(find.byType(LoginServicesSlider));
      final expectedH = LoginServicesSlider.naturalHeight(
        shrunk.width,
        2,
        compact: true,
      );
      expect(sliderSize.height, moreOrLessEquals(expectedH, epsilon: 2.0));
      expect(sliderSize.height, lessThanOrEqualTo(shrunk.height * 0.7));

      // Form overlaps the slider (Figma): title starts above the slider's
      // bottom edge (+ small tolerance).
      final sliderBottom =
          tester.getBottomLeft(find.byType(LoginServicesSlider)).dy;
      final titleTop = tester.getTopLeft(find.text('Pay Bills & Earn')).dy;
      expect(titleTop, lessThan(sliderBottom + 60));

      // Footer sits ~24 above the keyboard edge (Figma keyboard frame).
      final termsBottom = tester.getBottomLeft(find.text('Privacy Policy')).dy;
      expect(termsBottom, lessThanOrEqualTo(shrunk.height));
      final gap = shrunk.height - termsBottom;
      expect(gap, greaterThanOrEqualTo(18));
      expect(gap, lessThanOrEqualTo(30));
      expect(tester.takeException(), isNull);
    });

    testWidgets('focusing the mobile field lifts the form immediately',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await _pumpStep(
        tester,
        home: Scaffold(
          body: AuthMobileStep(
            controller: controller,
            isLoading: false,
            onContinue: () {},
          ),
        ),
      );
      expect(
        tester
            .widget<LoginServicesSlider>(find.byType(LoginServicesSlider))
            .compact,
        isFalse,
      );

      // No keyboard inset yet: focus alone must switch to the overlay layout.
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final slider = tester.widget<LoginServicesSlider>(
        find.byType(LoginServicesSlider),
      );
      expect(slider.compact, isTrue);
      expect(slider.rowCount, 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'external sheet hiding keyboard keeps overlay layout (phone hint dismissal)',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await _pumpStep(
        tester,
        home: Scaffold(
          body: AuthMobileStep(
            controller: controller,
            isLoading: false,
            onContinue: () {},
          ),
        ),
      );

      // Focus the field to enter overlay mode
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final sliderBefore = tester.widget<LoginServicesSlider>(
        find.byType(LoginServicesSlider),
      );
      expect(sliderBefore.compact, isTrue);
      expect(sliderBefore.rowCount, 2);

      // Simulate external sheet (phone hint) hiding keyboard while focus is retained
      tester.view.viewInsets = const FakeViewPadding(bottom: 0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Layout should stay in overlay mode (compact slider)
      final sliderAfter = tester.widget<LoginServicesSlider>(
        find.byType(LoginServicesSlider),
      );
      expect(sliderAfter.compact, isTrue,
          reason:
              'Overlay layout should persist when keyboard hidden by external sheet');
      expect(sliderAfter.rowCount, 2);
      expect(tester.takeException(), isNull);

      // Cleanup
      tester.view.resetViewInsets();
    });

    testWidgets('user keyboard dismissal returns to closed layout',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await _pumpStep(
        tester,
        home: Scaffold(
          body: AuthMobileStep(
            controller: controller,
            isLoading: false,
            onContinue: () {},
          ),
        ),
      );

      // Focus the field to enter overlay mode
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final sliderFocused = tester.widget<LoginServicesSlider>(
        find.byType(LoginServicesSlider),
      );
      expect(sliderFocused.compact, isTrue);

      // User taps outside to dismiss (focus lost first, then keyboard hidden)
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      tester.view.viewInsets = const FakeViewPadding(bottom: 0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Layout should return to closed mode (non-compact slider)
      final sliderDismissed = tester.widget<LoginServicesSlider>(
        find.byType(LoginServicesSlider),
      );
      expect(sliderDismissed.compact, isFalse,
          reason: 'Closed layout should return after user keyboard dismissal');
      expect(tester.takeException(), isNull);

      // Cleanup
      tester.view.resetViewInsets();
    });

    testWidgets(
        'keyboard open switches slider to compact mode without exceptions',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await _pumpStep(
        tester,
        home: Scaffold(
          body: AuthMobileStep(
            controller: controller,
            isLoading: false,
            onContinue: () {},
          ),
        ),
      );
      expect(
        tester
            .widget<LoginServicesSlider>(find.byType(LoginServicesSlider))
            .compact,
        isFalse,
      );

      await _pumpStep(
        tester,
        size: const Size(360, 410),
        viewInsetBottom: 1,
        home: Scaffold(
          body: AuthMobileStep(
            controller: controller,
            isLoading: false,
            onContinue: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        tester
            .widget<LoginServicesSlider>(find.byType(LoginServicesSlider))
            .compact,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps form and footer usable on short landscape phones',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await _pumpStep(
        tester,
        size: const Size(740, 360),
        home: Scaffold(
          body: AuthMobileStep(
            controller: controller,
            isLoading: false,
            onContinue: () {},
          ),
        ),
      );

      expect(find.byType(LoginServicesSlider), findsOneWidget);
      expect(find.text('Pay Bills & Earn'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Terms of Use'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Terms links use primary color and regular weight',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await _pumpStep(
        tester,
        home: Scaffold(
          body: AuthMobileStep(
            controller: controller,
            isLoading: false,
            onContinue: () {},
          ),
        ),
      );

      final terms = tester.widget<Text>(find.text('Terms of Use'));
      expect(terms.style?.color, const Color(0xFFDD5428));
      expect(terms.style?.fontWeight, FontWeight.w400);

      final privacy = tester.widget<Text>(find.text('Privacy Policy'));
      expect(privacy.style?.color, const Color(0xFFDD5428));
      expect(privacy.style?.fontWeight, FontWeight.w400);
    });

    testWidgets('+91 uses black medium weight', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await _pumpStep(
        tester,
        home: Scaffold(
          body: AuthMobileStep(
            controller: controller,
            isLoading: false,
            onContinue: () {},
          ),
        ),
      );

      final prefix = tester.widget<Text>(find.text('+91'));
      expect(prefix.style?.color, const Color(0xFF000000));
      expect(prefix.style?.fontWeight, FontWeight.w500);
    });

    testWidgets('slider tiles match Figma metrics across required sizes',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      for (final size in _loginRequiredSizes) {
        await _pumpStep(
          tester,
          size: size,
          home: Scaffold(
            body: AuthMobileStep(
              controller: controller,
              isLoading: false,
              onContinue: () {},
            ),
          ),
        );

        expect(find.byType(LoginServicesSlider), findsOneWidget);
        expect(find.text('Electricity'), findsWidgets);
        expect(find.text('Book LPG'), findsWidgets);
        expect(find.text('School Fees'), findsWidgets);
        expect(find.text('Personal Loan'), findsWidgets);
        expect(find.text('Shop Rent'), findsWidgets);

        final sliderSize =
            tester.getSize(find.byType(LoginServicesSlider).first);
        expect(sliderSize.height, greaterThan(0));
        expect(sliderSize.width, greaterThan(0));
        expect(sliderSize.height, lessThanOrEqualTo(size.height * 0.58));

        // Mirrors AuthMobileStep budget (keyboard closed, zero insets).
        final k = _k(size);
        final topPad = 6 * k;
        final available = size.height - topPad;
        final reserve = (AuthMobileStep.formReserveDesign +
                AuthMobileStep.closedBottomGapDesign) *
            k;
        final budget = (available - reserve)
            .clamp(available * 0.38, available * 0.56)
            .toDouble();
        final naturalH = LoginServicesSlider.naturalHeight(
          size.width,
          LoginServicesSlider.maxRowCount,
        );
        final expectedH = naturalH > budget ? budget : naturalH;
        expect(
          sliderSize.height,
          moreOrLessEquals(expectedH, epsilon: 2.0),
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('slider animates without exceptions', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await _pumpStep(
        tester,
        home: Scaffold(
          body: AuthMobileStep(
            controller: controller,
            isLoading: false,
            onContinue: () {},
          ),
        ),
      );

      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(seconds: 9));
        expect(tester.takeException(), isNull);
      }
    });
  });
}
