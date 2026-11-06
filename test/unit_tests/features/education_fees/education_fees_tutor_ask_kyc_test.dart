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
  }) async {
    sendCount++;
    return const EducationTutorSendRequestResponse(status: false);
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

  test('posts the tutor mobile and never calls send-request', () async {
    final adapter = _StubAdapter();
    final repository = EducationFeesRepository(
      service: EducationFeesService(dio: Dio()..httpClientAdapter = adapter),
    );

    await repository.askTutorForKyc(mobile: '9876543210');

    expect(adapter.options!.uri.toString(),
        ApiConstants.educationTutorAskKycEndpoint);
    expect(adapter.options!.data, {'mobile': '9876543210'});
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
        'mobile': '9876543210',
      },
    ]);
    expect(response?.status, isTrue);
  });

  test('asks with the searched mobile when no request exists', () async {
    final repo = _FakeAskRepository();
    final controller = EducationFeesController(repository: repo);
    controller.updateMobileInput('9876543210');

    final response = await controller.askTutorForKyc();

    expect(repo.sendCount, 0);
    expect(repo.askBodies.single['mobile'], '9876543210');
    expect(repo.askBodies.single['request_reference'], isNull);
    expect(response?.status, isTrue);
  });
}
