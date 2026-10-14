import 'dart:async';

import 'package:dio/dio.dart';
import 'package:e_rupaiya/constants/routes_constant.dart';
import 'package:e_rupaiya/features/mobile_prepaid/models/latest_transaction.dart';
import 'package:e_rupaiya/features/services/controllers/biller_listing_controller.dart';
import 'package:e_rupaiya/features/services/controllers/service_extras_controller.dart';
import 'package:e_rupaiya/features/services/models/biller_detail_args.dart';
import 'package:e_rupaiya/features/services/models/biller_model.dart';
import 'package:e_rupaiya/features/services/repositories/biller_repository.dart';
import 'package:e_rupaiya/features/services/views/biller_listing_view.dart';
import 'package:e_rupaiya/features/services/views/saved_billers_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../helpers/responsive_test_sizes.dart';

const _billers = [
  Biller(billerId: 'b1', billerName: 'Adani Electricity Mumbai Limited'),
  Biller(billerId: 'b2', billerName: 'B.E.S.T Mumbai'),
];

LatestTransaction _saved(int i) => LatestTransaction(
      id: 'saved-$i',
      billerId: 'b1',
      paymentType: 'Electricity',
      billerName: 'Adani Electricity Mumbai Limited',
      amount: 100 + i,
      status: 'success',
      transactionRef: 'ref-$i',
      serviceNo: '90000000${i.toString().padLeft(4, '0')}',
      icon: '',
      customerName: 'Customer $i',
      createdAt: '2026-09-05T10:00:00Z',
      dueDate: '2026-10-2${i % 9}',
    );

final _twelve = List.generate(12, _saved);

class _FakeBillerRepository extends BillerRepository {
  _FakeBillerRepository() : super(dio: Dio());

  @override
  Future<BillerListResponse> fetchBillers({
    required String categoryName,
    int page = 1,
    int limit = 20,
    String? search,
  }) async =>
      BillerListResponse(categoryName: categoryName, billers: _billers);
}

class _Harness {
  late GoRouter router;
  final opened = <BillerDetailArgs>[];
  final requestedServices = <String>[];
  int calls = 0;

  /// Top of the stack; `uri` stays on the base location after a push.
  String get location =>
      router.routerDelegate.currentConfiguration.last.matchedLocation;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  required Future<List<LatestTransaction>> Function(int call) savedBillers,
  bool startOnViewAll = false,
  Size size = const Size(390, 844),
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = size * 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final h = _Harness();
  h.router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) =>
            const BillerListingView(categoryName: 'Electricity'),
      ),
      GoRoute(
        path: RouteConstants.savedBillers,
        builder: (_, state) =>
            SavedBillersView(categoryName: state.extra as String? ?? ''),
      ),
      GoRoute(
        path: RouteConstants.billerDetail,
        builder: (_, state) {
          h.opened.add(state.extra! as BillerDetailArgs);
          return const Scaffold(body: Text('biller detail page'));
        },
      ),
    ],
  );
  addTearDown(h.router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        billerRepositoryProvider.overrideWithValue(_FakeBillerRepository()),
        serviceLatestTransactionsProvider.overrideWith((ref, service) {
          h.requestedServices.add(service);
          return savedBillers(h.calls++);
        }),
      ],
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        fontSizeResolver: FontSizeResolvers.radius,
        builder: (_, __) => MaterialApp.router(routerConfig: h.router),
      ),
    ),
  );
  await _settle(tester);
  if (startOnViewAll) {
    h.router.push(RouteConstants.savedBillers, extra: 'Electricity');
    await _settle(tester);
  }
  return h;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _finish(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

Finder _inViewAll(Finder finder) =>
    find.descendant(of: find.byType(SavedBillersView), matching: finder);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('View all opens the Saved Billers screen and back returns',
      (tester) async {
    final h = await _pump(tester, savedBillers: (_) async => _twelve);
    expect(h.location, '/');

    await tester.tap(find.text('View all'));
    await _settle(tester);
    expect(h.location, RouteConstants.savedBillers);
    expect(find.byType(SavedBillersView), findsOneWidget);
    expect(h.requestedServices.toSet(), {'Electricity'});

    await tester.tap(_inViewAll(find.byType(IconButton)).first);
    await _settle(tester);
    expect(h.location, '/');
    expect(find.byType(SavedBillersView), findsNothing);
    expect(find.byType(BillerListingView), findsOneWidget);
    await _finish(tester);
  });

  testWidgets('lists every saved biller, not just the preview row',
      (tester) async {
    await _pump(tester, savedBillers: (_) async => _twelve, startOnViewAll: true);
    final list = _inViewAll(find.byType(Scrollable)).first;
    for (final txn in [_twelve.first, _twelve[6], _twelve.last]) {
      await tester.scrollUntilVisible(
        _inViewAll(find.text(txn.serviceNo)),
        200,
        scrollable: list,
      );
      expect(_inViewAll(find.text(txn.serviceNo)), findsOneWidget);
    }
    expect(_inViewAll(find.text('Pay Now')), findsWidgets);
    expect(tester.takeException(), isNull);
    await _finish(tester);
  });

  testWidgets('Pay Now opens the biller payment with the saved number',
      (tester) async {
    final h = await _pump(
      tester,
      savedBillers: (_) async => _twelve,
      startOnViewAll: true,
    );
    await tester.tap(_inViewAll(find.text('Pay Now')).first);
    await _settle(tester);
    expect(find.text('biller detail page'), findsOneWidget);
    expect(h.opened, hasLength(1));
    final args = h.opened.single;
    expect(args.biller.billerId, 'b1');
    expect(args.paymentType, 'Electricity');
    expect(args.mobileNumber, _twelve.first.primaryConsumerNumber);
    expect(args.autoFetchBill, isTrue);
    await _finish(tester);
  });

  testWidgets('shows shimmer while loading', (tester) async {
    final pending = Completer<List<LatestTransaction>>();
    await _pump(
      tester,
      savedBillers: (_) => pending.future,
      startOnViewAll: true,
    );
    expect(
      _inViewAll(
        find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_SavedBillerCardShimmer',
        ),
      ),
      findsNWidgets(3),
    );
    expect(_inViewAll(find.text('Pay Now')), findsNothing);
    pending.complete(_twelve);
    await _settle(tester);
    expect(_inViewAll(find.text('Pay Now')), findsWidgets);
    await _finish(tester);
  });

  testWidgets('shows the empty state when there are no saved billers',
      (tester) async {
    await _pump(
      tester,
      savedBillers: (_) async => const [],
      startOnViewAll: true,
    );
    expect(_inViewAll(find.text('No saved billers yet')), findsOneWidget);
    expect(_inViewAll(find.text('Pay Now')), findsNothing);
    await _finish(tester);
  });

  testWidgets('shows the error state and Retry reloads', (tester) async {
    final h = await _pump(
      tester,
      savedBillers: (call) async {
        if (call == 0) throw Exception('boom');
        return _twelve;
      },
      startOnViewAll: true,
    );
    expect(_inViewAll(find.text('Retry')), findsOneWidget);
    expect(_inViewAll(find.text('Pay Now')), findsNothing);

    await tester.tap(_inViewAll(find.text('Retry')));
    await _settle(tester);
    expect(h.calls, greaterThanOrEqualTo(2));
    expect(_inViewAll(find.text('Retry')), findsNothing);
    expect(_inViewAll(find.text('Pay Now')), findsWidgets);
    await _finish(tester);
  });

  group('Saved Billers screen across shared sizes', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pump(
          tester,
          savedBillers: (_) async => _twelve,
          startOnViewAll: true,
          size: size,
        );
        expect(tester.takeException(), isNull);
        final card = tester.getRect(
          find
              .ancestor(
                of: _inViewAll(find.text(_twelve.first.serviceNo)),
                matching: find.byType(GestureDetector),
              )
              .last,
        );
        expect(card.left, greaterThanOrEqualTo(0));
        expect(card.right, lessThanOrEqualTo(size.width));
        await _finish(tester);
      });
    }
  });
}
