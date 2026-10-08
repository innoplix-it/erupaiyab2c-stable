import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:e_rupaiya/features/profile/controllers/transaction_history_controller.dart';
import 'package:e_rupaiya/features/profile/models/transaction_history_entry.dart';
import 'package:e_rupaiya/features/profile/models/transaction_history_page.dart';
import 'package:e_rupaiya/features/profile/repositories/transaction_history_repository.dart';
import 'package:e_rupaiya/features/profile/views/transaction_detail_screen.dart';
import 'package:e_rupaiya/features/profile/views/transaction_history_screen.dart';
import 'package:e_rupaiya/features/educationFees/services/education_fees_service.dart';
import 'package:dio/dio.dart';

/// Builds a [TransactionHistoryEntry] for a rent / education transaction.
///
/// The header card renders `resolvedParams[0]` on the LEFT and
/// `resolvedParams[1]` on the RIGHT. Before the rent fix, a rent row only
/// produced a single "Recipient Name" param, so the RIGHT side duplicated the
/// LEFT. These tests lock in the LEFT = Recipient Name / RIGHT = Fee Type
/// contract, driven entirely by the API `fee_type` (never hardcoded).
Map<String, dynamic> _rentJson({
  required String paymentType,
  String? feeType,
  String recipient = 'Darshan Rajendra Nikam',
}) {
  final json = <String, dynamic>{
    'payment_status': 'SUCCESS',
    'payment_type': paymentType,
    'biller_name': recipient,
    'masked_identifier': 'XXXXXX4455',
    'amount': 12000,
    'customer_mobile': '9800012345',
    'pg_transaction_id': 'pay_RENT001',
    'transaction_time': '08 Oct 2026, 07:26am',
    'method': 'upi',
    'payment_mode': 'Google Pay',
    'amount_breakdown': const {'Bill Amount': 12000, 'Total': 12000},
    'customer_params': [
      {'label': 'Recipient Name', 'value': recipient},
    ],
  };
  if (feeType != null) json['fee_type'] = feeType;
  return json;
}

Future<void> _pumpDetail(
    WidgetTester tester, TransactionHistoryEntry entry) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(390, 844) * 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) => MaterialApp(
        home: TransactionDetailScreen(entry: entry),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _StaticHistoryRepository extends TransactionHistoryRepository {
  _StaticHistoryRepository(this._items);
  final List<TransactionHistoryEntry> _items;

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
      items: _items,
      currentPage: 1,
      totalPages: 1,
      totalRecords: _items.length,
      limit: limit,
    );
  }

  @override
  Future<List<TransactionHistoryEntry>> fetchHistory({
    int? days,
    int? page,
    int? limit,
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
    return _items;
  }
}

Future<void> _pumpHistory(
  WidgetTester tester,
  List<TransactionHistoryEntry> entries,
) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(390, 844) * 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        transactionHistoryRepositoryProvider.overrideWithValue(
          _StaticHistoryRepository(entries),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, _) => const MaterialApp(
          home: TransactionHistoryScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Captures the create-order request body so the test can assert the dynamic
/// `fee_type` actually reaches the Education create-order endpoint.
class _CapturingAdapter implements HttpClientAdapter {
  Map<String, dynamic>? capturedBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final data = options.data;
    if (data is String) {
      capturedBody = jsonDecode(data) as Map<String, dynamic>;
    } else if (data is List<int>) {
      capturedBody = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
    } else if (data is Map) {
      capturedBody = Map<String, dynamic>.from(data);
    }
    return ResponseBody.fromString(
      '{"status":true,"message":"ok","order_id":"order_123","key":"rzp_test_1","transaction_ref_id":"EDU_REF_1"}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('Shop/House Rent — fee_type parsing (API source of truth)', () {
    test('maps response fee_type into TransactionHistoryEntry.feeType', () {
      final house = TransactionHistoryEntry.fromJson(
        _rentJson(paymentType: 'House Rent', feeType: 'House Rent'),
      );
      final shop = TransactionHistoryEntry.fromJson(
        _rentJson(paymentType: 'Shop Rent', feeType: 'Shop Rent'),
      );
      expect(house.feeType, 'House Rent');
      expect(shop.feeType, 'Shop Rent');
    });

    test('missing fee_type stays null (no fabricated value)', () {
      final entry = TransactionHistoryEntry.fromJson(
        _rentJson(paymentType: 'House Rent'),
      );
      expect(entry.feeType, isNull);
    });

    test('parses fee_type nested under the data map (real history shape)', () {
      // The backend nests order fields under `data` (same map createOrder
      // writes data['fee_type'] into). fee_type must be read from there too.
      final entry = TransactionHistoryEntry.fromJson({
        'payment_status': 'PENDING',
        'payment_type': '',
        'biller_name': 'Darshan Rajendra Nikam',
        'amount': 1,
        'data': const {'fee_type': 'House Rent'},
      });
      expect(entry.feeType, 'House Rent');
    });
  });

  group('House Rent — transaction detail header', () {
    testWidgets('LEFT = Recipient Name, RIGHT = Fee Type (from fee_type)',
        (tester) async {
      final entry = TransactionHistoryEntry.fromJson(
        _rentJson(paymentType: 'House Rent', feeType: 'House Rent'),
      );
      await _pumpDetail(tester, entry);

      // "Recipient Name" must appear exactly once (LEFT). Before the fix the
      // RIGHT side duplicated it, producing two occurrences.
      expect(find.text('Recipient Name'), findsOneWidget);
      expect(find.text('Fee Type'), findsOneWidget);
      // The dynamic fee_type value is shown, and the recipient value is shown
      // once (not repeated on the right).
      expect(find.text('Darshan Rajendra Nikam'), findsOneWidget);
      expect(find.text('House Rent'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('falls back to payment_type when fee_type is absent',
        (tester) async {
      final entry = TransactionHistoryEntry.fromJson(
        _rentJson(paymentType: 'House Rent'),
      );
      await _pumpDetail(tester, entry);

      expect(find.text('Recipient Name'), findsOneWidget);
      expect(find.text('Fee Type'), findsOneWidget);
      // Value still comes from an API field (payment_type), never a fake.
      expect(find.text('House Rent'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('nested-only fee_type (empty payment_type) shows Fee Type',
        (tester) async {
      // Reproduces the reported screenshot: fee_type arrives nested under
      // `data`, payment_type is empty, and customer_params carries the
      // recipient. Detection must key off the parsed feeType, not a label.
      final entry = TransactionHistoryEntry.fromJson({
        'payment_status': 'PENDING',
        'payment_type': '',
        'biller_name': 'Darshan Rajendra Nikam',
        'masked_identifier': 'XXXXXX4455',
        'amount': 1,
        'total_amount_charged': '1',
        'transaction_time': '08 Oct 2026, 02:39pm',
        'method': 'upi',
        'payment_mode': 'ECOINS',
        'data': const {'fee_type': 'House Rent'},
        'customer_params': const [
          {'label': 'Recipient Name', 'value': 'Darshan Rajendra Nikam'},
        ],
      });
      await _pumpDetail(tester, entry);

      expect(find.text('Recipient Name'), findsOneWidget);
      expect(find.text('Fee Type'), findsOneWidget);
      expect(find.text('Darshan Rajendra Nikam'), findsOneWidget);
      expect(find.text('House Rent'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('Shop Rent — transaction detail header', () {
    testWidgets('LEFT = Recipient Name, RIGHT = Fee Type (from fee_type)',
        (tester) async {
      final entry = TransactionHistoryEntry.fromJson(
        _rentJson(paymentType: 'Shop Rent', feeType: 'Shop Rent'),
      );
      await _pumpDetail(tester, entry);

      expect(find.text('Recipient Name'), findsOneWidget);
      expect(find.text('Fee Type'), findsOneWidget);
      expect(find.text('Darshan Rajendra Nikam'), findsOneWidget);
      expect(find.text('Shop Rent'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('Regression — other services unchanged', () {
    testWidgets('Education (School Fee) still shows Recipient Name + Fee Type',
        (tester) async {
      final entry = TransactionHistoryEntry.fromJson({
        'payment_status': 'SUCCESS',
        'payment_type': 'School Fee',
        'fee_type': 'School Fee',
        'biller_name': 'St. Vincent High School',
        'masked_identifier': 'XXXXXX9090',
        'amount': 2500,
        'pg_transaction_id': 'pay_SCH001',
        'transaction_time': '08 Oct 2026, 07:26am',
        'method': 'upi',
        'payment_mode': 'Google Pay',
        'amount_breakdown': const {'Bill Amount': 2500, 'Total': 2500},
        'customer_params': [
          {'label': 'Recipient Name', 'value': 'St. Vincent High School'},
        ],
      });
      await _pumpDetail(tester, entry);

      expect(find.text('Recipient Name'), findsOneWidget);
      expect(find.text('Fee Type'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Electricity keeps Payment to + Consumer No', (tester) async {
      final entry = TransactionHistoryEntry.fromJson({
        'payment_status': 'SUCCESS',
        'payment_type': 'Electricity',
        'biller_name': 'MSEDCL',
        'service_no_full': '1509876543',
        'masked_identifier': 'XXXXXX6543',
        'amount': 850,
        'pg_transaction_id': 'pay_ELC001',
        'transaction_time': '08 Oct 2026, 07:26am',
        'method': 'upi',
        'payment_mode': 'Google Pay',
        'amount_breakdown': const {'Bill Amount': 850, 'Total': 850},
        'customer_params': <dynamic>[],
      });
      await _pumpDetail(tester, entry);

      expect(find.text('Payment to'), findsOneWidget);
      expect(find.text('Consumer No'), findsOneWidget);
      // Rent-only labels must NOT leak into the electricity detail.
      expect(find.text('Fee Type'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Transaction History List — Rent & Service Title Mapping', () {
    testWidgets(
        'House Rent response with fee_type: "House Rent" -> history list displays House Rent',
        (tester) async {
      final entry = TransactionHistoryEntry.fromJson({
        'payment_status': 'SUCCESS',
        'payment_type': 'Rent',
        'fee_type': 'House Rent',
        'biller_name': 'Darshan Rajendra Nikam',
        'amount': '12000',
        'total_amount_charged': '12000',
        'transaction_time': '08 Oct 2026, 07:26am',
        'customer_params': [
          {'label': 'Recipient Name', 'value': 'Darshan Rajendra Nikam'},
        ],
      });

      await _pumpHistory(tester, [entry]);

      expect(find.text('House Rent'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Shop Rent response with fee_type: "Shop Rent" -> history list displays Shop Rent',
        (tester) async {
      final entry = TransactionHistoryEntry.fromJson({
        'payment_status': 'SUCCESS',
        'payment_type': 'Rent',
        'fee_type': 'Shop Rent',
        'biller_name': 'Darshan Rajendra Nikam',
        'amount': '15000',
        'total_amount_charged': '15000',
        'transaction_time': '08 Oct 2026, 07:26am',
        'customer_params': [
          {'label': 'Recipient Name', 'value': 'Darshan Rajendra Nikam'},
        ],
      });

      await _pumpHistory(tester, [entry]);

      expect(find.text('Shop Rent'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Existing Electricity/Mobile/etc. history titles remain unchanged',
        (tester) async {
      final electricity = TransactionHistoryEntry.fromJson({
        'payment_status': 'SUCCESS',
        'payment_type': 'Electricity Bill',
        'biller_name': 'MSEDCL',
        'amount': '850',
        'total_amount_charged': '850',
        'transaction_time': '08 Oct 2026, 07:26am',
      });
      final mobile = TransactionHistoryEntry.fromJson({
        'payment_status': 'SUCCESS',
        'payment_type': 'Mobile Recharge',
        'biller_name': 'Jio',
        'amount': '299',
        'total_amount_charged': '299',
        'transaction_time': '08 Oct 2026, 07:26am',
      });

      await _pumpHistory(tester, [electricity, mobile]);

      expect(find.text('Electricity Bill'), findsOneWidget);
      expect(find.text('Mobile Recharge'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('No hardcoded House Rent / Shop Rent in production code', () {
      const filesToCheck = [
        'lib/features/profile/views/transaction_history_screen.dart',
        'lib/features/profile/views/transaction_detail_screen.dart',
        'lib/features/profile/models/transaction_history_entry.dart',
      ];
      for (final filePath in filesToCheck) {
        final content = File(filePath).readAsStringSync();
        expect(content, isNot(contains("'House Rent'")), reason: filePath);
        expect(content, isNot(contains('"House Rent"')), reason: filePath);
        expect(content, isNot(contains("'Shop Rent'")), reason: filePath);
        expect(content, isNot(contains('"Shop Rent"')), reason: filePath);
      }
    });
  });

  group('Create-order request — dynamic fee_type (House + Shop Rent)', () {
    Future<Map<String, dynamic>?> captureCreateOrderBody(String feeType) async {
      final adapter = _CapturingAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final service = EducationFeesService(dio: dio);
      await service.createOrder(
        recipientName: 'Darshan Rajendra Nikam',
        accountNo: 'XXXXXX4455',
        ifsc: 'HDFC0001234',
        amount: 12000,
        feeType: feeType,
      );
      return adapter.capturedBody;
    }

    test('House Rent create-order sends fee_type: "House Rent"', () async {
      final body = await captureCreateOrderBody('House Rent');
      expect(body?['fee_type'], 'House Rent');
    });

    test('Shop Rent create-order sends fee_type: "Shop Rent"', () async {
      final body = await captureCreateOrderBody('Shop Rent');
      expect(body?['fee_type'], 'Shop Rent');
    });
  });
}
