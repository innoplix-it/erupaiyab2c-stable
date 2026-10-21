import 'package:dio/dio.dart';

import '../../../constants/api_constants.dart';
import '../../../services/dio_service.dart';
import '../../../services/logger_service.dart';

class ReferralTrackRepository {
  ReferralTrackRepository({Dio? dio})
      : _dio = dio ?? DioService.instance.client;

  final Dio _dio;

  Future<ReferralTrackResponse> fetchTrack() async {
    try {
      final response = await _dio.get(ApiConstants.referralTrackEndpoint);
      final payload = response.data as Map<String, dynamic>? ?? {};
      return ReferralTrackResponse.fromJson(payload);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch referral track data',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

class ReferralTrackResponse {
  const ReferralTrackResponse({
    required this.status,
    required this.totalReferrals,
    required this.thisMonthEarnings,
    required this.referrals,
  });

  factory ReferralTrackResponse.fromJson(Map<String, dynamic> json) {
    final referrals = json['my_referrals'] as List<dynamic>? ?? [];
    return ReferralTrackResponse(
      status: json['status'] == true,
      totalReferrals: _parseInt(json['total_referrals']),
      thisMonthEarnings: _parseInt(json['this_month_earnings']),
      referrals: referrals
          .whereType<Map<String, dynamic>>()
          .map(ReferralUser.fromJson)
          .toList(),
    );
  }

  final bool status;
  final int totalReferrals;
  final int thisMonthEarnings;
  final List<ReferralUser> referrals;
}

class ReferralUser {
  const ReferralUser({
    required this.name,
    required this.since,
    required this.commission,
    this.badge,
  });

  factory ReferralUser.fromJson(Map<String, dynamic> json) {
    return ReferralUser(
      name: (json['name'] ?? '').toString(),
      since: (json['since'] ?? '').toString(),
      commission: _parseInt(json['commission']),
      badge: (json['badge'] ?? '').toString().trim().isEmpty
          ? null
          : (json['badge'] ?? '').toString(),
    );
  }

  final String name;
  final String since;
  final int commission;
  final String? badge;
}

int _parseInt(dynamic raw) {
  if (raw == null) return 0;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw.toString()) ?? 0;
}
