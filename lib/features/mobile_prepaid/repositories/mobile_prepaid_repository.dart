import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';

import '../../../constants/api_constants.dart';
import '../../../services/dio_service.dart';
import '../../../services/logger_service.dart';
import '../../home/models/banner_model.dart';
import '../models/latest_transaction.dart';
import '../models/my_number_info.dart';
import '../models/operator_info.dart';
import '../models/operator_option.dart';
import '../models/plan_item.dart';
import '../models/prepaid_plans_response.dart';
import '../models/prepaid_transaction_status.dart';
import '../models/recharge_order_result.dart';
import '../models/region_option.dart';

class MobilePrepaidRepository {
  MobilePrepaidRepository({Dio? dio})
      : _dio = dio ?? DioService.instance.client;

  final Dio _dio;
  final Random _random = Random.secure();

  Never _throwApiMessage(DioException e, {String fallback = 'Request failed'}) {
    final data = e.response?.data;
    if (data is Map) {
      final direct = data['message']?.toString().trim();
      if (direct != null && direct.isNotEmpty) {
        throw Exception(direct);
      }
      final messages = data['messages'];
      if (messages is Map) {
        final nested =
            (messages['error'] ?? messages['message'] ?? '').toString().trim();
        if (nested.isNotEmpty) {
          throw Exception(nested);
        }
      }
    }
    throw Exception(fallback);
  }

  Future<List<BannerModel>> fetchMobilePrepaidBanners({
    String lang = 'en',
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.pageEndpoint('mobile-prepaid'),
        queryParameters: {'lang': lang},
      );
      final raw = response.data;
      final Map<String, dynamic> payload;
      if (raw is Map<String, dynamic>) {
        payload = raw;
      } else if (raw is String) {
        payload = jsonDecode(raw) as Map<String, dynamic>;
      } else {
        payload = Map<String, dynamic>.from(raw as Map);
      }

      final ok = (payload['success'] == true) || (payload['status'] == true);
      if (!ok) {
        final message =
            payload['message'] as String? ?? 'Failed to fetch banners';
        throw Exception(message);
      }

      final dataMap = payload['data'] as Map<String, dynamic>? ?? {};
      final list = dataMap['banners'];
      if (list is! List) return const <BannerModel>[];
      return list
          .whereType<Map<String, dynamic>>()
          .map(BannerModel.fromJson)
          .toList();
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch mobile prepaid banners',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<MyNumberInfo> fetchMyNumber({
    required String number,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.rechargeMyNumberEndpoint,
        queryParameters: {'number': number},
      );
      final raw = response.data;
      final Map<String, dynamic> payload;
      if (raw is Map<String, dynamic>) {
        payload = raw;
      } else if (raw is String) {
        payload = jsonDecode(raw) as Map<String, dynamic>;
      } else {
        payload = Map<String, dynamic>.from(raw as Map);
      }

      final ok = (payload['success'] == true) || (payload['status'] == true);
      if (!ok) {
        final message =
            payload['message'] as String? ?? 'Failed to fetch my number';
        throw Exception(message);
      }

      final data = payload['data'];
      Map<String, dynamic>? dataMap;
      if (data is Map) {
        dataMap = Map<String, dynamic>.from(data);
      } else if (data is List && data.isNotEmpty && data.first is Map) {
        dataMap = Map<String, dynamic>.from(data.first as Map);
      }
      if (dataMap != null) {
        final info = MyNumberInfo.fromJson(dataMap);
        if (info.number.trim().isNotEmpty) return info;
        return MyNumberInfo(
          number: number,
          operatorName: info.operatorName,
          operatorIcon: info.operatorIcon,
          lastOn: info.lastOn,
          dueLabel: info.dueLabel,
          dueDate: info.dueDate,
          dueStatus: info.dueStatus,
          dueAmount: info.dueAmount,
        );
      }
      return MyNumberInfo(number: number);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch my number',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<OperatorInfo> checkOperator({required String mobile}) async {
    try {
      final response = await _dio.post(
        ApiConstants.prepaidCheckOperatorEndpoint,
        data: {'mobile': mobile},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      final payload = _normalizePayload(response.data);
      final data = payload['data'] as Map<String, dynamic>? ?? {};
      return OperatorInfo.fromJson(data);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to check operator',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<PrepaidPlansResponse> fetchPlans({
    required String mobile,
    required String operatorName,
    required String circleCode,
    String search = '',
    List<String> filters = const [],
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final normalizedFilters =
          filters.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final trimmedSearch = search.trim();
      final response = await _dio.post(
        ApiConstants.prepaidFetchPlansEndpoint,
        data: {
          'mobile': mobile,
          'operator': operatorName,
          'circlecode': circleCode,
          'page': page,
          'limit': limit,
          if (trimmedSearch.isNotEmpty) 'search': trimmedSearch,
          if (normalizedFilters.isNotEmpty)
            'filter': normalizedFilters.length == 1
                ? normalizedFilters.first
                : jsonEncode(normalizedFilters),
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      final payload = _normalizePayload(response.data);
      final data = payload['data'] as Map<String, dynamic>? ?? {};

      final filtersMap = payload['filters'] as Map<String, dynamic>? ?? {};
      final pagination = payload['pagination'] as Map<String, dynamic>? ?? {};
      final validityFilters = (filtersMap['validity'] is List)
          ? (filtersMap['validity'] as List).map((e) => e.toString()).toList()
          : const <String>[];
      final dataFilters = (filtersMap['data'] is List)
          ? (filtersMap['data'] as List).map((e) => e.toString()).toList()
          : const <String>[];
      final filterTags = (payload['filterTags'] is List)
          ? (payload['filterTags'] as List).map((e) => e.toString()).toList()
          : normalizedFilters;
      final ecoinsRestrictionsPercent =
          double.tryParse((payload['ecoins_restrictions'] ?? '').toString());
      final hasPagination = pagination.isNotEmpty;
      final currentPage = _parseInt(pagination['current_page']) ?? page;
      final resolvedLimit = _parseInt(pagination['limit']) ?? limit;
      final totalRecords = _parseInt(pagination['total_records']) ?? 0;
      final totalPages = _parseInt(pagination['total_pages']) ?? 1;

      final result = <String, List<PlanItem>>{};
      var totalPlansCount = 0;
      data.forEach((key, value) {
        if (value is List) {
          final plans = value
              .map((item) =>
                  PlanItem.fromJson(item as Map<String, dynamic>? ?? {}))
              .toList();
          result[key] = plans;
          totalPlansCount += plans.length;
        }
      });
      return PrepaidPlansResponse(
        plansByCategory: result,
        validityFilters: validityFilters,
        dataFilters: dataFilters,
        filterTags: filterTags,
        currentPage: currentPage,
        totalPages: totalPages,
        totalRecords: totalRecords,
        limit: resolvedLimit,
        hasMorePages: hasPagination
            ? currentPage < totalPages
            : totalPlansCount >= resolvedLimit,
        ecoinsRestrictionsPercent: ecoinsRestrictionsPercent,
      );
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch plans',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  Future<List<OperatorOption>> fetchOperators() async {
    try {
      final response = await _dio.get(
        ApiConstants.prepaidFetchOperatorsEndpoint,
      );
      final payload = _normalizePayload(response.data);
      final data = payload['data'] as Map<String, dynamic>? ?? {};
      final operators = data['operators'];
      if (operators is List) {
        return operators
            .map((item) =>
                OperatorOption.fromJson(item as Map<String, dynamic>? ?? {}))
            .toList();
      }
      return [];
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch operators',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<RegionOption>> fetchRegions() async {
    try {
      final response = await _dio.get(
        ApiConstants.prepaidFetchRegionsEndpoint,
      );
      final payload = _normalizePayload(response.data);
      final data = payload['data'] as Map<String, dynamic>? ?? {};
      final regions = data['regions'];
      if (regions is List) {
        return regions
            .map((item) =>
                RegionOption.fromJson(item as Map<String, dynamic>? ?? {}))
            .toList();
      }
      return [];
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch regions',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<RechargeOrderResult> createRechargeOrder({
    required String mobile,
    required int amount,
    required String operatorName,
    required String desc,
    bool useWallet = false,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.rechargeCreateOrderEndpoint,
        data: {
          'mobile': mobile,
          'amount': amount.toDouble().toStringAsFixed(2),
          'operator': operatorName,
          'use_wallet': useWallet ? 1 : 0,
          'desc': desc,
          'idempotency_key': _generateUuid(),
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return RechargeOrderResult.fromJson(payload);
    } on DioException catch (e, stackTrace) {
      if (e.type == DioExceptionType.badResponse) {
        _throwApiMessage(e,
            fallback: 'Failed to create order. Please try again.');
      }
      logger.error(
        'Failed to create recharge order',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      logger.error(
        'Failed to create recharge order',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  String _generateUuid() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String toHex(int value) => value.toRadixString(16).padLeft(2, '0');
    final hex = bytes.map(toHex).toList();

    return '${hex.sublist(0, 4).join()}'
        '${hex.sublist(4, 6).join()}-'
        '${hex.sublist(6, 8).join()}-'
        '${hex.sublist(8, 10).join()}-'
        '${hex.sublist(10, 16).join()}';
  }

  Future<PrepaidTransactionStatus> fetchTransactionStatus({
    required String transactionId,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.transactionStatusEndpoint(transactionId),
        options: Options(
          validateStatus: (status) => status != null && status < 600,
        ),
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return PrepaidTransactionStatus.fromJson(payload);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch prepaid transaction status',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<PrepaidTransactionStatus> fetchRechargeStatus({
    required String transactionId,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.rechargeStatusEndpoint(transactionId),
        options: Options(
          validateStatus: (status) => status != null && status < 600,
        ),
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return PrepaidTransactionStatus.fromJson(payload);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch recharge status',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<LatestTransaction>> fetchLatestTransactions({
    required String service,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.latestTransactionsEndpoint(service: service),
      );
      final payload = _normalizePayload(response.data);
      final data = payload['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => LatestTransaction.fromJson(
                  e.map((key, value) => MapEntry(key.toString(), value)),
                ))
            .toList();
      }
      if (data is List<dynamic>) {
        return data
            .map((e) =>
                LatestTransaction.fromJson(e as Map<String, dynamic>? ?? {}))
            .toList();
      }
      return [];
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch latest transactions',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Map<String, dynamic> _normalizePayload(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) {
          return decoded.map(
            (key, value) => MapEntry(key.toString(), value),
          );
        }
      } catch (_) {
        return {};
      }
    }
    return {};
  }
}
