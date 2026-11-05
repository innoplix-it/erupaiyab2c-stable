import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../utils/error_message_utils.dart';
import '../../../services/logger_service.dart';
import '../repositories/education_fees_repository.dart';

final tutorReceivedRequestsRepositoryProvider =
    Provider<EducationFeesRepository>(
  (ref) => EducationFeesRepository(),
);

final tutorReceivedRequestsControllerProvider = StateNotifierProvider<
    TutorReceivedRequestsController, TutorReceivedRequestsState>(
  (ref) => TutorReceivedRequestsController(
    repository: ref.watch(tutorReceivedRequestsRepositoryProvider),
  ),
);

class TutorReceivedRequestsState {
  const TutorReceivedRequestsState({
    this.requests = const [],
    this.isLoading = false,
    this.errorMessage,
    this.currentPage = 1,
    this.perPage = 20,
    this.total = 0,
    this.totalPages = 0,
    this.hasMore = false,
  });

  final List<Map<String, dynamic>> requests;
  final bool isLoading;
  final String? errorMessage;
  final int currentPage;
  final int perPage;
  final int total;
  final int totalPages;
  final bool hasMore;

  TutorReceivedRequestsState copyWith({
    List<Map<String, dynamic>>? requests,
    bool? isLoading,
    Object? errorMessage,
    int? currentPage,
    int? perPage,
    int? total,
    int? totalPages,
    bool? hasMore,
  }) {
    return TutorReceivedRequestsState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage == null ? this.errorMessage : errorMessage as String?,
      currentPage: currentPage ?? this.currentPage,
      perPage: perPage ?? this.perPage,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class TutorReceivedRequestsController
    extends StateNotifier<TutorReceivedRequestsState> {
  TutorReceivedRequestsController({required EducationFeesRepository repository})
      : _repository = repository,
        super(const TutorReceivedRequestsState());

  final EducationFeesRepository _repository;

  /// Fetch pending tutor requests.
  Future<void> fetchPendingRequests({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    final page = refresh ? 1 : state.currentPage;
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      currentPage: refresh ? 1 : state.currentPage,
    );

    try {
      final response = await _repository.fetchTutorReceivedRequests(
        page: page,
        perPage: state.perPage,
        status: 'PENDING',
      );

      if (response.status && response.data != null) {
        final newRequests = response.data!.requests;
        final pagination = response.data!.pagination;

        state = state.copyWith(
          requests: refresh ? newRequests : [...state.requests, ...newRequests],
          isLoading: false,
          currentPage: pagination?.page ?? page,
          total: pagination?.total ?? 0,
          totalPages: pagination?.totalPages ?? 0,
          hasMore: (pagination?.page ?? 0) < (pagination?.totalPages ?? 0),
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message ?? 'Failed to fetch requests',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: ErrorMessageUtils.from(
          e,
          fallback: 'Failed to fetch requests. Please try again.',
        ),
      );
    }
  }

  /// Load more requests (pagination).
  Future<void> loadMoreRequests() async {
    if (state.isLoading || !state.hasMore) return;

    final nextPage = state.currentPage + 1;
    state = state.copyWith(
      isLoading: true,
      currentPage: nextPage,
    );

    try {
      final response = await _repository.fetchTutorReceivedRequests(
        page: nextPage,
        perPage: state.perPage,
        status: 'PENDING',
      );

      if (response.status && response.data != null) {
        final newRequests = response.data!.requests;
        final pagination = response.data!.pagination;

        state = state.copyWith(
          requests: [...state.requests, ...newRequests],
          isLoading: false,
          currentPage: pagination?.page ?? nextPage,
          total: pagination?.total ?? state.total,
          totalPages: pagination?.totalPages ?? state.totalPages,
          hasMore: (pagination?.page ?? 0) < (pagination?.totalPages ?? 0),
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message ?? 'Failed to load more requests',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: ErrorMessageUtils.from(
          e,
          fallback: 'Failed to load more requests. Please try again.',
        ),
      );
    }
  }

  /// Respond to a tutor request (ACCEPT or REJECT).
  Future<bool> respondToRequest({
    required String requestReference,
    required String action,
  }) async {
    try {
      final response = await _repository.respondToTutorRequest(
        requestReference: requestReference,
        action: action,
      );

      if (response.status) {
        // Remove the request from the list
        final updatedRequests = state.requests
            .where((req) {
              final ref = req['request_reference']?.toString() ?? '';
              return ref != requestReference;
            })
            .toList();

        state = state.copyWith(requests: updatedRequests);
        return true;
      }

      return false;
    } catch (e) {
      logger.error('Failed to respond to request: $e', error: e);
      return false;
    }
  }

  /// Reset the controller state.
  void reset() {
    state = const TutorReceivedRequestsState();
  }
}
