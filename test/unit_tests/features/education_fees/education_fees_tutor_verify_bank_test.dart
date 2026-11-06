import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_rupaiya/constants/api_constants.dart';
import 'package:e_rupaiya/features/educationFees/models/education_fees_responses.dart';
import 'package:e_rupaiya/features/educationFees/repositories/education_fees_repository.dart';
import 'package:e_rupaiya/features/educationFees/services/education_fees_service.dart';

/// Contract coverage for the Tutor Bank Recipient Verification API
/// (`POST /api/education/tutor/recipient/verify-bank`).
///
/// The tests assert the exact endpoint, the exact request JSON keys, dynamic
/// values, complete backend data preservation (including the masked account
/// number and numeric transaction reference), and both business and
/// transport failures.
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

  const reference = 'EDUTUT180D00AA6BBCBE0C941904F1';
  const otherReference = 'EDUTUT999Z00BBBBBBBB0000000000';
  const account = '1234567890123456';
  const otherAccount = '90000000011234';
  const ifsc = 'TEST0001234';

  Map<String, dynamic> successPayload({
    bool status = true,
    Map<String, dynamic>? dataOverrides,
  }) {
    return {
      'status': status,
      'message': 'Tutor recipient bank account verified successfully.',
      'data': {
        'recipient_reference': reference,
        'beneficiary_id': 39,
        'name': 'TEST TUTOR NAME',
        'account_number': 'XXXXXX3456',
        'ifsc': ifsc,
        'transaction_reference': 1474338350,
        'bank_verified': true,
        ...?dataOverrides,
      },
    };
  }

  Future<EducationTutorVerifyBankResponse> verify(
    EducationFeesRepository repository, {
    String recipientReference = reference,
    String accountNo = account,
    String ifscCode = ifsc,
  }) {
    return repository.verifyTutorBank(
      recipientReference: recipientReference,
      accountNo: accountNo,
      ifsc: ifscCode,
    );
  }

  group('POST /api/education/tutor/recipient/verify-bank', () {
    test('posts the three values to the tutor verify-bank endpoint', () async {
      final (adapter, repository) = _repository(payload: successPayload());

      await verify(repository);

      final options = adapter.options;
      expect(options, isNotNull);
      expect(options!.method, 'POST');
      expect(
        options.uri.toString(),
        ApiConstants.educationTutorVerifyBankEndpoint,
      );
      expect(options.uri.path, '/api/education/tutor/recipient/verify-bank');
      expect(_requestedBody(options), {
        'recipient_reference': reference,
        'account_no': account,
        'ifsc': ifsc,
      });
    });

    test('sends dynamic values and no hardcoded substitutions', () async {
      final (adapter, repository) = _repository(payload: successPayload());

      await verify(
        repository,
        recipientReference: otherReference,
        accountNo: otherAccount,
        ifscCode: 'HDFC0001234',
      );

      expect(_requestedBody(adapter.options!), {
        'recipient_reference': otherReference,
        'account_no': otherAccount,
        'ifsc': 'HDFC0001234',
      });
      // The reference is sent verbatim; nothing else leaks into the body.
      expect(_requestedBody(adapter.options!).containsKey('pan'), isFalse);
      expect(
        _requestedBody(adapter.options!).containsKey('beneficiary_id'),
        isFalse,
      );
      expect(
        _requestedBody(adapter.options!).containsKey('name'),
        isFalse,
      );
    });
  });

  group('EducationTutorVerifyBankResponse parsing', () {
    test('preserves a successful payload exactly', () async {
      final (_, repository) = _repository(payload: successPayload());

      final response = await verify(repository);
      final data = response.data;

      expect(response.status, isTrue);
      expect(
        response.message,
        'Tutor recipient bank account verified successfully.',
      );
      expect(data, isNotNull);
      expect(data!.recipientReference, reference);
      expect(data.beneficiaryId, 39);
      expect(data.name, 'TEST TUTOR NAME');
      // Masked account number is preserved exactly as returned.
      expect(data.accountNumber, 'XXXXXX3456');
      expect(data.ifsc, ifsc);
      expect(data.transactionReference, 1474338350);
      expect(data.bankVerified, isTrue);
      expect(response.confirmsVerifiedBank, isTrue);
    });

    test('preserves a different masked account variant verbatim', () async {
      final (_, repository) = _repository(
        payload: successPayload(
          dataOverrides: {'account_number': '912010*******11'},
        ),
      );

      final response = await verify(repository);

      expect(response.data!.accountNumber, '912010*******11');
    });

    test('keeps null beneficiary id and transaction reference when absent',
        () async {
      final (_, repository) = _repository(
        payload: {
          'status': true,
          'data': {
            'recipient_reference': reference,
            'name': 'TEST TUTOR NAME',
            'account_number': 'XXXXXX7911',
            'ifsc': ifsc,
            'bank_verified': true,
          },
        },
      );

      final response = await verify(repository);

      expect(response.data!.beneficiaryId, isNull);
      expect(response.data!.transactionReference, isNull);
      expect(response.confirmsVerifiedBank, isTrue);
    });

    test('string ids and a truthy bank_verified still confirm success', () async {
      final (_, repository) = _repository(
        payload: {
          'status': 'SUCCESS',
          'message': 'Tutor recipient bank account verified successfully.',
          'data': {
            'recipient_reference': reference,
            'beneficiary_id': '39',
            'name': 'TEST TUTOR NAME',
            'account_number': 'XXXXXX3456',
            'ifsc': ifsc,
            'transaction_reference': '1474338350',
            'bank_verified': 'true',
          },
        },
      );

      final response = await verify(repository);

      expect(response.status, isTrue);
      expect(response.data!.beneficiaryId, 39);
      expect(response.data!.transactionReference, 1474338350);
      expect(response.data!.bankVerified, isTrue);
      expect(response.confirmsVerifiedBank, isTrue);
    });

    test('bank_verified false never confirms success', () async {
      final (_, repository) = _repository(
        payload: successPayload(dataOverrides: {'bank_verified': false}),
      );

      final response = await verify(repository);

      expect(response.status, isTrue);
      expect(response.data!.bankVerified, isFalse);
      expect(response.confirmsVerifiedBank, isFalse);
    });

    test('missing data stays null', () async {
      final (_, repository) = _repository(
        payload: {'status': false, 'message': 'Invalid recipient reference.'},
      );

      final response = await verify(repository);

      expect(response.status, isFalse);
      expect(response.message, 'Invalid recipient reference.');
      expect(response.data, isNull);
      expect(response.confirmsVerifiedBank, isFalse);
    });

    test('empty data object defaults safely', () async {
      final (_, repository) = _repository(
        payload: {
          'status': true,
          'messages': {'error': 'Bank data unavailable.'},
          'data': <String, dynamic>{},
        },
      );

      final response = await verify(repository);

      expect(response.status, isTrue);
      expect(response.message, 'Bank data unavailable.');
      expect(response.data, isNotNull);
      expect(response.data!.recipientReference, isEmpty);
      expect(response.data!.accountNumber, isEmpty);
      expect(response.data!.bankVerified, isFalse);
      expect(response.confirmsVerifiedBank, isFalse);
    });

    test('status false is a business failure even on HTTP 200', () async {
      final (_, repository) = _repository(
        payload: successPayload(status: false),
      );

      final response = await verify(repository);

      expect(response.status, isFalse);
      expect(response.confirmsVerifiedBank, isFalse);
      // Data is still mapped, but success must never be inferred from HTTP 200.
      expect(response.data, isNotNull);
    });
  });

  group('HTTP and network failures', () {
    test('non-2xx JSON body is parsed as a business failure', () async {
      final (_, repository) = _repository(
        statusCode: 422,
        payload: const {
          'status': false,
          'message': 'Recipient reference not found.',
        },
      );

      final response = await verify(repository);

      expect(response.status, isFalse);
      expect(response.message, 'Recipient reference not found.');
      expect(response.data, isNull);
    });

    test('a non-JSON error body is rethrown', () async {
      final (_, repository) = _repository(
        statusCode: 500,
        rawBody: 'Internal Server Error',
        contentType: 'text/plain; charset=utf-8',
      );

      await expectLater(
        verify(repository),
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
        verify(repository),
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
