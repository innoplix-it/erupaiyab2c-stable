import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_rupaiya/features/profile/models/transaction_history_entry.dart';
import 'package:e_rupaiya/features/profile/views/transaction_detail_screen.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Electricity Transaction Details Header', () {
    testWidgets('Renders Payment to and Consumer No with dynamic backend values',
        (tester) async {
      final entry = TransactionHistoryEntry.fromJson({
        'payment_status': 'SUCCESS',
        'payment_type': 'Electricity Bill',
        'biller_name': 'Maharashtra State Electricity Distribution Co. Ltd',
        'service_no_full': '049338085841',
        'service_no': '049338085841',
        'amount': '1250.00',
        'total_amount_charged': '1250.00',
        'transaction_id': 'TXN12345678',
        'transaction_time': '2026-10-01 12:00:00',
      });

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(392, 852),
          builder: (context, child) => MaterialApp(
            home: TransactionDetailScreen(entry: entry),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check LEFT SIDE
      expect(find.text('Payment to'), findsOneWidget);
      expect(
        find.text('Maharashtra State Electricity Distribution Co. Ltd'),
        findsOneWidget,
      );

      // Check RIGHT SIDE
      expect(find.text('Consumer No'), findsOneWidget);
      expect(find.text('049338085841'), findsOneWidget);

      // Verify that "Payment Type" is NOT rendered in the header card
      expect(find.text('Payment Type'), findsNothing);
    });

    testWidgets('Falls back to service_no if service_no_full is empty',
        (tester) async {
      final entry = TransactionHistoryEntry.fromJson({
        'payment_status': 'SUCCESS',
        'payment_type': 'Electricity Bill',
        'biller_name': 'Adani Electricity Mumbai',
        'service_no': '987654321',
        'service_no_full': null,
        'amount': '800.00',
        'total_amount_charged': '800.00',
        'transaction_id': 'TXN87654321',
        'transaction_time': '2026-10-01 12:00:00',
      });

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(392, 852),
          builder: (context, child) => MaterialApp(
            home: TransactionDetailScreen(entry: entry),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Payment to'), findsOneWidget);
      expect(find.text('Adani Electricity Mumbai'), findsOneWidget);
      expect(find.text('Consumer No'), findsOneWidget);
      expect(find.text('987654321'), findsOneWidget);
      expect(find.text('Payment Type'), findsNothing);
    });
  });
}
