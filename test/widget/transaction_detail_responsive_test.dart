import 'package:e_rupaiya/features/profile/models/transaction_history_entry.dart';
import 'package:e_rupaiya/features/profile/views/transaction_detail_screen.dart';
import 'package:e_rupaiya/features/services/models/credit_card_transaction.dart';
import 'package:e_rupaiya/features/services/views/credit_card_transaction_detail_screen.dart';
import 'package:e_rupaiya/widgets/custom_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helpers/responsive_test_sizes.dart';

const _textScales = [0.85, 1.0, 1.15];

/// Status bar and home indicator insets of a notched phone (logical px).
const _topInset = 47.0;
const _bottomInset = 34.0;

const _longBiller =
    'Maharashtra State Electricity Distribution Company Limited Mumbai';
const _longTxnId = 'PGTXN20261014153200987654321012345678901234';
const _longBankRef = 'BANKREF-HDFC-0000123456789012345678901234567';
const _longVpa = 'very.long.customer.name.for.testing@okhdfcbankupi';
const _longRrn = '426812345678901234567890';

Future<void> _setView(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = size * 2;
  tester.view.padding = const FakeViewPadding(
    top: _topInset * 2,
    bottom: _bottomInset * 2,
  );
  tester.view.viewPadding = const FakeViewPadding(
    top: _topInset * 2,
    bottom: _bottomInset * 2,
  );
  addTearDown(tester.view.reset);
}

Widget _app(Widget home, double scale) => ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: MaterialApp(home: home),
      ),
    );

Finder _byTypeName(String name) =>
    find.byWidgetPredicate((w) => w.runtimeType.toString() == name);

TransactionHistoryEntry _refundEntry() => TransactionHistoryEntry.fromJson({
      'payment_status': 'REFUND_PENDING',
      'payment_type': 'Electricity Bill',
      'biller_name': _longBiller,
      'amount': '1234567.00',
      'total_amount_charged': '1234567.00',
      'pg_transaction_id': _longTxnId,
      'bank_reference_id': _longBankRef,
      'service_no_full': '170019239876543210',
      'transaction_time': '2026-10-14 15:32:00',
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('TransactionDetailScreen', () {
    for (final size in responsiveTestScreenSizes) {
      for (final scale in _textScales) {
        testWidgets('${size.width}x${size.height} @${scale}x', (tester) async {
          await _setView(tester, size);
          var done = 0;
          await tester.pumpWidget(
            _app(
              TransactionDetailScreen(
                entry: _refundEntry(),
                onDone: () => done++,
              ),
              scale,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Header: the full refund message sits above the details card.
          final message = find.textContaining('A refund of');
          expect(message, findsOneWidget);
          final card = _byTypeName('_TransactionResultCard');
          expect(card, findsOneWidget);
          final cardRect = tester.getRect(card);
          expect(
            tester.getRect(message).bottom,
            lessThanOrEqualTo(cardRect.top),
            reason: 'status message must not run under the details card',
          );
          expect(
            tester.getRect(find.text('Transaction Failed')).top,
            greaterThanOrEqualTo(_topInset),
            reason: 'header must clear the status bar',
          );

          // The card follows the real viewport width.
          expect(cardRect.width, moreOrLessEquals(size.width - 2 * 22.w));

          // Bottom actions sit above the home indicator and still work.
          final doneButton = find.byType(CustomElevatedButton);
          expect(doneButton, findsOneWidget);
          expect(
            tester.getRect(doneButton).bottom,
            lessThanOrEqualTo(size.height - _bottomInset),
          );
          final powered = find.text('powered by');
          expect(
            tester.getRect(powered).bottom,
            lessThanOrEqualTo(size.height - _bottomInset),
          );
          await tester.tap(doneButton);
          expect(done, 1);
        });
      }
    }
  });

  group('CreditCardTransactionDetailScreen', () {
    const tx = CreditCardTransaction(
      paymentStatus: 'SUCCESS',
      billerName: _longBiller,
      maskedIdentifier: 'XXXX XXXX XXXX 4321',
      amount: '1234567.00',
      platformFees: '12.50',
      totalAmountCharged: '1234579.50',
      paymentTransactionId: _longTxnId,
      bankReferenceId: _longBankRef,
      transactionTime: '2026-10-14 15:32:00',
      method: 'UPI',
      methodIcon: '',
      paymentMode: 'UPI Collect Request via Third Party Application',
      vpa: _longVpa,
      rrn: _longRrn,
      icon: '',
    );

    Future<void> pumpCard(WidgetTester tester, double scale) async {
      final router = GoRouter(
        initialLocation: '/detail',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(body: Text('history')),
            routes: [
              GoRoute(
                path: 'detail',
                builder: (_, __) =>
                    const CreditCardTransactionDetailScreen(transaction: tx),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, _) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    for (final size in responsiveTestScreenSizes) {
      for (final scale in _textScales) {
        testWidgets('${size.width}x${size.height} @${scale}x', (tester) async {
          await _setView(tester, size);
          await pumpCard(tester, scale);
          expect(tester.takeException(), isNull);

          // Every long value is shown in full and stays inside the screen.
          for (final value in [
            _longBiller,
            _longTxnId,
            _longBankRef,
            _longVpa,
            _longRrn,
            'UPI Collect Request via Third Party Application',
          ]) {
            final text = find.text(value);
            expect(text, findsOneWidget, reason: value);
            final widget = tester.widget<Text>(text);
            expect(widget.maxLines, isNull, reason: value);
            expect(widget.overflow, isNot(TextOverflow.ellipsis));
            final rect = tester.getRect(text);
            expect(rect.left, greaterThanOrEqualTo(0), reason: value);
            expect(rect.right, lessThanOrEqualTo(size.width), reason: value);
          }

          // Header clears the status bar.
          expect(
            tester.getRect(find.text('Success')).top,
            greaterThanOrEqualTo(_topInset),
          );

          // The last row can scroll fully above the home indicator.
          final scrollable = find.byType(Scrollable).first;
          await tester.drag(scrollable, const Offset(0, -3000));
          await tester.pumpAndSettle();
          expect(
            tester.getRect(find.text(_longRrn)).bottom,
            lessThanOrEqualTo(size.height - _bottomInset),
          );

          // Back still returns to the previous screen.
          await tester.tap(find.byIcon(Icons.arrow_back));
          await tester.pumpAndSettle();
          expect(find.text('history'), findsOneWidget);
        });
      }
    }
  });
}
