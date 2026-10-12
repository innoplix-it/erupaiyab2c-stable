import 'package:e_rupaiya/widgets/payment_processing_loader.dart';
import 'package:e_rupaiya/widgets/processing_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helpers/responsive_test_sizes.dart';

Widget _buildProcessingOverlayTestApp({
  required Size logicalSize,
  double textScale = 1.0,
  double bottomInset = 34.0,
}) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    minTextAdapt: true,
    splitScreenMode: true,
    fontSizeResolver: FontSizeResolvers.radius,
    builder: (context, _) => MaterialApp(
      home: Builder(
        builder: (context) {
          return MediaQuery(
            data: MediaQueryData(
              size: logicalSize,
              padding: EdgeInsets.only(top: 47, bottom: bottomInset),
              textScaler: TextScaler.linear(textScale),
            ),
            child: const Scaffold(
              body: ProcessingOverlay(
                isProcessing: true,
                message: 'Processing Your Payment',
                child: SizedBox.expand(),
              ),
            ),
          );
        },
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Processing Your Payment UI Spacing and Responsiveness', () {
    testWidgets('1. All required elements are rendered and visible',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildProcessingOverlayTestApp(logicalSize: const Size(390, 844)),
      );
      await tester.pump();

      // Circular loader
      expect(find.byType(PaymentProcessingLoader), findsOneWidget);

      // Title
      expect(find.text('Processing Your Payment'), findsOneWidget);

      // Description
      expect(
        find.textContaining('Your payment is currently being processed'),
        findsOneWidget,
      );

      // Security Card
      expect(find.text('Your Security Matters'), findsOneWidget);
      expect(
        find.textContaining('Your transaction is being processed securely'),
        findsOneWidget,
      );

      // 3 Trust indicators
      expect(find.text('Secure\nPayments'), findsOneWidget);
      expect(find.text('RBI Compliant\nPlatform'), findsOneWidget);
      expect(find.text('Trusted By\nMillions'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('2. Scrolling widgets are strictly not used', (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildProcessingOverlayTestApp(logicalSize: const Size(390, 844)),
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
          _buildProcessingOverlayTestApp(
            logicalSize: size,
            bottomInset: size.height > 700 ? 34.0 : 0.0,
          ),
        );
        await tester.pump();

        // Must find all critical elements
        expect(
          find.byType(PaymentProcessingLoader),
          findsOneWidget,
          reason: 'Loader missing on ${size.width}x${size.height}',
        );
        expect(
          find.text('Processing Your Payment'),
          findsOneWidget,
          reason: 'Title missing on ${size.width}x${size.height}',
        );
        expect(
          find.text('Your Security Matters'),
          findsOneWidget,
          reason: 'Security card missing on ${size.width}x${size.height}',
        );
        expect(
          find.text('Secure\nPayments'),
          findsOneWidget,
          reason: 'Secure payments missing on ${size.width}x${size.height}',
        );
        expect(
          find.text('RBI Compliant\nPlatform'),
          findsOneWidget,
          reason: 'RBI compliant missing on ${size.width}x${size.height}',
        );
        expect(
          find.text('Trusted By\nMillions'),
          findsOneWidget,
          reason: 'Trusted by millions missing on ${size.width}x${size.height}',
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
          _buildProcessingOverlayTestApp(
            logicalSize: size,
            textScale: scale,
            bottomInset: 0.0,
          ),
        );
        await tester.pump();


        expect(find.text('Processing Your Payment'), findsOneWidget);
        expect(find.text('Your Security Matters'), findsOneWidget);
        expect(find.text('Trusted By\nMillions'), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Failed with text scale $scale',
        );
      }
    });
  });
}
