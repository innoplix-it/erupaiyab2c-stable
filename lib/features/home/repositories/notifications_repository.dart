import 'package:dio/dio.dart';

import '../../../constants/api_constants.dart';
import '../../../services/dio_service.dart';
import '../../../services/logger_service.dart';
import '../models/notifications_feed.dart';
import '../models/notification_item.dart';

class NotificationsRepository {
  NotificationsRepository({Dio? dio})
      : _dio = dio ?? DioService.instance.client;

  final Dio _dio;

  Future<NotificationsFeed> fetchNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.notificationsEndpoint,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      final unread = _parseCount(payload['unread_count']) ?? 0;
      final pagination = payload['pagination'] as Map<String, dynamic>? ?? {};
      final currentPage = _parseCount(pagination['current_page']) ?? page;
      final resolvedLimit = _parseCount(pagination['limit']) ?? limit;
      final totalRecords = _parseCount(pagination['total_records']) ?? 0;
      final totalPages = _parseCount(pagination['total_pages']) ?? 1;

      final updatesRaw = payload['updates'];
      final notificationsRaw = payload['notifications'];
      if (updatesRaw is List || notificationsRaw is List) {
        final updates = (updatesRaw is List ? updatesRaw : const [])
            .whereType<Map<String, dynamic>>()
            .map(NotificationItem.fromApi)
            .toList();
        final notifications = (notificationsRaw is List ? notificationsRaw : const [])
            .whereType<Map<String, dynamic>>()
            .map(NotificationItem.fromApi)
            .toList();
        return NotificationsFeed(
          unreadCount: unread,
          updates: updates,
          notifications: notifications,
          currentPage: currentPage,
          totalPages: totalPages,
          limit: resolvedLimit,
          totalRecords: totalRecords,
        );
      }

      // Backward compatibility: older API under `data: []`.
      final data = payload['data'];
      if (data is List) {
        final items = data
            .whereType<Map<String, dynamic>>()
            .map(NotificationItem.fromApi)
            .toList();
        final computedUnread =
            unread > 0 ? unread : items.where((n) => !n.isRead).length;
        return NotificationsFeed(
          unreadCount: computedUnread,
          updates: const [],
          notifications: items,
          currentPage: currentPage,
          totalPages: totalPages,
          limit: resolvedLimit,
          totalRecords: totalRecords,
        );
      }

      return NotificationsFeed(
        unreadCount: 0,
        updates: const [],
        notifications: const [],
        currentPage: currentPage,
        totalPages: totalPages,
        limit: resolvedLimit,
        totalRecords: totalRecords,
      );
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch notifications',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<int> fetchUnreadCount() async {
    try {
      final feed = await fetchNotifications();
      return feed.unreadCount;
    } catch (e, stackTrace) {
      logger.error(
        'Failed to fetch notification count',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<bool> markNotificationRead(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return false;
    try {
      final response =
          await _dio.post(ApiConstants.notificationReadEndpoint(trimmed));
      final payload = response.data as Map<String, dynamic>? ?? {};
      final success = payload['success'];
      if (success is bool) return success;
      return success?.toString().toLowerCase() == 'true';
    } catch (e, stackTrace) {
      logger.error(
        'Failed to mark notification read',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Deletes the already-read notifications server-side
  /// (`POST api/notification/clear-read`). No request body: the endpoint
  /// takes no parameters. Response `success` is parsed with the same
  /// pattern as the sibling notification mutations above.
  Future<bool> clearReadNotifications() async {
    try {
      final response =
          await _dio.post(ApiConstants.notificationClearReadEndpoint);
      final payload = response.data as Map<String, dynamic>? ?? {};
      final success = payload['success'];
      if (success is bool) return success;
      return success?.toString().toLowerCase() == 'true';
    } catch (e, stackTrace) {
      logger.error(
        'Failed to clear read notifications',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// `POST api/notification/delete` with `{"notification_id": "<id>"}`.
  Future<bool> deleteNotification(String notificationId) async {
    final trimmed = notificationId.trim();
    if (trimmed.isEmpty) return false;
    try {
      final response = await _dio.post(
        ApiConstants.notificationDeleteEndpoint,
        data: {'notification_id': trimmed},
        options: Options(contentType: Headers.jsonContentType),
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      final success = payload['success'];
      if (success is bool) return success;
      return success?.toString().toLowerCase() == 'true';
    } catch (e, stackTrace) {
      logger.error(
        'Failed to delete notification',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<bool> remindMeLater(String notificationId) async {
    final trimmed = notificationId.trim();
    if (trimmed.isEmpty) return false;
    try {
      final response = await _dio.post(
        ApiConstants.notificationRemindMeLaterEndpoint,
        data: {'notification_id': trimmed},
      );
      final payload = response.data as Map<String, dynamic>? ?? {};
      final success = payload['success'];
      if (success is bool) return success;
      return success?.toString().toLowerCase() == 'true';
    } catch (e, stackTrace) {
      logger.error(
        'Failed to remind me later',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}

int? _parseCount(dynamic raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw.toString());
}
