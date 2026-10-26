import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:e_rupaiya/features/profile/models/transaction_history_entry.dart';
import 'package:e_rupaiya/features/profile/views/transaction_detail_screen.dart';
import 'package:e_rupaiya/features/services/models/credit_card_transaction.dart';
import 'package:e_rupaiya/features/services/views/credit_card_transaction_detail_screen.dart';

// Verifies that the "Payment to" biller / operator name renders with an
// identical effective TextStyle on both the Electricity Transaction Details
// screen (shared TransactionDetailScreen) and the Credit Card Transaction
// Details screen (standalone CreditCardTransactionDetailScreen).
//
// Both headers are built by a private _CardHeading that styles the value with
// bodyMedium?.copyWith(fontSize: 11.5.sp, fontWeight: w600). This test proves
// the two screens resolve to the same size, so no code change is warranted.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  // Pump a screen under a fixed, identical ScreenUtil + device configuration
  // and return the resolved TextStyle of the header value Text.
  Future<TextStyle> headerValueStyle(
    WidgetTester tester,
    Widget screen,
    String valueText,
  ) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        fontSizeResolver: FontSizeResolvers.radius,
        builder: (context, _) => MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();

    final finder = find.text(valueText);
    expect(finder, findsWidgets,
        reason: 'Header value "$valueText" should be rendered');

    final text = tester.widget<Text>(finder.first);
    return text.style!;
  }

  testWidgets(
      'Electricity and Credit Card "Payment to" name share the same effective font size',
      (tester) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(390, 844) * 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final electricityStyle = await headerValueStyle(
      tester,
      TransactionDetailScreen(
        entry: TransactionHistoryEntry.fromJson({
          'payment_status': 'success',
          'payment_type': 'Electricity',
          'biller_name': 'MSEDCL',
          'amount': '1500',
          'total_amount_charged': '1500',
          'service_no_full': '102345678901',
          'customer_params': [
            {'label': 'Consumer Number', 'value': '102345678901'},
          ],
        }),
      ),
      'MSEDCL',
    );

    final creditCardStyle = await headerValueStyle(
      tester,
      const CreditCardTransactionDetailScreen(
        transaction: CreditCardTransaction(
          paymentStatus: 'success',
          billerName: 'HDFC Bank Credit Card',
          maskedIdentifier: '1234',
          amount: '2500',
          platformFees: '0',
          totalAmountCharged: '2500',
          paymentTransactionId: 'TXN123',
          bankReferenceId: 'BANK123',
          transactionTime: '',
          method: '',
          methodIcon: '',
          paymentMode: '',
          vpa: '',
          rrn: '',
          icon: '',
        ),
      ),
      'HDFC Bank Credit Card',
    );

    // Effective rendered size and weight must match exactly.
    expect(electricityStyle.fontSize, creditCardStyle.fontSize,
        reason: 'Font sizes must be identical across both detail screens');
    expect(electricityStyle.fontWeight, creditCardStyle.fontWeight,
        reason: 'Font weights must be identical across both detail screens');

    // Sanity: the shared header resolves to the design 11.5.sp value.
    expect(electricityStyle.fontSize, 11.5.sp);
    expect(electricityStyle.fontWeight, FontWeight.w600);

    expect(tester.takeException(), isNull);
  });
}
