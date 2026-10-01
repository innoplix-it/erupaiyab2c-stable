import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:e_rupaiya/features/profile/models/transaction_history_entry.dart';
import 'package:e_rupaiya/features/profile/views/transaction_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('FASTag Customer Params & Detail Screen', () {
    test('Parses actual FASTag API response correctly from JSON', () {
      final json = {
        'source': 'BBPS',
        'payment_status': 'REFUNDED',
        'payment_type': 'Fastag Recharge',
        'biller_name': 'Airtel Payments Bank NETC FASTag',
        'masked_identifier': '******4040',
        'amount': 10,
        'customer_mobile': '8055851920',
        'pg_transaction_id': 'pay_TexqmkYOdFBZmn',
        'ecoins_transaction_id': null,
        'bank_reference_id': null,
        'org_ref_id': 'INOP20260922051748E00B041D',
        'transaction_time': '22 Sep 2026, 10:47am',
        'method': 'upi',
        'method_icon':
            'https://test.erupaiya.com/assets/images/google-pay-icon.png',
        'payment_mode': 'Google Pay',
        'vpa': 'darshannikam8055@okhdfcbank',
        'rrn': '130039530481',
        'icon':
            'https://test.erupaiya.com/assets/images/fastag_recharge/aitel-payments-bank.png',
        'routes': [],
        'amount_breakdown': {'Bill Amount': 10, 'Total': 10},
        'customer_params': [
          {'label': 'Vehicle Registration Number', 'value': 'MH12YL4040'},
        ],
      };

      final entry = TransactionHistoryEntry.fromJson(json);

      expect(entry.paymentType, 'Fastag Recharge');
      expect(entry.billerName, 'Airtel Payments Bank NETC FASTag');
      expect(entry.customerMobile, '8055851920');
      expect(entry.customerParams, hasLength(1));
      expect(entry.customerParams[0].label, 'Vehicle Registration Number');
      expect(entry.customerParams[0].value, 'MH12YL4040');
    });

    test('Unpacks nested customer_params if input wrapper is provided', () {
      final json = {
        'payment_status': 'success',
        'payment_type': 'Fastag Recharge',
        'biller_name': 'ICICI Bank Fastag',
        'amount': '500',
        'customer_params': [
          {
            'label': 'input',
            'value': [
              {
                'paramName': 'Vehicle Registration Number',
                'paramValue': 'MH14EU1234',
              },
              {
                'paramName': 'Registered Mobile Number',
                'paramValue': '9876543210',
              },
            ],
          },
        ],
      };

      final entry = TransactionHistoryEntry.fromJson(json);

      expect(entry.customerParams, hasLength(2));
      expect(entry.customerParams[0].label, 'Vehicle Registration Number');
      expect(entry.customerParams[0].value, 'MH14EU1234');
      expect(entry.customerParams[1].label, 'Registered Mobile Number');
      expect(entry.customerParams[1].value, '9876543210');
    });

    testWidgets(
        'Renders Registered Mobile Number and Vehicle Registration Number without duplicate columns',
        (tester) async {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(390, 844) * 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final entry = TransactionHistoryEntry.fromJson({
        'source': 'BBPS',
        'payment_status': 'REFUNDED',
        'payment_type': 'Fastag Recharge',
        'biller_name': 'Airtel Payments Bank NETC FASTag',
        'masked_identifier': '******4040',
        'amount': 10,
        'customer_mobile': '8055851920',
        'pg_transaction_id': 'pay_TexqmkYOdFBZmn',
        'transaction_time': '22 Sep 2026, 10:47am',
        'method': 'upi',
        'payment_mode': 'Google Pay',
        'vpa': 'darshannikam8055@okhdfcbank',
        'rrn': '130039530481',
        'amount_breakdown': {'Bill Amount': 10, 'Total': 10},
        'customer_params': [
          {'label': 'Vehicle Registration Number', 'value': 'MH12YL4040'},
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

      // Must NOT render raw map/list structures or duplicate headings
      expect(find.text('input'), findsNothing);
      expect(find.textContaining('[{paramName'), findsNothing);

      // Must display Registered Mobile Number and Vehicle Registration Number
      expect(find.text('Registered Mobile Number'), findsOneWidget);
      expect(find.text('8055851920'), findsOneWidget);
      expect(find.text('Vehicle Registration Number'), findsOneWidget);
      expect(find.text('MH12YL4040'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    for (final width in [320.0, 360.0, 375.0, 390.0, 412.0, 440.0]) {
      testWidgets(
          'FASTag detail renders without overflow at ${width.toInt()}px with text scale 1.15',
          (tester) async {
        tester.view.devicePixelRatio = 2;
        tester.view.physicalSize = Size(width, 800) * 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final entry = TransactionHistoryEntry.fromJson({
          'source': 'BBPS',
          'payment_status': 'SUCCESS',
          'payment_type': 'Fastag Recharge',
          'biller_name': 'Airtel Payments Bank NETC FASTag',
          'masked_identifier': '******4040',
          'amount': 100,
          'customer_mobile': '8055851920',
          'pg_transaction_id': 'pay_TexqmkYOdFBZmn',
          'transaction_time': '22 Sep 2026, 10:47am',
          'method': 'upi',
          'payment_mode': 'Google Pay',
          'amount_breakdown': {'Bill Amount': 100, 'Total': 100},
          'customer_params': [
            {'label': 'Vehicle Registration Number', 'value': 'MH12YL4040'},
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

        expect(find.text('8055851920'), findsOneWidget);
        expect(find.text('MH12YL4040'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
