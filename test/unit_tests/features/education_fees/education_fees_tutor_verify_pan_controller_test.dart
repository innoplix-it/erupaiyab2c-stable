import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_rupaiya/features/educationFees/controllers/education_fees_controller.dart';
import 'package:e_rupaiya/features/educationFees/models/education_fees_responses.dart';
import 'package:e_rupaiya/features/educationFees/repositories/education_fees_repository.dart';

class _FakeTutorPanRepository extends EducationFeesRepository {
  _FakeTutorPanRepository() : super();

  Object? error;
  EducationTutorVerifyPanResponse? response;
  int callCount = 0;
  final pans = <String>[];
  int verifyPanCallCount = 0;

  bool hangNext = false;
  final inFlight = <Completer<EducationTutorVerifyPanResponse>>[];

  @override
  Future<EducationTutorVerifyPanResponse> verifyTutorPan(String pan) async {
    callCount++;
    pans.add(pan);
    if (hangNext) {
      final completer = Completer<EducationTutorVerifyPanResponse>();
      inFlight.add(completer);
      return completer.future;
    }
    final thrown = error;
    if (thrown != null) throw thrown;
    return response ??
        const EducationTutorVerifyPanResponse(
          status: true,
          message: 'Tutor PAN already verified.',
          data: EducationTutorVerifyPanData(
            recipientReference: 'EDUTUT180D00AA6BBCBE0C941904F1',
            beneficiaryId: 39,
            name: 'TEST TUTOR NAME',
            panMasked: 'ABCDE****F',
            panVerified: true,
          ),
        );
  }

  @override
  Future<EducationVerifyPanResponse> verifyPan({
    required String name,
    required String pan,
    required String deviceId,
  }) async {
    verifyPanCallCount++;
    return const EducationVerifyPanResponse(status: true);
  }
}

void main() {
  late _FakeTutorPanRepository repository;
  late EducationFeesController controller;

  setUp(() {
    repository = _FakeTutorPanRepository();
    controller = EducationFeesController(repository: repository);
    controller.updateRecipientName('Ravi Kumar');
  });

  tearDown(() {
    controller.dispose();
  });

  group('EducationFeesController.verifyTutorPan', () {
    test('incomplete or invalid PAN never calls the API', () async {
      for (final pan in ['A', 'ABCDE1234', '1234567890', 'ABCDEFGHIJ']) {
        controller.updatePan(pan);
        await controller.verifyTutorPan();
      }

      expect(repository.callCount, 0);
      expect(controller.state.panVerified, isFalse);
      expect(controller.state.recipientReference, isNull);
    });

    test('a valid PAN is sent in uppercase and stored from the response',
        () async {
      controller.updateRecipientName('test tutor name');
      controller.updatePan('abcde1234f');
      await controller.verifyTutorPan();

      expect(repository.callCount, 1);
      expect(repository.pans, ['ABCDE1234F']);
      expect(repository.verifyPanCallCount, 0);
      expect(controller.state.isVerifyingPan, isFalse);
      expect(controller.state.panVerified, isTrue);
      expect(controller.state.panErrorMessage, isNull);
      expect(
        controller.state.recipientReference,
        'EDUTUT180D00AA6BBCBE0C941904F1',
      );
      expect(controller.state.beneficiaryId, 39);
      expect(controller.state.panMasked, 'ABCDE****F');
      expect(controller.state.verifiedPanName, 'TEST TUTOR NAME');
      expect(controller.state.pan, 'abcde1234f');
    });

    test('status false does not keep the reference or mark PAN verified',
        () async {
      repository.response = const EducationTutorVerifyPanResponse(
        status: false,
        message: 'Invalid PAN',
        data: EducationTutorVerifyPanData(
          recipientReference: 'EDUTUT180D00AA6BBCBE0C941904F1',
          beneficiaryId: 39,
          name: 'TEST TUTOR NAME',
          panMasked: 'ABCDE****F',
          panVerified: true,
        ),
      );
      controller.updatePan('FGHIJ5678K');

      await controller.verifyTutorPan();

      expect(controller.state.panVerified, isFalse);
      expect(controller.state.panErrorMessage, 'Invalid PAN');
      expect(controller.state.recipientReference, isNull);
      expect(controller.state.beneficiaryId, isNull);
      expect(controller.state.panMasked, isNull);
      expect(controller.state.isVerifyingPan, isFalse);
    });

    test('missing data is not treated as success', () async {
      repository.response = const EducationTutorVerifyPanResponse(
        status: true,
        message: 'Tutor PAN already verified.',
      );
      controller.updatePan('FGHIJ5678K');

      await controller.verifyTutorPan();

      expect(controller.state.panVerified, isFalse);
      expect(controller.state.recipientReference, isNull);
      expect(
        controller.state.panErrorMessage,
        'Tutor PAN already verified.',
      );
    });

    test('pan_verified false is not business success', () async {
      repository.response = const EducationTutorVerifyPanResponse(
        status: true,
        message: 'PAN could not be verified.',
        data: EducationTutorVerifyPanData(
          recipientReference: 'EDUTUTSHOULDNOTBEUSED',
          beneficiaryId: 8,
          name: 'SOME NAME',
          panMasked: 'ABCDE****F',
          panVerified: false,
        ),
      );
      controller.updatePan('FGHIJ5678K');

      await controller.verifyTutorPan();

      expect(controller.state.panVerified, isFalse);
      expect(controller.state.recipientReference, isNull);
      expect(controller.state.beneficiaryId, isNull);
      expect(controller.state.panErrorMessage, 'PAN could not be verified.');
    });

    test('network failure surfaces an error and clears the reference',
        () async {
      repository.error = DioException(
        type: DioExceptionType.connectionError,
        requestOptions: RequestOptions(path: ''),
      );
      controller.updatePan('FGHIJ5678K');

      await controller.verifyTutorPan();

      expect(controller.state.panVerified, isFalse);
      expect(controller.state.isVerifyingPan, isFalse);
      expect(controller.state.recipientReference, isNull);
      expect(controller.state.panErrorMessage, isNotNull);
      expect(controller.state.panErrorMessage, isNot(contains('ABCDE1234F')));
    });

    test('a different spelling is not treated as verified', () async {
      controller.updateRecipientName('Ravi Kumar');
      controller.updatePan('FGHIJ5678K');

      await controller.verifyTutorPan();

      expect(repository.callCount, 1);
      expect(controller.state.panVerified, isFalse);
      expect(controller.state.recipientReference, isNull);
      expect(controller.state.beneficiaryId, isNull);
      expect(controller.state.panMasked, isNull);
      expect(
        controller.state.panErrorMessage,
        'Name does not match the PAN name. Enter TEST TUTOR NAME.',
      );
    });

    test('a second call while loading does not send another request', () async {
      repository.hangNext = true;
      controller.updateRecipientName('TEST TUTOR NAME');
      controller.updatePan('FGHIJ5678K');

      final first = controller.verifyTutorPan();
      expect(controller.state.isVerifyingPan, isTrue);
      final second = controller.verifyTutorPan();

      expect(repository.callCount, 1);
      repository.inFlight.single.complete(
        const EducationTutorVerifyPanResponse(
          status: true,
          data: EducationTutorVerifyPanData(
            recipientReference: 'EDUTUT180D00AA6BBCBE0C941904F1',
            beneficiaryId: 39,
            name: 'TEST TUTOR NAME',
            panMasked: 'ABCDE****F',
            panVerified: true,
          ),
        ),
      );
      await first;
      await second;

      expect(controller.state.panVerified, isTrue);
      expect(
        controller.state.recipientReference,
        'EDUTUT180D00AA6BBCBE0C941904F1',
      );
      expect(controller.state.isVerifyingPan, isFalse);
    });

    test('a late response for a previous PAN cannot replace the new one',
        () async {
      repository.hangNext = true;
      controller.updateRecipientName('New Name');
      controller.updatePan('FGHIJ5678K');
      final first = controller.verifyTutorPan();
      controller.updatePan('XYZAB1234C');
      final second = controller.verifyTutorPan();

      expect(repository.pans, ['FGHIJ5678K', 'XYZAB1234C']);

      repository.inFlight[1].complete(
        const EducationTutorVerifyPanResponse(
          status: true,
          data: EducationTutorVerifyPanData(
            recipientReference: 'EDUTUTNEW',
            beneficiaryId: 40,
            name: 'NEW NAME',
            panMasked: 'XYZAB****C',
            panVerified: true,
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      repository.inFlight[0].complete(
        const EducationTutorVerifyPanResponse(
          status: false,
          message: 'stale',
        ),
      );
      await first;
      await second;

      expect(controller.state.panVerified, isTrue);
      expect(controller.state.recipientReference, 'EDUTUTNEW');
      expect(controller.state.beneficiaryId, 40);
      expect(controller.state.panMasked, 'XYZAB****C');
      expect(controller.state.panErrorMessage, isNull);
    });

    test('editing the PAN drops the stored recipient reference', () async {
      controller.updateRecipientName('TEST TUTOR NAME');
      controller.updatePan('FGHIJ5678K');
      await controller.verifyTutorPan();
      expect(controller.state.recipientReference, isNotNull);

      controller.updatePan('XYZAB1234C');

      expect(controller.state.recipientReference, isNull);
      expect(controller.state.beneficiaryId, isNull);
      expect(controller.state.panMasked, isNull);
      expect(controller.state.panVerified, isFalse);
    });

    test('existing education verifyPan does not call tutor PAN verify',
        () async {
      controller.updatePan('FGHIJ5678K');

      await controller.verifyPan();

      expect(repository.verifyPanCallCount, 1);
      expect(repository.callCount, 0);
      expect(controller.state.panVerified, isTrue);
      expect(controller.state.recipientReference, isNull);
    });
  });
}
