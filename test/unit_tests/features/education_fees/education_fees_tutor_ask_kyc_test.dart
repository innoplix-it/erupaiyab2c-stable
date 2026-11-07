import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_rupaiya/constants/api_constants.dart';
import 'package:e_rupaiya/features/educationFees/controllers/education_fees_controller.dart';
import 'package:e_rupaiya/features/educationFees/models/education_fees_responses.dart';
import 'package:e_rupaiya/features/educationFees/repositories/education_fees_repository.dart';
import 'package:e_rupaiya/features/educationFees/services/education_fees_service.dart';

class _StubAdapter implements HttpClientAdapter {
  RequestOptions? options;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    this.options = options;
    return ResponseBody.fromString(
      jsonEncode({
        'status': true,
        'message': 'KYC reminder notification sent successfully.',
        'data': {
          'request_reference': 'EDUTR20261106061937FFB19244',
          'notification_sent_to': 10,
        },
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeAskRepository extends EducationFeesRepository {
  final askBodies = <Map<String, String?>>[];
  int sendCount = 0;

  @override
  Future<EducationTutorSendRequestResponse> sendTutorRequest({
    required String mobile,
    required int amount,
    required String subject,
    String? feeType,
    String? senderName,
  }) async {
    sendCount++;
    return const EducationTutorSendRequestResponse(
      status: true,
      data: EducationTutorSendRequestData(
        requestId: 1,
        requestReference: 'EDUTR-CREATED',
        tutorId: 1,
        amount: '2000',
        requestStatus: 'PENDING',
        createdAt: '',
      ),
    );
  }

  @override
  Future<EducationTutorAskKycResponse> askTutorForKyc({
    String? requestReference,
    String? mobile,
  }) async {
    askBodies.add({
      'request_reference': requestReference,
      'mobile': mobile,
    });
    return EducationTutorAskKycResponse(
      status: true,
      message: 'KYC reminder notification sent successfully.',
      data: EducationTutorAskKycData(
        requestReference: requestReference ?? '',
        notificationSentTo: 10,
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('posts request_reference to the ask-kyc endpoint', () async {
    final adapter = _StubAdapter();
    final repository = EducationFeesRepository(
      service: EducationFeesService(dio: Dio()..httpClientAdapter = adapter),
    );

    final response = await repository.askTutorForKyc(
      requestReference: 'EDUTR20261106061937FFB19244',
    );

    final options = adapter.options!;
    expect(options.method, 'POST');
    expect(options.uri.toString(), ApiConstants.educationTutorAskKycEndpoint);
    expect(options.data, {
      'request_reference': 'EDUTR20261106061937FFB19244',
    });
    expect(response.status, isTrue);
    expect(
      response.message,
      'KYC reminder notification sent successfully.',
    );
    expect(response.data?.requestReference, 'EDUTR20261106061937FFB19244');
    expect(response.data?.notificationSentTo, 10);
  });

  test('parses notification_sent_to when the backend sends it as text', () {
    final response = EducationTutorAskKycResponse.fromJson({
      'status': true,
      'message': 'KYC reminder notification sent successfully.',
      'data': {
        'request_reference': 'EDUTR20261106061937FFB19244',
        'notification_sent_to': '10',
      },
    });

    expect(response.data?.notificationSentTo, 10);
  });

  test('ask-kyc body is request_reference and never the mobile', () async {
    final adapter = _StubAdapter();
    final repository = EducationFeesRepository(
      service: EducationFeesService(dio: Dio()..httpClientAdapter = adapter),
    );

    await repository.askTutorForKyc(
      requestReference: 'EDUTR20261106061937FFB19244',
      mobile: '9876543210',
    );

    expect(adapter.options!.uri.toString(),
        ApiConstants.educationTutorAskKycEndpoint);
    expect(adapter.options!.data, {
      'request_reference': 'EDUTR20261106061937FFB19244',
    });
    expect(adapter.options!.data.toString().contains('mobile'), isFalse);
  });

  test('asks with the stored reference and does not send a payment request',
      () async {
    final repo = _FakeAskRepository();
    final controller = EducationFeesController(repository: repo);
    controller.storeTutorRequestReference('EDUTR-ALREADY-SENT');
    controller.updateMobileInput('9876543210');

    final response = await controller.askTutorForKyc();

    expect(repo.sendCount, 0);
    expect(repo.askBodies, [
      {
        'request_reference': 'EDUTR-ALREADY-SENT',
        'mobile': null,
      },
    ]);
    expect(response?.status, isTrue);
  });

  test('creates a request reference before ask-kyc when none is stored',
      () async {
    final repo = _FakeAskRepository();
    final controller = EducationFeesController(repository: repo);
    controller.updateMobileInput('9876543210');
    controller.updateAmountInput('2000');
    controller.updateFeeType('tuition fees');

    final response = await controller.askTutorForKyc();

    expect(repo.sendCount, 1);
    expect(repo.askBodies.single['mobile'], isNull);
    expect(repo.askBodies.single['request_reference'], 'EDUTR-CREATED');
    expect(response?.status, isTrue);
  });
}
