import 'dart:async';

import 'package:dio/dio.dart';
import 'package:e_rupaiya/features/mobile_prepaid/models/latest_transaction.dart';
import 'package:e_rupaiya/features/services/controllers/biller_listing_controller.dart';
import 'package:e_rupaiya/features/services/controllers/service_extras_controller.dart';
import 'package:e_rupaiya/features/services/models/biller_model.dart';
import 'package:e_rupaiya/features/services/repositories/biller_repository.dart';
import 'package:e_rupaiya/features/services/views/biller_listing_view.dart';
import 'package:e_rupaiya/widgets/app_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../helpers/responsive_test_sizes.dart';

/// Nine portrait sizes from [responsiveTestScreenSizes] (no duplicate matrix).
final _nineElectricitySizes = responsiveTestScreenSizes.where((s) {
  const allowed = <String>{
    '320x568',
    '360x640',
    '360x690',
    '360x800',
    '375x812',
    '390x844',
    '412x915',
    '440x956',
    '458x1024',
  };
  return allowed.contains('${s.width.toInt()}x${s.height.toInt()}');
}).toList(growable: false);

const _allBillers = [
  Biller(
    billerId: '1',
    billerName: 'Maharashtra State Electricity Distribution Co. Ltd',
  ),
  Biller(billerId: '2', billerName: 'Adani Electricity Mumbai Limited'),
  Biller(billerId: '3', billerName: 'B.E.S.T Mumbai'),
];

const _saved = LatestTransaction(
  id: '1',
  paymentType: 'Electricity',
  billerName: 'MSEDCL Mahavitaran Maharashtra',
  amount: 450,
  status: 'success',
  transactionRef: 'ref',
  serviceNo: '123456789012',
  icon: '',
  customerName: 'Rajiv Sanjiv Kumar',
  autoPayActive: true,
  createdAt: '2026-09-05T10:00:00Z',
);

/// Repository that can delay responses and filter by [search], reproducing
/// the loading/empty transitions that previously unmounted the search bar.
class _ControllableBillerRepository extends BillerRepository {
  _ControllableBillerRepository({this.delay = Duration.zero})
      : super(dio: Dio());

  Duration delay;
  int fetchCount = 0;
  final List<Completer<void>> _gates = [];

  /// When non-null, the next [fetchBillers] waits until the completer is
  /// completed (in addition to [delay]).
  Completer<void>? gateNextFetch() {
    final c = Completer<void>();
    _gates.add(c);
    return c;
  }

  @override
  Future<BillerListResponse> fetchBillers({
    required String categoryName,
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    fetchCount++;
    if (_gates.isNotEmpty) {
      final gate = _gates.removeAt(0);
      await gate.future;
    }
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    final q = (search ?? '').trim().toLowerCase();
    final billers = q.isEmpty
        ? _allBillers
        : _allBillers
            .where((b) => b.billerName.toLowerCase().contains(q))
            .toList(growable: false);
    return BillerListResponse(categoryName: categoryName, billers: billers);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpElectricity(
    WidgetTester tester, {
    required _ControllableBillerRepository repository,
    Size size = const Size(390, 844),
  }) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = size * 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          billerRepositoryProvider.overrideWithValue(repository),
          serviceLatestTransactionsProvider.overrideWith(
            (ref, service) async => const [_saved],
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          splitScreenMode: true,
          fontSizeResolver: FontSizeResolvers.radius,
          builder: (context, _) => const MaterialApp(
            home: BillerListingView(categoryName: 'Electricity'),
          ),
        ),
      ),
    );
    // Initial fetch + first frames.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  void expectSearchBarVisible(WidgetTester tester, {required Size size}) {
    final bar = find.byType(AppSearchBar);
    expect(bar, findsOneWidget, reason: 'search bar must stay in the tree');
    expect(find.text('Search by billers'), findsOneWidget);

    final rect = tester.getRect(bar);
    expect(rect.height, greaterThan(0));
    expect(rect.width, greaterThan(0));
    // Fully inside the viewport (not scrolled away / clipped to zero).
    expect(rect.top, greaterThanOrEqualTo(-0.5));
    expect(rect.bottom, lessThanOrEqualTo(size.height + 0.5));
    expect(rect.left, greaterThanOrEqualTo(-0.5));
    expect(rect.right, lessThanOrEqualTo(size.width + 0.5));
    // Hit-testable: not covered by an opaque overlay that steals taps.
    expect(bar.hitTestable(), findsOneWidget);
  }

  Finder searchField() => find.descendant(
        of: find.byType(AppSearchBar),
        matching: find.byType(TextField),
      );

  bool searchHasFocus(WidgetTester tester) {
    final field = tester.widget<TextField>(searchField());
    return field.focusNode?.hasFocus ?? false;
  }

  group('Electricity search bar stays visible', () {
    testWidgets('1. visible before typing', (tester) async {
      const size = Size(390, 844);
      final repo = _ControllableBillerRepository();
      await pumpElectricity(tester, repository: repo, size: size);
      expectSearchBarVisible(tester, size: size);
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. remains visible after the first character', (tester) async {
      const size = Size(390, 844);
      final repo = _ControllableBillerRepository(
        delay: const Duration(milliseconds: 400),
      );
      await pumpElectricity(tester, repository: repo, size: size);
      expectSearchBarVisible(tester, size: size);

      await tester.tap(searchField());
      await tester.pump();
      await tester.enterText(searchField(), 'a');
      await tester.pump();
      expectSearchBarVisible(tester, size: size);
      expect(tester.widget<TextField>(searchField()).controller!.text, 'a');

      // Past debounce (300ms) into the in-flight fetch — previously this
      // cleared billers and swapped in SliverFillRemaining, hiding the bar.
      await tester.pump(const Duration(milliseconds: 350));
      expectSearchBarVisible(tester, size: size);
      expect(tester.widget<TextField>(searchField()).controller!.text, 'a');
      expect(searchHasFocus(tester), isTrue);

      await tester.pump(const Duration(milliseconds: 500));
      expectSearchBarVisible(tester, size: size);
      expect(tester.takeException(), isNull);
    });

    testWidgets('3. remains visible while entering multiple characters',
        (tester) async {
      const size = Size(390, 844);
      final repo = _ControllableBillerRepository(
        delay: const Duration(milliseconds: 200),
      );
      await pumpElectricity(tester, repository: repo, size: size);

      await tester.tap(searchField());
      await tester.pump();
      for (final chunk in ['a', 'ad', 'ada', 'adan', 'adani']) {
        await tester.enterText(searchField(), chunk);
        await tester.pump();
        expectSearchBarVisible(tester, size: size);
        expect(
          tester.widget<TextField>(searchField()).controller!.text,
          chunk,
        );
        await tester.pump(const Duration(milliseconds: 100));
        expectSearchBarVisible(tester, size: size);
      }
      await tester.pump(const Duration(milliseconds: 500));
      expectSearchBarVisible(tester, size: size);
      expect(find.textContaining('Adani'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('4. stays visible when results are empty', (tester) async {
      const size = Size(390, 844);
      final repo = _ControllableBillerRepository();
      await pumpElectricity(tester, repository: repo, size: size);

      await tester.enterText(searchField(), 'zzzz-no-match');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expectSearchBarVisible(tester, size: size);
      expect(find.text('No providers found'), findsOneWidget);
      expect(
        tester.widget<TextField>(searchField()).controller!.text,
        'zzzz-no-match',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '5. clearing the query restores results without removing search',
        (tester) async {
      const size = Size(390, 844);
      final repo = _ControllableBillerRepository();
      await pumpElectricity(tester, repository: repo, size: size);

      await tester.enterText(searchField(), 'adani');
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('Adani'), findsWidgets);

      await tester.enterText(searchField(), '');
      await tester.pump();
      expectSearchBarVisible(tester, size: size);
      await tester.pump(const Duration(milliseconds: 400));
      expectSearchBarVisible(tester, size: size);
      expect(find.text(_allBillers.first.billerName), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '6. loading / provider updates do not remove search or lose query',
        (tester) async {
      const size = Size(390, 844);
      final repo = _ControllableBillerRepository();
      await pumpElectricity(tester, repository: repo, size: size);

      final gate = repo.gateNextFetch();
      await tester.tap(searchField());
      await tester.pump();
      await tester.enterText(searchField(), 'adani');
      await tester.pump(const Duration(milliseconds: 350));

      // Debounced fetch is blocked on the gate — still loading.
      expectSearchBarVisible(tester, size: size);
      expect(tester.widget<TextField>(searchField()).controller!.text, 'adani');
      expect(searchHasFocus(tester), isTrue);

      gate!.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expectSearchBarVisible(tester, size: size);
      expect(tester.widget<TextField>(searchField()).controller!.text, 'adani');
      expect(find.textContaining('Adani'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('7. keyboard inset does not hide search or overflow the layout',
        (tester) async {
      const size = Size(390, 844);
      final repo = _ControllableBillerRepository();
      await pumpElectricity(tester, repository: repo, size: size);

      await tester.tap(searchField());
      await tester.pump();
      // Simulate keyboard: shrink viewInsets like a soft keyboard.
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(() => tester.view.resetViewInsets());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expectSearchBarVisible(tester, size: size);
      expect(tester.takeException(), isNull);

      await tester.enterText(searchField(), 'tata');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expectSearchBarVisible(tester, size: size);
      expect(tester.takeException(), isNull);
    });
  });

  group('Electricity responsive audit (9 sizes × text scale)', () {
    for (final size in _nineElectricitySizes) {
      for (final textScale in const [0.85, 1.15]) {
        testWidgets(
          '${size.width.toInt()}x${size.height.toInt()} @ $textScale — '
          'no overflow, search stable, empty state ok',
          (tester) async {
            final repo = _ControllableBillerRepository();
            tester.view.devicePixelRatio = 2;
            tester.view.physicalSize = size * 2;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);

            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  billerRepositoryProvider.overrideWithValue(repo),
                  serviceLatestTransactionsProvider.overrideWith(
                    (ref, service) async => const [_saved],
                  ),
                ],
                child: ScreenUtilInit(
                  designSize: const Size(360, 690),
                  minTextAdapt: true,
                  splitScreenMode: true,
                  fontSizeResolver: FontSizeResolvers.radius,
                  builder: (context, _) => MaterialApp(
                    home: Builder(
                      builder: (context) => MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          textScaler: TextScaler.linear(textScale),
                        ),
                        child: const BillerListingView(
                          categoryName: 'Electricity',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            for (var i = 0; i < 8; i++) {
              await tester.pump(const Duration(milliseconds: 50));
            }

            expect(tester.takeException(), isNull);
            expectSearchBarVisible(tester, size: size);
            expect(find.text('Saved Billers'), findsOneWidget);

            await tester.enterText(searchField(), 'zzz-none');
            await tester.pump(const Duration(milliseconds: 400));
            expectSearchBarVisible(tester, size: size);
            expect(find.text('No providers found'), findsOneWidget);
            expect(tester.takeException(), isNull);

            tester.view.viewInsets = const FakeViewPadding(bottom: 280);
            addTearDown(() => tester.view.resetViewInsets());
            await tester.pump();
            expectSearchBarVisible(tester, size: size);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });
}
