import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_rupaiya/constants/api_constants.dart';
import 'package:e_rupaiya/features/educationFees/models/education_fees_responses.dart';
import 'package:e_rupaiya/features/educationFees/repositories/education_fees_repository.dart';
import 'package:e_rupaiya/features/educationFees/services/education_fees_service.dart';

/// Returns a canned payload and remembers the request it answered.
class _StubAdapter implements HttpClientAdapter {
  int statusCode = 200;
  String body = '{}';
  String contentType = Headers.jsonContentType;
  Object? error;

  RequestOptions? options;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    this.options = options;
    final thrown = error;
    if (thrown != null) throw thrown;
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [contentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

(_StubAdapter, EducationFeesRepository) _repository({
  int statusCode = 200,
  Map<String, dynamic>? payload,
  String? rawBody,
  String contentType = Headers.jsonContentType,
  Object? error,
}) {
  final adapter = _StubAdapter()
    ..statusCode = statusCode
    ..body = rawBody ?? jsonEncode(payload ?? <String, dynamic>{})
    ..contentType = contentType
    ..error = error;
  final repository = EducationFeesRepository(
    service: EducationFeesService(dio: Dio()..httpClientAdapter = adapter),
  );
  return (adapter, repository);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const requestReference = 'EDUTR2026110319024285BCD9D0';

  group('GET /api/education/tutor/request-status/{request_reference} request contract',
      () {
    test('uses GET method and dynamic request reference in endpoint', () async {
      final (adapter, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Request status fetched successfully.',
          'data': {
            'request_reference': 'EDUTR2026110319024285BCD9D0',
            'amount': '5000.00',
            'subject': 'Maths',
            'request_status': 'PENDING',
            'is_accepted': false,
            'is_rejected': false,
            'is_pending': true,
            'rejection_reason': null,
            'created_at': '2026-11-03 19:02:42',
            'responded_at': null,
          },
        },
      );

      await repository.fetchTutorRequestStatus(requestReference);

      final options = adapter.options;
      expect(options, isNotNull);
      expect(options!.method, 'GET');
      expect(
        options.uri.toString(),
        ApiConstants.educationTutorRequestStatusEndpoint(requestReference),
      );
    });

    test('uses the request reference passed in and never hardcoded value', () async {
      final (adapter, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Request status fetched successfully.',
          'data': {
            'request_reference': 'EDUTR2026110319024285BCD9D1',
            'amount': '10000.00',
            'subject': 'Physics',
            'request_status': 'PENDING',
            'is_accepted': false,
            'is_rejected': false,
            'is_pending': true,
            'rejection_reason': null,
            'created_at': '2026-11-03 19:02:42',
            'responded_at': null,
          },
        },
      );

      await repository.fetchTutorRequestStatus('EDUTR2026110319024285BCD9D1');

      expect(
        adapter.options!.uri.toString(),
        ApiConstants.educationTutorRequestStatusEndpoint(
          'EDUTR2026110319024285BCD9D1',
        ),
      );
    });

    test('does not send request body with GET', () async {
      final (adapter, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Request status fetched successfully.',
          'data': {
            'request_reference': 'EDUTR2026110319024285BCD9D0',
            'amount': '5000.00',
            'subject': 'Maths',
            'request_status': 'PENDING',
            'is_accepted': false,
            'is_rejected': false,
            'is_pending': true,
            'rejection_reason': null,
            'created_at': '2026-11-03 19:02:42',
            'responded_at': null,
          },
        },
      );

      await repository.fetchTutorRequestStatus(requestReference);

      expect(adapter.options!.data, isNull);
    });
  });

  group('EducationTutorRequestStatusResponse successful response', () {
    test('parses complete request status response', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Request status fetched successfully.',
          'data': {
            'request_reference': 'EDUTR2026110319024285BCD9D0',
            'amount': '5000.00',
            'subject': 'Maths',
            'request_status': 'PENDING',
            'is_accepted': false,
            'is_rejected': false,
            'is_pending': true,
            'rejection_reason': null,
            'created_at': '2026-11-03 19:02:42',
            'responded_at': null,
          },
        },
      );

      final response = await repository.fetchTutorRequestStatus(requestReference);

      expect(response.status, isTrue);
      expect(response.message, 'Request status fetched successfully.');
      expect(response.data, isNotNull);
      expect(response.data!.requestReference, 'EDUTR2026110319024285BCD9D0');
      expect(response.data!.amount, '5000.00');
      expect(response.data!.subject, 'Maths');
      expect(response.data!.requestStatus, 'PENDING');
      expect(response.data!.isAccepted, isFalse);
      expect(response.data!.isRejected, isFalse);
      expect(response.data!.isPending, isTrue);
      expect(response.data!.rejectionReason, isNull);
      expect(response.data!.createdAt, '2026-11-03 19:02:42');
      expect(response.data!.respondedAt, isNull);
    });

    test('preserves decimal amount "5000.00" exactly as returned', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Request status fetched successfully.',
          'data': {
            'request_reference': 'EDUTR2026110319024285BCD9D0',
            'amount': '5000.00',
            'subject': 'Maths',
            'request_status': 'PENDING',
            'is_accepted': false,
            'is_rejected': false,
            'is_pending': true,
            'rejection_reason': null,
            'created_at': '2026-11-03 19:02:42',
            'responded_at': null,
          },
        },
      );

      final response = await repository.fetchTutorRequestStatus(requestReference);

      expect(response.data!.amount, '5000.00');
    });

    test('parses subject correctly', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Request status fetched successfully.',
          'data': {
            'request_reference': 'EDUTR2026110319024285BCD9D0',
            'amount': '5000.00',
            'subject': 'Physics',
            'request_status': 'PENDING',
            'is_accepted': false,
            'is_rejected': false,
            'is_pending': true,
            'rejection_reason': null,
            'created_at': '2026-11-03 19:02:42',
            'responded_at': null,
          },
        },
      );

      final response = await repository.fetchTutorRequestStatus(requestReference);

      expect(response.data!.subject, 'Physics');
    });

    test('parses PENDING status correctly', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Request status fetched successfully.',
          'data': {
            'request_reference': 'EDUTR2026110319024285BCD9D0',
            'amount': '5000.00',
            'subject': 'Maths',
            'request_status': 'PENDING',
            'is_accepted': false,
            'is_rejected': false,
            'is_pending': true,
            'rejection_reason': null,
            'created_at': '2026-11-03 19:02:42',
            'responded_at': null,
          },
        },
      );

      final response = await repository.fetchTutorRequestStatus(requestReference);

      expect(response.data!.requestStatus, 'PENDING');
      expect(response.data!.isPending, isTrue);
    });

    test('parses boolean fields correctly', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Request status fetched successfully.',
          'data': {
            'request_reference': 'EDUTR2026110319024285BCD9D0',
            'amount': '5000.00',
            'subject': 'Maths',
            'request_status': 'PENDING',
            'is_accepted': false,
            'is_rejected': false,
            'is_pending': true,
            'rejection_reason': null,
            'created_at': '2026-11-03 19:02:42',
            'responded_at': null,
          },
        },
      );

      final response = await repository.fetchTutorRequestStatus(requestReference);

      expect(response.data!.isAccepted, isFalse);
      expect(response.data!.isRejected, isFalse);
      expect(response.data!.isPending, isTrue);
    });

    test('handles nullable rejection_reason', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Request status fetched successfully.',
          'data': {
            'request_reference': 'EDUTR2026110319024285BCD9D0',
            'amount': '5000.00',
            'subject': 'Maths',
            'request_status': 'REJECTED',
            'is_accepted': false,
            'is_rejected': true,
            'is_pending': false,
            'rejection_reason': null,
            'created_at': '2026-11-03 19:02:42',
            'responded_at': '2026-11-03 19:05:00',
          },
        },
      );

      final response = await repository.fetchTutorRequestStatus(requestReference);

      expect(response.data!.rejectionReason, isNull);
    });

    test('handles nullable responded_at', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Request status fetched successfully.',
          'data': {
            'request_reference': 'EDUTR2026110319024285BCD9D0',
            'amount': '5000.00',
            'subject': 'Maths',
            'request_status': 'PENDING',
            'is_accepted': false,
            'is_rejected': false,
            'is_pending': true,
            'rejection_reason': null,
            'created_at': '2026-11-03 19:02:42',
            'responded_at': null,
          },
        },
      );

      final response = await repository.fetchTutorRequestStatus(requestReference);

      expect(response.data!.respondedAt, isNull);
    });

    test('preserves created_at according to the model', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Request status fetched successfully.',
          'data': {
            'request_reference': 'EDUTR2026110319024285BCD9D0',
            'amount': '5000.00',
            'subject': 'Maths',
            'request_status': 'PENDING',
            'is_accepted': false,
            'is_rejected': false,
            'is_pending': true,
            'rejection_reason': null,
            'created_at': '2026-11-03 19:02:42',
            'responded_at': null,
          },
        },
      );

      final response = await repository.fetchTutorRequestStatus(requestReference);

      expect(response.data!.createdAt, '2026-11-03 19:02:42');
    });

    test('parses accepted status correctly', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Request status fetched successfully.',
          'data': {
            'request_reference': 'EDUTR2026110319024285BCD9D0',
            'amount': '5000.00',
            'subject': 'Maths',
            'request_status': 'ACCEPTED',
            'is_accepted': true,
            'is_rejected': false,
            'is_pending': false,
            'rejection_reason': null,
            'created_at': '2026-11-03 19:02:42',
            'responded_at': '2026-11-03 19:05:00',
          },
        },
      );

      final response = await repository.fetchTutorRequestStatus(requestReference);

      expect(response.data!.requestStatus, 'ACCEPTED');
      expect(response.data!.isAccepted, isTrue);
      expect(response.data!.isRejected, isFalse);
      expect(response.data!.isPending, isFalse);
    });

    test('parses rejected status with reason correctly', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Request status fetched successfully.',
          'data': {
            'request_reference': 'EDUTR2026110319024285BCD9D0',
            'amount': '5000.00',
            'subject': 'Maths',
            'request_status': 'REJECTED',
            'is_accepted': false,
            'is_rejected': true,
            'is_pending': false,
            'rejection_reason': 'Amount too high',
            'created_at': '2026-11-03 19:02:42',
            'responded_at': '2026-11-03 19:05:00',
          },
        },
      );

      final response = await repository.fetchTutorRequestStatus(requestReference);

      expect(response.data!.requestStatus, 'REJECTED');
      expect(response.data!.isRejected, isTrue);
      expect(response.data!.rejectionReason, 'Amount too high');
      expect(response.data!.respondedAt, '2026-11-03 19:05:00');
    });

    test('preserves all backend status values independently', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Request status fetched successfully.',
          'data': {
            'request_reference': 'EDUTR2026110319024285BCD9D0',
            'amount': '5000.00',
            'subject': 'Maths',
            'request_status': 'PENDING',
            'is_accepted': false,
            'is_rejected': false,
            'is_pending': true,
            'rejection_reason': null,
            'created_at': '2026-11-03 19:02:42',
            'responded_at': null,
          },
        },
      );

      final response = await repository.fetchTutorRequestStatus(requestReference);

      expect(response.data!.requestStatus, 'PENDING');
      expect(response.data!.isAccepted, isFalse);
      expect(response.data!.isRejected, isFalse);
      expect(response.data!.isPending, isTrue);
    });
  });

  group('missing/null nested data handling', () {
    test('handles missing data field gracefully', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Request status fetched successfully.',
        },
      );

      final response = await repository.fetchTutorRequestStatus(requestReference);

      expect(response.status, isTrue);
      expect(response.data, isNull);
    });

    test('handles invalid data field gracefully', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Request status fetched successfully.',
          'data': 'invalid',
        },
      );

      final response = await repository.fetchTutorRequestStatus(requestReference);

      expect(response.status, isTrue);
      expect(response.data, isNull);
    });

    test('handles missing nested fields with defaults', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Request status fetched successfully.',
          'data': {
            'request_reference': '',
            'amount': '0',
            'subject': '',
            'request_status': '',
            'is_accepted': false,
            'is_rejected': false,
            'is_pending': false,
            'rejection_reason': null,
            'created_at': '',
            'responded_at': null,
          },
        },
      );

      final response = await repository.fetchTutorRequestStatus(requestReference);

      expect(response.data!.requestReference, '');
      expect(response.data!.amount, '0');
      expect(response.data!.subject, '');
      expect(response.data!.requestStatus, '');
      expect(response.data!.isAccepted, isFalse);
      expect(response.data!.isRejected, isFalse);
      expect(response.data!.isPending, isFalse);
      expect(response.data!.rejectionReason, isNull);
      expect(response.data!.createdAt, '');
      expect(response.data!.respondedAt, isNull);
    });
  });

  group('API and network failures', () {
    test('error payload with a non-2xx status is still parsed', () async {
      final (_, repository) = _repository(
        statusCode: 400,
        payload: const {
          'status': false,
          'message': 'Invalid request reference',
          'data': null,
        },
      );

      final response = await repository.fetchTutorRequestStatus(requestReference);

      expect(response.status, isFalse);
      expect(response.message, 'Invalid request reference');
    });

    test('server error without a JSON payload rethrows', () async {
      final (_, repository) = _repository(
        statusCode: 500,
        rawBody: 'Internal Server Error',
        contentType: 'text/plain; charset=utf-8',
      );

      await expectLater(
        repository.fetchTutorRequestStatus(requestReference),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
    });

    test('connection failure rethrows instead of inventing a status', () async {
      final (_, repository) = _repository(
        error: DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      await expectLater(
        repository.fetchTutorRequestStatus(requestReference),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.connectionError,
          ),
        ),
      );
    });
  });

  group('invalid response handling', () {
    test('empty payload parses to a failed response', () async {
      final (_, repository) = _repository(rawBody: '{}');

      final response = await repository.fetchTutorRequestStatus(requestReference);

      expect(response.status, isFalse);
      expect(response.message, isNull);
      expect(response.data, isNull);
    });

    test('non-object success body is not swallowed', () async {
      final (_, repository) = _repository(rawBody: '"unexpected"');

      await expectLater(
        repository.fetchTutorRequestStatus(requestReference),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('unknown request_status preservation', () {
    test('preserves unknown request_status as returned by backend', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Request status fetched successfully.',
          'data': {
            'request_reference': 'EDUTR2026110319024285BCD9D0',
            'amount': '5000.00',
            'subject': 'Maths',
            'request_status': 'CANCELLED',
            'is_accepted': false,
            'is_rejected': false,
            'is_pending': false,
            'rejection_reason': null,
            'created_at': '2026-11-03 19:02:42',
            'responded_at': '2026-11-03 19:03:00',
          },
        },
      );

      final response = await repository.fetchTutorRequestStatus(requestReference);

      expect(response.data!.requestStatus, 'CANCELLED');
    });
  });
}
