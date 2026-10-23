import 'dart:async';

import 'package:dio/dio.dart';
import 'package:e_rupaiya/constants/api_constants.dart';
import 'package:e_rupaiya/constants/routes_constant.dart';
import 'package:e_rupaiya/features/home/controllers/home_controller.dart';
import 'package:e_rupaiya/features/home/models/banner_model.dart';
import 'package:e_rupaiya/features/home/models/credit_card_item.dart';
import 'package:e_rupaiya/features/home/models/home_state.dart';
import 'package:e_rupaiya/features/home/repositories/home_repository.dart';
import 'package:e_rupaiya/features/profile/controllers/transaction_history_controller.dart';
import 'package:e_rupaiya/features/profile/models/transaction_history_entry.dart';
import 'package:e_rupaiya/features/profile/models/transaction_history_filter.dart';
import 'package:e_rupaiya/features/profile/models/transaction_history_page.dart';
import 'package:e_rupaiya/features/profile/repositories/transaction_history_repository.dart';
import 'package:e_rupaiya/features/profile/views/transaction_detail_screen.dart';
import 'package:e_rupaiya/features/profile/views/transaction_history_screen.dart';
import 'package:e_rupaiya/features/services/controllers/service_extras_controller.dart';
import 'package:e_rupaiya/features/services/views/credit_card_my_cards_view.dart';
import 'package:e_rupaiya/widgets/k_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _widths = <double>[320, 360, 390, 412, 440];

TransactionHistoryEntry _entry({
  required String id,
  required String paymentType,
  required String billerName,
  required String amount,
  required String status,
  String masked = '',
  String mobile = '9552529513',
  String last4 = '',
  String bankRef = '',
  String time = '2026-10-01 12:30:00',
}) {
  return TransactionHistoryEntry.fromJson({
    'payment_status': status,
    'payment_type': paymentType,
    'biller_name': billerName,
    'amount': amount,
    'total_amount_charged': amount,
    'platform_fees': '2.00',
    'masked_identifier': masked,
    'customer_mobile': mobile,
    'pg_transaction_id': id,
    'bank_reference_id': bankRef,
    'transaction_time': time,
    if (last4.isNotEmpty)
      'customer_params': [
        {
          'label': 'input',
          'value': [
            {
              'paramName': 'Registered Mobile Number',
              'paramValue': mobile,
            },
            {
              'paramName': 'Last 4 digits of Credit Card Number',
              'paramValue': last4,
            },
          ],
        },
      ],
  });
}

TransactionHistoryEntry _hdfc() => _entry(
      id: 'PG-HDFC-2656',
      paymentType: 'Credit Card',
      billerName: 'HDFC Bank Credit Card',
      amount: '1500.00',
      status: 'SUCCESS',
      masked: '****2656',
      last4: '2656',
      bankRef: 'BANK-HDFC-2656',
    );

TransactionHistoryEntry _icici() => _entry(
      id: 'PG-ICICI-9999',
      paymentType: 'Credit Card',
      billerName: 'ICICI Bank Credit Card',
      amount: '880.50',
      status: 'FAILED',
      masked: '****9999',
      last4: '9999',
      bankRef: 'BANK-ICICI-9999',
      time: '2026-10-02 09:15:00',
    );

List<TransactionHistoryEntry> _mixed() => [
      _hdfc(),
      _icici(),
      _entry(
        id: 'PG-ELEC-1',
        paymentType: 'Electricity',
        billerName: 'Adani Electricity Mumbai Limited',
        amount: '410.00',
        status: 'SUCCESS',
      ),
      _entry(
        id: 'PG-FASTAG-1',
        paymentType: 'FASTag',
        billerName: 'ICICI FASTag',
        amount: '200.00',
        status: 'PENDING',
      ),
      _entry(
        id: 'PG-MOBILE-1',
        paymentType: 'Mobile Recharge',
        billerName: 'Airtel Prepaid',
        amount: '99.00',
        status: 'SUCCESS',
      ),
    ];

class _RecordingRepository extends TransactionHistoryRepository {
  _RecordingRepository() : super(dio: Dio());

  final requests = <({int page, String? service, String? paymentType})>[];
  List<TransactionHistoryEntry> items = _mixed();
  Object? error;
  Completer<TransactionHistoryPage>? hold;
  int totalPages = 1;

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
    requests.add((page: page, service: service, paymentType: paymentType));
    final pending = hold;
    if (pending != null) return pending.future;
    if (error != null) throw error!;
    return TransactionHistoryPage(
      items: page == 1 ? items : const <TransactionHistoryEntry>[],
      currentPage: page,
      totalPages: totalPages,
      totalRecords: items.length,
      limit: limit,
    );
  }
}

class _IdleHomeController extends HomeController {
  _IdleHomeController() : super(repository: HomeRepository(dio: Dio())) {
    state = const HomeState(
      isFetchingCreditCards: false,
      creditCardActions: [
        CreditCardItem(
          billerName: 'HSBC Credit Card',
          maskedIdentifier: '***7355055961',
          lastAmount: 1,
        ),
      ],
    );
  }

  @override
  Future<void> fetchCreditCardActions() async {}
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Widget _app({
  required ProviderContainer container,
  required GoRouter router,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      fontSizeResolver: FontSizeResolvers.radius,
      builder: (_, __) => MaterialApp.router(routerConfig: router),
    ),
  );
}

void _size(WidgetTester tester, double width, {double height = 800}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  tester.view.padding = const FakeViewPadding(top: 24);
}

GoRouter _historyRouter({bool creditCardScoped = true}) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: RouteConstants.transactions,
    routes: [
      GoRoute(
        path: RouteConstants.creditCardMyCards,
        builder: (_, __) => const Scaffold(body: Text('My Cards')),
      ),
      GoRoute(
        path: RouteConstants.transactions,
        builder: (_, __) => TransactionHistoryScreen(
          initialCreditCardScoped: creditCardScoped,
          initialServiceFilter: creditCardScoped ? 'Credit Card' : null,
          initialPaymentTypeFilter: creditCardScoped ? 'Credit Card' : null,
        ),
      ),
      for (final path in [
        RouteConstants.transactionDetailSuccess,
        RouteConstants.transactionDetailFailed,
        RouteConstants.transactionDetailPending,
      ])
        GoRoute(
          path: path,
          builder: (_, state) => TransactionDetailScreen(
            entry: state.extra is TransactionHistoryEntry
                ? state.extra as TransactionHistoryEntry
                : null,
          ),
        ),
    ],
  );
}

Future<ProviderContainer> _pumpHistory(
  WidgetTester tester,
  _RecordingRepository repo, {
  double width = 390,
  double height = 800,
  bool creditCardScoped = true,
}) async {
  _size(tester, width, height: height);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);

  final container = ProviderContainer(
    overrides: [
      transactionHistoryRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(container.dispose);
  final router = _historyRouter(creditCardScoped: creditCardScoped);
  addTearDown(router.dispose);

  await tester.pumpWidget(_app(container: container, router: router));
  await _settle(tester);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('history API sends service and payment_type Credit Card', () async {
    final captured = <String, dynamic>{};
    String? path;
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            path = options.uri.path;
            captured.addAll(options.queryParameters);
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: const {'data': <dynamic>[]},
              ),
            );
          },
        ),
      );

    await TransactionHistoryRepository(dio: dio).fetchHistoryPage(
      page: 1,
      service: 'Credit Card',
      paymentType: 'Credit Card',
    );

    expect(
        path, Uri.parse(ApiConstants.prepaidTransactionHistoryEndpoint).path);
    expect(captured['service'], 'Credit Card');
    expect(captured['payment_type'], 'Credit Card');
    expect(captured.containsKey('service_no_full'), isFalse);
  });

  test(
      'applyFilter keeps Credit Card service and payment type on the next page',
      () async {
    final repo = _RecordingRepository();
    final controller = TransactionHistoryController(repository: repo);
    await controller.applyFilter(
      const TransactionHistoryFilter(
        service: 'Credit Card',
        paymentType: 'Credit Card',
      ),
    );
    expect(repo.requests, [
      (page: 1, service: 'Credit Card', paymentType: 'Credit Card'),
    ]);
    expect(controller.state.items, isNotEmpty);

    repo.items = [_hdfc()];
    repo.requests.clear();
    // Force another page without inventing a new request field.
    controller.state = controller.state.copyWith(
      currentPage: 1,
      totalPages: 2,
    );
    await controller.fetchNextPage();
    expect(repo.requests.single.service, 'Credit Card');
    expect(repo.requests.single.paymentType, 'Credit Card');
    expect(repo.requests.single.page, 2);
  });

  testWidgets('History opens credit-card transactions and hides other services',
      (tester) async {
    final repo = _RecordingRepository();
    await _pumpHistory(tester, repo);

    expect(repo.requests, hasLength(1));
    expect(repo.requests.single.service, 'Credit Card');
    expect(repo.requests.single.paymentType, 'Credit Card');
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Hdfc Bank Credit Card'), findsOneWidget);
    expect(find.text('Icici Bank Credit Card'), findsOneWidget);
    expect(find.text('₹ 1500.00'), findsOneWidget);
    expect(find.text('₹ 880.50'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('****2656'), findsOneWidget);
    expect(find.text('****9999'), findsOneWidget);
    expect(find.text('Adani Electricity Mumbai Limited'), findsNothing);
    expect(find.text('ICICI FASTag'), findsNothing);
    expect(find.text('Airtel Prepaid'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'bank name without Credit Card text stays visible and other services stay hidden',
      (tester) async {
    final repo = _RecordingRepository()
      ..totalPages = 2
      ..items = [
        _entry(
          id: 'PG-SBI-4242',
          paymentType: 'SBI Card',
          billerName: 'SBI Card',
          amount: '2500.00',
          status: 'SUCCESS',
          masked: '****4242',
          bankRef: 'BANK-SBI-4242',
        ),
        _entry(
          id: 'PG-AXIS-1111',
          paymentType: 'Axis Bank',
          billerName: 'Axis Bank',
          amount: '640.00',
          status: 'SUCCESS',
          masked: '****1111',
          last4: '1111',
          bankRef: 'BANK-AXIS-1111',
          time: '2026-10-03 11:00:00',
        ),
        _entry(
          id: 'PG-ELEC-1',
          paymentType: 'Electricity',
          billerName: 'Adani Electricity Mumbai Limited',
          amount: '410.00',
          status: 'SUCCESS',
        ),
        _entry(
          id: 'PG-FASTAG-1',
          paymentType: 'FASTag',
          billerName: 'ICICI FASTag',
          amount: '200.00',
          status: 'PENDING',
        ),
        _entry(
          id: 'PG-MOBILE-1',
          paymentType: 'Mobile Recharge',
          billerName: 'Airtel Prepaid',
          amount: '99.00',
          status: 'SUCCESS',
        ),
        _entry(
          id: 'PG-RENT-1',
          paymentType: 'House Rent',
          billerName: 'House Rent',
          amount: '12000.00',
          status: 'SUCCESS',
        ),
      ];
    await _pumpHistory(tester, repo);

    expect(repo.requests.first.service, 'Credit Card');
    expect(repo.requests.first.paymentType, 'Credit Card');
    expect(
      repo.requests.every(
        (request) =>
            request.service == 'Credit Card' &&
            request.paymentType == 'Credit Card',
      ),
      isTrue,
    );
    expect(find.text('No Transactions Found.'), findsNothing);
    expect(find.text('Sbi Card'), findsOneWidget);
    expect(find.text('Axis Bank'), findsOneWidget);
    expect(find.text('₹ 2500.00'), findsOneWidget);
    expect(find.text('₹ 640.00'), findsOneWidget);
    expect(find.text('Adani Electricity Mumbai Limited'), findsNothing);
    expect(find.text('ICICI FASTag'), findsNothing);
    expect(find.text('Airtel Prepaid'), findsNothing);
    expect(find.text('House Rent'), findsNothing);

    await tester.tap(find.text('Sbi Card'));
    await _settle(tester);

    expect(find.text('PG-SBI-4242'), findsOneWidget);
    expect(find.text('BANK-SBI-4242'), findsOneWidget);
    expect(find.text('PG-AXIS-1111'), findsNothing);
    expect(find.text('BANK-AXIS-1111'), findsNothing);
    expect(find.text('Adani Electricity Mumbai Limited'), findsNothing);
  });

  testWidgets('row tap opens that transaction and back keeps the list',
      (tester) async {
    final repo = _RecordingRepository();
    await _pumpHistory(tester, repo);
    final callsBeforeTap = repo.requests.length;

    await tester.tap(find.text('Icici Bank Credit Card'));
    await _settle(tester);

    expect(find.text('PG-ICICI-9999'), findsOneWidget);
    expect(find.text('BANK-ICICI-9999'), findsOneWidget);
    expect(find.text('**** **** **** 9999'), findsOneWidget);
    expect(find.text('PG-HDFC-2656'), findsNothing);
    expect(find.text('BANK-HDFC-2656'), findsNothing);
    expect(find.text('**** **** **** 2656'), findsNothing);
    expect(find.text('Adani Electricity Mumbai Limited'), findsNothing);
    expect(repo.requests, hasLength(callsBeforeTap));

    await tester.tap(find.byIcon(Icons.arrow_back));
    await _settle(tester);

    expect(find.text('Hdfc Bank Credit Card'), findsOneWidget);
    expect(find.text('Icici Bank Credit Card'), findsOneWidget);
    expect(find.text('Adani Electricity Mumbai Limited'), findsNothing);
    expect(repo.requests, hasLength(callsBeforeTap));
  });

  testWidgets('HDFC row opens HDFC details, not the other card',
      (tester) async {
    final repo = _RecordingRepository();
    await _pumpHistory(tester, repo);

    await tester.tap(find.text('Hdfc Bank Credit Card'));
    await _settle(tester);

    expect(find.text('PG-HDFC-2656'), findsOneWidget);
    expect(find.text('BANK-HDFC-2656'), findsOneWidget);
    expect(find.text('**** **** **** 2656'), findsOneWidget);
    expect(find.text('9552529513'), findsWidgets);
    expect(find.text('PG-ICICI-9999'), findsNothing);
    expect(find.text('**** **** **** 9999'), findsNothing);
  });

  testWidgets('loading then empty state', (tester) async {
    final loading = _RecordingRepository()
      ..hold = Completer<TransactionHistoryPage>();
    await _pumpHistory(tester, loading);
    expect(find.text('Loading transaction'), findsWidgets);
    expect(find.text('Hdfc Bank Credit Card'), findsNothing);

    loading.hold!.complete(
      const TransactionHistoryPage(
        items: [],
        currentPage: 1,
        totalPages: 1,
        totalRecords: 0,
        limit: 20,
      ),
    );
    await _settle(tester);
    expect(find.text('No Transactions Found.'), findsOneWidget);
    expect(find.text('HDFC Bank Credit Card'), findsNothing);
  });

  testWidgets('API error does not show another transaction', (tester) async {
    final failed = _RecordingRepository()..error = Exception('down');
    await _pumpHistory(tester, failed);
    expect(
      find.text('Failed to load transactions. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('HDFC Bank Credit Card'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('back from credit card history returns to My Cards',
      (tester) async {
    final repo = _RecordingRepository();
    await _pumpHistory(tester, repo);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await _settle(tester);

    expect(find.text('My Cards'), findsOneWidget);
    expect(find.text('Transactions'), findsNothing);
  });

  for (final width in _widths) {
    testWidgets('credit card history fits width $width', (tester) async {
      final repo = _RecordingRepository()
        ..items = [
          _entry(
            id: 'PG-LONG-REF-ABCDEFGHIJKLMNOPQRSTUVWXYZ-1234567890',
            paymentType: 'Credit Card',
            billerName: 'Very Long Credit Card Bank Name That Should Ellipsize',
            amount: '1234567.89',
            status: 'SUCCESS',
            masked: '****1234-VERY-LONG-MASKED-IDENTIFIER',
            last4: '1234',
            bankRef: 'BANK-REF-THAT-IS-ALSO-QUITE-LONG-998877',
          ),
        ];
      await _pumpHistory(tester, repo, width: width, height: 700);

      expect(
        find.text('Very Long Credit Card Bank Name That Should Ellipsize'),
        findsOneWidget,
      );
      expect(find.text('₹ 1234567.89'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(
        find.text('Very Long Credit Card Bank Name That Should Ellipsize'),
      );
      await _settle(tester);
      expect(
        find.text('PG-LONG-REF-ABCDEFGHIJKLMNOPQRSTUVWXYZ-1234567890'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('My Cards History opens the selected card transaction list',
      (tester) async {
    _size(tester, 390);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);

    String capturedMaskedId = '';
    final container = ProviderContainer(
      overrides: [
        homeControllerProvider.overrideWith((ref) => _IdleHomeController()),
        servicePageBannersProvider.overrideWith(
          (ref, slug) async => const <BannerModel>[],
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: RouteConstants.creditCardMyCards,
      routes: [
        GoRoute(
          path: RouteConstants.creditCardMyCards,
          builder: (_, __) => const CreditCardMyCardsView(),
        ),
        GoRoute(
          path: RouteConstants.creditCardTransactions,
          builder: (_, state) {
            capturedMaskedId = state.extra as String? ?? '';
            return Scaffold(
              body: Text('Card Transactions for $capturedMaskedId'),
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(container: container, router: router));
    await _settle(tester);

    expect(find.text('HSBC Credit Card'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.more_vert));
    await _settle(tester);
    await tester.tap(find.text('History'));
    await _settle(tester);

    expect(find.text('Card Transactions for ***7355055961'), findsOneWidget);
    expect(capturedMaskedId, '***7355055961');
  });
}
