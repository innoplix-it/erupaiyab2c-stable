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

/// `{"request_reference": "...", "action": "..."}` body as decoded by Dio.
Map<String, dynamic> _requestedBody(RequestOptions options) {
  final data = options.data;
  if (data is String) {
    return jsonDecode(data) as Map<String, dynamic>;
  }
  return Map<String, dynamic>.from(data as Map);
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

  const requestReference = 'EDUTR20261103180707F4A2C57A';

  group('POST /api/education/tutor/request-status/{request_reference} request contract',
      () {
    test('uses POST method and correct dynamic endpoint', () async {
      final (adapter, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Payment request accepted successfully.',
          'data': {
            'request_reference': 'EDUTUTOR123456',
            'amount': '5000.00',
            'request_status': 'ACCEPTED',
            'responded_at': '2026-11-04 10:30:00',
          },
        },
      );

      await repository.respondToTutorRequest(
        requestReference: requestReference,
        action: 'ACCEPTED',
      );

      final options = adapter.options;
      expect(options, isNotNull);
      expect(options!.method, 'POST');
      expect(
        options.uri.toString(),
        ApiConstants.educationTutorRespondToRequestEndpoint(requestReference),
      );
    });

    test('includes request_reference in URL path', () async {
      final (adapter, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Payment request accepted successfully.',
          'data': {
            'request_reference': 'EDUTUTOR123456',
            'amount': '5000.00',
            'request_status': 'ACCEPTED',
            'responded_at': '2026-11-04 10:30:00',
          },
        },
      );

      await repository.respondToTutorRequest(
        requestReference: requestReference,
        action: 'ACCEPTED',
      );

      expect(
        adapter.options!.uri.toString(),
        contains(requestReference),
      );
    });

    test('includes request_reference in POST body', () async {
      final (adapter, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Payment request accepted successfully.',
          'data': {
            'request_reference': 'EDUTUTOR123456',
            'amount': '5000.00',
            'request_status': 'ACCEPTED',
            'responded_at': '2026-11-04 10:30:00',
          },
        },
      );

      await repository.respondToTutorRequest(
        requestReference: requestReference,
        action: 'ACCEPTED',
      );

      expect(_requestedBody(adapter.options!)['request_reference'], requestReference);
    });

    test('serializes ACCEPTED action correctly', () async {
      final (adapter, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Payment request accepted successfully.',
          'data': {
            'request_reference': 'EDUTUTOR123456',
            'amount': '5000.00',
            'request_status': 'ACCEPTED',
            'responded_at': '2026-11-04 10:30:00',
          },
        },
      );

      await repository.respondToTutorRequest(
        requestReference: requestReference,
        action: 'ACCEPTED',
      );

      expect(_requestedBody(adapter.options!)['action'], 'ACCEPTED');
    });

    test('serializes REJECTED action correctly', () async {
      final (adapter, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Payment request rejected successfully.',
          'data': {
            'request_reference': 'EDUTUTOR123456',
            'amount': '5000.00',
            'request_status': 'REJECTED',
            'responded_at': '2026-11-04 10:30:00',
          },
        },
      );

      await repository.respondToTutorRequest(
        requestReference: requestReference,
        action: 'REJECTED',
      );

      expect(_requestedBody(adapter.options!)['action'], 'REJECTED');
    });

    test('uses dynamic request reference and action values', () async {
      final (adapter, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Payment request accepted successfully.',
          'data': {
            'request_reference': 'EDUTUTOR999999',
            'amount': '10000.00',
            'request_status': 'ACCEPTED',
            'responded_at': '2026-11-04 10:30:00',
          },
        },
      );

      await repository.respondToTutorRequest(
        requestReference: 'EDUTR2026110319024285BCD9D1',
        action: 'ACCEPTED',
      );

      expect(_requestedBody(adapter.options!)['request_reference'],
          'EDUTR2026110319024285BCD9D1');
      expect(_requestedBody(adapter.options!)['action'], 'ACCEPTED');
    });
  });

  group('EducationTutorRespondToRequestResponse successful ACCEPTED response', () {
    test('parses successful ACCEPTED response', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Payment request accepted successfully.',
          'data': {
            'request_reference': 'EDUTUTOR123456',
            'amount': '5000.00',
            'request_status': 'ACCEPTED',
            'responded_at': '2026-11-04 10:30:00',
          },
        },
      );

      final response = await repository.respondToTutorRequest(
        requestReference: requestReference,
        action: 'ACCEPTED',
      );

      expect(response.status, isTrue);
      expect(response.message, 'Payment request accepted successfully.');
      expect(response.data, isNotNull);
      expect(response.data!.requestReference, 'EDUTUTOR123456');
      expect(response.data!.amount, '5000.00');
      expect(response.data!.requestStatus, 'ACCEPTED');
      expect(response.data!.respondedAt, '2026-11-04 10:30:00');
    });

    test('preserves amount "5000.00" as String', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Payment request accepted successfully.',
          'data': {
            'request_reference': 'EDUTUTOR123456',
            'amount': '5000.00',
            'request_status': 'ACCEPTED',
            'responded_at': '2026-11-04 10:30:00',
          },
        },
      );

      final response = await repository.respondToTutorRequest(
        requestReference: requestReference,
        action: 'ACCEPTED',
      );

      expect(response.data!.amount, '5000.00');
    });

    test('handles nullable responded_at', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Payment request accepted successfully.',
          'data': {
            'request_reference': 'EDUTUTOR123456',
            'amount': '5000.00',
            'request_status': 'ACCEPTED',
            'responded_at': null,
          },
        },
      );

      final response = await repository.respondToTutorRequest(
        requestReference: requestReference,
        action: 'ACCEPTED',
      );

      expect(response.data!.respondedAt, isNull);
    });
  });

  group('Business failure responses', () {
    test('handles request not found response (status: false)', () async {
      final requestRef = 'EDUTR20261103180707F4A2C57A';
      final (_, repository) = _repository(
        payload: const {
          'status': false,
          'message': 'Request not found.',
        },
      );

      final response = await repository.respondToTutorRequest(
        requestReference: requestRef,
        action: 'ACCEPTED',
      );

      expect(response.status, isFalse);
      expect(response.message, 'Request not found.');
      expect(response.data, isNull);
    });

    test('handles already responded response with root-level request_status',
        () async {
      final requestRef = 'EDUTR20261103180707F4A2C57A';
      final (_, repository) = _repository(
        payload: const {
          'status': false,
          'message': 'This request has already been responded to.',
          'request_status': 'ACCEPTED',
        },
      );

      final response = await repository.respondToTutorRequest(
        requestReference: requestRef,
        action: 'ACCEPTED',
      );

      expect(response.status, isFalse);
      expect(response.message, 'This request has already been responded to.');
      expect(response.requestStatus, 'ACCEPTED');
      expect(response.data, isNull);
    });
  });

  group('null/missing data handling', () {
    test('handles missing data field gracefully', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Payment request accepted successfully.',
        },
      );

      final response = await repository.respondToTutorRequest(
        requestReference: requestReference,
        action: 'ACCEPTED',
      );

      expect(response.status, isTrue);
      expect(response.data, isNull);
    });

    test('handles invalid data field gracefully', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Payment request accepted successfully.',
          'data': 'invalid',
        },
      );

      final response = await repository.respondToTutorRequest(
        requestReference: requestReference,
        action: 'ACCEPTED',
      );

      expect(response.status, isTrue);
      expect(response.data, isNull);
    });

    test('handles missing nested fields with defaults', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Payment request accepted successfully.',
          'data': {
            'request_reference': '',
            'amount': '0',
            'request_status': '',
            'responded_at': null,
          },
        },
      );

      final response = await repository.respondToTutorRequest(
        requestReference: requestReference,
        action: 'ACCEPTED',
      );

      expect(response.data!.requestReference, '');
      expect(response.data!.amount, '0');
      expect(response.data!.requestStatus, '');
      expect(response.data!.respondedAt, isNull);
    });
  });

  group('HTTP error handling', () {
    test('error payload with a non-2xx status is still parsed', () async {
      final (_, repository) = _repository(
        statusCode: 400,
        payload: const {
          'status': false,
          'message': 'Invalid request reference',
          'data': null,
        },
      );

      final response = await repository.respondToTutorRequest(
        requestReference: requestReference,
        action: 'ACCEPTED',
      );

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
        repository.respondToTutorRequest(
          requestReference: requestReference,
          action: 'ACCEPTED',
        ),
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
        repository.respondToTutorRequest(
          requestReference: requestReference,
          action: 'ACCEPTED',
        ),
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

      final response = await repository.respondToTutorRequest(
        requestReference: requestReference,
        action: 'ACCEPTED',
      );

      expect(response.status, isFalse);
      expect(response.message, isNull);
      expect(response.data, isNull);
    });

    test('non-object success body is not swallowed', () async {
      final (_, repository) = _repository(rawBody: '"unexpected"');

      await expectLater(
        repository.respondToTutorRequest(
          requestReference: requestReference,
          action: 'ACCEPTED',
        ),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('GET Request Status API regression test', () {
    test('existing GET Request Status API still works', () async {
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

      await repository.fetchTutorRequestStatus('EDUTR2026110319024285BCD9D0');

      final options = adapter.options;
      expect(options, isNotNull);
      expect(options!.method, 'GET');
      expect(
        options.uri.toString(),
        ApiConstants.educationTutorRequestStatusEndpoint(
          'EDUTR2026110319024285BCD9D0',
        ),
      );
    });
  });
}
