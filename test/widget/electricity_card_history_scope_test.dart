import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_rupaiya/features/mobile_prepaid/models/latest_transaction.dart';
import 'package:e_rupaiya/features/profile/controllers/transaction_history_controller.dart';
import 'package:e_rupaiya/features/profile/models/electricity_card_history_scope.dart';
import 'package:e_rupaiya/features/profile/models/transaction_history_entry.dart';
import 'package:e_rupaiya/features/profile/models/transaction_history_filter.dart';
import 'package:e_rupaiya/features/profile/models/transaction_history_page.dart';
import 'package:e_rupaiya/features/profile/repositories/transaction_history_repository.dart';

/// Focused tests for the Electricity Saved Biller Card-Scoped View History
/// flow (Saved Biller card -> 3 dots -> View History).
///
/// Scope under test:
/// Selected card's exact dynamic `service_no_full` -> `service=Electricity` +
/// `service_no_full=<selected>` on EVERY API page -> ALL pages merged ->
/// back to Electricity Fetch Your Provider.
///
/// Generic/main Transaction History behavior is intentionally NOT covered
/// here (see transaction_history_filter_test.dart for the regression suite).

LatestTransaction _card({required String fullNo, String shortNo = 'SHORT'}) {
  return LatestTransaction.fromJson({
    'id': 'card-$fullNo',
    'biller_id': 'biller-1',
    'payment_type': 'Electricity',
    'biller_name': 'Maharashtra State Electricity Distribution Co. Ltd',
    'amount': 100,
    'status': 'success',
    'transaction_ref': 'ref-$fullNo',
    'service_no': shortNo,
    'service_no_full': fullNo,
  });
}

TransactionHistoryEntry _historyEntry({
  required String id,
  String? serviceFullNo,
  String? serviceNo,
  String? consumerParam,
  String paymentType = 'Electricity Bill',
  String billerName = 'Maharashtra State Electricity Distribution Co. Ltd',
}) {
  final json = <String, dynamic>{
    'payment_status': 'SUCCESS',
    'payment_type': paymentType,
    'biller_name': billerName,
    'amount': '1250.00',
    'total_amount_charged': '1250.00',
    'pg_transaction_id': id,
    'transaction_time': '2026-10-01 12:00:00',
    'customer_mobile': '9876543210',
  };
  if (serviceFullNo != null) json['service_no_full'] = serviceFullNo;
  if (serviceNo != null) json['service_no'] = serviceNo;
  if (consumerParam != null) {
    json['customer_params'] = [
      {'label': 'Consumer Number', 'value': consumerParam},
    ];
  }
  return TransactionHistoryEntry.fromJson(json);
}

class _RecordingRequest {
  _RecordingRequest({required this.page, this.service, this.consumerId});
  final int page;
  final String? service;
  final String? consumerId;
}

class _RecordingRepository extends TransactionHistoryRepository {
  _RecordingRepository() : super(dio: Dio());

  final List<_RecordingRequest> requests = [];
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
    requests.add(
      _RecordingRequest(page: page, service: service, consumerId: consumerId),
    );
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

class _QueryCapture extends Interceptor {
  _QueryCapture(this.captured);
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

/// The single scoped predicate shared by the controller (per page) and the
/// screen (visible list): keep everything except rows that explicitly name
/// another card or another service.
List<TransactionHistoryEntry> _scopedVisible(
  List<TransactionHistoryEntry> items,
  String target,
) {
  final scope = ElectricityCardHistoryScope(serviceNoFull: target);
  return items.where(scope.includesEntry).toList(growable: false);
}

void main() {
  group('Electricity card scope — selected card reaches the API', () {
    test('1: card A scopes the request to service + service_no_full=A',
        () async {
      const cardA = '049338085841';
      final scope = ElectricityCardHistoryScope.fromTransaction(
        _card(fullNo: cardA, shortNo: '9999'),
      )!;
      expect(scope.serviceNoFull, cardA);

      final extra = scope.toNavigationExtra();
      expect(extra['service'], 'Electricity');
      expect(extra['serviceNoFull'], cardA);
      expect(extra['consumerId'], cardA);
      expect(extra['electricityCardScoped'], isTrue);

      final captured = <String, dynamic>{};
      final dio = Dio()..interceptors.add(_QueryCapture(captured));
      await TransactionHistoryRepository(dio: dio).fetchHistoryPage(
        page: 1,
        limit: 20,
        service: extra['service'] as String,
        consumerId: extra['consumerId'] as String,
      );
      expect(captured['service'], 'Electricity');
      expect(captured['service_no_full'], cardA);
    });

    test('2: card B scopes the request to service + service_no_full=B',
        () async {
      const cardB = '070518803466';
      final scope = ElectricityCardHistoryScope.fromTransaction(
        _card(fullNo: cardB, shortNo: '1111'),
      )!;
      expect(scope.serviceNoFull, cardB);

      final captured = <String, dynamic>{};
      final dio = Dio()..interceptors.add(_QueryCapture(captured));
      final controller =
          TransactionHistoryController(repository: _RecordingRepository());
      await controller.fetchElectricityCardHistory(serviceNoFull: cardB);
      expect(controller.activeFilter?.service, 'Electricity');
      expect(controller.activeFilter?.consumerId, cardB);
      expect(controller.activeFilter?.electricityCardScoped, isTrue);

      await TransactionHistoryRepository(dio: dio).fetchHistoryPage(
        page: 1,
        limit: 20,
        service: 'Electricity',
        consumerId: cardB,
      );
      expect(captured['service'], 'Electricity');
      expect(captured['service_no_full'], cardB);
    });

    test('scope uses the exact service_no_full, never the service_no fallback',
        () {
      final scope = ElectricityCardHistoryScope.fromTransaction(
        _card(fullNo: '049338085841', shortNo: '5046'),
      )!;
      expect(scope.serviceNoFull, '049338085841');
      expect(scope.serviceNoFull, isNot('5046'));
    });

    test('card without service_no_full yields no scope (no fallback)', () {
      final txn = LatestTransaction.fromJson({
        'id': 'card-x',
        'biller_id': 'biller-1',
        'payment_type': 'Electricity',
        'biller_name': 'Some Provider',
        'amount': 100,
        'status': 'success',
        'transaction_ref': 'ref-x',
        'service_no': '5046',
      });
      expect(
        ElectricityCardHistoryScope.fromTransaction(txn),
        isNull,
      );
    });

    test('3: switching cards changes the history scope', () async {
      final repo = _RecordingRepository()..pagesFor = {1: []};
      final controller = TransactionHistoryController(repository: repo);

      await controller.fetchElectricityCardHistory(
        serviceNoFull: '049338085841',
      );
      await controller.fetchElectricityCardHistory(
        serviceNoFull: '070518803466',
      );

      expect(controller.activeFilter?.consumerId, '070518803466');
      expect(controller.activeFilter?.service, 'Electricity');
      expect(repo.requests.last.consumerId, '070518803466');
      expect(repo.requests.last.service, 'Electricity');
    });
  });

  group('Electricity card scope — fetch ALL records', () {
    test('4: API returns 20 records -> 20 displayed', () async {
      final repo = _RecordingRepository()
        ..totalPages = 1
        ..pagesFor = {
          1: [
            for (var i = 0; i < 20; i++)
              _historyEntry(
                id: 'TXN-$i',
                serviceFullNo: '049338085841',
              ),
          ],
        };
      final controller = TransactionHistoryController(repository: repo);

      await controller.fetchElectricityCardHistory(
        serviceNoFull: '049338085841',
      );

      expect(controller.state.items.length, 20);
    });

    test('5: multiple pages are all fetched with the SAME scope', () async {
      final repo = _RecordingRepository()
        ..totalPages = 3
        ..pagesFor = {
          1: [_historyEntry(id: 'TXN-1', serviceFullNo: '049338085841')],
          2: [_historyEntry(id: 'TXN-2', serviceFullNo: '049338085841')],
          3: [_historyEntry(id: 'TXN-3', serviceFullNo: '049338085841')],
        };
      final controller = TransactionHistoryController(repository: repo);

      await controller.fetchElectricityCardHistory(
        serviceNoFull: '049338085841',
      );

      expect(repo.requests.map((r) => r.page).toList(), [1, 2, 3]);
      expect(
        repo.requests.map((r) => r.consumerId).toSet(),
        {'049338085841'},
      );
      expect(
        repo.requests.map((r) => r.service).toSet(),
        {'Electricity'},
      );
      expect(controller.state.items.length, 3);
    });

    test('6: 130 records across 7 pages are all displayed', () async {
      final all = [
        for (var i = 0; i < 130; i++)
          _historyEntry(id: 'TXN-$i', serviceFullNo: '049338085841'),
      ];
      final repo = _RecordingRepository()
        ..totalPages = 7
        ..pagesFor = {
          for (var p = 1; p <= 7; p++)
            p: all.sublist((p - 1) * 20, p == 7 ? 130 : p * 20),
        };
      final controller = TransactionHistoryController(repository: repo);

      await controller.fetchElectricityCardHistory(
        serviceNoFull: '049338085841',
      );

      expect(repo.requests, hasLength(7));
      expect(controller.state.items.length, 130);
    });

    test('overlapping pages dedupe only true duplicate IDs', () async {
      final repo = _RecordingRepository()
        ..totalPages = 2
        ..pagesFor = {
          1: [
            _historyEntry(id: 'TXN-A', serviceFullNo: '049338085841'),
            _historyEntry(id: 'TXN-B', serviceFullNo: '049338085841'),
          ],
          2: [
            _historyEntry(id: 'TXN-B', serviceFullNo: '049338085841'),
            _historyEntry(id: 'TXN-C', serviceFullNo: '049338085841'),
          ],
        };
      final controller = TransactionHistoryController(repository: repo);

      await controller.fetchElectricityCardHistory(
        serviceNoFull: '049338085841',
      );

      expect(
        controller.state.items.map((e) => e.transactionId).toList(),
        ['TXN-A', 'TXN-B', 'TXN-C'],
      );
    });
  });

  group('Electricity card scope — response handling', () {
    test('7: another Electricity card\u2019s records are not displayed',
        () async {
      const selected = '049338085841';
      const other = '070518803466';
      final rows = [
        _historyEntry(id: 'TXN-OWN', serviceFullNo: selected),
        _historyEntry(id: 'TXN-OTHER', serviceFullNo: other),
        // Missing identifier rows are preserved (never dropped for that).
        _historyEntry(id: 'TXN-NO-ID', serviceFullNo: null),
      ];

      final visible = _scopedVisible(rows, selected).map((e) => e.transactionId);

      expect(visible, contains('TXN-OWN'));
      expect(visible, contains('TXN-NO-ID'));
      expect(visible, isNot(contains('TXN-OTHER')));
    });

    test('8: FASTag / Mobile / Tuition records are not displayed', () {
      final rows = [
        _historyEntry(
          id: 'TXN-ELEC',
          serviceFullNo: '049338085841',
          paymentType: 'Electricity Bill',
        ),
        _historyEntry(
          id: 'TXN-FASTAG',
          serviceFullNo: '049338085841',
          paymentType: 'FASTag Recharge',
          billerName: 'FASTag',
        ),
        _historyEntry(
          id: 'TXN-MOBILE',
          serviceFullNo: '049338085841',
          paymentType: 'Mobile Prepaid',
          billerName: 'Airtel Prepaid',
        ),
        _historyEntry(
          id: 'TXN-TUITION',
          serviceFullNo: '049338085841',
          paymentType: 'Tuition Fee',
          billerName: 'City School',
        ),
      ];

      final visible =
          _scopedVisible(rows, '049338085841').map((e) => e.transactionId);

      expect(visible, contains('TXN-ELEC'));
      expect(visible, isNot(contains('TXN-FASTAG')));
      expect(visible, isNot(contains('TXN-MOBILE')));
      expect(visible, isNot(contains('TXN-TUITION')));
    });

    test('rows missing any full consumer number are preserved', () {
      final entry = _historyEntry(id: 'TXN-X');
      expect(entry.explicitFullConsumerNumber, isNull);
      expect(
        entry.explicitlyBelongsToDifferentCard('049338085841'),
        isFalse,
      );
    });

    test(
        'B (screenshot bug): other consumer carried only in service_no / '
        'customer_params (no service_no_full) is removed', () {
      const selected = '049338085841';
      final rows = [
        _historyEntry(id: 'TXN-OWN', serviceNo: selected),
        _historyEntry(id: 'TXN-OTHER-SNO', serviceNo: '070518803466'),
        _historyEntry(id: 'TXN-OTHER-PARAM', consumerParam: '070518803466'),
      ];

      final visible = _scopedVisible(rows, selected).map((e) => e.transactionId);

      expect(visible, contains('TXN-OWN'));
      expect(visible, isNot(contains('TXN-OTHER-SNO')));
      expect(visible, isNot(contains('TXN-OTHER-PARAM')));
    });

    test('masked / last-4 / mobile values are never used for matching', () {
      const selected = '049338085841';
      final rows = [
        // Masked service_no: no full number -> preserved.
        _historyEntry(id: 'TXN-MASKED', serviceNo: 'XXXXXXXX5841'),
        _historyEntry(id: 'TXN-STARS', serviceNo: '********3466'),
        // Last-4 partial (even if it looks like another card) -> preserved.
        _historyEntry(id: 'TXN-LAST4', serviceNo: '3466'),
        // Only customer_mobile present -> preserved (mobile never matched).
        _historyEntry(id: 'TXN-MOBILE-ONLY'),
      ];

      final visible = _scopedVisible(rows, selected).map((e) => e.transactionId);

      expect(
        visible,
        containsAll(
          <String>['TXN-MASKED', 'TXN-STARS', 'TXN-LAST4', 'TXN-MOBILE-ONLY'],
        ),
      );
    });

    test('exact equality only: a longer number containing the target is '
        'another consumer', () {
      const selected = '049338085841';
      final rows = [
        _historyEntry(id: 'TXN-SUPER', serviceFullNo: '1049338085841'),
        _historyEntry(id: 'TXN-SPACED', serviceFullNo: '0493 3808 5841'),
      ];

      final visible = _scopedVisible(rows, selected).map((e) => e.transactionId);

      expect(visible, isNot(contains('TXN-SUPER')));
      expect(visible, contains('TXN-SPACED'));
    });

    test('A: controller state holds ONLY the selected card after a mixed '
        'multi-page response', () async {
      const selected = '049338085841';
      final repo = _RecordingRepository()
        ..totalPages = 2
        ..pagesFor = {
          1: [
            _historyEntry(id: 'TXN-1', serviceFullNo: selected),
            _historyEntry(id: 'TXN-2', serviceNo: '070518803466'),
            _historyEntry(id: 'TXN-3', serviceFullNo: selected),
          ],
          2: [
            _historyEntry(id: 'TXN-4', serviceFullNo: '070518803466'),
            _historyEntry(id: 'TXN-5', serviceFullNo: selected),
            _historyEntry(
              id: 'TXN-6',
              serviceFullNo: selected,
              paymentType: 'FASTag Recharge',
              billerName: 'FASTag',
            ),
          ],
        };
      final controller = TransactionHistoryController(repository: repo);

      await controller.fetchElectricityCardHistory(serviceNoFull: selected);

      expect(
        controller.state.items.map((e) => e.transactionId).toList(),
        ['TXN-1', 'TXN-3', 'TXN-5'],
      );
      expect(
        controller.state.items.map((e) => e.primaryConsumerNumber).toSet(),
        {selected},
      );
    });
  });

  group('Electricity card scope — navigation + invariants', () {
    test('10: scoped extra parses as card-scoped; generic extra does not',
        () {
      final scoped = ElectricityCardHistoryScope.fromNavigationExtra(
        <String, dynamic>{
          'service': 'Electricity',
          'consumerId': '049338085841',
          'serviceNoFull': '049338085841',
          'electricityCardScoped': true,
        },
      );
      expect(scoped?.serviceNoFull, '049338085841');

      expect(
        ElectricityCardHistoryScope.fromNavigationExtra(
          <String, dynamic>{'service': 'Electricity'},
        ),
        isNull,
      );
      expect(ElectricityCardHistoryScope.fromNavigationExtra('Electricity'),
          isNull);
    });

    test('10: back from card-scoped history targets Fetch Your Provider', () {
      // TransactionHistoryScreen pops back to the Electricity Fetch Your
      // Provider screen when scoped; only the deep-link fallback navigates,
      // using the biller-listing route with the Electricity category.
      expect(
        ElectricityCardHistoryScope.backFallbackCategory,
        'Electricity',
      );
    });

    test('9: no hardcoded consumer number in production code', () {
      const touchedFiles = [
        'lib/features/profile/models/electricity_card_history_scope.dart',
        'lib/features/profile/models/transaction_history_filter.dart',
        'lib/features/profile/models/transaction_history_entry.dart',
        'lib/features/profile/controllers/transaction_history_controller.dart',
        'lib/features/profile/views/transaction_history_screen.dart',
        'lib/features/services/components/service_recent_section.dart',
        'lib/router.dart',
      ];

      for (final path in touchedFiles) {
        final source = File(path).readAsStringSync();
        expect(source, isNot(contains('049338085841')), reason: path);
        expect(source, isNot(contains('070518803466')), reason: path);
      }
      expect(ElectricityCardHistoryScope.serviceName, 'Electricity');
    });

    test('11: generic/main history defaults stay untouched', () async {
      const filter = TransactionHistoryFilter();
      expect(filter.electricityCardScoped, isFalse);
      expect(filter.isEmpty, isTrue);

      final captured = <String, dynamic>{};
      final dio = Dio()..interceptors.add(_QueryCapture(captured));
      await TransactionHistoryRepository(dio: dio).fetchHistoryPage(
        page: 1,
        limit: 20,
        days: 30,
      );
      expect(captured.containsKey('service_no_full'), isFalse);
      expect(captured.containsKey('consumer_id'), isFalse);
    });
  });
}
