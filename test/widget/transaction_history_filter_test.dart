import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_rupaiya/features/profile/controllers/transaction_history_controller.dart';
import 'package:e_rupaiya/features/profile/models/transaction_history_entry.dart';
import 'package:e_rupaiya/features/profile/models/transaction_history_filter.dart';
import 'package:e_rupaiya/features/profile/models/transaction_history_page.dart';
import 'package:e_rupaiya/features/profile/repositories/transaction_history_repository.dart';

/// A canned transaction row carrying an unmasked [service_no_full] so the
/// controller/safety-net filtering can be asserted without network.
TransactionHistoryEntry _entry({
  required String id,
  required String serviceFullNo,
}) {
  return TransactionHistoryEntry.fromJson({
    'payment_status': 'SUCCESS',
    'payment_type': 'Electricity Bill',
    'biller_name': 'Maharashtra State Electricity Distribution Co. Ltd',
    'service_no_full': serviceFullNo,
    'service_no': serviceFullNo,
    'amount': '1250.00',
    'total_amount_charged': '1250.00',
    'pg_transaction_id': id,
    'transaction_time': '2026-10-01 12:00:00',
  });
}

/// Records the filter the controller sends on every request and returns
/// programmable pages so refresh/pagination persistence can be verified.
class _RecordingRepository extends TransactionHistoryRepository {
  _RecordingRepository() : super(dio: Dio());

  final List<_RecordedRequest> requests = [];

  /// Pages keyed by requested page number; falls back to an empty page.
  Map<int, List<TransactionHistoryEntry>> pagesFor = {};
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
    requests.add(_RecordedRequest(page: page, consumerId: consumerId));
    final items = pagesFor[page] ?? const <TransactionHistoryEntry>[];
    return TransactionHistoryPage(
      items: items,
      currentPage: page,
      totalPages: totalPages,
      totalRecords: items.length,
      limit: limit,
    );
  }
}

class _RecordedRequest {
  _RecordedRequest({required this.page, this.consumerId});
  final int page;
  final String? consumerId;
}

void main() {
  group('TransactionHistoryController — View History consumer filter', () {
    test('CASE 1: initial load requests the selected consumer scope', () async {
      final repo = _RecordingRepository()
        ..pagesFor = {1: []};
      final controller = TransactionHistoryController(repository: repo);

      await controller.applyFilter(
        const TransactionHistoryFilter(
          service: 'Electricity',
          consumerId: '049338085841',
        ),
      );

      expect(repo.requests, hasLength(1));
      expect(repo.requests.single.page, 1);
      expect(repo.requests.single.consumerId, '049338085841');
      // Controller is the single source of truth for the active filter.
      expect(controller.activeFilter?.consumerId, '049338085841');
    });

    test('CASE 2: refresh reuses the SAME consumer filter and replaces rows',
        () async {
      final repo = _RecordingRepository()
        ..pagesFor = {
          1: [
            _TxnEntries.a,
          ]
        };
      final controller = TransactionHistoryController(repository: repo);
      const filter =
          TransactionHistoryFilter(service: 'Electricity', consumerId: 'A-111');

      await controller.applyFilter(filter);
      // Simulate a prior session having more rows, then refresh.
      await controller.applyFilter(controller.activeFilter!);

      expect(repo.requests, hasLength(2));
      expect(repo.requests.every((r) => r.consumerId == 'A-111'), isTrue);
      expect(repo.requests.last.page, 1);
      // Page-1 result replaces (no accumulation across refreshes).
      expect(controller.state.items.length, 1);
    });

    test('CASE 3: pagination keeps the SAME consumer filter and appends',
        () async {
      final repo = _RecordingRepository()
        ..totalPages = 2
        ..pagesFor = {
          1: [
            _TxnEntries.a,
          ],
          2: [
            _TxnEntries.b,
          ]
        };
      final controller = TransactionHistoryController(repository: repo);

      await controller.applyFilter(
        const TransactionHistoryFilter(consumerId: 'A-111'),
      );
      await controller.fetchNextPage();

      expect(repo.requests.map((r) => r.consumerId),
          everyElement('A-111'));
      expect(repo.requests.last.page, 2);
      expect(controller.state.items.map((e) => e.transactionId),
          containsAll(<String>['TXN-A', 'TXN-B']));
    });

    test('CASE 4: refresh after pagination resets to page 1 with SAME filter',
        () async {
      final repo = _RecordingRepository()
        ..totalPages = 2
        ..pagesFor = {
          1: [
            _TxnEntries.a,
          ],
          2: [
            _TxnEntries.b,
          ]
        };
      final controller = TransactionHistoryController(repository: repo);

      await controller.applyFilter(
        const TransactionHistoryFilter(consumerId: 'A-111'),
      );
      await controller.fetchNextPage();
      expect(controller.state.items.length, 2);

      await controller.applyFilter(controller.activeFilter!);

      expect(repo.requests.last.page, 1);
      expect(repo.requests.last.consumerId, 'A-111');
      // Back to page-1 only; the page-2 row must not linger.
      expect(controller.state.items.length, 1);
      expect(controller.state.currentPage, 1);
    });

    test('CASE 5: opening consumer B does not reuse A', () async {
      final repo = _RecordingRepository()
        ..pagesFor = {1: []};
      final controller = TransactionHistoryController(repository: repo);

      await controller.applyFilter(
        const TransactionHistoryFilter(consumerId: 'A-111'),
      );
      await controller.applyFilter(
        const TransactionHistoryFilter(consumerId: 'B-222'),
      );

      expect(controller.activeFilter?.consumerId, 'B-222');
      expect(repo.requests.last.consumerId, 'B-222');
    });

    test('CASE 6: no consumer id falls back to the generic scope', () async {
      final repo = _RecordingRepository()
        ..pagesFor = {1: []};
      final controller = TransactionHistoryController(repository: repo);

      await controller.fetchHistory(days: 30);

      expect(repo.requests.single.consumerId, isNull);
      expect(controller.activeFilter, isNull);
    });

    test('pagination deduplicates overlapping server pages', () async {
      final repo = _RecordingRepository()
        ..totalPages = 2
        ..pagesFor = {
          1: [
            _TxnEntries.a,
            _TxnEntries.b,
          ],
          // Page 2 overlaps TXN-B (window shifted mid-session).
          2: [
            _TxnEntries.b,
            _TxnEntries.c,
          ]
        };
      final controller = TransactionHistoryController(repository: repo);

      await controller.applyFilter(
        const TransactionHistoryFilter(consumerId: 'A-111'),
      );
      await controller.fetchNextPage();

      final ids = controller.state.items.map((e) => e.transactionId).toList();
      expect(ids, <String>['TXN-A', 'TXN-B', 'TXN-C']);
    });
  });

  group('TransactionHistoryEntry.matchesConsumerId — client-side safety net', () {
    test('CASE 7: keeps the exact target row, drops unrelated rows', () {
      final target = _entry(id: 'TXN-A', serviceFullNo: '049338085841');
      final unrelated = _entry(id: 'TXN-X', serviceFullNo: '999999999999');

      expect(target.matchesConsumerId('049338085841'), isTrue);
      expect(unrelated.matchesConsumerId('049338085841'), isFalse);
    });

    test('an empty target matches everything (no filter applied)', () {
      final entry = _entry(id: 'TXN-A', serviceFullNo: '049338085841');
      expect(entry.matchesConsumerId(''), isTrue);
    });
  });

  group('TransactionHistoryRepository — service_no_full request param', () {
    test('View History scopes the API request by service_no_full', () async {
      final captured = <String, dynamic>{};
      final dio = Dio()
        ..interceptors.add(
          _RecordingInterceptor(captured),
        );
      final repo = TransactionHistoryRepository(dio: dio);

      await repo.fetchHistoryPage(
        page: 1,
        limit: 20,
        service: 'Electricity',
        consumerId: '049338085841',
      );

      expect(captured['service_no_full'], '049338085841');
      expect(captured['consumer_id'], '049338085841');
      expect(captured['service'], 'Electricity');
    });

    test('no consumer id omits every consumer-scoped param', () async {
      final captured = <String, dynamic>{};
      final dio = Dio()
        ..interceptors.add(
          _RecordingInterceptor(captured),
        );
      final repo = TransactionHistoryRepository(dio: dio);

      await repo.fetchHistoryPage(page: 1, limit: 20, days: 30);

      expect(captured.containsKey('service_no_full'), isFalse);
      expect(captured.containsKey('consumer_id'), isFalse);
    });
  });
}

/// Shared canned entries used across the controller cases.
// ignore: non_constant_identifier_names
class _TxnEntries {
  static final a = _entry(id: 'TXN-A', serviceFullNo: 'A-111');
  static final b = _entry(id: 'TXN-B', serviceFullNo: 'A-111');
  static final c = _entry(id: 'TXN-C', serviceFullNo: 'A-111');
}

/// Short-circuits the request, capturing the query parameters and returning an
/// empty history page so the repository's query building can be asserted.
class _RecordingInterceptor extends Interceptor {
  _RecordingInterceptor(this.captured);
  final Map<String, dynamic> captured;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    captured.addAll(options.queryParameters);
    handler.resolve(
      Response(
        requestOptions: options,
        statusCode: 200,
        data: <String, dynamic>{'data': <dynamic>[]},
      ),
    );
  }
}
