import 'package:e_rupaiya/features/services/models/credit_card_month_section.dart';
import 'package:e_rupaiya/features/services/models/credit_card_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

CreditCardTransaction _tx({
  required String id,
  required String time,
  String billerName = 'Bank Credit Card',
  String maskedIdentifier = '****1234',
}) {
  return CreditCardTransaction(
    paymentStatus: 'SUCCESS',
    billerName: billerName,
    maskedIdentifier: maskedIdentifier,
    amount: '100.00',
    platformFees: '2.00',
    totalAmountCharged: '100.00',
    paymentTransactionId: id,
    bankReferenceId: 'REF-$id',
    transactionTime: time,
    method: 'UPI',
    methodIcon: '',
    paymentMode: 'Online',
    vpa: 'user@bank',
    rrn: 'RRN-$id',
    icon: '',
  );
}

void main() {
  group('parseCreditCardTxnDate tests', () {
    test('parses ISO-8601 strings', () {
      final dt = parseCreditCardTxnDate('2026-10-23T14:30:00.000Z');
      expect(dt, isNotNull);
      expect(dt!.year, 2026);
      expect(dt.month, 10);
      expect(dt.day, 23);
    });

    test('parses SQL datetime strings YYYY-MM-DD HH:mm:ss', () {
      final dt = parseCreditCardTxnDate('2026-03-15 09:20:00');
      expect(dt, isNotNull);
      expect(dt!.year, 2026);
      expect(dt.month, 3);
      expect(dt.day, 15);
      expect(dt.hour, 9);
      expect(dt.minute, 20);
    });

    test('parses human readable string "24 Sep 2026, 7:45am"', () {
      final dt = parseCreditCardTxnDate('24 Sep 2026, 7:45am');
      expect(dt, isNotNull);
      expect(dt!.year, 2026);
      expect(dt.month, 9);
      expect(dt.day, 24);
      expect(dt.hour, 7);
      expect(dt.minute, 45);
    });

    test('parses human readable string "12 Jan 2026, 08:15 pm"', () {
      final dt = parseCreditCardTxnDate('12 Jan 2026, 08:15 pm');
      expect(dt, isNotNull);
      expect(dt!.year, 2026);
      expect(dt.month, 1);
      expect(dt.day, 12);
      expect(dt.hour, 20);
      expect(dt.minute, 15);
    });

    test('parses date-only YYYY-MM-DD', () {
      final dt = parseCreditCardTxnDate('2026-05-04');
      expect(dt, isNotNull);
      expect(dt!.year, 2026);
      expect(dt.month, 5);
      expect(dt.day, 4);
    });

    test('parses DD-MM-YYYY and DD/MM/YYYY', () {
      final dt1 = parseCreditCardTxnDate('15-08-2026');
      expect(dt1, isNotNull);
      expect(dt1!.year, 2026);
      expect(dt1.month, 8);
      expect(dt1.day, 15);

      final dt2 = parseCreditCardTxnDate('01/11/2026');
      expect(dt2, isNotNull);
      expect(dt2!.year, 2026);
      expect(dt2.month, 11);
      expect(dt2.day, 1);
    });

    test('returns null on invalid or empty date string without crashing', () {
      expect(parseCreditCardTxnDate(''), isNull);
      expect(parseCreditCardTxnDate('   '), isNull);
      expect(parseCreditCardTxnDate('invalid_date_format'), isNull);
      expect(parseCreditCardTxnDate('N/A'), isNull);
    });
  });

  group('groupCreditCardTransactionsByMonth tests', () {
    test('returns empty list when input is empty', () {
      final sections = groupCreditCardTransactionsByMonth([]);
      expect(sections, isEmpty);
    });

    test('groups transactions by month and sorts newest month first', () {
      final txs = [
        _tx(id: '1', time: '2026-01-10 10:00:00'),
        _tx(id: '2', time: '2026-03-05 11:00:00'),
        _tx(id: '3', time: '2026-03-20 12:00:00'),
        _tx(id: '4', time: '2026-10-01 13:00:00'),
      ];

      final sections = groupCreditCardTransactionsByMonth(txs);
      expect(sections.length, 3);

      // October 2026 (newest first)
      expect(sections[0].title, 'October 2026');
      expect(sections[0].year, 2026);
      expect(sections[0].month, 10);
      expect(sections[0].count, 1);
      expect(sections[0].items.length, 1);

      // March 2026
      expect(sections[1].title, 'March 2026');
      expect(sections[1].year, 2026);
      expect(sections[1].month, 3);
      expect(sections[1].count, 2);
      expect(sections[1].items.length, 2);

      // January 2026
      expect(sections[2].title, 'January 2026');
      expect(sections[2].year, 2026);
      expect(sections[2].month, 1);
      expect(sections[2].count, 1);
      expect(sections[2].items.length, 1);
    });

    test('does NOT create groups for months with zero transactions', () {
      final txs = [
        _tx(id: '1', time: '2026-01-10 10:00:00'),
        // No transactions in February 2026
        _tx(id: '2', time: '2026-03-05 11:00:00'),
      ];

      final sections = groupCreditCardTransactionsByMonth(txs);
      final titles = sections.map((s) => s.title).toList();

      expect(titles, contains('March 2026'));
      expect(titles, contains('January 2026'));
      expect(titles, isNot(contains('February 2026')));
      expect(titles, isNot(contains('April 2026')));
    });

    test(
        'groups undated or invalid date records into fallback Transactions section',
        () {
      final txs = [
        _tx(id: '1', time: '2026-10-15 10:00:00'),
        _tx(id: '2', time: 'invalid-date'),
        _tx(id: '3', time: ''),
      ];

      final sections = groupCreditCardTransactionsByMonth(txs);
      expect(sections.length, 2);

      expect(sections[0].title, 'October 2026');
      expect(sections[0].count, 1);

      expect(sections[1].title, 'Transactions');
      expect(sections[1].count, 2);
      expect(sections[1].items.map((i) => i.paymentTransactionId), ['2', '3']);
    });
  });
}
