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

  group('GET /api/education/tutor/received-requests request contract', () {
    test('uses GET method and correct endpoint', () async {
      final (adapter, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Received requests fetched successfully.',
          'data': {
            'requests': [],
            'pagination': {
              'page': 1,
              'per_page': 20,
              'total': 0,
              'total_pages': 0,
            },
          },
        },
      );

      await repository.fetchTutorReceivedRequests(page: 1, perPage: 20);

      final options = adapter.options;
      expect(options, isNotNull);
      expect(options!.method, 'GET');
      expect(
        options.uri.toString(),
        startsWith(ApiConstants.educationTutorReceivedRequestsEndpoint),
      );
    });

    test('includes page query parameter', () async {
      final (adapter, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Received requests fetched successfully.',
          'data': {
            'requests': [],
            'pagination': {
              'page': 2,
              'per_page': 20,
              'total': 0,
              'total_pages': 0,
            },
          },
        },
      );

      await repository.fetchTutorReceivedRequests(page: 2, perPage: 20);

      expect(adapter.options!.queryParameters['page'], 2);
    });

    test('includes per_page query parameter', () async {
      final (adapter, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Received requests fetched successfully.',
          'data': {
            'requests': [],
            'pagination': {
              'page': 1,
              'per_page': 50,
              'total': 0,
              'total_pages': 0,
            },
          },
        },
      );

      await repository.fetchTutorReceivedRequests(page: 1, perPage: 50);

      expect(adapter.options!.queryParameters['per_page'], 50);
    });

    test('includes status query parameter when provided', () async {
      final (adapter, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Received requests fetched successfully.',
          'data': {
            'requests': [],
            'pagination': {
              'page': 1,
              'per_page': 20,
              'total': 0,
              'total_pages': 0,
            },
          },
        },
      );

      await repository.fetchTutorReceivedRequests(
        page: 1,
        perPage: 20,
        status: 'PENDING',
      );

      expect(adapter.options!.queryParameters['status'], 'PENDING');
    });

    test('omits status query parameter when null', () async {
      final (adapter, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Received requests fetched successfully.',
          'data': {
            'requests': [],
            'pagination': {
              'page': 1,
              'per_page': 20,
              'total': 0,
              'total_pages': 0,
            },
          },
        },
      );

      await repository.fetchTutorReceivedRequests(page: 1, perPage: 20);

      expect(adapter.options!.queryParameters.containsKey('status'), isFalse);
    });

    test('omits status query parameter when empty string', () async {
      final (adapter, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Received requests fetched successfully.',
          'data': {
            'requests': [],
            'pagination': {
              'page': 1,
              'per_page': 20,
              'total': 0,
              'total_pages': 0,
            },
          },
        },
      );

      await repository.fetchTutorReceivedRequests(
        page: 1,
        perPage: 20,
        status: '',
      );

      expect(adapter.options!.queryParameters.containsKey('status'), isFalse);
    });

    test('uses dynamic parameter values', () async {
      final (adapter, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Received requests fetched successfully.',
          'data': {
            'requests': [],
            'pagination': {
              'page': 3,
              'per_page': 30,
              'total': 0,
              'total_pages': 0,
            },
          },
        },
      );

      await repository.fetchTutorReceivedRequests(
        page: 3,
        perPage: 30,
        status: 'ACCEPTED',
      );

      expect(adapter.options!.queryParameters['page'], 3);
      expect(adapter.options!.queryParameters['per_page'], 30);
      expect(adapter.options!.queryParameters['status'], 'ACCEPTED');
    });

    test('does not send request body with GET', () async {
      final (adapter, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Received requests fetched successfully.',
          'data': {
            'requests': [],
            'pagination': {
              'page': 1,
              'per_page': 20,
              'total': 0,
              'total_pages': 0,
            },
          },
        },
      );

      await repository.fetchTutorReceivedRequests(page: 1, perPage: 20);

      expect(adapter.options!.data, isNull);
    });
  });

  group('EducationTutorReceivedRequestsResponse successful response', () {
    test('parses complete response with empty requests array', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Received requests fetched successfully.',
          'data': {
            'requests': [],
            'pagination': {
              'page': 1,
              'per_page': 20,
              'total': 0,
              'total_pages': 0,
            },
          },
        },
      );

      final response = await repository.fetchTutorReceivedRequests(
        page: 1,
        perPage: 20,
      );

      expect(response.status, isTrue);
      expect(response.message, 'Received requests fetched successfully.');
      expect(response.data, isNotNull);
      expect(response.data!.requests, isEmpty);
      expect(response.data!.pagination, isNotNull);
    });

    test('parses pagination correctly', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Received requests fetched successfully.',
          'data': {
            'requests': [],
            'pagination': {
              'page': 1,
              'per_page': 20,
              'total': 100,
              'total_pages': 5,
            },
          },
        },
      );

      final response = await repository.fetchTutorReceivedRequests(
        page: 1,
        perPage: 20,
      );

      expect(response.data!.pagination!.page, 1);
      expect(response.data!.pagination!.perPage, 20);
      expect(response.data!.pagination!.total, 100);
      expect(response.data!.pagination!.totalPages, 5);
    });

    test('preserves non-empty generic request objects without assuming fields',
        () async {
      final (_, repository) = _repository(
        payload: {
          'status': true,
          'message': 'Received requests fetched successfully.',
          'data': {
            'requests': [
              {
                'id': 1,
                'unknown_field': 'some_value',
              },
              {
                'id': 2,
                'another_field': 123,
              },
            ],
            'pagination': {
              'page': 1,
              'per_page': 20,
              'total': 2,
              'total_pages': 1,
            },
          },
        },
      );

      final response = await repository.fetchTutorReceivedRequests(
        page: 1,
        perPage: 20,
      );

      expect(response.data!.requests.length, 2);
      expect(response.data!.requests[0]['id'], 1);
      expect(response.data!.requests[0]['unknown_field'], 'some_value');
      expect(response.data!.requests[1]['id'], 2);
      expect(response.data!.requests[1]['another_field'], 123);
    });
  });

  group('null/missing data handling', () {
    test('handles missing data field gracefully', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Received requests fetched successfully.',
        },
      );

      final response = await repository.fetchTutorReceivedRequests(
        page: 1,
        perPage: 20,
      );

      expect(response.status, isTrue);
      expect(response.data, isNull);
    });

    test('handles invalid data field gracefully', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Received requests fetched successfully.',
          'data': 'invalid',
        },
      );

      final response = await repository.fetchTutorReceivedRequests(
        page: 1,
        perPage: 20,
      );

      expect(response.status, isTrue);
      expect(response.data, isNull);
    });

    test('handles missing pagination field gracefully', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Received requests fetched successfully.',
          'data': {
            'requests': [],
          },
        },
      );

      final response = await repository.fetchTutorReceivedRequests(
        page: 1,
        perPage: 20,
      );

      expect(response.status, isTrue);
      expect(response.data, isNotNull);
      expect(response.data!.requests, isEmpty);
      expect(response.data!.pagination, isNull);
    });

    test('handles invalid requests field gracefully', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Received requests fetched successfully.',
          'data': {
            'requests': 'not an array',
            'pagination': {
              'page': 1,
              'per_page': 20,
              'total': 0,
              'total_pages': 0,
            },
          },
        },
      );

      final response = await repository.fetchTutorReceivedRequests(
        page: 1,
        perPage: 20,
      );

      expect(response.status, isTrue);
      expect(response.data, isNotNull);
      expect(response.data!.requests, isEmpty);
    });

    test('handles missing pagination fields with defaults', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Received requests fetched successfully.',
          'data': {
            'requests': [],
            'pagination': {},
          },
        },
      );

      final response = await repository.fetchTutorReceivedRequests(
        page: 1,
        perPage: 20,
      );

      expect(response.data!.pagination!.page, 1);
      expect(response.data!.pagination!.perPage, 20);
      expect(response.data!.pagination!.total, 0);
      expect(response.data!.pagination!.totalPages, 0);
    });
  });

  group('API and network failures', () {
    test('error payload with a non-2xx status is still parsed', () async {
      final (_, repository) = _repository(
        statusCode: 400,
        payload: const {
          'status': false,
          'message': 'Invalid pagination parameters',
          'data': null,
        },
      );

      final response = await repository.fetchTutorReceivedRequests(
        page: 1,
        perPage: 20,
      );

      expect(response.status, isFalse);
      expect(response.message, 'Invalid pagination parameters');
    });

    test('server error without a JSON payload rethrows', () async {
      final (_, repository) = _repository(
        statusCode: 500,
        rawBody: 'Internal Server Error',
        contentType: 'text/plain; charset=utf-8',
      );

      await expectLater(
        repository.fetchTutorReceivedRequests(page: 1, perPage: 20),
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
        repository.fetchTutorReceivedRequests(page: 1, perPage: 20),
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

      final response = await repository.fetchTutorReceivedRequests(
        page: 1,
        perPage: 20,
      );

      expect(response.status, isFalse);
      expect(response.message, isNull);
      expect(response.data, isNull);
    });

    test('non-object success body is not swallowed', () async {
      final (_, repository) = _repository(rawBody: '"unexpected"');

      await expectLater(
        repository.fetchTutorReceivedRequests(page: 1, perPage: 20),
        throwsA(isA<TypeError>()),
      );
    });
  });

  test('keeps the sender requester_name ahead of tutor_name', () {
    final data = EducationTutorReceivedRequestsData.fromJson(const {
      'requests': [
        {
          'request_reference': 'EDUTR20261106061937FFB19244',
          'requester_name': 'Asha Patil',
          'tutor_name': 'Darshan Nikam',
          'subject': 'tuition fees',
          'amount': '1.00',
          'status': 'PENDING',
        },
      ],
    });

    expect(data.requests.single['requester_name'], 'Asha Patil');
    expect(data.requests.single['fee_type'], 'tuition fees');
  });
}
