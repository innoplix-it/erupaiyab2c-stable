import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:e_rupaiya/features/profile/models/transaction_history_entry.dart';
import 'package:e_rupaiya/features/profile/views/transaction_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('Tuition Fee Customer Params & Detail Screen', () {
    test('Parses Tuition Fee response structure correctly from JSON', () {
      final json = {
        'source': 'DIRECT',
        'payment_status': 'SUCCESS',
        'payment_type': 'Tuition Fees',
        'fee_type': 'Tuition Fee',
        'biller_name': 'Prof. Sharma Classes',
        'masked_identifier': 'XXXXXX9876',
        'amount': 3500,
        'customer_mobile': '9876543210',
        'pg_transaction_id': 'pay_Edu123456789',
        'ecoins_transaction_id': null,
        'bank_reference_id': null,
        'org_ref_id': 'EDU20260930123456',
        'transaction_time': '30 Sep 2026, 04:30pm',
        'method': 'upi',
        'payment_mode': 'Google Pay',
        'routes': [],
        'amount_breakdown': {'Bill Amount': 3500, 'Total': 3500},
        'customer_params': [
          {'label': 'Recipient Name', 'value': 'Prof. Sharma Classes'},
          {'label': 'Account Number', 'value': 'XXXXXX9876'},
        ],
      };

      final entry = TransactionHistoryEntry.fromJson(json);

      expect(entry.paymentType, 'Tuition Fees');
      expect(entry.feeType, 'Tuition Fee');
      expect(entry.billerName, 'Prof. Sharma Classes');
      expect(entry.customerParams, hasLength(2));
      expect(entry.customerParams[0].label, 'Recipient Name');
      expect(entry.customerParams[0].value, 'Prof. Sharma Classes');
      expect(entry.customerParams[1].label, 'Account Number');
      expect(entry.customerParams[1].value, 'XXXXXX9876');
    });

    test('Unpacks nested customer_params if input wrapper is returned for Tuition Fee', () {
      final json = {
        'payment_status': 'success',
        'payment_type': 'Education Fees',
        'fee_type': 'tuition fee',
        'biller_name': 'Apex Coaching Academy',
        'amount': '5000',
        'customer_params': [
          {
            'label': 'input',
            'value': [
              {
                'paramName': 'Student Name',
                'paramValue': 'Rohan Kulkarni',
              },
              {
                'paramName': 'Tutor Name',
                'paramValue': 'Apex Coaching Academy',
              },
            ],
          },
        ],
      };

      final entry = TransactionHistoryEntry.fromJson(json);

      expect(entry.customerParams, hasLength(2));
      expect(entry.customerParams[0].label, 'Student Name');
      expect(entry.customerParams[0].value, 'Rohan Kulkarni');
      expect(entry.customerParams[1].label, 'Tutor Name');
      expect(entry.customerParams[1].value, 'Apex Coaching Academy');
    });

    testWidgets(
        'Renders dynamic Tuition Fee parameters without duplicate headers or raw Map/List strings',
        (tester) async {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(390, 844) * 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final entry = TransactionHistoryEntry.fromJson({
        'payment_status': 'SUCCESS',
        'payment_type': 'Tuition Fees',
        'fee_type': 'Tuition Fee',
        'biller_name': 'Dr. Kulkarni Tutorials',
        'masked_identifier': 'XXXXXX4321',
        'amount': 4200,
        'customer_mobile': '9890123456',
        'pg_transaction_id': 'pay_Edu987654321',
        'transaction_time': '30 Sep 2026, 05:00pm',
        'method': 'upi',
        'payment_mode': 'Google Pay',
        'amount_breakdown': {'Bill Amount': 4200, 'Total': 4200},
        'customer_params': [
          {'label': 'Recipient Name', 'value': 'Dr. Kulkarni Tutorials'},
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

      // Must display Recipient Name and Account Number dynamically
      expect(find.text('Recipient Name'), findsOneWidget);
      expect(find.text('Dr. Kulkarni Tutorials'), findsOneWidget);
      expect(find.text('Account Number'), findsOneWidget);
      expect(find.text('XXXXXX4321'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Renders unpacked nested parameters directly on Tuition Fee detail screen',
        (tester) async {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(390, 844) * 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final entry = TransactionHistoryEntry.fromJson({
        'payment_status': 'SUCCESS',
        'payment_type': 'Tuition Fee',
        'biller_name': 'Prof. Deshmukh',
        'amount': 6000,
        'customer_params': [
          {
            'label': 'input',
            'value': [
              {'paramName': 'Student Name', 'paramValue': 'Amit Deshmukh'},
              {'paramName': 'Subject', 'paramValue': 'Mathematics'},
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

      expect(find.text('input'), findsNothing);
      expect(find.text('Student Name'), findsOneWidget);
      expect(find.text('Amit Deshmukh'), findsOneWidget);
      expect(find.text('Subject'), findsOneWidget);
      expect(find.text('Mathematics'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    for (final width in [320.0, 360.0, 375.0, 390.0, 412.0, 440.0]) {
      testWidgets(
          'Tuition Fee detail renders without overflow at ${width.toInt()}px with text scale 1.15',
          (tester) async {
        tester.view.devicePixelRatio = 2;
        tester.view.physicalSize = Size(width, 800) * 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final entry = TransactionHistoryEntry.fromJson({
          'payment_status': 'SUCCESS',
          'payment_type': 'Tuition Fees',
          'fee_type': 'Tuition Fee',
          'biller_name': 'Mathematics Foundation Institute',
          'masked_identifier': 'XXXXXX7890',
          'amount': 7500,
          'customer_mobile': '9822334455',
          'pg_transaction_id': 'pay_Edu7500',
          'transaction_time': '30 Sep 2026, 05:30pm',
          'method': 'upi',
          'payment_mode': 'Google Pay',
          'amount_breakdown': {'Bill Amount': 7500, 'Total': 7500},
          'customer_params': [
            {
              'label': 'Recipient Name',
              'value': 'Mathematics Foundation Institute',
            },
            {'label': 'Account Number', 'value': 'XXXXXX7890'},
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

        expect(find.text('Mathematics Foundation Institute'), findsOneWidget);
        expect(find.text('XXXXXX7890'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
