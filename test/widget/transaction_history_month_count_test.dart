import 'package:dio/dio.dart';
import 'package:e_rupaiya/features/profile/controllers/transaction_history_controller.dart';
import 'package:e_rupaiya/features/profile/models/transaction_history_entry.dart';
import 'package:e_rupaiya/features/profile/models/transaction_history_filter.dart';
import 'package:e_rupaiya/features/profile/models/transaction_history_page.dart';
import 'package:e_rupaiya/features/profile/repositories/transaction_history_repository.dart';
import 'package:e_rupaiya/features/profile/views/transaction_filter_screen.dart';
import 'package:e_rupaiya/features/profile/views/transaction_history_screen.dart';
import 'package:e_rupaiya/widgets/app_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../helpers/responsive_test_sizes.dart';

TransactionHistoryEntry _txn(String id, String time) =>
    TransactionHistoryEntry.fromJson({
      'payment_status': 'SUCCESS',
      'payment_type': 'Electricity Bill',
      'biller_name': 'Adani Electricity Mumbai Limited',
      'amount': '100.00',
      'total_amount_charged': '100.00',
      'pg_transaction_id': id,
      'transaction_time': time,
    });

/// [count] rows in one month, newest first, ids `<prefix>-<n>`.
List<TransactionHistoryEntry> _month(
  String prefix,
  int year,
  int month,
  int count, {
  int start = 0,
}) =>
    List.generate(count, (i) {
      final n = start + i;
      final day = (28 - (n % 28)).toString().padLeft(2, '0');
      final mm = month.toString().padLeft(2, '0');
      return _txn('$prefix-$n', '$year-$mm-$day 10:00:00');
    });

/// Serves programmable pages shaped like the API (`data` + `pagination`).
class _PagedRepository extends TransactionHistoryRepository {
  _PagedRepository() : super(dio: Dio());

  Map<int, List<TransactionHistoryEntry>> pages = {};
  int? totalRecords;
  Set<int> failingPages = {};
  final requests = <({int page, String? month, String? status})>[];

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
    requests.add((page: page, month: month, status: status));
    if (failingPages.contains(page)) throw Exception('network down');
    final items = pages[page] ?? const <TransactionHistoryEntry>[];
    return TransactionHistoryPage(
      items: items,
      currentPage: page,
      totalPages: pages.isEmpty ? 1 : pages.length,
      totalRecords:
          totalRecords ?? pages.values.fold<int>(0, (sum, p) => sum + p.length),
      limit: limit,
    );
  }
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  _PagedRepository repo, {
  Size size = const Size(390, 844),
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = size * 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    overrides: [transactionHistoryRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const TransactionHistoryScreen(),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        fontSizeResolver: FontSizeResolvers.radius,
        builder: (_, __) => MaterialApp.router(routerConfig: router),
      ),
    ),
  );
  await _settle(tester);
  return container;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

TransactionHistoryController _controller(ProviderContainer c) =>
    c.read(transactionHistoryControllerProvider.notifier);

/// The header row for [month] shows exactly [label].
void _expectHeader(String month, String label) {
  final count = find.text(label);
  expect(count, findsOneWidget, reason: '$month should show "$label"');
  final row = find.ancestor(of: count, matching: find.byType(Row)).first;
  expect(
    find.descendant(of: row, matching: find.textContaining(month)),
    findsOneWidget,
  );
}

/// The transaction list's scrollable (the search field has its own).
Finder _list() => find
    .descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(Scrollable),
    )
    .first;

Finder _anyCount() => find.byWidgetPredicate(
      (w) => w is Text && RegExp(r'^\d+ Transactions?$').hasMatch(w.data ?? ''),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets(
      'a one-month request uses the API total_records, not the loaded rows',
      (tester) async {
    final repo = _PagedRepository()..pages = {1: _month('oct', 2026, 10, 20)};
    final container = await _pump(tester, repo);

    repo
      ..pages = {
        1: _month('oct', 2026, 10, 20),
        2: _month('oct', 2026, 10, 20, start: 20),
        3: _month('oct', 2026, 10, 17, start: 40),
      }
      ..totalRecords = 57
      ..requests.clear();
    await _controller(container)
        .applyFilter(const TransactionHistoryFilter(month: '2026-10'));
    await _settle(tester);

    _expectHeader('October', '57 Transactions');
    expect(find.text('20 Transactions'), findsNothing);
    // The total is authoritative, so no extra pages are pulled for it.
    expect(repo.requests.map((r) => r.page), [1]);
    expect(repo.requests.single.month, '2026-10');
  });

  testWidgets(
      'records only: the first month is completed across pages before its '
      'count is shown', (tester) async {
    final repo = _PagedRepository()
      ..pages = {
        1: _month('oct', 2026, 10, 20),
        2: [
          ..._month('oct', 2026, 10, 5, start: 20),
          ..._month('sep', 2026, 9, 15)
        ],
        3: [
          ..._month('sep', 2026, 9, 3, start: 15),
          ..._month('aug', 2026, 8, 2)
        ],
      };
    final container = await _pump(tester, repo);

    expect(repo.requests.map((r) => r.page).take(2), [1, 2]);
    _expectHeader('October', '25 Transactions');
    expect(find.text('20 Transactions'), findsNothing);
    // September may continue on page 3, so it is not shown with 15 yet.
    expect(find.text('15 Transactions'), findsNothing);
    expect(find.textContaining('September'), findsNothing);

    await _controller(container).fetchNextPage();
    await _settle(tester);
    expect(
        container.read(transactionHistoryControllerProvider).hasMore, isFalse);
    final list = _list();
    await tester.scrollUntilVisible(find.text('18 Transactions'), 300,
        scrollable: list);
    _expectHeader('September', '18 Transactions');
    await tester.scrollUntilVisible(find.text('2 Transactions'), 300,
        scrollable: list);
    _expectHeader('August', '2 Transactions');
  });

  testWidgets('rows repeated across pages are counted once', (tester) async {
    final repo = _PagedRepository()
      ..pages = {
        1: _month('oct', 2026, 10, 20),
        // Window shifted: the last 3 October rows of page 1 come back.
        2: [
          ..._month('oct', 2026, 10, 3, start: 17),
          ..._month('oct', 2026, 10, 4, start: 20),
          ..._month('sep', 2026, 9, 2),
        ],
      };
    await _pump(tester, repo);

    _expectHeader('October', '24 Transactions');
    expect(find.text('27 Transactions'), findsNothing);
    final list = _list();
    await tester.scrollUntilVisible(find.text('2 Transactions'), 300,
        scrollable: list);
    _expectHeader('September', '2 Transactions');
  });

  testWidgets('a single page groups and counts each month', (tester) async {
    final repo = _PagedRepository()
      ..pages = {
        1: [
          ..._month('oct', 2026, 10, 2),
          ..._month('sep', 2026, 9, 1),
          ..._month('aug', 2026, 8, 3),
        ],
      };
    await _pump(tester, repo);

    _expectHeader('October', '2 Transactions');
    _expectHeader('September', '1 Transaction');
    _expectHeader('August', '3 Transactions');
  });

  testWidgets('month boundaries: last second vs first second', (tester) async {
    final repo = _PagedRepository()
      ..pages = {
        1: [
          _txn('a', '2026-10-01 00:00:00'),
          _txn('b', '2026-09-30 23:59:59'),
          _txn('c', '2026-09-01 00:00:00'),
        ],
      };
    await _pump(tester, repo);
    _expectHeader('October', '1 Transaction');
    _expectHeader('September', '2 Transactions');
  });

  testWidgets('no transactions shows the empty state and no count',
      (tester) async {
    final repo = _PagedRepository()..pages = {1: const []};
    await _pump(tester, repo);
    expect(find.text('No Transactions Found.'), findsOneWidget);
    expect(_anyCount(), findsNothing);
  });

  testWidgets('a failed first load shows the error with Retry, no count',
      (tester) async {
    final repo = _PagedRepository()
      ..pages = {1: _month('oct', 2026, 10, 3)}
      ..failingPages = {1};
    await _pump(tester, repo);

    expect(find.text('Failed to load transactions. Please try again.'),
        findsOneWidget);
    expect(find.text('No Transactions Found.'), findsNothing);
    expect(_anyCount(), findsNothing);

    repo.failingPages = {};
    await tester.tap(find.text('Retry'));
    await _settle(tester);
    _expectHeader('October', '3 Transactions');
  });

  testWidgets(
      'a failure while completing a month shows Retry, never a partial count',
      (tester) async {
    final repo = _PagedRepository()
      ..pages = {
        1: _month('oct', 2026, 10, 20),
        2: [
          ..._month('oct', 2026, 10, 6, start: 20),
          ..._month('sep', 2026, 9, 1)
        ],
      }
      ..failingPages = {2};
    await _pump(tester, repo);

    expect(find.text('Failed to load more transactions.'), findsOneWidget);
    expect(_anyCount(), findsNothing);
    // The auto-load stops on failure instead of retrying in a loop.
    expect(repo.requests.where((r) => r.page == 2), hasLength(1));

    repo.failingPages = {};
    await tester.tap(find.text('Retry'));
    await _settle(tester);
    _expectHeader('October', '26 Transactions');
  });

  testWidgets('refresh and filters replace the counts instead of adding up',
      (tester) async {
    final repo = _PagedRepository()
      ..pages = {
        1: [..._month('oct', 2026, 10, 4), ..._month('sep', 2026, 9, 2)],
      };
    final container = await _pump(tester, repo);
    _expectHeader('October', '4 Transactions');

    await _controller(container).fetchHistory();
    await _settle(tester);
    _expectHeader('October', '4 Transactions');
    _expectHeader('September', '2 Transactions');

    repo.pages = {1: _month('oct', 2026, 10, 1)};
    await _controller(container)
        .applyFilter(const TransactionHistoryFilter(status: 'FAILED'));
    await _settle(tester);
    expect(repo.requests.last.status, 'FAILED');
    _expectHeader('October', '1 Transaction');
    expect(find.text('4 Transactions'), findsNothing);
    expect(find.textContaining('September'), findsNothing);
  });

  testWidgets(
      'a device-side service filter counts records, never the API total',
      (tester) async {
    final repo = _PagedRepository()..pages = {1: _month('oct', 2026, 10, 1)};
    final container = await _pump(tester, repo);

    repo
      ..pages = {
        1: _month('oct', 2026, 10, 20),
        2: _month('oct', 2026, 10, 5, start: 20),
      }
      ..totalRecords = 57;
    await _controller(container).applyFilter(
      const TransactionHistoryFilter(month: '2026-10', service: 'Electricity'),
    );
    await _settle(tester);

    _expectHeader('October', '25 Transactions');
    expect(find.text('57 Transactions'), findsNothing);
  });

  testWidgets('every payment type uses the School Fee card typography',
      (tester) async {
    const types = [
      'School Fee',
      'House Rent',
      'Shop Rent',
      'Education Fee',
      'Electricity Bill',
    ];
    final repo = _PagedRepository()
      ..pages = {
        1: [
          for (var i = 0; i < types.length; i++)
            TransactionHistoryEntry.fromJson({
              'payment_status': 'SUCCESS',
              'payment_type': types[i],
              'amount': '${i + 1}00.00',
              'total_amount_charged': '${i + 1}00.00',
              'pg_transaction_id': 'card-$i',
              'recipient_name': 'Recipient $i',
              'transaction_time': '2026-10-${20 - i} 15:32:00',
            }),
        ],
      };
    await _pump(tester, repo, size: const Size(390, 1400));

    final tiles = find.ancestor(
      of: find.byKey(const ValueKey('transaction-recipient-name')),
      matching: find.byType(InkWell),
    );
    expect(tiles, findsNWidgets(types.length));

    TextStyle styleOf(Finder tile, bool Function(Text) test) => tester
        .widgetList<Text>(
            find.descendant(of: tile, matching: find.byType(Text)))
        .firstWhere(test)
        .style!;

    List<TextStyle> stylesFor(int i) {
      final tile = tiles.at(i);
      return [
        // Payment type is the first line; display names may be normalised.
        styleOf(tile, (_) => true),
        styleOf(
            tile, (t) => t.key == const ValueKey('transaction-recipient-name')),
        styleOf(tile, (t) => RegExp(r'\d:\d\d ?[AP]M').hasMatch(t.data ?? '')),
        styleOf(tile, (t) => (t.data ?? '').startsWith('₹')),
      ];
    }

    final reference = stylesFor(0);
    for (final style in reference) {
      expect(style.fontFamily, contains('PlusJakartaSans'));
    }
    for (var i = 1; i < types.length; i++) {
      final styles = stylesFor(i);
      for (var s = 0; s < styles.length; s++) {
        expect(styles[s].fontFamily, reference[s].fontFamily, reason: types[i]);
        expect(styles[s].fontSize, reference[s].fontSize, reason: types[i]);
        expect(styles[s].fontWeight, reference[s].fontWeight, reason: types[i]);
        expect(styles[s].color, reference[s].color, reason: types[i]);
      }
    }
  });

  group('larger payment type and amount fit at shared sizes', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        final repo = _PagedRepository()
          ..pages = {
            1: [
              TransactionHistoryEntry.fromJson({
                'payment_status': 'FAILED',
                'payment_type': 'Maharashtra State Electricity Distribution',
                'biller_name': 'MSEDCL',
                'amount': '1234567.00',
                'total_amount_charged': '1234567.00',
                'pg_transaction_id': 'long-1',
                'service_no_full': '170019239876',
                'transaction_time': '2026-10-12 15:32:00',
              }),
            ],
          };
        await _pump(tester, repo, size: size);
        expect(tester.takeException(), isNull);
        final amount = tester.getRect(find.text('₹ 1234567.00'));
        expect(amount.right, lessThanOrEqualTo(size.width));
      });
    }
  });

  testWidgets('search narrows the count to the matching rows', (tester) async {
    final repo = _PagedRepository()
      ..pages = {
        1: [
          ..._month('oct', 2026, 10, 3),
          TransactionHistoryEntry.fromJson({
            'payment_status': 'SUCCESS',
            'payment_type': 'Mobile Prepaid',
            'biller_name': 'Jio',
            'amount': '199.00',
            'total_amount_charged': '199.00',
            'pg_transaction_id': 'jio-1',
            'transaction_time': '2026-10-02 09:00:00',
          }),
        ],
      }
      ..totalRecords = 9;
    final container = await _pump(tester, repo);
    await _controller(container)
        .applyFilter(const TransactionHistoryFilter(month: '2026-10'));
    await _settle(tester);
    _expectHeader('October', '9 Transactions');

    await tester.enterText(find.byType(EditableText), 'jio');
    await _settle(tester);
    // The API total covers all of October, so it yields to the matches.
    _expectHeader('October', '1 Transaction');
  });

  group('recipient_name parsing', () {
    Map<String, dynamic> base([Map<String, dynamic> extra = const {}]) => {
          'payment_status': 'SUCCESS',
          'payment_type': 'House Rent',
          'amount': '5000.00',
          'pg_transaction_id': 'rent-1',
          'transaction_time': '2026-10-12 15:32:00',
          ...extra,
        };

    test('reads the top-level field', () {
      final entry = TransactionHistoryEntry.fromJson(
        base({'recipient_name': '  Asha Patil '}),
      );
      expect(entry.recipientName, 'Asha Patil');
    });

    test('falls back to the order data map', () {
      final entry = TransactionHistoryEntry.fromJson(
        base({
          'data': {'recipient_name': 'Ravi Kumar'},
        }),
      );
      expect(entry.recipientName, 'Ravi Kumar');
    });

    test('falls back to the Recipient Name customer param', () {
      final entry = TransactionHistoryEntry.fromJson(
        base({
          'customer_params': [
            {'label': 'Recipient Name', 'value': 'Meena Shah'},
          ],
        }),
      );
      expect(entry.recipientName, 'Meena Shah');
    });

    test('missing, empty or "null" values stay null', () {
      expect(TransactionHistoryEntry.fromJson(base()).recipientName, isNull);
      expect(
        TransactionHistoryEntry.fromJson(base({'recipient_name': '  '}))
            .recipientName,
        isNull,
      );
      expect(
        TransactionHistoryEntry.fromJson(
          base({
            'recipient_name': 'null',
            'data': {'recipient_name': null},
          }),
        ).recipientName,
        isNull,
      );
    });
  });

  testWidgets(
      'Electricity and Mobile number lines match the School Fee recipient',
      (tester) async {
    Map<String, dynamic> row(
            String type, String id, String day, Map<String, dynamic> extra) =>
        {
          'payment_status': 'SUCCESS',
          'payment_type': type,
          'amount': '100.00',
          'total_amount_charged': '100.00',
          'pg_transaction_id': id,
          'transaction_time': '2026-10-$day 10:00:00',
          ...extra,
        };
    final repo = _PagedRepository()
      ..pages = {
        1: [
          TransactionHistoryEntry.fromJson(
            row('School Fee', 'school-1', '20', {'recipient_name': 'Asha'}),
          ),
          TransactionHistoryEntry.fromJson(
            row('Electricity Bill', 'elec-1', '19',
                {'service_no_full': '170019239876'}),
          ),
          TransactionHistoryEntry.fromJson(
            row('Mobile Prepaid', 'mob-1', '18',
                {'service_no_full': '9876543210'}),
          ),
        ],
      };
    await _pump(tester, repo, size: const Size(390, 1200));

    final reference = tester
        .widget<Text>(find.byKey(const ValueKey('transaction-recipient-name')))
        .style!;
    final numbers = tester
        .widgetList<Text>(
            find.byKey(const ValueKey('transaction-consumer-number')))
        .toList();
    expect(numbers.map((t) => t.data),
        containsAll(['170019239876', '9876543210']));
    for (final text in numbers) {
      final style = text.style!;
      expect(style.fontFamily, reference.fontFamily, reason: text.data);
      expect(style.fontSize, reference.fontSize, reason: text.data);
      expect(style.fontWeight, reference.fontWeight, reason: text.data);
      expect(style.color, reference.color, reason: text.data);
    }
  });

  testWidgets('the card shows the recipient only when the API sends one',
      (tester) async {
    final repo = _PagedRepository()
      ..pages = {
        1: [
          TransactionHistoryEntry.fromJson({
            'payment_status': 'SUCCESS',
            'payment_type': 'House Rent',
            'amount': '5000.00',
            'total_amount_charged': '5000.00',
            'pg_transaction_id': 'rent-1',
            'recipient_name': 'Asha Patil',
            'transaction_time': '2026-10-12 15:32:00',
          }),
          _txn('elec-1', '2026-10-11 10:00:00'),
        ],
      };
    await _pump(tester, repo);

    final recipient = find.byKey(const ValueKey('transaction-recipient-name'));
    expect(recipient, findsOneWidget);
    final text = tester.widget<Text>(recipient);
    expect(text.data, 'Asha Patil');
    expect(text.style!.fontFamily, contains('PlusJakartaSans'));
    expect(text.style!.fontWeight, FontWeight.w600);
    expect(text.style!.fontSize, moreOrLessEquals(12.sp));

    final rentTile =
        find.ancestor(of: recipient, matching: find.byType(InkWell)).first;
    expect(
      find.descendant(of: rentTile, matching: find.text('House Rent')),
      findsOneWidget,
    );
  });

  testWidgets('month title and count label are 12.sp w600', (tester) async {
    final repo = _PagedRepository()..pages = {1: _month('oct', 2026, 10, 2)};
    await _pump(tester, repo);

    final count = tester.widget<Text>(find.text('2 Transactions'));
    final row = find.ancestor(
        of: find.text('2 Transactions'), matching: find.byType(Row));
    final title = tester.widget<Text>(
      find
          .descendant(of: row.first, matching: find.textContaining('October'))
          .first,
    );
    for (final text in [title, count]) {
      expect(text.style!.fontSize, moreOrLessEquals(12.sp), reason: text.data);
      expect(text.style!.fontWeight, FontWeight.w600, reason: text.data);
      expect(text.style!.fontFamily, contains('PlusJakartaSans'));
    }
  });

  testWidgets('scrolled cards stop the same gap below the search bar as above',
      (tester) async {
    final repo = _PagedRepository()..pages = {1: _month('oct', 2026, 10, 12)};
    await _pump(tester, repo);

    final gap = AppSearchBar.verticalInset;
    final searchRow = find
        .ancestor(of: find.byType(AppSearchBar), matching: find.byType(Padding))
        .first;
    final row = tester.getRect(find.byType(AppSearchBar));
    final padded = tester.getRect(searchRow);
    expect(row.top - padded.top, moreOrLessEquals(gap));
    expect(padded.bottom - row.bottom, moreOrLessEquals(gap));

    final listTop = tester.getRect(_list()).top;
    expect(listTop - row.bottom, moreOrLessEquals(gap));

    await tester.drag(_list(), const Offset(0, -300));
    await _settle(tester);
    // Gap remains: list viewport top is unchanged while content scrolls.
    expect(tester.getRect(_list()).top, moreOrLessEquals(listTop));
  });

  testWidgets('first month header sits closer to the search bar than others',
      (tester) async {
    final repo = _PagedRepository()
      ..pages = {
        1: [..._month('oct', 2026, 10, 1), ..._month('sep', 2026, 9, 1)],
      };
    await _pump(tester, repo);

    double figma(double px) => (px * 360 / 440).w;
    final searchBottom = tester.getRect(find.byType(AppSearchBar)).bottom;
    final october = tester.getRect(find.textContaining('October').first);
    expect(october.top - searchBottom, moreOrLessEquals(figma(16) + figma(4)));

    final septemberTitle = find.textContaining('September').first;
    final octoberCard = find
        .ancestor(
            of: find.text('₹ 100.00').first, matching: find.byType(InkWell))
        .first;
    expect(
      tester.getRect(septemberTitle).top - tester.getRect(octoberCard).bottom,
      moreOrLessEquals(figma(15)),
    );
  });

  testWidgets('the filter icon sits outside the search field and opens filters',
      (tester) async {
    final repo = _PagedRepository()..pages = {1: _month('oct', 2026, 10, 1)};
    await _pump(tester, repo);

    final search = find.byType(AppSearchBar);
    final filter = find.byKey(const ValueKey('transaction-filter-button'));
    expect(search, findsOneWidget);
    expect(filter, findsOneWidget);
    expect(
      find.descendant(of: search, matching: filter),
      findsNothing,
    );
    expect(
      tester.getRect(filter).left,
      greaterThanOrEqualTo(tester.getRect(search).right),
    );

    await tester.tap(filter);
    await _settle(tester);
    expect(find.byType(TransactionFilterScreen), findsOneWidget);
  });

  group('recipient, header and search row fit at shared sizes', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        final repo = _PagedRepository()
          ..pages = {
            1: [
              TransactionHistoryEntry.fromJson({
                'payment_status': 'SUCCESS',
                'payment_type': 'Shop Rent',
                'amount': '125000.00',
                'total_amount_charged': '125000.00',
                'pg_transaction_id': 'rent-long',
                'recipient_name':
                    'Shree Venkateshwara Commercial Properties Private Limited',
                'transaction_time': '2026-10-12 15:32:00',
              }),
            ],
          };
        await _pump(tester, repo, size: size);
        expect(tester.takeException(), isNull);
        final filter = tester.getRect(
          find.byKey(const ValueKey('transaction-filter-button')),
        );
        expect(filter.right, lessThanOrEqualTo(size.width));
        expect(
          find.byKey(const ValueKey('transaction-recipient-name')),
          findsOneWidget,
        );
      });
    }
  });
}
