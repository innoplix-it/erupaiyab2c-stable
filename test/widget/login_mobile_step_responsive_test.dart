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

    testWidgets('keeps form usable when keyboard inset is applied',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await _pumpStep(
        tester,
        size: const Size(360, 690),
        viewInsetBottom: 280,
        home: Scaffold(
          resizeToAvoidBottomInset: true,
          body: AuthMobileStep(
            controller: controller,
            isLoading: false,
            onContinue: () {},
          ),
        ),
      );

      expect(find.text('Pay Bills & Earn'), findsOneWidget);
      expect(find.text('Mobile Number'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Terms of Use'), findsOneWidget);

      // Terms sit tight above the keyboard — no large home-indicator gap.
      final termsBottom = tester.getBottomLeft(find.text('Privacy Policy')).dy;
      final bodyHeight = tester.getSize(find.byType(Scaffold)).height;
      expect(bodyHeight - termsBottom, lessThanOrEqualTo(24));
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
        expect(find.text('Electricity Bill'), findsWidgets);
        expect(find.text('Book LPG'), findsWidgets);
        expect(find.text('School Fees'), findsWidgets);
        expect(find.text('Personal Loan'), findsWidgets);

        final sliderSize =
            tester.getSize(find.byType(LoginServicesSlider).first);
        expect(sliderSize.height, greaterThan(0));
        expect(sliderSize.width, greaterThan(0));
        // Four compact rows occupy the upper half, not the whole screen.
        expect(sliderSize.height, lessThanOrEqualTo(size.height * 0.58));

        // Square tiles: width == height from Figma 100/440 mapping.
        final expectedTile = size.width *
            (LoginServicesSlider.tileDesign /
                LoginServicesSlider.figmaFrameWidth);
        final expectedGap = size.width *
            (LoginServicesSlider.gapDesign /
                LoginServicesSlider.figmaFrameWidth);
        final expectedFourRowH = LoginServicesSlider.rowCount * expectedTile +
            (LoginServicesSlider.rowCount - 1) * expectedGap;
        // Matches AuthMobileStep LayoutBuilder budget.
        final topPad = 8 * size.height / 690;
        final maxBudget =
            ((size.height - topPad) * 0.55).clamp(72.0, size.height * 0.58);
        final expectedH =
            expectedFourRowH > maxBudget ? maxBudget : expectedFourRowH;
        expect(
          sliderSize.height,
          moreOrLessEquals(expectedH, epsilon: 2.0),
        );
        expect(tester.takeException(), isNull);
      }
    });
  });
}
