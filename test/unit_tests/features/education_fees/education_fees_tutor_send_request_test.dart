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

/// `{"mobile": "...", "amount": ..., "subject": "..."}` body as decoded by Dio,
/// whatever form it reaches the adapter in.
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

  const mobile = '9000000002';
  const amount = 5000;
  const subject = 'Maths';

  group('POST /api/education/tutor/send-request request contract', () {
    test('posts the mobile, amount and subject to the send request endpoint',
        () async {
      final (adapter, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Payment request sent successfully.',
          'data': {
            'request_id': 1,
            'request_reference': 'EDUTR20261103180707F4A2C57A',
            'tutor_id': 1,
            'amount': '5000.00',
            'request_status': 'PENDING',
            'created_at': '2026-11-03 18:07:07',
          },
        },
      );

      await repository.sendTutorRequest(
        mobile: mobile,
        amount: amount,
        subject: subject,
      );

      final options = adapter.options;
      expect(options, isNotNull);
      expect(options!.method, 'POST');
      expect(
        options.uri.toString(),
        ApiConstants.educationTutorSendRequestEndpoint,
      );
      expect(_requestedBody(options), {
        'mobile': mobile,
        'amount': amount,
        'subject': subject,
      });
    });

    test('uses the mobile, amount and subject passed in and never hardcoded values',
        () async {
      final (adapter, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Payment request sent successfully.',
          'data': {
            'request_id': 2,
            'request_reference': 'EDUTR20261103190707B5B3D68B',
            'tutor_id': 2,
            'amount': '10000.00',
            'request_status': 'PENDING',
            'created_at': '2026-11-03 19:07:07',
          },
        },
      );

      await repository.sendTutorRequest(
        mobile: '9000000001',
        amount: 10000,
        subject: 'Physics',
      );

      expect(_requestedBody(adapter.options!), {
        'mobile': '9000000001',
        'amount': 10000,
        'subject': 'Physics',
      });
    });
  });

  group('EducationTutorSendRequestResponse successful response', () {
    test('parses complete send request response', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Payment request sent successfully.',
          'data': {
            'request_id': 1,
            'request_reference': 'EDUTR20261103180707F4A2C57A',
            'tutor_id': 1,
            'amount': '5000.00',
            'request_status': 'PENDING',
            'created_at': '2026-11-03 18:07:07',
          },
        },
      );

      final response = await repository.sendTutorRequest(
        mobile: mobile,
        amount: amount,
        subject: subject,
      );

      expect(response.status, isTrue);
      expect(response.message, 'Payment request sent successfully.');
      expect(response.data, isNotNull);
      expect(response.data!.requestId, 1);
      expect(response.data!.requestReference, 'EDUTR20261103180707F4A2C57A');
      expect(response.data!.tutorId, 1);
      expect(response.data!.amount, '5000.00');
      expect(response.data!.requestStatus, 'PENDING');
      expect(response.data!.createdAt, '2026-11-03 18:07:07');
    });

    test('preserves decimal amount "5000.00" exactly as returned', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Payment request sent successfully.',
          'data': {
            'request_id': 1,
            'request_reference': 'EDUTR20261103180707F4A2C57A',
            'tutor_id': 1,
            'amount': '5000.00',
            'request_status': 'PENDING',
            'created_at': '2026-11-03 18:07:07',
          },
        },
      );

      final response = await repository.sendTutorRequest(
        mobile: mobile,
        amount: amount,
        subject: subject,
      );

      expect(response.data!.amount, '5000.00');
    });

    test('preserves request_reference exactly as returned', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Payment request sent successfully.',
          'data': {
            'request_id': 1,
            'request_reference': 'EDUTR20261103180707F4A2C57A',
            'tutor_id': 1,
            'amount': '5000.00',
            'request_status': 'PENDING',
            'created_at': '2026-11-03 18:07:07',
          },
        },
      );

      final response = await repository.sendTutorRequest(
        mobile: mobile,
        amount: amount,
        subject: subject,
      );

      expect(response.data!.requestReference, 'EDUTR20261103180707F4A2C57A');
    });

    test('handles request_status dynamically as returned', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Payment request sent successfully.',
          'data': {
            'request_id': 1,
            'request_reference': 'EDUTR20261103180707F4A2C57A',
            'tutor_id': 1,
            'amount': '5000.00',
            'request_status': 'APPROVED',
            'created_at': '2026-11-03 18:07:07',
          },
        },
      );

      final response = await repository.sendTutorRequest(
        mobile: mobile,
        amount: amount,
        subject: subject,
      );

      expect(response.data!.requestStatus, 'APPROVED');
    });

    test('preserves created_at according to the model', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Payment request sent successfully.',
          'data': {
            'request_id': 1,
            'request_reference': 'EDUTR20261103180707F4A2C57A',
            'tutor_id': 1,
            'amount': '5000.00',
            'request_status': 'PENDING',
            'created_at': '2026-11-03 18:07:07',
          },
        },
      );

      final response = await repository.sendTutorRequest(
        mobile: mobile,
        amount: amount,
        subject: subject,
      );

      expect(response.data!.createdAt, '2026-11-03 18:07:07');
    });

    test('parses request_id and tutor_id correctly', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Payment request sent successfully.',
          'data': {
            'request_id': 123,
            'request_reference': 'EDUTR20261103180707F4A2C57A',
            'tutor_id': 456,
            'amount': '5000.00',
            'request_status': 'PENDING',
            'created_at': '2026-11-03 18:07:07',
          },
        },
      );

      final response = await repository.sendTutorRequest(
        mobile: mobile,
        amount: amount,
        subject: subject,
      );

      expect(response.data!.requestId, 123);
      expect(response.data!.tutorId, 456);
    });

    test('handles status false response', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': false,
          'message': 'Failed to send request',
          'data': null,
        },
      );

      final response = await repository.sendTutorRequest(
        mobile: mobile,
        amount: amount,
        subject: subject,
      );

      expect(response.status, isFalse);
      expect(response.message, 'Failed to send request');
      expect(response.data, isNull);
    });
  });

  group('nullable or missing data handling', () {
    test('handles missing data field gracefully', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Payment request sent successfully.',
        },
      );

      final response = await repository.sendTutorRequest(
        mobile: mobile,
        amount: amount,
        subject: subject,
      );

      expect(response.status, isTrue);
      expect(response.data, isNull);
    });

    test('handles invalid data field gracefully', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Payment request sent successfully.',
          'data': 'invalid',
        },
      );

      final response = await repository.sendTutorRequest(
        mobile: mobile,
        amount: amount,
        subject: subject,
      );

      expect(response.status, isTrue);
      expect(response.data, isNull);
    });

    test('handles missing nested fields with defaults', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Payment request sent successfully.',
          'data': {
            'request_id': 1,
            'request_reference': '',
            'tutor_id': 0,
            'amount': '0',
            'request_status': '',
            'created_at': '',
          },
        },
      );

      final response = await repository.sendTutorRequest(
        mobile: mobile,
        amount: amount,
        subject: subject,
      );

      expect(response.data!.requestId, 1);
      expect(response.data!.requestReference, '');
      expect(response.data!.tutorId, 0);
      expect(response.data!.amount, '0');
      expect(response.data!.requestStatus, '');
      expect(response.data!.createdAt, '');
    });
  });

  group('API and network failures', () {
    test('error payload with a non-2xx status is still parsed', () async {
      final (_, repository) = _repository(
        statusCode: 400,
        payload: const {
          'status': false,
          'message': 'Mobile is required',
          'data': null,
        },
      );

      final response = await repository.sendTutorRequest(
        mobile: mobile,
        amount: amount,
        subject: subject,
      );

      expect(response.status, isFalse);
      expect(response.message, 'Mobile is required');
    });

    test('server error without a JSON payload rethrows', () async {
      final (_, repository) = _repository(
        statusCode: 500,
        rawBody: 'Internal Server Error',
        contentType: 'text/plain; charset=utf-8',
      );

      await expectLater(
        repository.sendTutorRequest(
          mobile: mobile,
          amount: amount,
          subject: subject,
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
        repository.sendTutorRequest(
          mobile: mobile,
          amount: amount,
          subject: subject,
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

      final response = await repository.sendTutorRequest(
        mobile: mobile,
        amount: amount,
        subject: subject,
      );

      expect(response.status, isFalse);
      expect(response.message, isNull);
      expect(response.data, isNull);
    });

    test('non-object success body is not swallowed', () async {
      final (_, repository) = _repository(rawBody: '"unexpected"');

      await expectLater(
        repository.sendTutorRequest(
          mobile: mobile,
          amount: amount,
          subject: subject,
        ),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('nested data parsing', () {
    test('parses all nested data fields correctly', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Payment request sent successfully.',
          'data': {
            'request_id': 999,
            'request_reference': 'EDUTR20261103200000XYZ123ABC',
            'tutor_id': 888,
            'amount': '7500.50',
            'request_status': 'COMPLETED',
            'created_at': '2026-11-03 20:00:00',
          },
        },
      );

      final response = await repository.sendTutorRequest(
        mobile: mobile,
        amount: amount,
        subject: subject,
      );

      expect(response.data!.requestId, 999);
      expect(response.data!.requestReference, 'EDUTR20261103200000XYZ123ABC');
      expect(response.data!.tutorId, 888);
      expect(response.data!.amount, '7500.50');
      expect(response.data!.requestStatus, 'COMPLETED');
      expect(response.data!.createdAt, '2026-11-03 20:00:00');
    });
  });
}
