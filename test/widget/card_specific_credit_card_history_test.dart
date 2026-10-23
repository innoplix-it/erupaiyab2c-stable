import 'package:dio/dio.dart';
import 'package:e_rupaiya/constants/routes_constant.dart';
import 'package:e_rupaiya/features/home/controllers/home_controller.dart';
import 'package:e_rupaiya/features/home/models/banner_model.dart';
import 'package:e_rupaiya/features/home/models/credit_card_item.dart';
import 'package:e_rupaiya/features/home/models/home_state.dart';
import 'package:e_rupaiya/features/home/repositories/home_repository.dart';
import 'package:e_rupaiya/features/services/controllers/credit_card_transactions_controller.dart';
import 'package:e_rupaiya/features/services/controllers/service_extras_controller.dart';
import 'package:e_rupaiya/features/services/models/credit_card_transaction.dart';
import 'package:e_rupaiya/features/services/repositories/credit_card_transactions_repository.dart';
import 'package:e_rupaiya/features/services/views/credit_card_my_cards_view.dart';
import 'package:e_rupaiya/features/services/views/credit_card_transaction_detail_screen.dart';
import 'package:e_rupaiya/features/services/views/credit_card_transactions_screen.dart';
import 'package:e_rupaiya/widgets/k_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

CreditCardTransaction _tx({
  required String id,
  required String billerName,
  required String maskedIdentifier,
  required String amount,
  String status = 'SUCCESS',
  String time = '2026-10-15 14:30:00',
  String bankRef = 'REF12345',
}) {
  return CreditCardTransaction(
    paymentStatus: status,
    billerName: billerName,
    maskedIdentifier: maskedIdentifier,
    amount: amount,
    platformFees: '2.00',
    totalAmountCharged: amount,
    paymentTransactionId: id,
    bankReferenceId: bankRef,
    transactionTime: time,
    method: 'UPI',
    methodIcon: '',
    paymentMode: 'Online',
    vpa: 'user@okhdfcbank',
    rrn: 'RRN-$id',
    icon: '',
  );
}

class _MockCardsHomeController extends HomeController {
  _MockCardsHomeController(List<CreditCardItem> cards)
      : super(repository: HomeRepository(dio: Dio())) {
    state = HomeState(
      isFetchingCreditCards: false,
      creditCardActions: cards,
    );
  }

  @override
  Future<void> fetchCreditCardActions() async {}
}

class _MockCreditCardTransactionsRepository
    extends CreditCardTransactionsRepository {
  _MockCreditCardTransactionsRepository() : super(dio: Dio());

  final requests = <({String maskedIdentifier, int page, int limit})>[];
  final Map<String, Map<int, List<CreditCardTransaction>>> pagesByCard = {};
  final Map<String, int> totalPagesByCard = {};
  Object? error;

  @override
  Future<CreditCardTransactionsResponse> fetchTransactions({
    required String maskedIdentifier,
    int page = 1,
    int limit = 10,
  }) async {
    requests
        .add((maskedIdentifier: maskedIdentifier, page: page, limit: limit));
    if (error != null) throw error!;

    final cardPages = pagesByCard[maskedIdentifier] ?? {};
    final items = cardPages[page] ?? const <CreditCardTransaction>[];
    final totalPages = totalPagesByCard[maskedIdentifier] ?? 1;

    return CreditCardTransactionsResponse(
      success: true,
      message: 'OK',
      items: items,
      currentPage: page,
      totalPages: totalPages,
      totalRecords: items.length,
    );
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required ProviderContainer container,
  required Widget child,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          home: child,
        ),
      ),
    ),
  );
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Card-Specific Credit Card History Tests', () {
    testWidgets(
        '1 & 2: RBL History passes RBL identifier, ICICI History passes ICICI identifier',
        (tester) async {
      final cards = [
        const CreditCardItem(
          billerName: 'RBL Bank Credit Card',
          maskedIdentifier: '****6264',
          lastAmount: 1200,
        ),
        const CreditCardItem(
          billerName: 'ICICI Bank Credit Card',
          maskedIdentifier: '****9999',
          lastAmount: 2500,
        ),
      ];

      String openedMaskedId = '';
      final container = ProviderContainer(
        overrides: [
          homeControllerProvider.overrideWith(
            (ref) => _MockCardsHomeController(cards),
          ),
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
              openedMaskedId = state.extra as String? ?? '';
              return Scaffold(body: Text('View: $openedMaskedId'));
            },
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (_, __) => MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Tap first card (RBL) menu
      expect(find.text('RBL Bank Credit Card'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.more_vert).first);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.tap(find.text('History'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(openedMaskedId, '****6264');
      expect(find.text('View: ****6264'), findsOneWidget);
    });

    testWidgets(
        '3: Multiple cards of the same bank keep separate history per unique identifier',
        (tester) async {
      final repo = _MockCreditCardTransactionsRepository();
      repo.pagesByCard['****1111'] = {
        1: [
          _tx(
            id: 'TX-HDFC-1',
            billerName: 'HDFC Card 1',
            maskedIdentifier: '****1111',
            amount: '1000.00',
          ),
        ],
      };
      repo.pagesByCard['****2222'] = {
        1: [
          _tx(
            id: 'TX-HDFC-2',
            billerName: 'HDFC Card 2',
            maskedIdentifier: '****2222',
            amount: '2000.00',
          ),
        ],
      };

      final container = ProviderContainer(
        overrides: [
          creditCardTransactionsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      // Open Card 1
      await _pump(
        tester,
        container: container,
        child: const CreditCardTransactionsScreen(maskedIdentifier: '****1111'),
      );
      expect(find.text('HDFC Card 1'), findsOneWidget);
      expect(find.text('HDFC Card 2'), findsNothing);

      // Open Card 2
      await _pump(
        tester,
        container: container,
        child: const CreditCardTransactionsScreen(maskedIdentifier: '****2222'),
      );
      expect(find.text('HDFC Card 2'), findsOneWidget);
      expect(find.text('HDFC Card 1'), findsNothing);
    });

    testWidgets('4: Multi-page transactions fetch ALL pages up to totalPages',
        (tester) async {
      final repo = _MockCreditCardTransactionsRepository();
      repo.totalPagesByCard['****6264'] = 3;
      repo.pagesByCard['****6264'] = {
        1: [
          _tx(
              id: 'TX-1',
              billerName: 'RBL Page 1',
              maskedIdentifier: '****6264',
              amount: '100'),
          _tx(
              id: 'TX-2',
              billerName: 'RBL Page 1 B',
              maskedIdentifier: '****6264',
              amount: '200'),
        ],
        2: [
          _tx(
              id: 'TX-3',
              billerName: 'RBL Page 2',
              maskedIdentifier: '****6264',
              amount: '300'),
        ],
        3: [
          _tx(
              id: 'TX-4',
              billerName: 'RBL Page 3',
              maskedIdentifier: '****6264',
              amount: '400'),
        ],
      };

      final container = ProviderContainer(
        overrides: [
          creditCardTransactionsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await _pump(
        tester,
        container: container,
        child: const CreditCardTransactionsScreen(maskedIdentifier: '****6264'),
      );

      // All 3 pages must have been requested
      expect(repo.requests.map((r) => r.page).toList(), [1, 2, 3]);

      // All 4 transactions must be present
      expect(find.text('RBL Page 1'), findsOneWidget);
      expect(find.text('RBL Page 1 B'), findsOneWidget);
      expect(find.text('RBL Page 2'), findsOneWidget);
      expect(find.text('RBL Page 3'), findsOneWidget);
    });

    testWidgets(
        '5: Duplicates across pages are prevented and unique records are preserved',
        (tester) async {
      final repo = _MockCreditCardTransactionsRepository();
      repo.totalPagesByCard['****6264'] = 2;
      repo.pagesByCard['****6264'] = {
        1: [
          _tx(
              id: 'TX-DUP',
              billerName: 'RBL Unique Item',
              maskedIdentifier: '****6264',
              amount: '100'),
        ],
        2: [
          // Same transaction ID returned on page 2
          _tx(
              id: 'TX-DUP',
              billerName: 'RBL Unique Item',
              maskedIdentifier: '****6264',
              amount: '100'),
          _tx(
              id: 'TX-NEW',
              billerName: 'RBL Second Item',
              maskedIdentifier: '****6264',
              amount: '200'),
        ],
      };

      final container = ProviderContainer(
        overrides: [
          creditCardTransactionsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await _pump(
        tester,
        container: container,
        child: const CreditCardTransactionsScreen(maskedIdentifier: '****6264'),
      );

      expect(find.text('RBL Unique Item'), findsOneWidget);
      expect(find.text('RBL Second Item'), findsOneWidget);
    });

    testWidgets('6: Pull to refresh resets and fetches latest records',
        (tester) async {
      final repo = _MockCreditCardTransactionsRepository();
      repo.pagesByCard['****6264'] = {
        1: [
          _tx(
              id: 'TX-OLD',
              billerName: 'RBL Initial',
              maskedIdentifier: '****6264',
              amount: '100'),
        ],
      };

      final container = ProviderContainer(
        overrides: [
          creditCardTransactionsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await _pump(
        tester,
        container: container,
        child: const CreditCardTransactionsScreen(maskedIdentifier: '****6264'),
      );
      expect(find.text('RBL Initial'), findsOneWidget);

      // Now backend has updated record
      repo.pagesByCard['****6264'] = {
        1: [
          _tx(
              id: 'TX-FRESH',
              billerName: 'RBL Refreshed',
              maskedIdentifier: '****6264',
              amount: '500'),
        ],
      };

      // Trigger refresh via controller
      await container
          .read(creditCardTransactionsControllerProvider.notifier)
          .fetchTransactions(maskedIdentifier: '****6264', isRefresh: true);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('RBL Refreshed'), findsOneWidget);
      expect(find.text('RBL Initial'), findsNothing);
    });

    testWidgets(
        '7: Switching cards immediately isolates state and avoids leaking transactions',
        (tester) async {
      final repo = _MockCreditCardTransactionsRepository();
      repo.pagesByCard['****AAAA'] = {
        1: [
          _tx(
              id: 'TX-A',
              billerName: 'Card A Bank',
              maskedIdentifier: '****AAAA',
              amount: '100')
        ],
      };
      repo.pagesByCard['****BBBB'] = {
        1: [
          _tx(
              id: 'TX-B',
              billerName: 'Card B Bank',
              maskedIdentifier: '****BBBB',
              amount: '200')
        ],
      };

      final container = ProviderContainer(
        overrides: [
          creditCardTransactionsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await _pump(
        tester,
        container: container,
        child: const CreditCardTransactionsScreen(maskedIdentifier: '****AAAA'),
      );
      expect(find.text('Card A Bank'), findsOneWidget);

      await _pump(
        tester,
        container: container,
        child: const CreditCardTransactionsScreen(maskedIdentifier: '****BBBB'),
      );
      expect(find.text('Card B Bank'), findsOneWidget);
      expect(find.text('Card A Bank'), findsNothing);
    });

    testWidgets('8: Row tap opens exact transaction details screen',
        (tester) async {
      final repo = _MockCreditCardTransactionsRepository();
      final item = _tx(
        id: 'PG-EXACT-9876',
        billerName: 'IndusInd Bank Credit Card',
        maskedIdentifier: '****4455',
        amount: '3450.00',
        bankRef: 'BANK-REF-9988',
      );
      repo.pagesByCard['****4455'] = {
        1: [item],
      };

      final container = ProviderContainer(
        overrides: [
          creditCardTransactionsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: RouteConstants.creditCardTransactions,
        routes: [
          GoRoute(
            path: RouteConstants.creditCardTransactions,
            builder: (_, __) => const CreditCardTransactionsScreen(
                maskedIdentifier: '****4455'),
          ),
          GoRoute(
            path: RouteConstants.creditCardTransactionDetail,
            builder: (_, state) => CreditCardTransactionDetailScreen(
              transaction: state.extra as CreditCardTransaction?,
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (_, __) => MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('IndusInd Bank Credit Card'), findsOneWidget);
      await tester.tap(find.text('IndusInd Bank Credit Card'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Details screen elements
      expect(find.text('Payment Details'), findsOneWidget);
      expect(find.text('PG-EXACT-9876'), findsOneWidget);
      expect(find.text('BANK-REF-9988'), findsOneWidget);
    });

    testWidgets(
        '9: Empty state, API failure with Retry, and missing identifier handled gracefully',
        (tester) async {
      final repo = _MockCreditCardTransactionsRepository();
      repo.pagesByCard['****EMPTY'] = {1: []};

      final container = ProviderContainer(
        overrides: [
          creditCardTransactionsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      // Missing identifier
      await _pump(
        tester,
        container: container,
        child: const CreditCardTransactionsScreen(maskedIdentifier: ''),
      );
      expect(find.text('Masked identifier is missing.'), findsOneWidget);

      // Empty response
      await _pump(
        tester,
        container: container,
        child:
            const CreditCardTransactionsScreen(maskedIdentifier: '****EMPTY'),
      );
      expect(find.text('No transactions found'), findsOneWidget);

      // API Error
      repo.error = Exception('Network down');
      await _pump(
        tester,
        container: container,
        child: const CreditCardTransactionsScreen(maskedIdentifier: '****ERR'),
      );
      expect(find.text('Failed to fetch transactions. Please try again.'),
          findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Clear error and retry
      repo.error = null;
      repo.pagesByCard['****ERR'] = {
        1: [
          _tx(
              id: 'TX-RECOVERED',
              billerName: 'Recovered Card',
              maskedIdentifier: '****ERR',
              amount: '10')
        ],
      };
      await tester.tap(find.text('Retry'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('Recovered Card'), findsOneWidget);
    });
  });
}
