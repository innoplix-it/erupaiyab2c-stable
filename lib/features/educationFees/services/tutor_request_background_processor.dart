import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../constants/api_constants.dart';
import '../../../services/logger_service.dart';
import '../../../services/secure_storage_service.dart';
import '../constants/tutor_notification_constants.dart';
import '../models/education_fees_responses.dart';
import '../repositories/education_fees_repository.dart';
import 'education_fees_service.dart';
import 'tutor_request_notification_service.dart';
import 'tutor_request_pending_store.dart';

/// Background-isolate safe tutor-request processing.
///
/// Does not touch BuildContext, Navigator, Riverpod UI, or showDialog.
/// Uses a lightweight authenticated Dio client (token from secure storage)
/// instead of the main-isolate [DioService] singleton so SSL-pinning /
/// navigator-coupled interceptors are not required in the FCM isolate.
class TutorRequestBackgroundProcessor {
  TutorRequestBackgroundProcessor._();

  static const _storage = SecureStorageService.instance;

  /// Process an FCM message in a background isolate.
  static Future<void> handle(RemoteMessage message) async {
    final data = message.data;
    if (!TutorRequestNotificationService.isTutorRequestPayload(data)) {
      return;
    }

    final requestReference =
        TutorRequestNotificationService.extractRequestReference(data);
    if (requestReference == null || requestReference.isEmpty) {
      logger.warning('BACKGROUND_TUTOR_REQUEST missing request_reference');
      return;
    }

    logger.info(
      'BACKGROUND_TUTOR_REQUEST_RECEIVED: $requestReference '
      'id=${message.messageId}',
    );

    // Already queued from a prior background delivery — skip duplicate GET.
    final existing = await TutorRequestPendingStore.loadAll();
    final alreadyQueued = existing.any(
      (entry) =>
          entry.requestReference == requestReference && entry.verified,
    );
    if (alreadyQueued) {
      logger.info(
        'BACKGROUND_TUTOR_REQUEST_ALREADY_QUEUED: $requestReference',
      );
      return;
    }

    final accessToken = await _storage.read(key: 'accessToken');
    if (accessToken == null || accessToken.trim().isEmpty) {
      logger.info(
        'BACKGROUND_TUTOR_REQUEST_AUTH_UNAVAILABLE: $requestReference',
      );
      await TutorRequestPendingStore.upsert(
        TutorRequestPendingEntry(
          requestReference: requestReference,
          verified: false,
        ),
      );
      return;
    }

    final tokenType = await _storage.read(key: 'tokenType') ?? TutorNotificationConstants.defaultTokenType;
    try {
      logger.info('BACKGROUND_REQUEST_STATUS_API_STARTED: $requestReference');
      final repository = EducationFeesRepository(
        service: EducationFeesService(
          dio: Dio(
            BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: TutorNotificationConstants.backgroundConnectTimeout,
              sendTimeout: TutorNotificationConstants.backgroundSendTimeout,
              receiveTimeout: TutorNotificationConstants.backgroundReceiveTimeout,
              headers: {
                'Authorization': '$tokenType ${accessToken.trim()}',
                'Accept': TutorNotificationConstants.acceptHeader,
              },
            ),
          ),
        ),
      );

      final response =
          await repository.fetchTutorRequestStatus(requestReference);
      logger.info('BACKGROUND_REQUEST_STATUS_API_SUCCESS: $requestReference');

      if (!_isStrictPending(response, requestReference)) {
        logger.info(
          'BACKGROUND_REQUEST_NOT_PENDING: $requestReference',
        );
        await TutorRequestPendingStore.remove(requestReference);
        return;
      }

      final dataPayload = response.data!;
      await TutorRequestPendingStore.upsert(
        TutorRequestPendingEntry(
          requestReference: requestReference,
          verified: true,
          amount: dataPayload.amount,
          subject: dataPayload.subject,
          requesterName: dataPayload.requesterName,
          requesterUserId: dataPayload.requesterUserId,
          requestStatus: dataPayload.requestStatus,
        ),
      );
      logger.info(
        'BACKGROUND_REQUEST_STATUS_PENDING_PERSISTED: $requestReference',
      );
    } catch (e) {
      logger.error(
        'BACKGROUND_REQUEST_STATUS_API_ERROR: $e',
        error: e,
      );
      // Persist unverified so foreground can retry the status GET.
      await TutorRequestPendingStore.upsert(
        TutorRequestPendingEntry(
          requestReference: requestReference,
          verified: false,
        ),
      );
    }
  }

  static bool _isStrictPending(
    EducationTutorRequestStatusResponse response,
    String incomingRequestReference,
  ) {
    final data = response.data;
    return response.status == true &&
        data != null &&
        data.requestReference == incomingRequestReference &&
        data.requestStatus.trim().toUpperCase() == 'PENDING' &&
        data.isPending == true &&
        data.isAccepted == false &&
        data.isRejected == false;
  }
}
