import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_rupaiya/constants/api_constants.dart';
import 'package:e_rupaiya/features/educationFees/repositories/education_fees_repository.dart';
import 'package:e_rupaiya/features/educationFees/services/education_fees_service.dart';

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

  const enteredPan = 'ABCDE1234F';
  const otherPan = 'FGHIJ5678K';

  Map<String, dynamic> successPayload({String panMasked = 'ABCDE****F'}) {
    return {
      'status': true,
      'message': 'Tutor PAN already verified.',
      'data': {
        'recipient_reference': 'EDUTUT180D00AA6BBCBE0C941904F1',
        'beneficiary_id': 39,
        'name': 'TEST TUTOR NAME',
        'pan_masked': panMasked,
        'pan_verified': true,
      },
    };
  }

  group('POST /api/education/tutor/recipient/verify-pan', () {
    test('posts the entered PAN to the tutor verify-pan endpoint', () async {
      final (adapter, repository) = _repository(payload: successPayload());

      await repository.verifyTutorPan(enteredPan);

      final options = adapter.options;
      expect(options, isNotNull);
      expect(options!.method, 'POST');
      expect(
        options.uri.toString(),
        ApiConstants.educationTutorVerifyPanEndpoint,
      );
      expect(options.uri.path, '/api/education/tutor/recipient/verify-pan');
      expect(_requestedBody(options), {'pan': enteredPan});
    });

    test('sends the PAN argument and no hardcoded number', () async {
      final (adapter, repository) = _repository(payload: successPayload());

      await repository.verifyTutorPan(otherPan);

      expect(_requestedBody(adapter.options!), {'pan': otherPan});
      expect(_requestedBody(adapter.options!).containsKey('name'), isFalse);
      expect(
        _requestedBody(adapter.options!).containsKey('device_id'),
        isFalse,
      );
    });
  });

  group('EducationTutorVerifyPanResponse parsing', () {
    test('preserves a successful payload exactly', () async {
      final (_, repository) = _repository(payload: successPayload());

      final response = await repository.verifyTutorPan(enteredPan);

      expect(response.status, isTrue);
      expect(response.message, 'Tutor PAN already verified.');
      expect(response.confirmsVerifiedPan, isTrue);
      final data = response.data;
      expect(data, isNotNull);
      expect(data!.recipientReference, 'EDUTUT180D00AA6BBCBE0C941904F1');
      expect(data.beneficiaryId, 39);
      expect(data.name, 'TEST TUTOR NAME');
      expect(data.panMasked, 'ABCDE****F');
      expect(data.panVerified, isTrue);
    });

    test('keeps pan_masked exactly as the backend sent it', () async {
      final (_, repository) = _repository(
        payload: successPayload(panMasked: 'ABCDE*****F'),
      );

      final response = await repository.verifyTutorPan(enteredPan);

      expect(response.data?.panMasked, 'ABCDE*****F');
    });

    test('parses pan_verified false without treating status as success',
        () async {
      final (_, repository) = _repository(
        payload: {
          'status': true,
          'message': 'PAN could not be verified.',
          'data': {
            'recipient_reference': 'EDUTUTSHOULDNOTBEUSED',
            'beneficiary_id': 8,
            'name': 'SOME NAME',
            'pan_masked': 'ABCDE****F',
            'pan_verified': false,
          },
        },
      );

      final response = await repository.verifyTutorPan(otherPan);

      expect(response.status, isTrue);
      expect(response.data?.panVerified, isFalse);
      expect(response.confirmsVerifiedPan, isFalse);
      expect(response.data?.recipientReference, 'EDUTUTSHOULDNOTBEUSED');
    });

    test('missing data stays null', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'message': 'Tutor PAN already verified.',
        },
      );

      final response = await repository.verifyTutorPan(enteredPan);

      expect(response.status, isTrue);
      expect(response.data, isNull);
      expect(response.confirmsVerifiedPan, isFalse);
    });

    test('missing nested fields are empty or null', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'data': <String, dynamic>{},
        },
      );

      final response = await repository.verifyTutorPan(enteredPan);
      final data = response.data;

      expect(data, isNotNull);
      expect(data!.recipientReference, isEmpty);
      expect(data.beneficiaryId, isNull);
      expect(data.name, isEmpty);
      expect(data.panMasked, isEmpty);
      expect(data.panVerified, isFalse);
      expect(response.confirmsVerifiedPan, isFalse);
    });

    test('status false is a business failure even on HTTP 200', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': false,
          'message': 'Invalid PAN',
          'data': {
            'recipient_reference': 'EDUTUT180D00AA6BBCBE0C941904F1',
            'beneficiary_id': 39,
            'name': 'TEST TUTOR NAME',
            'pan_masked': 'ABXPI****E',
            'pan_verified': true,
          },
        },
      );

      final response = await repository.verifyTutorPan(enteredPan);

      expect(response.status, isFalse);
      expect(response.message, 'Invalid PAN');
      expect(response.confirmsVerifiedPan, isFalse);
    });

    test('messages.error is used when message is absent', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': false,
          'messages': {'error': 'PAN is required'},
        },
      );

      final response = await repository.verifyTutorPan(enteredPan);

      expect(response.status, isFalse);
      expect(response.message, 'PAN is required');
      expect(response.data, isNull);
    });
  });

  group('HTTP and network failures', () {
    test('non-2xx JSON body is parsed as a business failure', () async {
      final (_, repository) = _repository(
        statusCode: 422,
        payload: const {
          'status': false,
          'message': 'PAN format is invalid',
        },
      );

      final response = await repository.verifyTutorPan(enteredPan);

      expect(response.status, isFalse);
      expect(response.message, 'PAN format is invalid');
      expect(response.data, isNull);
    });

    test('a non-JSON error body is rethrown', () async {
      final (_, repository) = _repository(
        statusCode: 500,
        rawBody: 'Internal Server Error',
        contentType: 'text/plain; charset=utf-8',
      );

      await expectLater(
        repository.verifyTutorPan(enteredPan),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
    });

    test('connection failure rethrows', () async {
      final (_, repository) = _repository(
        error: DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      await expectLater(
        repository.verifyTutorPan(enteredPan),
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
}
