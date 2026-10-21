import 'package:dio/dio.dart';

import '../../../constants/api_constants.dart';
import '../../../services/dio_service.dart';
import '../../../services/logger_service.dart';

class ReferralRepository {
  ReferralRepository({Dio? dio}) : _dio = dio ?? DioService.instance.client;

  final Dio _dio;

  Future<ReferralLinkResponse> generateLink() async {
    try {
      final response =
          await _dio.post(ApiConstants.referralGenerateLinkEndpoint);
      final payload = response.data as Map<String, dynamic>? ?? {};
      return ReferralLinkResponse.fromJson(payload);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to generate referral link',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<ReferralRegisterResponse> registerReferral({
    required String newUserId,
    required String referralCode,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.referralRegisterEndpoint,
        data: {
          'new_user_id': newUserId,
          'referral_code': referralCode,
        },
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      return ReferralRegisterResponse.fromJson(payload);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to register referral',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

class ReferralLinkResponse {
  const ReferralLinkResponse({
    required this.status,
    required this.referralCode,
    required this.referralLink,
    this.rewardCoins,
  });

  factory ReferralLinkResponse.fromJson(Map<String, dynamic> json) {
    // Some backends wrap the payload under `data`.
    final root = (json['data'] is Map)
        ? (json['data'] as Map).map((k, v) => MapEntry(k.toString(), v))
        : json;
    return ReferralLinkResponse(
      status: root['status'] == true || json['status'] == true,
      referralCode:
          (root['referral_code'] ?? json['referral_code'] ?? '').toString(),
      referralLink:
          (root['referral_link'] ?? json['referral_link'] ?? '').toString(),
      rewardCoins: _parseOptionalInt(
        root['reward_coins'] ??
            root['rewardCoins'] ??
            root['ecoins'] ??
            root['e_coins'] ??
            root['referral_reward_coins'] ??
            root['referral_ecoins'] ??
            root['coins_per_referral'] ??
            json['reward_coins'] ??
            json['rewardCoins'] ??
            json['ecoins'],
      ),
    );
  }

  final bool status;
  final String referralCode;
  final String referralLink;

  /// Per-referral eCoins reward from generate-link when the backend sends it.
  final int? rewardCoins;
}

int? _parseOptionalInt(dynamic raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toInt();
  final parsed = int.tryParse(raw.toString().trim());
  return parsed;
}

class ReferralRegisterResponse {
  const ReferralRegisterResponse({
    required this.status,
    required this.message,
  });

  factory ReferralRegisterResponse.fromJson(Map<String, dynamic> json) {
    return ReferralRegisterResponse(
      status: json['status'] == true,
      message: (json['message'] ?? '').toString(),
    );
  }

  final bool status;
  final String message;
}
