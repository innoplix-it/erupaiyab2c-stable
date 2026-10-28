import 'package:dio/dio.dart';
import 'package:e_rupaiya/features/profile/controllers/transaction_history_controller.dart';
import 'package:e_rupaiya/features/profile/models/transaction_history_entry.dart';
import 'package:e_rupaiya/features/profile/models/transaction_history_page.dart';
import 'package:e_rupaiya/features/profile/repositories/transaction_history_repository.dart';
import 'package:e_rupaiya/features/profile/views/transaction_history_screen.dart';
import 'package:e_rupaiya/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

TransactionHistoryEntry _txn({
  required String id,
  required String status,
  String methodIcon = '',
}) {
  return TransactionHistoryEntry.fromJson({
    'payment_status': status,
    'payment_type': 'Electricity Bill',
    'biller_name': 'Adani Electricity',
    'amount': '100.00',
    'total_amount_charged': '100.00',
    'pg_transaction_id': id,
    'transaction_time': '2026-10-02 10:00:00',
    'method_icon': methodIcon,
  });
}

class _Repo extends TransactionHistoryRepository {
  _Repo(this.items) : super(dio: Dio());

  final List<TransactionHistoryEntry> items;

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
    return TransactionHistoryPage(
      items: page == 1 ? items : const [],
      currentPage: page,
      totalPages: 1,
      totalRecords: items.length,
      limit: limit,
    );
  }
}

Future<void> _pump(WidgetTester tester, List<TransactionHistoryEntry> items) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(390, 844) * 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    overrides: [
      transactionHistoryRepositoryProvider.overrideWithValue(_Repo(items)),
    ],
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
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

List<String> _networkIconUrls(WidgetTester tester) {
  return tester
      .widgetList<AppNetworkImage>(find.byType(AppNetworkImage))
      .map((image) => image.url?.trim() ?? '')
      .where((url) => url.isNotEmpty)
      .toList();
}

void main() {
  testWidgets('each success row uses its own method_icon url', (tester) async {
    await _pump(tester, [
      _txn(
        id: 'upi-1',
        status: 'SUCCESS',
        methodIcon: 'https://cdn.example/upi.png',
      ),
      _txn(
        id: 'card-1',
        status: 'SUCCESS',
        methodIcon: 'https://cdn.example/card.png',
      ),
    ]);

    expect(find.text('Paid From'), findsNWidgets(2));
    expect(
      _networkIconUrls(tester),
      containsAll([
        'https://cdn.example/upi.png',
        'https://cdn.example/card.png',
      ]),
    );
    expect(_paidFromAsset(), findsNothing);
  });

  testWidgets('missing or invalid method_icon does not use the static badge',
      (tester) async {
    await _pump(tester, [
      _txn(id: 'empty', status: 'SUCCESS'),
      _txn(
        id: 'bad',
        status: 'SUCCESS',
        methodIcon: 'assets/images/badge_paid_from.svg',
      ),
      _txn(
        id: 'failed',
        status: 'FAILED',
        methodIcon: 'https://cdn.example/should-not-show.png',
      ),
    ]);

    expect(find.text('Paid From'), findsNWidgets(2));
    expect(find.text('Failed'), findsOneWidget);
    expect(_networkIconUrls(tester), isEmpty);
    expect(_paidFromAsset(), findsNothing);
  });
}

Finder _paidFromAsset() {
  return find.byWidgetPredicate((widget) {
    if (widget is! SvgPicture) return false;
    final loader = widget.bytesLoader;
    return loader is SvgAssetLoader &&
        loader.assetName.contains('badge_paid_from');
  });
}
