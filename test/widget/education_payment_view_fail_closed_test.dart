import 'package:e_rupaiya/features/educationFees/components/education_payment_sheets.dart';
import 'package:e_rupaiya/features/educationFees/models/education_fees_responses.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../helpers/responsive_test_sizes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Education Payment Summary Sheet - Fail-Closed Behavior', () {
    testWidgets(
        '1. Pay button is disabled when summary is null',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: ScreenUtilInit(
            designSize: const Size(360, 690),
            minTextAdapt: true,
            splitScreenMode: true,
            fontSizeResolver: FontSizeResolvers.radius,
            builder: (context, child) => MaterialApp(
              home: Scaffold(
                body: MediaQuery(
                  data: const MediaQueryData(
                    size: Size(390, 844),
                    padding: EdgeInsets.only(top: 47, bottom: 34),
                  ),
                  child: Container(
                    color: Colors.white,
                    child: EducationPaymentSummarySheet(
                      amount: 1000.0,
                      initialSummary: null,
                      onPayNow: (payable) async {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final unavailableButton = find.text('Unavailable');
      expect(unavailableButton, findsOneWidget);

      final elevatedButton = tester.widget<ElevatedButton>(
        find.ancestor(
          of: unavailableButton,
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(elevatedButton.onPressed, isNull);
    });

    testWidgets(
        '2. Pay button is enabled when summary is valid',
        (tester) async {
      const validSummary = EducationPaymentSummaryData(
        amount: 1000.0,
        serviceCharge: 10.0,
        gstRate: 18.0,
        gstOnServiceCharge: 1.8,
        walletBalance: 0.0,
        walletUsed: 0.0,
        totalPayable: 1011.8,
      );

      tester.view.physicalSize = const Size(390, 844) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: ScreenUtilInit(
            designSize: const Size(360, 690),
            minTextAdapt: true,
            splitScreenMode: true,
            fontSizeResolver: FontSizeResolvers.radius,
            builder: (context, child) => MaterialApp(
              home: Scaffold(
                body: MediaQuery(
                  data: const MediaQueryData(
                    size: Size(390, 844),
                    padding: EdgeInsets.only(top: 47, bottom: 34),
                  ),
                  child: Container(
                    color: Colors.white,
                    child: EducationPaymentSummarySheet(
                      amount: 1000.0,
                      initialSummary: validSummary,
                      onPayNow: (payable) async {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final payButton = find.textContaining('Pay ₹');
      expect(payButton, findsOneWidget);

      final elevatedButton = tester.widget<ElevatedButton>(
        find.ancestor(
          of: payButton,
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(elevatedButton.onPressed, isNotNull);
    });

    testWidgets(
        '3. onPayNow callback is not invoked when summary is null (Razorpay entry point blocked)',
        (tester) async {
      bool onPayNowCalled = false;

      tester.view.physicalSize = const Size(390, 844) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: ScreenUtilInit(
            designSize: const Size(360, 690),
            minTextAdapt: true,
            splitScreenMode: true,
            fontSizeResolver: FontSizeResolvers.radius,
            builder: (context, child) => MaterialApp(
              home: Scaffold(
                body: MediaQuery(
                  data: const MediaQueryData(
                    size: Size(390, 844),
                    padding: EdgeInsets.only(top: 47, bottom: 34),
                  ),
                  child: Container(
                    color: Colors.white,
                    child: EducationPaymentSummarySheet(
                      amount: 1000.0,
                      initialSummary: null,
                      onPayNow: (payable) async {
                        onPayNowCalled = true;
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final unavailableButton = find.text('Unavailable');
      expect(unavailableButton, findsOneWidget);
      await tester.tap(unavailableButton);
      await tester.pump();

      expect(onPayNowCalled, isFalse);
    });

    testWidgets(
        '4. onPayNow callback is invoked when summary is valid (Razorpay entry point available)',
        (tester) async {
      bool onPayNowCalled = false;
      double? payableAmount;

      const validSummary = EducationPaymentSummaryData(
        amount: 1000.0,
        serviceCharge: 10.0,
        gstRate: 18.0,
        gstOnServiceCharge: 1.8,
        walletBalance: 0.0,
        walletUsed: 0.0,
        totalPayable: 1011.8,
      );

      tester.view.physicalSize = const Size(390, 844) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: ScreenUtilInit(
            designSize: const Size(360, 690),
            minTextAdapt: true,
            splitScreenMode: true,
            fontSizeResolver: FontSizeResolvers.radius,
            builder: (context, child) => MaterialApp(
              home: Scaffold(
                body: MediaQuery(
                  data: const MediaQueryData(
                    size: Size(390, 844),
                    padding: EdgeInsets.only(top: 47, bottom: 34),
                  ),
                  child: Container(
                    color: Colors.white,
                    child: EducationPaymentSummarySheet(
                      amount: 1000.0,
                      initialSummary: validSummary,
                      onPayNow: (payable) async {
                        onPayNowCalled = true;
                        payableAmount = payable;
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final payButton = find.textContaining('Pay ₹');
      expect(payButton, findsOneWidget);
      await tester.tap(payButton);
      await tester.pump();

      expect(onPayNowCalled, isTrue);
      expect(payableAmount, equals(1011.8));
    });

    testWidgets(
        '5. Repeated taps on disabled Pay button do not invoke onPayNow',
        (tester) async {
      int onPayNowCallCount = 0;

      tester.view.physicalSize = const Size(390, 844) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: ScreenUtilInit(
            designSize: const Size(360, 690),
            minTextAdapt: true,
            splitScreenMode: true,
            fontSizeResolver: FontSizeResolvers.radius,
            builder: (context, child) => MaterialApp(
              home: Scaffold(
                body: MediaQuery(
                  data: const MediaQueryData(
                    size: Size(390, 844),
                    padding: EdgeInsets.only(top: 47, bottom: 34),
                  ),
                  child: Container(
                    color: Colors.white,
                    child: EducationPaymentSummarySheet(
                      amount: 1000.0,
                      initialSummary: null,
                      onPayNow: (payable) async {
                        onPayNowCallCount++;
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final unavailableButton = find.text('Unavailable');

      for (int i = 0; i < 5; i++) {
        await tester.tap(unavailableButton);
        await tester.pump();
      }

      expect(onPayNowCallCount, equals(0));
    });
  });
}
