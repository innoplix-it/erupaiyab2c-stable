import 'package:dio/dio.dart';

import '../../../constants/api_constants.dart';
import '../../../helpers/date_helpers.dart';
import '../../../services/dio_service.dart';
import '../../../services/logger_service.dart';
import '../models/transaction_history_entry.dart';
import '../models/transaction_history_page.dart';

class TransactionHistoryRepository {
  TransactionHistoryRepository({Dio? dio})
      : _dio = dio ?? DioService.instance.client;

  final Dio _dio;

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
    try {
      final query = <String, dynamic>{};
      if (fromDate != null && toDate != null) {
        query['from_date'] = DateHelpers.formatYmd(fromDate);
        query['to_date'] = DateHelpers.formatYmd(toDate);
      } else if (month != null && month.isNotEmpty) {
        query['month'] = month;
      } else if (lastYears != null) {
        query['last_years'] = lastYears;
      } else if (days != null) {
        query['days'] = days;
      }
      if (status != null && status.isNotEmpty) {
        query['status'] = status;
      }
      if (service != null && service.isNotEmpty) {
        query['service'] = service;
      }
      if (paymentType != null && paymentType.isNotEmpty) {
        query['payment_type'] = paymentType;
      }
      if (minAmount != null) {
        query['min_amount'] = minAmount.toStringAsFixed(0);
      }
      if (maxAmount != null) {
        query['max_amount'] = maxAmount.toStringAsFixed(0);
      }
      if (consumerId != null && consumerId.isNotEmpty) {
        query['consumer_id'] = consumerId;
        query['customer_number'] = consumerId;
        query['service_no'] = consumerId;
        // Backend's canonical full consumer-number field (the same key both
        // transaction models parse back from responses). Without it the API
        // falls back to looser matching and leaks unrelated service
        // transactions into View History results.
        query['service_no_full'] = consumerId;
      }

      query['page'] = page;
      query['limit'] = limit;

      final response = await _dio.get(
        ApiConstants.prepaidTransactionHistoryEndpoint,
        queryParameters: query,
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return TransactionHistoryPage.fromJson(payload);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch transaction history page',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

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
    try {
      final query = <String, dynamic>{};
      if (fromDate != null && toDate != null) {
        query['from_date'] = DateHelpers.formatYmd(fromDate);
        query['to_date'] = DateHelpers.formatYmd(toDate);
      } else if (month != null && month.isNotEmpty) {
        query['month'] = month;
      } else if (lastYears != null) {
        query['last_years'] = lastYears;
      } else if (days != null) {
        query['days'] = days;
      }
      if (status != null && status.isNotEmpty) {
        query['status'] = status;
      }
      if (service != null && service.isNotEmpty) {
        query['service'] = service;
      }
      if (paymentType != null && paymentType.isNotEmpty) {
        query['payment_type'] = paymentType;
      }
      if (minAmount != null) {
        query['min_amount'] = minAmount.toStringAsFixed(0);
      }
      if (maxAmount != null) {
        query['max_amount'] = maxAmount.toStringAsFixed(0);
      }
      if (consumerId != null && consumerId.isNotEmpty) {
        query['consumer_id'] = consumerId;
        query['customer_number'] = consumerId;
        query['service_no'] = consumerId;
        // See fetchHistoryPage: keep the exact biller scope server-side.
        query['service_no_full'] = consumerId;
      }
      if (page != null) query['page'] = page;
      if (limit != null) query['limit'] = limit;

      final response = await _dio.get(
        ApiConstants.prepaidTransactionHistoryEndpoint,
        queryParameters: query,
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      final data = payload['data'];
      if (data is List) {
        return data
            .map((item) => TransactionHistoryEntry.fromJson(
                item as Map<String, dynamic>? ?? {}))
            .toList();
      }
      return [];
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch transaction history',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
