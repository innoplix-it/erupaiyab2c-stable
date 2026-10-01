import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:e_rupaiya/features/profile/models/transaction_history_entry.dart';
import 'package:e_rupaiya/features/profile/views/transaction_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('Credit Card Customer Params & Detail Screen', () {
    test('Unpacks nested customer_params correctly from JSON', () {
      final json = {
        'payment_status': 'success',
        'payment_type': 'Credit Card',
        'biller_name': 'HDFC Credit Card',
        'amount': '2500',
        'customer_params': [
          {
            'label': 'input',
            'value': [
              {
                'paramName': 'Registered Mobile Number',
                'paramValue': '9552529513',
              },
              {
                'paramName': 'Last 4 digits of Credit Card Number',
                'paramValue': '2656',
              },
            ],
          },
        ],
      };

      final entry = TransactionHistoryEntry.fromJson(json);

      expect(entry.customerParams, hasLength(2));
      expect(entry.customerParams[0].label, 'Registered Mobile Number');
      expect(entry.customerParams[0].value, '9552529513');
      expect(entry.customerParams[1].label, 'Last 4 digits of Credit Card Number');
      expect(entry.customerParams[1].value, '2656');
    });

    testWidgets(
        'Renders Registered Mobile Number and masked Credit Card Number with dynamic last 4 digits',
        (tester) async {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(390, 844) * 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final entry = TransactionHistoryEntry.fromJson({
        'payment_status': 'success',
        'payment_type': 'Credit Card',
        'biller_name': 'HDFC Credit Card',
        'amount': '2500',
        'total_amount_charged': '2500',
        'customer_params': [
          {
            'label': 'input',
            'value': [
              {
                'paramName': 'Registered Mobile Number',
                'paramValue': '9552529513',
              },
              {
                'paramName': 'Last 4 digits of Credit Card Number',
                'paramValue': '2656',
              },
            ],
          },
        ],
      });

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, _) => MaterialApp(
            home: TransactionDetailScreen(entry: entry),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Must NOT display raw input or Map/List structure
      expect(find.text('input'), findsNothing);
      expect(find.textContaining('[{paramName'), findsNothing);

      // Must display Registered Mobile Number with actual dynamic value
      expect(find.text('Registered Mobile Number'), findsOneWidget);
      expect(find.text('9552529513'), findsOneWidget);

      // Must display Credit Card Number with ONLY last 4 digits visible
      expect(find.text('Credit Card Number'), findsOneWidget);
      expect(find.text('**** **** **** 2656'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('Non-credit card transactions preserve regular customer params',
        (tester) async {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(390, 844) * 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final entry = TransactionHistoryEntry.fromJson({
        'payment_status': 'success',
        'payment_type': 'Electricity',
        'biller_name': 'MSEDCL',
        'amount': '1500',
        'total_amount_charged': '1500',
        'customer_params': [
          {
            'label': 'Consumer Number',
            'value': '102345678901',
          },
        ],
      });

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, _) => MaterialApp(
            home: TransactionDetailScreen(entry: entry),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Consumer Number'), findsAtLeastNWidgets(1));
      expect(find.text('102345678901'), findsAtLeastNWidgets(1));

      expect(tester.takeException(), isNull);
    });

    for (final width in [320.0, 360.0, 375.0, 390.0, 412.0, 440.0]) {
      testWidgets('Credit Card detail renders without overflow at ${width.toInt()}px',
          (tester) async {
        tester.view.devicePixelRatio = 2;
        tester.view.physicalSize = Size(width, 800) * 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final entry = TransactionHistoryEntry.fromJson({
          'payment_status': 'success',
          'payment_type': 'Credit Card',
          'biller_name': 'HDFC Bank Credit Card',
          'amount': '4999',
          'total_amount_charged': '4999',
          'customer_params': [
            {
              'label': 'input',
              'value': [
                {
                  'paramName': 'Registered Mobile Number',
                  'paramValue': '9876543210',
                },
                {
                  'paramName': 'Last 4 digits of Credit Card Number',
                  'paramValue': '4321',
                },
              ],
            },
          ],
        });

        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(360, 690),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, _) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.15)),
              child: MaterialApp(
                home: TransactionDetailScreen(entry: entry),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('9876543210'), findsOneWidget);
        expect(find.text('**** **** **** 4321'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
