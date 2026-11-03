import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../constants/api_constants.dart';
import '../../../services/dio_service.dart';
import '../../../services/logger_service.dart';

class BankAccountsRepository {
  BankAccountsRepository({Dio? dio}) : _dio = dio ?? DioService.instance.client;

  final Dio _dio;

  Future<List<BankAccountEntry>> fetchAccounts() async {
    try {
      final response = await _dio.get(ApiConstants.bankAccountsEndpoint);
      final payload = _asMap(response.data);
      final data = payload['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(BankAccountEntry.fromJson)
            .toList();
      }
      return const <BankAccountEntry>[];
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch bank accounts',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<BankDeleteResponse> deleteBank({
    required int bankId,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.bankDeleteEndpoint,
        data: {
          'bank_id': bankId,
        },
      );
      final payload = _asMap(response.data);
      return BankDeleteResponse.fromJson(payload);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to delete bank account',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

class BankDeleteResponse {
  const BankDeleteResponse({
    required this.status,
    required this.message,
  });

  factory BankDeleteResponse.fromJson(Map<String, dynamic> json) {
    return BankDeleteResponse(
      status: json['status'] == true,
      message: (json['message'] ?? '').toString(),
    );
  }

  final bool status;
  final String message;
}

class BankAccountEntry {
  const BankAccountEntry({
    this.id,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolderName,
    required this.verified,
    this.ifsc,
    this.referenceId,
    this.bankLogo,
  });

  factory BankAccountEntry.fromJson(Map<String, dynamic> json) {
    return BankAccountEntry(
      id: json['bank_id'] is int
          ? json['bank_id'] as int
          : int.tryParse(json['bank_id']?.toString() ?? ''),
      bankName: (json['bank_name'] ?? '').toString(),
      accountNumber: (json['account_number'] ?? '').toString(),
      accountHolderName: (json['account_holder_name'] ?? '').toString(),
      verified: json['verified'] == true,
      ifsc: (json['ifsc'] ?? '').toString(),
      referenceId: (json['reference_id'] ?? '').toString(),
      bankLogo: (json['bank_logo'] ??
              json['bank_icon'] ??
              json['logo'] ??
              json['image_url'] ??
              '')
          .toString(),
    );
  }

  final int? id;
  final String bankName;
  final String accountNumber;
  final String accountHolderName;
  final bool verified;
  final String? ifsc;
  final String? referenceId;
  final String? bankLogo;
}

Map<String, dynamic> _asMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is String && data.isNotEmpty) {
    final decoded = jsonDecode(data);
    if (decoded is Map<String, dynamic>) return decoded;
  }
  return <String, dynamic>{};
}
