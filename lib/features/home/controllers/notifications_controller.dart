import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/notification_item.dart';
import '../repositories/notifications_repository.dart';

class NotificationsState {
  const NotificationsState({
    this.isLoading = false,
    this.isFetchingMore = false,
    this.notifications = const [],
    this.unreadCount = 0,
    this.currentPage = 1,
    this.totalPages = 1,
    this.limit = 20,
    this.errorMessage,
  });

  final bool isLoading;
  final bool isFetchingMore;
  final List<NotificationItem> notifications;
  final int unreadCount;
  final int currentPage;
  final int totalPages;
  final int limit;
  final String? errorMessage;

  bool get hasMore => currentPage < totalPages;

  NotificationsState copyWith({
    bool? isLoading,
    bool? isFetchingMore,
    List<NotificationItem>? notifications,
    int? unreadCount,
    int? currentPage,
    int? totalPages,
    int? limit,
    String? errorMessage,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      limit: limit ?? this.limit,
      errorMessage: errorMessage,
    );
  }
}

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) => NotificationsRepository());

final notificationsControllerProvider =
    StateNotifierProvider.autoDispose<
        NotificationsController,
        NotificationsState>(
  (ref) => NotificationsController(
    repository: ref.watch(notificationsRepositoryProvider),
  ),
);

class NotificationsController extends StateNotifier<NotificationsState> {
  NotificationsController({required NotificationsRepository repository})
      : _repository = repository,
        super(const NotificationsState());

  final NotificationsRepository _repository;

  Future<void> fetchNotifications({bool force = false}) async {
    if (state.isLoading && !force) return;
    state = state.copyWith(
      isLoading: true,
      isFetchingMore: false,
      notifications: const [],
      currentPage: 1,
      totalPages: 1,
      errorMessage: null,
    );
    try {
      final page = await _repository.fetchNotifications(page: 1, limit: state.limit);
      state = state.copyWith(
        isLoading: false,
        notifications: [...page.notifications, ...page.updates],
        unreadCount: page.unreadCount,
        currentPage: page.currentPage,
        totalPages: page.totalPages,
        limit: page.limit,
        errorMessage: null,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load notifications. Please try again.',
      );
    }
  }

  /// Clears the already-read notifications server-side via the repository.
  /// On success the feed is refreshed through the existing pattern, so the
  /// list and unread count always reflect the server state. On failure the
  /// current state is left untouched. Returns whether the clear succeeded.
  Future<bool> clearReadNotifications() async {
    final ok = await _repository.clearReadNotifications();
    if (ok) {
      await fetchNotifications(force: true);
    }
    return ok;
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || state.isFetchingMore || !state.hasMore) return;
    state = state.copyWith(isFetchingMore: true, errorMessage: null);
    try {
      final nextPage = state.currentPage + 1;
      final page = await _repository.fetchNotifications(
        page: nextPage,
        limit: state.limit,
      );
      state = state.copyWith(
        isFetchingMore: false,
        notifications: [...state.notifications, ...page.notifications, ...page.updates],
        unreadCount: page.unreadCount,
        currentPage: page.currentPage,
        totalPages: page.totalPages,
        limit: page.limit,
        errorMessage: null,
      );
    } catch (_) {
      state = state.copyWith(
        isFetchingMore: false,
        errorMessage: 'Failed to load more notifications.',
      );
    }
  }
}
