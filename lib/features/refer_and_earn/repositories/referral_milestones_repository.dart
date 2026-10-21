import 'package:dio/dio.dart';

import '../../../constants/api_constants.dart';
import '../../../services/dio_service.dart';
import '../../../services/logger_service.dart';

class ReferralMilestonesRepository {
  ReferralMilestonesRepository({Dio? dio})
      : _dio = dio ?? DioService.instance.client;

  final Dio _dio;

  Future<ReferralMilestonesResponse> fetchMilestones() async {
    try {
      final response = await _dio.get(ApiConstants.referralMilestonesEndpoint);
      final payload = response.data as Map<String, dynamic>? ?? {};
      return ReferralMilestonesResponse.fromJson(payload);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch referral milestones',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

class ReferralMilestonesResponse {
  const ReferralMilestonesResponse({
    required this.status,
    required this.totalReferrals,
    required this.milestones,
  });

  factory ReferralMilestonesResponse.fromJson(Map<String, dynamic> json) {
    final milestones = json['milestones'] as List<dynamic>? ?? [];
    return ReferralMilestonesResponse(
      status: json['status'] == true,
      totalReferrals: _parseInt(json['total_referrals']),
      milestones: milestones
          .whereType<Map<String, dynamic>>()
          .map(ReferralMilestoneItem.fromJson)
          .toList(),
    );
  }

  final bool status;
  final int totalReferrals;
  final List<ReferralMilestoneItem> milestones;
}

class ReferralMilestoneItem {
  const ReferralMilestoneItem({
    required this.title,
    required this.reward,
    required this.progressText,
    required this.progressCurrent,
    required this.progressTarget,
    required this.completed,
    required this.status,
  });

  factory ReferralMilestoneItem.fromJson(Map<String, dynamic> json) {
    return ReferralMilestoneItem(
      title: (json['title'] ?? '').toString(),
      reward: (json['reward'] ?? '').toString(),
      progressText: (json['progress_text'] ?? '').toString(),
      progressCurrent: _parseInt(json['progress_current']),
      progressTarget: _parseInt(json['progress_target']),
      completed: json['completed'] == true,
      status: (json['status'] ?? '').toString(),
    );
  }

  final String title;
  final String reward;
  final String progressText;
  final int progressCurrent;
  final int progressTarget;
  final bool completed;
  final String status;
}

int _parseInt(dynamic raw) {
  if (raw == null) return 0;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw.toString()) ?? 0;
}
