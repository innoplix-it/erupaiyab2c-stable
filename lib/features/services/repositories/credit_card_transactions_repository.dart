import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../constants/api_constants.dart';
import '../../../services/dio_service.dart';
import '../../../services/logger_service.dart';
import '../models/credit_card_transaction.dart';

class CreditCardTransactionsRepository {
  CreditCardTransactionsRepository({Dio? dio})
      : _dio = dio ?? DioService.instance.client;

  final Dio _dio;

  Future<CreditCardTransactionsResponse> fetchTransactions({
    required String maskedIdentifier,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.creditCardTransactionsEndpoint,
        queryParameters: {
          'masked_identifier': maskedIdentifier,
          'page': page,
          'limit': limit,
        },
      );
      final payload = response.data;
      Map<String, dynamic> json;
      if (payload is String) {
        json = jsonDecode(payload) as Map<String, dynamic>;
      } else if (payload is Map<String, dynamic>) {
        json = payload;
      } else {
        json = Map<String, dynamic>.from(payload as Map);
      }
      return CreditCardTransactionsResponse.fromJson(json);
    } catch (e) {
      logger.error('Failed to fetch credit card transactions: $e', error: e);
      rethrow;
    }
  }
}

class CreditCardTransactionsResponse {
  CreditCardTransactionsResponse({
    required this.success,
    required this.message,
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalRecords,
  });

  factory CreditCardTransactionsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    List<CreditCardTransaction> items = <CreditCardTransaction>[];
    if (data is List) {
      items = data
          .whereType<Map<String, dynamic>>()
          .map(CreditCardTransaction.fromJson)
          .toList();
    } else if (data is Map<String, dynamic>) {
      final list = data['items'] ?? data['transactions'] ?? data['data'];
      if (list is List) {
        items = list
            .whereType<Map<String, dynamic>>()
            .map(CreditCardTransaction.fromJson)
            .toList();
      }
    }

    final pagination = (json['pagination'] as Map<String, dynamic>?) ??
        ((data is Map<String, dynamic>)
            ? (data['pagination'] as Map<String, dynamic>?)
            : null) ??
        {};

    int parseInt(dynamic val, int defaultVal) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? defaultVal;
      return defaultVal;
    }

    final currentPage = parseInt(
      pagination['current_page'] ?? json['current_page'] ?? json['page'],
      1,
    );
    final totalPages = parseInt(
      pagination['total_pages'] ?? json['total_pages'] ?? json['totalPages'],
      1,
    );
    final totalRecords = parseInt(
      pagination['total_records'] ??
          json['total_records'] ??
          json['totalRecords'] ??
          json['total'],
      items.length,
    );

    return CreditCardTransactionsResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      items: items,
      currentPage: currentPage,
      totalPages: totalPages,
      totalRecords: totalRecords,
    );
  }

  final bool success;
  final String message;
  final List<CreditCardTransaction> items;
  final int currentPage;
  final int totalPages;
  final int totalRecords;
}
