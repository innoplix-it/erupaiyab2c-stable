// Notification -> transaction details navigation.
//
// Transaction notifications from every module (bill payments, recharges,
// credit card, FASTag, digital gold, refunds, ...) must open the details of
// exactly the transaction they refer to, on that module's existing details
// screen (credit card has its own; the rest share TransactionDetailScreen),
// from the View label or anywhere on the card. Missing or unknown ids never open another
// transaction's details. Responsive checks use the canonical
// `responsiveTestScreenSizes` matrix.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:e_rupaiya/constants/routes_constant.dart';
import 'package:e_rupaiya/features/home/controllers/home_controller.dart';
import 'package:e_rupaiya/features/home/controllers/notifications_controller.dart';
import 'package:e_rupaiya/features/home/helpers/bill_reminder_payment.dart';
import 'package:e_rupaiya/features/home/models/bill_reminder_model.dart';
import 'package:e_rupaiya/features/home/repositories/home_repository.dart';
import 'package:e_rupaiya/features/home/helpers/notification_transaction_resolver.dart';
import 'package:e_rupaiya/features/home/models/notification_item.dart';
import 'package:e_rupaiya/features/home/models/notifications_feed.dart';
import 'package:e_rupaiya/features/home/repositories/notifications_repository.dart';
import 'package:e_rupaiya/features/home/views/notifications_screen.dart';
import 'package:e_rupaiya/features/profile/controllers/transaction_history_controller.dart';
import 'package:e_rupaiya/features/profile/models/transaction_history_entry.dart';
import 'package:e_rupaiya/features/profile/models/transaction_history_page.dart';
import 'package:e_rupaiya/features/profile/repositories/transaction_history_repository.dart';
import 'package:e_rupaiya/features/profile/views/transaction_detail_screen.dart';
import 'package:e_rupaiya/features/services/views/credit_card_transaction_detail_screen.dart';
import 'package:e_rupaiya/features/services/controllers/biller_detail_controller.dart';
import 'package:e_rupaiya/features/services/controllers/credit_card_transactions_controller.dart';
import 'package:e_rupaiya/features/services/models/biller_detail_args.dart';
import 'package:e_rupaiya/features/services/models/biller_model.dart';
import 'package:e_rupaiya/features/services/repositories/biller_repository.dart';
import 'package:e_rupaiya/features/services/models/credit_card_transaction.dart';
import 'package:e_rupaiya/features/services/repositories/credit_card_transactions_repository.dart';
import 'package:e_rupaiya/widgets/k_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../helpers/responsive_test_sizes.dart';

const _logo = 'assets/images/png/erupaiyaLogo.png';

NotificationItem _notification(
  String id, {
  required String title,
  String subtitle = 'Electricity bill of \u20B9100',
  String? referenceId,
  String redirect = '',
  bool isRead = false,
}) {
  return NotificationItem(
    id: id,
    title: title,
    subtitle: subtitle,
    actionLabel: 'View',
    iconAsset: _logo,
    section: 'Today',
    referenceId: referenceId,
    redirectScreen: redirect,
    isRead: isRead,
    createdAt: DateTime(2026, 10, 10, 12),
  );
}

TransactionHistoryEntry _entry(
  String ref,
  String status, {
  String paymentType = 'Electricity',
  String maskedIdentifier = '',
  String bankReferenceId = '',
  String rrn = '',
}) {
  return TransactionHistoryEntry(
    paymentStatus: status,
    paymentType: paymentType,
    billerName: 'Biller $ref',
    maskedIdentifier: maskedIdentifier,
    amount: '100',
    platformFees: '',
    totalAmountCharged: '100',
    customerMobile: '',
    iconUrl: '',
    pgTransactionId: 'pg-$ref',
    ecoinsTransactionId: '',
    transactionId: 'txn-$ref',
    bankReferenceId: bankReferenceId,
    referenceId: ref,
    transactionTime: '',
    method: '',
    methodIcon: '',
    paymentMode: '',
    vpa: '',
    rrn: rrn,
  );
}

/// One transaction per module, as the shared history API returns them.
final _moduleHistory = [
  [
    _entry('MOB-1', 'SUCCESS', paymentType: 'Mobile Prepaid'),
    _entry('DTH-1', 'FAILED', paymentType: 'DTH'),
    _entry('FT-1', 'PENDING', paymentType: 'FASTag'),
  ],
  [
    _entry(
      'CC-1',
      'SUCCESS',
      paymentType: 'Credit Card',
      maskedIdentifier: 'XXXX1234',
    ),
    _entry(
      'CC-2',
      'FAILED',
      paymentType: 'Credit Card',
      maskedIdentifier: 'XXXX1234',
    ),
    _entry('GOLD-1', 'PROCESSING', paymentType: 'Digital Gold'),
    _entry('RF-1', 'REFUNDED', paymentType: 'Water'),
    _entry(
      'LPG-1',
      'SUCCESS',
      paymentType: 'LPG',
      bankReferenceId: 'BANK-77',
      rrn: 'RRN-88',
    ),
  ],
  [
    _entry('ELEC-1', 'SUCCESS', paymentType: 'Electricity Bill'),
    _entry('EDU-1', 'FAILED', paymentType: 'Tuition Fees'),
    _entry('RENT-1', 'PROCESSING', paymentType: 'House Rent'),
    _entry('SHOP-1', 'SUCCESS', paymentType: 'Shop Rent'),
    _entry('INS-1', 'PENDING', paymentType: 'Insurance'),
    _entry('LOAN-1', 'PROCESSING', paymentType: 'Loan Repayment'),
    _entry('GOLD-2', 'SUCCESS', paymentType: 'Digital Gold'),
  ],
];

class _FakeNotificationsRepository extends NotificationsRepository {
  _FakeNotificationsRepository(this.items) : super(dio: Dio());

  final List<NotificationItem> items;
  final markReadIds = <String>[];

  @override
  Future<NotificationsFeed> fetchNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    return NotificationsFeed(
      unreadCount: items.where((n) => !n.isRead).length,
      updates: const [],
      notifications: items,
      totalRecords: items.length,
    );
  }

  @override
  Future<bool> markNotificationRead(String id) async {
    markReadIds.add(id);
    return true;
  }
}

/// Serves [pages] in order and records each history request.
class _FakeHistoryRepository extends TransactionHistoryRepository {
  _FakeHistoryRepository(this.pages) : super(dio: Dio());

  final List<List<TransactionHistoryEntry>> pages;
  final requests = <({int page, DateTime? fromDate, DateTime? toDate})>[];
  bool fail = false;
  Completer<void>? gate;

  @override
  Future<TransactionHistoryPage> fetchHistoryPage({
    int? days,
    int page = 1,
    int limit = 20,
    DateTime? fromDate,
    DateTime? toDate,
    int? lastYears,
    String? month,
    String? status,
    String? service,
    String? paymentType,
    double? minAmount,
    double? maxAmount,
    String? consumerId,
  }) async {
    requests.add((page: page, fromDate: fromDate, toDate: toDate));
    await gate?.future;
    if (fail) {
      throw DioException(requestOptions: RequestOptions(path: '/history'));
    }
    final items = page <= pages.length
        ? pages[page - 1]
        : const <TransactionHistoryEntry>[];
    return TransactionHistoryPage(
      items: items,
      currentPage: page,
      totalPages: pages.length,
      totalRecords: pages.fold(0, (sum, p) => sum + p.length),
      limit: limit,
    );
  }
}

CreditCardTransaction _cardTxn(String paymentTransactionId, String status) {
  return CreditCardTransaction(
    paymentStatus: status,
    billerName: 'HDFC',
    maskedIdentifier: 'XXXX1234',
    amount: '5000',
    platformFees: '',
    totalAmountCharged: '5000',
    paymentTransactionId: paymentTransactionId,
    bankReferenceId: '',
    transactionTime: '',
    method: '',
    methodIcon: '',
    paymentMode: '',
    vpa: '',
    rrn: '',
    icon: '',
  );
}

/// Card transactions as the credit card module's list API returns them.
/// CC-2 is deliberately missing, to exercise the generic fallback.
class _FakeCreditCardRepository extends CreditCardTransactionsRepository {
  _FakeCreditCardRepository() : super(dio: Dio());

  final requests = <String>[];

  @override
  Future<CreditCardTransactionsResponse> fetchTransactions({
    required String maskedIdentifier,
    int page = 1,
    int limit = 10,
  }) async {
    requests.add(maskedIdentifier);
    return CreditCardTransactionsResponse(
      success: true,
      message: '',
      items: [
        _cardTxn('txn-OTHER', 'SUCCESS'),
        _cardTxn('txn-CC-1', 'SUCCESS'),
      ],
      currentPage: 1,
      totalPages: 1,
      totalRecords: 2,
    );
  }
}

class _CreditCardDetailProbe extends StatelessWidget {
  const _CreditCardDetailProbe(this.transaction);

  final CreditCardTransaction? transaction;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Text('card detail ${transaction?.paymentTransactionId}'),
      );
}

class _DetailProbe extends StatelessWidget {
  const _DetailProbe(this.path, this.entry);

  final String path;
  final TransactionHistoryEntry? entry;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Text('detail $path ${entry?.transactionId}'),
      );
}

BillReminderItem _reminder(
  int id, {
  String billerId = 'MSEDCL0001',
  String billerName = 'MSEDCL',
  String paymentType = 'Electricity',
  String maskedIdentifier = '170010012345',
  String customerMobile = '9876543210',
  bool canPayNow = true,
}) {
  return BillReminderItem(
    id: id,
    billerId: billerId,
    billerName: billerName,
    paymentType: paymentType,
    billerIcon: '',
    maskedIdentifier: maskedIdentifier,
    customerMobile: customerMobile,
    lastBillAmount: 1200,
    dueDate: '2026-10-20',
    billGeneratedDate: '2026-10-05',
    daysRemaining: 6,
    priority: '',
    note: '',
    description: null,
    lastFetchedAt: '',
    canPayNow: canPayNow,
  );
}

/// Serves bill reminders as `GET /api/bill-reminders` pages.
class _FakeHomeRepository extends HomeRepository {
  _FakeHomeRepository() : super(dio: Dio());

  List<List<BillReminderItem>> pages = [
    [
      _reminder(40, billerId: 'TATA0001', billerName: 'Tata Power'),
      _reminder(41),
    ],
    [
      _reminder(
        52,
        billerId: 'HDFC0CC',
        billerName: 'HDFC Credit Card',
        paymentType: 'Credit Card',
        maskedIdentifier: 'XXXX XXXX XXXX 4321',
      ),
      _reminder(53, billerId: 'JIO0001', paymentType: 'Mobile Postpaid'),
      _reminder(54, canPayNow: false),
    ],
  ];
  final requestedPages = <int>[];
  bool fail = false;
  Completer<void>? gate;

  @override
  Future<BillReminderResponse> fetchBillReminders({
    int page = 1,
    int limit = 20,
  }) async {
    requestedPages.add(page);
    await gate?.future;
    if (fail) {
      throw DioException(requestOptions: RequestOptions(path: '/reminders'));
    }
    return BillReminderResponse(
      status: true,
      message: '',
      currentPage: page,
      limit: limit,
      totalRecords: pages.fold(0, (sum, p) => sum + p.length),
      totalPages: pages.length,
      items: page <= pages.length ? pages[page - 1] : const [],
    );
  }
}

class _FakeBillerDetailController extends BillerDetailController {
  _FakeBillerDetailController(this.selected)
      : super(repository: BillerRepository(dio: Dio()));

  final List<(Biller, String?)> selected;

  @override
  void selectBiller(Biller biller, {String? categoryName}) {
    selected.add((biller, categoryName));
  }
}

class _BillPaymentProbe extends StatelessWidget {
  const _BillPaymentProbe(this.args);

  final BillerDetailArgs? args;

  @override
  Widget build(BuildContext context) {
    final a = args;
    return Scaffold(
      body: Text(
        a == null
            ? 'pay none'
            : 'pay ${a.biller.billerId} ${a.paymentType} ${a.mobileNumber} '
                '${a.cardLast4} ${a.isCreditCard} ${a.autoFetchBill}',
      ),
    );
  }
}

final _historyPages = [
  [
    _entry('REF-S-2', 'SUCCESS'),
    _entry('REF-S', 'SUCCESS'),
  ],
  [
    _entry('REF-F', 'FAILED'),
    _entry('REF-P', 'PENDING'),
  ],
];

final _defaultNotifications = [
  _notification('n-s', title: 'Bill Payment Successful', referenceId: 'REF-S'),
  _notification('n-f', title: 'Bill Payment Failed', referenceId: 'REF-F'),
  _notification('n-p', title: 'Bill Payment Pending', referenceId: 'REF-P'),
];

class _Harness {
  _Harness(this.notifications, this.history);

  final creditCards = _FakeCreditCardRepository();
  final home = _FakeHomeRepository();
  final selectedBillers = <(Biller, String?)>[];

  final _FakeNotificationsRepository notifications;
  final _FakeHistoryRepository history;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  List<NotificationItem>? items,
  List<List<TransactionHistoryEntry>>? pages,
  bool realDetails = false,
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = size * 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final harness = _Harness(
    _FakeNotificationsRepository(items ?? _defaultNotifications),
    _FakeHistoryRepository(pages ?? _historyPages),
  );

  GoRoute detail(String path) => GoRoute(
        path: path,
        builder: (_, state) => realDetails
            ? TransactionDetailScreen(
                entry: state.extra as TransactionHistoryEntry?,
              )
            : _DetailProbe(path, state.extra as TransactionHistoryEntry?),
      );

  final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: RouteConstants.notifications,
    routes: [
      GoRoute(
        path: RouteConstants.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: RouteConstants.transactions,
        builder: (_, __) => const Scaffold(body: Text('history list')),
      ),
      detail(RouteConstants.transactionDetailSuccess),
      detail(RouteConstants.transactionDetailFailed),
      detail(RouteConstants.transactionDetailPending),
      GoRoute(
        path: RouteConstants.creditCardTransactionDetail,
        builder: (_, state) => realDetails
            ? CreditCardTransactionDetailScreen(
                transaction: state.extra as CreditCardTransaction?,
              )
            : _CreditCardDetailProbe(state.extra as CreditCardTransaction?),
      ),
      GoRoute(
        path: RouteConstants.billerDetail,
        builder: (_, state) =>
            _BillPaymentProbe(state.extra as BillerDetailArgs?),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) => ProviderScope(
        overrides: [
          notificationsRepositoryProvider
              .overrideWithValue(harness.notifications),
          transactionHistoryRepositoryProvider
              .overrideWithValue(harness.history),
          creditCardTransactionsRepositoryProvider
              .overrideWithValue(harness.creditCards),
          homeRepositoryProvider.overrideWithValue(harness.home),
          billerDetailControllerProvider.overrideWith(
            (ref) => _FakeBillerDetailController(harness.selectedBillers),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return harness;
}

Future<void> _settleNavigation(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

/// Lets the error snackbar finish its auto-dismiss timer.
Future<void> _drainSnackbar(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 4));
}

Finder _card(String id) => find.byKey(ValueKey('notification-card-$id'));

Finder _viewOf(String id) =>
    find.descendant(of: _card(id), matching: find.text('View'));

String _detailText(String path, String ref) => 'detail $path txn-$ref';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('View opens the matching transaction details', () {
    for (final (id, ref, path) in [
      ('n-s', 'REF-S', RouteConstants.transactionDetailSuccess),
      ('n-f', 'REF-F', RouteConstants.transactionDetailFailed),
      ('n-p', 'REF-P', RouteConstants.transactionDetailPending),
    ]) {
      testWidgets('$ref -> $path', (tester) async {
        final harness = await _pump(tester);
        await tester.ensureVisible(_viewOf(id));
        await tester.tap(_viewOf(id));
        await _settleNavigation(tester);

        expect(find.text(_detailText(path, ref)), findsOneWidget);
        expect(harness.notifications.markReadIds, [id]);
      });
    }
  });

  testWidgets('tapping the card body opens the same details as View',
      (tester) async {
    await _pump(tester);
    await tester.tap(
      find.descendant(
        of: _card('n-f'),
        matching: find.text('Bill Payment Failed', findRichText: true),
      ),
    );
    await _settleNavigation(tester);
    expect(
      find.text(_detailText(RouteConstants.transactionDetailFailed, 'REF-F')),
      findsOneWidget,
    );
  });

  testWidgets('the close button dismisses without navigating', (tester) async {
    final harness = await _pump(tester);
    final close = find.descendant(
      of: _card('n-s'),
      matching: find.byType(InkWell),
    );
    // Card InkWell, View InkWell, close InkWell.
    await tester.tap(close.last);
    await _settleNavigation(tester);
    expect(_card('n-s'), findsNothing);
    expect(find.textContaining('detail '), findsNothing);
    expect(harness.history.requests, isEmpty);
  });

  testWidgets('a reference that matches transactionId also resolves',
      (tester) async {
    await _pump(
      tester,
      items: [
        _notification(
          'n-t',
          title: 'Payment Successful',
          referenceId: 'txn-REF-P',
        ),
      ],
    );
    await tester.tap(_card('n-t'));
    await _settleNavigation(tester);
    expect(
      find.text(_detailText(RouteConstants.transactionDetailPending, 'REF-P')),
      findsOneWidget,
    );
  });

  testWidgets('status comes from the transaction, not the notification text',
      (tester) async {
    await _pump(
      tester,
      items: [
        _notification(
          'n-old',
          title: 'Bill Payment Pending',
          referenceId: 'REF-S',
        ),
      ],
    );
    await tester.tap(_card('n-old'));
    await _settleNavigation(tester);
    expect(
      find.text(_detailText(RouteConstants.transactionDetailSuccess, 'REF-S')),
      findsOneWidget,
    );
  });

  group('missing or unknown ids never open another transaction', () {
    for (final (label, ref) in [
      ('empty', ''),
      ('null text', 'null'),
      ('zero', '0'),
      ('unknown', 'REF-NOPE'),
      ('partial', 'REF'),
    ]) {
      testWidgets(label, (tester) async {
        final harness = await _pump(
          tester,
          items: [
            _notification(
              'n-x',
              title: 'Bill Payment Failed',
              referenceId: ref,
              redirect: 'bill_history',
            ),
          ],
        );
        await tester.tap(_card('n-x'));
        await _settleNavigation(tester);

        expect(find.textContaining('detail '), findsNothing);
        expect(find.text('history list'), findsOneWidget);
        expect(
          find.text(
            'Transaction details are not available for this notification.',
          ),
          findsOneWidget,
        );
        if (ref == 'REF-NOPE' || ref == 'REF') {
          expect(harness.history.requests, isNotEmpty);
        } else {
          expect(harness.history.requests, isEmpty);
        }
        await _drainSnackbar(tester);
      });
    }
  });

  testWidgets('a rapid double tap opens details only once', (tester) async {
    final harness = await _pump(tester);
    await tester.tap(_card('n-s'));
    await tester.tap(_card('n-s'), warnIfMissed: false);
    await _settleNavigation(tester);
    expect(
      find.text(_detailText(RouteConstants.transactionDetailSuccess, 'REF-S')),
      findsOneWidget,
    );
    // REF-S is on the first page; one lookup means one navigation.
    expect(harness.history.requests, hasLength(1));
  });

  testWidgets('non-transaction notifications keep their existing redirect',
      (tester) async {
    final harness = await _pump(
      tester,
      items: [
        _notification('n-o', title: 'New offer for you', subtitle: 'Hello'),
      ],
    );
    await tester.tap(_card('n-o'));
    await _settleNavigation(tester);
    expect(find.text('Notifications'), findsOneWidget);
    expect(harness.history.requests, isEmpty);
    expect(harness.notifications.markReadIds, ['n-o']);
  });

  group('every module opens its own transaction details', () {
    for (final (title, subtitle, ref, expectedRef, path, redirect) in [
      (
        'Recharge Successful',
        'Your mobile recharge of \u20B9199 was successful',
        'MOB-1',
        'MOB-1',
        RouteConstants.transactionDetailSuccess,
        '',
      ),
      (
        'DTH Recharge Failed',
        'Your DTH recharge could not be completed',
        'DTH-1',
        'DTH-1',
        RouteConstants.transactionDetailFailed,
        '',
      ),
      (
        'FASTag Recharge Pending',
        'Your FASTag recharge is being processed',
        'FT-1',
        'FT-1',
        RouteConstants.transactionDetailPending,
        '',
      ),
      (
        'Gold Purchase Processing',
        'Your digital gold purchase is processing',
        'GOLD-1',
        'GOLD-1',
        RouteConstants.transactionDetailPending,
        '',
      ),
      (
        'Refund Processed',
        'Refund of \u20B9100 credited to your account',
        'RF-1',
        'RF-1',
        RouteConstants.transactionDetailFailed,
        '',
      ),
      (
        'Booking confirmed',
        'Your LPG cylinder is booked',
        'BANK-77',
        'LPG-1',
        RouteConstants.transactionDetailSuccess,
        'transaction_history',
      ),
      (
        'Transaction Successful',
        'Matched by RRN',
        'RRN-88',
        'LPG-1',
        RouteConstants.transactionDetailSuccess,
        '',
      ),
    ]) {
      testWidgets('$title -> $expectedRef', (tester) async {
        final harness = await _pump(
          tester,
          items: [
            _notification(
              'n-m',
              title: title,
              subtitle: subtitle,
              referenceId: ref,
              redirect: redirect,
            ),
          ],
          pages: _moduleHistory,
        );
        await tester.tap(_viewOf('n-m'));
        await _settleNavigation(tester);
        expect(find.text(_detailText(path, expectedRef)), findsOneWidget);
        expect(harness.notifications.markReadIds, ['n-m']);
        expect(harness.creditCards.requests, isEmpty);
      });
    }
  });

  testWidgets('a credit card payment opens the credit card details screen',
      (tester) async {
    final harness = await _pump(
      tester,
      items: [
        _notification(
          'n-cc',
          title: 'Credit Card Bill Paid',
          subtitle: 'Credit card bill of \u20B95000 paid',
          referenceId: 'CC-1',
        ),
      ],
      pages: _moduleHistory,
    );
    await tester.tap(_card('n-cc'));
    await _settleNavigation(tester);
    expect(find.text('card detail txn-CC-1'), findsOneWidget);
    expect(find.textContaining('detail /'), findsNothing);
    expect(harness.creditCards.requests, ['XXXX1234']);
  });

  testWidgets(
      'a credit card payment missing from the card list falls back to the '
      'shared details of the same transaction', (tester) async {
    await _pump(
      tester,
      items: [
        _notification(
          'n-cc2',
          title: 'Credit Card Payment Failed',
          referenceId: 'CC-2',
        ),
      ],
      pages: _moduleHistory,
    );
    await tester.tap(_card('n-cc2'));
    await _settleNavigation(tester);
    expect(
      find.text(_detailText(RouteConstants.transactionDetailFailed, 'CC-2')),
      findsOneWidget,
    );
    expect(find.textContaining('card detail'), findsNothing);
  });

  group('an id without transaction wording', () {
    testWidgets('opens the details when it matches a transaction',
        (tester) async {
      await _pump(
        tester,
        items: [
          _notification(
            'n-b',
            title: 'Booking confirmed',
            subtitle: 'Your FASTag is ready',
            referenceId: 'FT-1',
          ),
        ],
        pages: _moduleHistory,
      );
      await tester.tap(_card('n-b'));
      await _settleNavigation(tester);
      expect(
        find.text(_detailText(RouteConstants.transactionDetailPending, 'FT-1')),
        findsOneWidget,
      );
    });

    testWidgets('keeps the existing behaviour when it matches nothing',
        (tester) async {
      final harness = await _pump(
        tester,
        items: [
          _notification(
            'n-o2',
            title: 'New offer for you',
            subtitle: 'Hello',
            referenceId: 'OFFER-9',
          ),
        ],
        pages: _moduleHistory,
      );
      await tester.tap(_card('n-o2'));
      await _settleNavigation(tester);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('history list'), findsNothing);
      expect(
        find.text(
          'Transaction details are not available for this notification.',
        ),
        findsNothing,
      );
      expect(harness.history.requests, isNotEmpty);
    });
  });

  group('isCreditCardPayment', () {
    for (final (type, expected) in [
      ('Credit Card', true),
      ('CREDIT_CARD', true),
      ('credit-card bill', true),
      ('Electricity', false),
      ('Mobile Prepaid', false),
    ]) {
      test(type, () {
        expect(
          NotificationTransactionResolver.isCreditCardPayment(
            _entry('x', 'SUCCESS', paymentType: type),
          ),
          expected,
        );
      });
    }
  });

  testWidgets('a module notification with an unknown id opens no details',
      (tester) async {
    await _pump(
      tester,
      items: [
        _notification(
          'n-u',
          title: 'Recharge Successful',
          subtitle: 'Your mobile recharge was successful',
          referenceId: 'MOB-404',
        ),
      ],
      pages: _moduleHistory,
    );
    await tester.tap(_card('n-u'));
    await _settleNavigation(tester);
    expect(find.textContaining('detail '), findsNothing);
    expect(find.text('history list'), findsOneWidget);
    await _drainSnackbar(tester);
  });

  group('isTransactionNotification', () {
    NotificationItem item(
      String title, {
      String subtitle = '',
      String redirect = '',
      bool remind = false,
    }) =>
        NotificationItem(
          id: 'x',
          title: title,
          subtitle: subtitle,
          actionLabel: 'View',
          iconAsset: _logo,
          section: 'Today',
          redirectScreen: redirect,
          showRemindButton: remind,
        );

    for (final (label, notification, expected) in [
      ('bill payment', item('Bill Payment Successful'), true),
      ('mobile recharge', item('Recharge Successful'), true),
      ('credit card', item('Credit card bill paid'), true),
      ('gold purchase', item('Digital gold purchase failed'), true),
      ('refund', item('Refund initiated'), true),
      ('debit', item('\u20B9100 debited'), true),
      ('history redirect', item('Done', redirect: 'transaction_history'), true),
      (
        'bill reminder',
        item('Bill Payment Reminder', subtitle: 'Due in 2 days'),
        false
      ),
      ('remind button', item('Electricity payment', remind: true), false),
      ('spin', item('Spin & Win', subtitle: 'Win on every payment'), false),
      (
        'spin redirect',
        item('Payment bonus', redirect: 'spin_screen'),
        false,
      ),
      (
        'wallet history',
        item('Cashback on payment', redirect: 'wallet_history'),
        false,
      ),
      (
        'app update',
        item('Faster payments', redirect: 'app_update_screen'),
        false,
      ),
      ('offer', item('New offer for you', subtitle: 'Hello'), false),
    ]) {
      test(label, () {
        expect(notification.isTransactionNotification, expected);
      });
    }
  });

  group('all modules and statuses, from View or anywhere on the card', () {
    const success = RouteConstants.transactionDetailSuccess;
    const failed = RouteConstants.transactionDetailFailed;
    const pending = RouteConstants.transactionDetailPending;
    var index = 0;
    for (final (title, subtitle, ref, path) in [
      (
        'Payment Successful',
        'Electricity bill of \u20B91200 paid',
        'ELEC-1',
        success
      ),
      (
        'Transaction Failed',
        'Tuition fee of \u20B95000 failed',
        'EDU-1',
        failed
      ),
      (
        'Processing',
        'House rent of \u20B912000 is processing',
        'RENT-1',
        pending
      ),
      ('Transaction Successful', 'Shop rent of \u20B98000', 'SHOP-1', success),
      (
        'Pending',
        'Insurance premium of \u20B92400 is pending',
        'INS-1',
        pending
      ),
      (
        'Loan EMI processing',
        'Loan EMI of Rs 2500 is in process',
        'LOAN-1',
        pending
      ),
      (
        'LPG booking confirmed',
        'LPG booking of \u20B9900 confirmed',
        'LPG-1',
        success
      ),
      (
        'Gold bought',
        'Digital gold worth \u20B9500 successful',
        'GOLD-2',
        success
      ),
      ('Recharge Successful', 'Mobile recharge of \u20B9199', 'MOB-1', success),
      ('DTH Payment Failed', 'DTH of \u20B9350', 'DTH-1', failed),
      ('FASTag Pending', 'FASTag recharge of \u20B9500', 'FT-1', pending),
      ('Refund Processed', 'Refund of \u20B9100', 'RF-1', failed),
    ]) {
      final viaView = (index++).isEven;
      testWidgets('$ref via ${viaView ? 'View' : 'card'}', (tester) async {
        final item = _notification(
          'n-all',
          title: title,
          subtitle: subtitle,
          referenceId: ref,
        );
        expect(item.isTransactionNotification, isTrue);
        final harness = await _pump(
          tester,
          items: [item],
          pages: _moduleHistory,
        );
        await tester.tap(viaView ? _viewOf('n-all') : _card('n-all'));
        await _settleNavigation(tester);
        expect(find.text(_detailText(path, ref)), findsOneWidget);
        expect(harness.notifications.markReadIds, ['n-all']);
      });
    }
  });

  group('the real details screens show the tapped transaction', () {
    testWidgets('shared details: status, amount, method, ids, time',
        (tester) async {
      const entry = TransactionHistoryEntry(
        paymentStatus: 'PROCESSING',
        paymentType: 'Tuition Fees',
        billerName: 'Sunrise School',
        maskedIdentifier: '',
        amount: '5000',
        platformFees: '',
        totalAmountCharged: '5000',
        customerMobile: '',
        iconUrl: '',
        pgTransactionId: 'pay_EDU77',
        ecoinsTransactionId: '',
        transactionId: 'pay_EDU77',
        bankReferenceId: 'BANK-EDU77',
        referenceId: 'EDU-77',
        transactionTime: '08 Oct 2026, 07:26am',
        method: 'UPI',
        methodIcon: '',
        paymentMode: '',
        vpa: '',
        rrn: '',
      );
      final other = _entry('EDU-78', 'SUCCESS', paymentType: 'Tuition Fees');
      await _pump(
        tester,
        items: [
          _notification(
            'n-real',
            title: 'Tuition fee processing',
            subtitle: 'Your tuition fee of \u20B95000 is processing',
            referenceId: 'EDU-77',
          ),
        ],
        pages: [
          [other, entry],
        ],
        realDetails: true,
      );
      await tester.tap(_card('n-real'));
      await _settleNavigation(tester);
      expect(find.byType(TransactionDetailScreen), findsOneWidget);
      expect(find.text('Transaction Pending'), findsOneWidget);
      expect(find.text('\u20B95000'), findsWidgets);
      expect(find.text('UPI'), findsOneWidget);
      expect(find.text('EDU-77'), findsOneWidget);
      expect(find.text('pay_EDU77'), findsOneWidget);
      expect(find.text('BANK-EDU77'), findsOneWidget);
      expect(find.textContaining('08 Oct 2026'), findsWidgets);
      expect(find.text('EDU-78'), findsNothing);
    });

    testWidgets('credit card opens its own details screen', (tester) async {
      await _pump(
        tester,
        items: [
          _notification(
            'n-ccr',
            title: 'Credit Card Payment Successful',
            referenceId: 'CC-1',
          ),
        ],
        pages: _moduleHistory,
        realDetails: true,
      );
      await tester.tap(_viewOf('n-ccr'));
      await _settleNavigation(tester);
      expect(find.byType(CreditCardTransactionDetailScreen), findsOneWidget);
      expect(find.byType(TransactionDetailScreen), findsNothing);
      expect(find.text('txn-CC-1'), findsWidgets);
      expect(find.text('txn-OTHER'), findsNothing);
    });
  });

  group('wording classification', () {
    NotificationItem item(String title, [String subtitle = '']) =>
        NotificationItem(
          id: 'x',
          title: title,
          subtitle: subtitle,
          actionLabel: 'View',
          iconAsset: _logo,
          section: 'Today',
        );

    for (final (text, expected) in [
      ('Tuition fee of \u20B95000 successful', true),
      ('LPG booking of \u20B9900 failed', true),
      ('Loan EMI of Rs 2500 processing', true),
      ('Insurance premium INR 2400 pending', true),
      ('Transaction Successful', true),
      ('Payment Failed', true),
      ('Your KYC verification is pending', false),
      ('Profile updated successfully', false),
      ('Get \u20B9100 cashback on your next payment', false),
      ('Flat 10% off: offer on recharge of \u20B9199', false),
      ('Refer a friend and earn \u20B950', false),
      ('Play Now and win \u20B9500', false),
    ]) {
      test(text, () {
        expect(item(text).isTransactionNotification, expected);
      });
    }
  });

  group('Pay Now opens the existing bill payment screen', () {
    NotificationItem reminderNotification(String? ref) => _notification(
          'n-pay',
          title: 'Electricity Bill Reminder',
          subtitle: 'Your bill of \u20B91200 is due in 6 days',
          referenceId: ref,
        );

    Finder payNow() => find.descendant(
          of: _card('n-pay'),
          matching: find.text('Pay Now'),
        );

    testWidgets('passes the matched reminder biller and consumer details',
        (tester) async {
      final harness = await _pump(
        tester,
        items: [reminderNotification('41')],
      );
      expect(payNow(), findsOneWidget);
      await tester.tap(payNow());
      await _settleNavigation(tester);
      expect(
        find.text('pay MSEDCL0001 Electricity 170010012345 2345 false true'),
        findsOneWidget,
      );
      expect(harness.selectedBillers.single.$1.billerId, 'MSEDCL0001');
      expect(harness.selectedBillers.single.$2, 'Electricity');
      expect(harness.home.requestedPages, [1]);
      expect(harness.history.requests, isEmpty);
      expect(harness.notifications.markReadIds, ['n-pay']);
    });

    testWidgets('searches later pages and passes credit card details',
        (tester) async {
      final harness = await _pump(
        tester,
        items: [reminderNotification('52')],
      );
      await tester.tap(_card('n-pay'));
      await _settleNavigation(tester);
      expect(
        find.text('pay HDFC0CC Credit Card 9876543210 4321 true true'),
        findsOneWidget,
      );
      expect(harness.home.requestedPages, [1, 2]);
    });

    testWidgets('mobile bills prefill the registered mobile', (tester) async {
      await _pump(tester, items: [reminderNotification('53')]);
      await tester.tap(payNow());
      await _settleNavigation(tester);
      expect(
        find.text('pay JIO0001 Mobile Postpaid 9876543210 2345 false true'),
        findsOneWidget,
      );
    });

    testWidgets('home reminder popup and notification build the same args',
        (tester) async {
      final args = billerDetailArgsForReminder(_reminder(41));
      expect(args.biller.billerId, 'MSEDCL0001');
      expect(args.paymentType, 'Electricity');
      expect(args.mobileNumber, '170010012345');
      expect(args.autoFetchBill, isTrue);
      expect(args.autoOpenPaymentSheet, isFalse);
    });

    for (final (label, ref) in [
      ('a missing reference id', null),
      ('an unknown reference id', '999'),
    ]) {
      testWidgets('$label stays on the list with a message', (tester) async {
        final harness = await _pump(
          tester,
          items: [reminderNotification(ref)],
        );
        await tester.tap(payNow());
        await _settleNavigation(tester);
        expect(find.byType(NotificationsScreen), findsOneWidget);
        expect(find.textContaining('pay '), findsNothing);
        expect(
          find.text('Bill details are not available for this notification.'),
          findsOneWidget,
        );
        expect(harness.selectedBillers, isEmpty);
        expect(harness.home.requestedPages, ref == null ? isEmpty : [1, 2]);
        await _drainSnackbar(tester);
      });
    }

    testWidgets('a reminder that cannot be paid now is not opened',
        (tester) async {
      await _pump(tester, items: [reminderNotification('54')]);
      await tester.tap(payNow());
      await _settleNavigation(tester);
      expect(find.textContaining('pay '), findsNothing);
      expect(find.text('This bill cannot be paid right now.'), findsOneWidget);
      await _drainSnackbar(tester);
    });

    testWidgets('API failure shows a retry message', (tester) async {
      final harness = await _pump(tester, items: [reminderNotification('41')]);
      harness.home.fail = true;
      await tester.tap(payNow());
      await _settleNavigation(tester);
      expect(find.textContaining('pay '), findsNothing);
      expect(
        find.text('Could not load bill details. Please try again.'),
        findsOneWidget,
      );
      await _drainSnackbar(tester);
      harness.home.fail = false;
      await tester.tap(payNow());
      await _settleNavigation(tester);
      expect(find.textContaining('pay MSEDCL0001'), findsOneWidget);
    });

    testWidgets('shows a loader and ignores taps while loading',
        (tester) async {
      final harness = await _pump(tester, items: [reminderNotification('41')]);
      final gate = harness.home.gate = Completer<void>();
      await tester.tap(payNow());
      await tester.pump();
      expect(find.byType(SpinKitCircle), findsOneWidget);
      await tester.tap(payNow(), warnIfMissed: false);
      await tester.tap(_card('n-pay'), warnIfMissed: false);
      await tester.pump();
      gate.complete();
      await _settleNavigation(tester);
      expect(find.textContaining('pay MSEDCL0001'), findsOneWidget);
      expect(harness.home.requestedPages, [1]);
      expect(harness.selectedBillers, hasLength(1));
      expect(find.byType(SpinKitCircle), findsNothing);
    });
  });

  group('View: loading and API failures', () {
    testWidgets('history API failure shows a retry message, no details',
        (tester) async {
      final harness = await _pump(tester);
      harness.history.fail = true;
      await tester.tap(_viewOf('n-f'));
      await _settleNavigation(tester);
      expect(find.byType(NotificationsScreen), findsOneWidget);
      expect(find.textContaining('detail '), findsNothing);
      expect(find.text('history list'), findsNothing);
      expect(
        find.text('Could not load transaction details. Please try again.'),
        findsOneWidget,
      );
      await _drainSnackbar(tester);
      harness.history.fail = false;
      await tester.tap(_viewOf('n-f'));
      await _settleNavigation(tester);
      expect(
        find.text(
          _detailText(RouteConstants.transactionDetailFailed, 'REF-F'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a single tap makes one lookup, with a loader', (tester) async {
      final harness = await _pump(tester);
      final gate = harness.history.gate = Completer<void>();
      await tester.tap(_viewOf('n-p'));
      await tester.pump();
      expect(find.byType(SpinKitCircle), findsOneWidget);
      await tester.tap(_card('n-p'), warnIfMissed: false);
      await tester.tap(_viewOf('n-s'), warnIfMissed: false);
      gate.complete();
      await _settleNavigation(tester);
      expect(
        find.text(
          _detailText(RouteConstants.transactionDetailPending, 'REF-P'),
        ),
        findsOneWidget,
      );
      expect(harness.history.requests.map((r) => r.page), [1, 2]);
    });
  });

  group('the whole card is tappable across shared sizes', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pump(tester, size: size);
        expect(tester.takeException(), isNull);
        final rect = tester.getRect(_card('n-f'));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));

        // Points inside the rounded card, away from the View label and the
        // close icon. The rect is re-read each time because a read card
        // moves from Unread to Updates.
        for (final pointIn in <Offset Function(Rect)>[
          (r) => r.centerLeft + const Offset(4, 0),
          (r) => r.bottomCenter + const Offset(0, -4),
          (r) => r.center,
        ]) {
          await tester.ensureVisible(_card('n-f'));
          await tester.pump();
          final point = pointIn(tester.getRect(_card('n-f')));
          await tester.tapAt(point);
          await _settleNavigation(tester);
          expect(
            find.text(
              _detailText(RouteConstants.transactionDetailFailed, 'REF-F'),
            ),
            findsOneWidget,
            reason: 'tap at $point',
          );
          navigatorKey.currentState!.pop();
          await _settleNavigation(tester);
          expect(_card('n-f'), findsOneWidget);
        }
      });
    }
  });

  group('NotificationTransactionResolver', () {
    test('searches around the notification date and stops on a match',
        () async {
      final repo = _FakeHistoryRepository(_historyPages);
      final entry = await NotificationTransactionResolver(repo).resolve(
        _notification('n', title: 'Payment Failed', referenceId: 'REF-F'),
      );
      expect(entry?.transactionId, 'txn-REF-F');
      expect(repo.requests.map((r) => r.page), [1, 2]);
      expect(repo.requests.first.fromDate, DateTime(2026, 9, 10, 12));
      expect(repo.requests.first.toDate, DateTime(2026, 10, 11, 12));
    });

    test('two different transactions with the same id resolve to nothing',
        () async {
      const clash = TransactionHistoryEntry(
        paymentStatus: 'FAILED',
        paymentType: 'Electricity',
        billerName: 'Other',
        maskedIdentifier: '',
        amount: '1',
        platformFees: '',
        totalAmountCharged: '1',
        customerMobile: '',
        iconUrl: '',
        pgTransactionId: 'REF-S',
        ecoinsTransactionId: '',
        transactionId: 'txn-other',
        bankReferenceId: '',
        referenceId: 'other',
        transactionTime: '',
        method: '',
        methodIcon: '',
        paymentMode: '',
        vpa: '',
        rrn: '',
      );
      final repo = _FakeHistoryRepository([
        [_entry('REF-S', 'SUCCESS'), clash],
      ]);
      final entry = await NotificationTransactionResolver(repo).resolve(
        _notification('n', title: 'Payment Successful', referenceId: 'REF-S'),
      );
      expect(entry, isNull);
    });

    test('API errors resolve to nothing instead of throwing', () async {
      final entry =
          await NotificationTransactionResolver(_ThrowingRepo()).resolve(
        _notification('n', title: 'Payment Failed', referenceId: 'REF-F'),
      );
      expect(entry, isNull);
    });
  });
}

class _ThrowingRepo extends TransactionHistoryRepository {
  _ThrowingRepo() : super(dio: Dio());

  @override
  Future<TransactionHistoryPage> fetchHistoryPage({
    int? days,
    int page = 1,
    int limit = 20,
    DateTime? fromDate,
    DateTime? toDate,
    int? lastYears,
    String? month,
    String? status,
    String? service,
    String? paymentType,
    double? minAmount,
    double? maxAmount,
    String? consumerId,
  }) async {
    throw DioException(requestOptions: RequestOptions(path: '/history'));
  }
}
