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

/// `{"mobile": "..."}` body as decoded by Dio, whatever form it reaches the
/// adapter in.
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

  const mobile = '9000000003';

  group('POST /api/education/tutor/verify request contract', () {
    test('posts the mobile number to the tutor verify endpoint', () async {
      final (adapter, repository) = _repository(
        payload: const {
          'status': true,
          'verification_status': 'VERIFIED',
          'message': 'Mobile number verified successfully.',
        },
      );

      await repository.verifyTutor(mobile);

      final options = adapter.options;
      expect(options, isNotNull);
      expect(options!.method, 'POST');
      expect(options.uri.toString(), ApiConstants.educationTutorVerifyEndpoint);
      expect(_requestedBody(options), {'mobile': mobile});
    });

    test('uses the mobile passed in and never a hardcoded number', () async {
      final (adapter, repository) = _repository(
        payload: const {'status': true, 'verification_status': 'NOT_FOUND'},
      );

      await repository.verifyTutor('9000000001');

      expect(_requestedBody(adapter.options!), {'mobile': '9000000001'});
    });
  });

  group('EducationFeesService.verifyTutor responses', () {
    test('VERIFIED is reported as a verified tutor', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'verification_status': 'VERIFIED',
          'message': 'Mobile number verified successfully.',
        },
      );

      final response = await repository.verifyTutor(mobile);

      expect(response.status, isTrue);
      expect(
        response.verificationStatus,
        EducationTutorVerificationStatus.verified,
      );
      expect(response.message, 'Mobile number verified successfully.');
      expect(response.isVerified, isTrue);
      expect(response.isNotVerified, isFalse);
      expect(response.isNotFound, isFalse);
      expect(response.hasKnownVerificationStatus, isTrue);
      expect(response.confirmsVerifiedTutor, isTrue);
    });

    test('NOT_VERIFIED keeps status true but is not a verified tutor',
        () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'verification_status': 'NOT_VERIFIED',
          'message': 'This user is registered but KYC is not completed.',
        },
      );

      final response = await repository.verifyTutor(mobile);

      expect(response.status, isTrue);
      expect(
        response.verificationStatus,
        EducationTutorVerificationStatus.notVerified,
      );
      expect(response.message,
          'This user is registered but KYC is not completed.');
      expect(response.isNotVerified, isTrue);
      expect(response.confirmsVerifiedTutor, isFalse);
    });

    test('NOT_FOUND maps to the not-registered outcome', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'verification_status': 'NOT_FOUND',
          'message': 'This mobile number is not registered in eRupaiya.',
        },
      );

      final response = await repository.verifyTutor(mobile);

      expect(response.status, isTrue);
      expect(
        response.verificationStatus,
        EducationTutorVerificationStatus.notFound,
      );
      expect(response.message,
          'This mobile number is not registered in eRupaiya.');
      expect(response.isNotFound, isTrue);
      expect(response.confirmsVerifiedTutor, isFalse);
    });

    test('status false is a failed request even when VERIFIED is echoed',
        () async {
      final (_, repository) = _repository(
        payload: const {
          'status': false,
          'verification_status': 'VERIFIED',
          'message': 'Invalid request',
        },
      );

      final response = await repository.verifyTutor(mobile);

      expect(response.status, isFalse);
      expect(response.isVerified, isTrue);
      expect(response.confirmsVerifiedTutor, isFalse);
    });
  });

  group('unknown and invalid payloads', () {
    test('unrecognised verification_status falls back to unknown', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'verification_status': 'SUSPENDED',
          'message': 'Unexpected backend state',
        },
      );

      final response = await repository.verifyTutor(mobile);

      expect(
        response.verificationStatus,
        EducationTutorVerificationStatus.unknown,
      );
      expect(response.hasKnownVerificationStatus, isFalse);
      expect(response.confirmsVerifiedTutor, isFalse);
    });

    test('missing verification_status fails closed', () async {
      final (_, repository) = _repository(
        payload: const {'status': true, 'message': 'No status sent'},
      );

      final response = await repository.verifyTutor(mobile);

      expect(response.status, isTrue);
      expect(
        response.verificationStatus,
        EducationTutorVerificationStatus.unknown,
      );
      expect(response.isVerified, isFalse);
    });

    test('empty payload parses to a failed unknown response', () async {
      final (_, repository) = _repository(rawBody: '{}');

      final response = await repository.verifyTutor(mobile);

      expect(response.status, isFalse);
      expect(
        response.verificationStatus,
        EducationTutorVerificationStatus.unknown,
      );
      expect(response.message, isNull);
    });

    test('non-object success body is not swallowed', () async {
      final (_, repository) = _repository(rawBody: '"unexpected"');

      await expectLater(
        repository.verifyTutor(mobile),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('API and network failures', () {
    test('error payload with a non-2xx status is still parsed', () async {
      final (_, repository) = _repository(
        statusCode: 400,
        payload: const {
          'status': false,
          'verification_status': 'NOT_FOUND',
          'message': 'Mobile is required',
        },
      );

      final response = await repository.verifyTutor(mobile);

      expect(response.status, isFalse);
      expect(
        response.verificationStatus,
        EducationTutorVerificationStatus.notFound,
      );
      expect(response.message, 'Mobile is required');
    });

    test('server error without a JSON payload rethrows', () async {
      final (_, repository) = _repository(
        statusCode: 500,
        rawBody: 'Internal Server Error',
        contentType: 'text/plain; charset=utf-8',
      );

      await expectLater(
        repository.verifyTutor(mobile),
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
        repository.verifyTutor(mobile),
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
