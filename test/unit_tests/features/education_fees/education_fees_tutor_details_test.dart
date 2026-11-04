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

/// `{"mobile": "...", "amount": ...}` body as decoded by Dio, whatever form it reaches the
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

  const mobile = '9284354642';
  const amount = 10;

  group('POST /api/education/tutor/details request contract', () {
    test('posts the mobile and amount to the tutor details endpoint', () async {
      final (adapter, repository) = _repository(
        payload: const {
          'status': true,
          'verification_status': 'VERIFIED',
          'message': 'Tutor details fetched successfully.',
          'data': {
            'tutor_id': 1,
            'tutor_name': 'MONU ALI',
            'bank_name': '',
            'account_number': 'XXXXXXXX4642',
            'account_holder_name': 'MONU ALI',
            'ifsc': 'INDB0000746',
            'bank_logo': null,
            'amount': 10,
          },
        },
      );

      await repository.fetchTutorDetails(mobile: mobile, amount: amount);

      final options = adapter.options;
      expect(options, isNotNull);
      expect(options!.method, 'POST');
      expect(options.uri.toString(), ApiConstants.educationTutorDetailsEndpoint);
      expect(_requestedBody(options), {'mobile': mobile, 'amount': amount});
    });

    test('uses the mobile and amount passed in and never hardcoded values', () async {
      final (adapter, repository) = _repository(
        payload: const {
          'status': true,
          'verification_status': 'VERIFIED',
          'data': {
            'tutor_id': 2,
            'tutor_name': 'TEST USER',
            'bank_name': 'Test Bank',
            'account_number': 'XXXXXXXX1234',
            'account_holder_name': 'TEST USER',
            'ifsc': 'TEST0001234',
            'bank_logo': null,
            'amount': 50,
          },
        },
      );

      await repository.fetchTutorDetails(mobile: '9876543210', amount: 50);

      expect(_requestedBody(adapter.options!), {'mobile': '9876543210', 'amount': 50});
    });
  });

  group('EducationTutorDetailsResponse successful response', () {
    test('parses complete tutor details response', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'verification_status': 'VERIFIED',
          'message': 'Tutor details fetched successfully.',
          'data': {
            'tutor_id': 1,
            'tutor_name': 'MONU ALI',
            'bank_name': '',
            'account_number': 'XXXXXXXX4642',
            'account_holder_name': 'MONU ALI',
            'ifsc': 'INDB0000746',
            'bank_logo': null,
            'amount': 10,
          },
        },
      );

      final response = await repository.fetchTutorDetails(mobile: mobile, amount: amount);

      expect(response.status, isTrue);
      expect(
        response.verificationStatus,
        EducationTutorVerificationStatus.verified,
      );
      expect(response.message, 'Tutor details fetched successfully.');
      expect(response.data, isNotNull);
      expect(response.data!.tutorId, 1);
      expect(response.data!.tutorName, 'MONU ALI');
      expect(response.data!.bankName, '');
      expect(response.data!.accountNumber, 'XXXXXXXX4642');
      expect(response.data!.accountHolderName, 'MONU ALI');
      expect(response.data!.ifsc, 'INDB0000746');
      expect(response.data!.bankLogo, isNull);
      expect(response.data!.amount, 10);
      expect(response.isVerified, isTrue);
      expect(response.confirmsVerifiedTutor, isTrue);
    });

    test('handles nullable bank_logo', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'verification_status': 'VERIFIED',
          'message': 'Tutor details fetched successfully.',
          'data': {
            'tutor_id': 1,
            'tutor_name': 'MONU ALI',
            'bank_name': 'Test Bank',
            'account_number': 'XXXXXXXX4642',
            'account_holder_name': 'MONU ALI',
            'ifsc': 'INDB0000746',
            'bank_logo': null,
            'amount': 10,
          },
        },
      );

      final response = await repository.fetchTutorDetails(mobile: mobile, amount: amount);

      expect(response.data!.bankLogo, isNull);
    });

    test('handles empty bank_name', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'verification_status': 'VERIFIED',
          'message': 'Tutor details fetched successfully.',
          'data': {
            'tutor_id': 1,
            'tutor_name': 'MONU ALI',
            'bank_name': '',
            'account_number': 'XXXXXXXX4642',
            'account_holder_name': 'MONU ALI',
            'ifsc': 'INDB0000746',
            'bank_logo': null,
            'amount': 10,
          },
        },
      );

      final response = await repository.fetchTutorDetails(mobile: mobile, amount: amount);

      expect(response.data!.bankName, '');
    });

    test('preserves masked account numbers exactly as returned', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'verification_status': 'VERIFIED',
          'data': {
            'tutor_id': 1,
            'tutor_name': 'MONU ALI',
            'bank_name': '',
            'account_number': 'XXXXXXXX4642',
            'account_holder_name': 'MONU ALI',
            'ifsc': 'INDB0000746',
            'bank_logo': null,
            'amount': 10,
          },
        },
      );

      final response = await repository.fetchTutorDetails(mobile: mobile, amount: amount);

      expect(response.data!.accountNumber, 'XXXXXXXX4642');
    });

    test('handles NOT_VERIFIED status', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'verification_status': 'NOT_VERIFIED',
          'message': 'This user is registered but KYC is not completed.',
          'data': null,
        },
      );

      final response = await repository.fetchTutorDetails(mobile: mobile, amount: amount);

      expect(response.status, isTrue);
      expect(
        response.verificationStatus,
        EducationTutorVerificationStatus.notVerified,
      );
      expect(response.data, isNull);
      expect(response.isNotVerified, isTrue);
      expect(response.confirmsVerifiedTutor, isFalse);
    });

    test('handles NOT_FOUND status', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'verification_status': 'NOT_FOUND',
          'message': 'This mobile number is not registered in eRupaiya.',
          'data': null,
        },
      );

      final response = await repository.fetchTutorDetails(mobile: mobile, amount: amount);

      expect(response.status, isTrue);
      expect(
        response.verificationStatus,
        EducationTutorVerificationStatus.notFound,
      );
      expect(response.data, isNull);
      expect(response.isNotFound, isTrue);
      expect(response.confirmsVerifiedTutor, isFalse);
    });

    test('status false is a failed request even when VERIFIED is echoed', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': false,
          'verification_status': 'VERIFIED',
          'message': 'Invalid request',
          'data': null,
        },
      );

      final response = await repository.fetchTutorDetails(mobile: mobile, amount: amount);

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
          'data': null,
        },
      );

      final response = await repository.fetchTutorDetails(mobile: mobile, amount: amount);

      expect(
        response.verificationStatus,
        EducationTutorVerificationStatus.unknown,
      );
      expect(response.hasKnownVerificationStatus, isFalse);
      expect(response.confirmsVerifiedTutor, isFalse);
    });

    test('missing verification_status fails closed', () async {
      final (_, repository) = _repository(
        payload: const {'status': true, 'message': 'No status sent', 'data': null},
      );

      final response = await repository.fetchTutorDetails(mobile: mobile, amount: amount);

      expect(response.status, isTrue);
      expect(
        response.verificationStatus,
        EducationTutorVerificationStatus.unknown,
      );
      expect(response.isVerified, isFalse);
    });

    test('empty payload parses to a failed unknown response', () async {
      final (_, repository) = _repository(rawBody: '{}');

      final response = await repository.fetchTutorDetails(mobile: mobile, amount: amount);

      expect(response.status, isFalse);
      expect(
        response.verificationStatus,
        EducationTutorVerificationStatus.unknown,
      );
      expect(response.message, isNull);
      expect(response.data, isNull);
    });

    test('non-object success body is not swallowed', () async {
      final (_, repository) = _repository(rawBody: '"unexpected"');

      await expectLater(
        repository.fetchTutorDetails(mobile: mobile, amount: amount),
        throwsA(isA<TypeError>()),
      );
    });

    test('missing data field is handled gracefully', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'verification_status': 'VERIFIED',
          'message': 'Tutor details fetched successfully.',
        },
      );

      final response = await repository.fetchTutorDetails(mobile: mobile, amount: amount);

      expect(response.status, isTrue);
      expect(response.data, isNull);
    });

    test('invalid data field is handled gracefully', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'verification_status': 'VERIFIED',
          'message': 'Tutor details fetched successfully.',
          'data': 'invalid',
        },
      );

      final response = await repository.fetchTutorDetails(mobile: mobile, amount: amount);

      expect(response.status, isTrue);
      expect(response.data, isNull);
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
          'data': null,
        },
      );

      final response = await repository.fetchTutorDetails(mobile: mobile, amount: amount);

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
        repository.fetchTutorDetails(mobile: mobile, amount: amount),
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
        repository.fetchTutorDetails(mobile: mobile, amount: amount),
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

  group('nested data parsing', () {
    test('parses all nested data fields correctly', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'verification_status': 'VERIFIED',
          'message': 'Tutor details fetched successfully.',
          'data': {
            'tutor_id': 123,
            'tutor_name': 'John Doe',
            'bank_name': 'HDFC Bank',
            'account_number': 'XXXXXXXX9999',
            'account_holder_name': 'John Doe',
            'ifsc': 'HDFC0001234',
            'bank_logo': 'https://example.com/logo.png',
            'amount': 500,
          },
        },
      );

      final response = await repository.fetchTutorDetails(mobile: mobile, amount: amount);

      expect(response.data!.tutorId, 123);
      expect(response.data!.tutorName, 'John Doe');
      expect(response.data!.bankName, 'HDFC Bank');
      expect(response.data!.accountNumber, 'XXXXXXXX9999');
      expect(response.data!.accountHolderName, 'John Doe');
      expect(response.data!.ifsc, 'HDFC0001234');
      expect(response.data!.bankLogo, 'https://example.com/logo.png');
      expect(response.data!.amount, 500);
    });

    test('handles missing nested fields with defaults', () async {
      final (_, repository) = _repository(
        payload: const {
          'status': true,
          'verification_status': 'VERIFIED',
          'message': 'Tutor details fetched successfully.',
          'data': {
            'tutor_id': 1,
            'tutor_name': 'Test',
            'bank_name': '',
            'account_number': '',
            'account_holder_name': '',
            'ifsc': '',
            'amount': 0,
          },
        },
      );

      final response = await repository.fetchTutorDetails(mobile: mobile, amount: amount);

      expect(response.data!.tutorId, 1);
      expect(response.data!.tutorName, 'Test');
      expect(response.data!.bankName, '');
      expect(response.data!.accountNumber, '');
      expect(response.data!.accountHolderName, '');
      expect(response.data!.ifsc, '');
      expect(response.data!.bankLogo, isNull);
      expect(response.data!.amount, 0);
    });
  });
}
