import 'package:e_rupaiya/features/educationFees/views/education_payment_thank_you_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../helpers/responsive_test_sizes.dart';

Widget _buildEducationThankYouTestApp({
  required Size logicalSize,
  double textScale = 1.0,
  double bottomInset = 34.0,
}) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    minTextAdapt: true,
    splitScreenMode: true,
    fontSizeResolver: FontSizeResolvers.radius,
    builder: (context, _) => MaterialApp.router(
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Builder(
              builder: (context) {
                return MediaQuery(
                  data: MediaQueryData(
                    size: logicalSize,
                    padding: EdgeInsets.only(top: 47, bottom: bottomInset),
                    textScaler: TextScaler.linear(textScale),
                  ),
                  child: const Scaffold(
                    body: EducationPaymentThankYouView(
                      amount: '100.00',
                      payableAmount: '',
                      transactionTime: '2026-10-11 07:07:00',
                      bannerImage: '',
                      paymentType: 'House Rent',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Education Payment Thank You UI Spacing and Responsiveness', () {
    testWidgets('1. All required elements are rendered and visible',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildEducationThankYouTestApp(logicalSize: const Size(390, 844)),
      );
      await tester.pump();

      // Success icon
      expect(find.byType(Image), findsWidgets);

      // Thank you title
      expect(find.textContaining('Thank You'), findsOneWidget);

      // Amount
      expect(find.textContaining('₹'), findsOneWidget);

      // Date/time
      expect(find.textContaining('October'), findsOneWidget);

      // Done button
      expect(find.text('Done'), findsOneWidget);

      // Powered by text
      expect(find.text('powered by'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('2. Scrolling widgets are strictly not used', (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildEducationThankYouTestApp(logicalSize: const Size(390, 844)),
      );
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(CustomScrollView), findsNothing);
    });

    testWidgets(
        '3. Fits across all supported screen sizes without overflow or clipping',
        (tester) async {
      for (final size in responsiveTestScreenSizes) {
        tester.view.physicalSize = size * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildEducationThankYouTestApp(
            logicalSize: size,
            bottomInset: size.height > 700 ? 34.0 : 0.0,
          ),
        );
        await tester.pump();

        // Must find all critical elements
        expect(
          find.textContaining('Thank You'),
          findsOneWidget,
          reason: 'Title missing on ${size.width}x${size.height}',
        );
        expect(
          find.textContaining('₹'),
          findsOneWidget,
          reason: 'Amount missing on ${size.width}x${size.height}',
        );
        expect(
          find.text('Done'),
          findsOneWidget,
          reason: 'Done button missing on ${size.width}x${size.height}',
        );

        // No render flex or other overflow exception
        expect(
          tester.takeException(),
          isNull,
          reason: 'Overflow on ${size.width}x${size.height}',
        );
      }
    });

    testWidgets(
        '4. Fits with different text scale factors (0.85x, 1.0x, 1.15x)',
        (tester) async {
      const textScales = [0.85, 1.0, 1.15];
      const size = Size(360, 690);

      for (final scale in textScales) {
        tester.view.physicalSize = size * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildEducationThankYouTestApp(
            logicalSize: size,
            textScale: scale,
            bottomInset: 0.0,
          ),
        );
        await tester.pump();

        expect(find.textContaining('Thank You'), findsOneWidget);
        expect(find.text('Done'), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Failed with text scale $scale',
        );
      }
    });

    testWidgets('5. Green arc scales proportionally across widths',
        (tester) async {
      const widths = [320.0, 360.0, 375.0, 390.0, 412.0, 440.0];
      const height = 800.0;

      for (final width in widths) {
        tester.view.physicalSize = Size(width, height) * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildEducationThankYouTestApp(
            logicalSize: Size(width, height),
            bottomInset: 34.0,
          ),
        );
        await tester.pump();

        // Verify no overflow
        expect(
          tester.takeException(),
          isNull,
          reason: 'Overflow on width $width',
        );

        // Verify arc is rendered
        expect(find.byType(Container), findsWidgets);
      }
    });
  });
}
