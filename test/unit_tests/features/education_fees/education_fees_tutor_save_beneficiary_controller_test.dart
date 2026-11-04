import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_rupaiya/features/educationFees/controllers/education_fees_controller.dart';
import 'package:e_rupaiya/features/educationFees/models/education_account_type.dart';
import 'package:e_rupaiya/features/educationFees/models/education_fees_responses.dart';
import 'package:e_rupaiya/features/educationFees/repositories/education_fees_repository.dart';

const _panReference = 'EDUTUT180D00AA6BBCBE0C941904F1';

class _FakeTutorSaveBeneficiaryRepository extends EducationFeesRepository {
  _FakeTutorSaveBeneficiaryRepository() : super();

  Object? error;
  EducationTutorSaveBeneficiaryResponse? response;
  int callCount = 0;
  final requests = <String>[];
  int verifyTutorPanCallCount = 0;
  int verifyTutorBankCallCount = 0;

  @override
  Future<EducationTutorVerifyPanResponse> verifyTutorPan(String pan) async {
    verifyTutorPanCallCount++;
    return const EducationTutorVerifyPanResponse(
      status: true,
      message: 'Tutor PAN already verified.',
      data: EducationTutorVerifyPanData(
        recipientReference: _panReference,
        beneficiaryId: 39,
        name: 'SUPRIYA SARANG ITHAPE',
        panMasked: 'ABXPI****E',
        panVerified: true,
      ),
    );
  }

  @override
  Future<EducationTutorVerifyBankResponse> verifyTutorBank({
    required String recipientReference,
    required String accountNo,
    required String ifsc,
  }) async {
    verifyTutorBankCallCount++;
    return const EducationTutorVerifyBankResponse(
      status: true,
      message: 'Tutor recipient bank account verified successfully.',
      data: EducationTutorVerifyBankData(
        recipientReference: _panReference,
        beneficiaryId: 39,
        name: 'SUPRIYA SARANG ITHAPE',
        accountNumber: 'XXXXXX7911',
        ifsc: 'UBIN0546771',
        transactionReference: 1474338350,
        bankVerified: true,
      ),
    );
  }

  @override
  Future<EducationTutorSaveBeneficiaryResponse> saveTutorBeneficiary({
    required String recipientReference,
  }) async {
    callCount++;
    requests.add(recipientReference);
    final thrown = error;
    if (thrown != null) throw thrown;
    return response ??
        const EducationTutorSaveBeneficiaryResponse(
          status: true,
          message: 'Tutor beneficiary saved successfully.',
          beneficiaryId: 39,
          recipientReference: _panReference,
        );
  }

  @override
  Future<EducationSaveBeneficiaryResponse> saveBeneficiary({
    required String name,
    required String mobile,
    required String pan,
    required String accountType,
    required String accountNo,
    required String ifsc,
  }) async {
    // Mock the registered flow to avoid real HTTP calls
    return const EducationSaveBeneficiaryResponse(
      status: true,
      beneficiaryId: 100,
    );
  }
}

void main() {
  late _FakeTutorSaveBeneficiaryRepository repository;
  late EducationFeesController controller;

  /// Drives the controller into the exact state the Add Details form
  /// reaches after successful PAN and bank verification.
  Future<void> readyForm({
    String account = '91201000123457911',
    String ifsc = 'ubin0546771',
  }) async {
    controller.updateRecipientName('SUPRIYA SARANG ITHAPE');
    controller.updatePan('ABXPI7963E');
    await controller.verifyTutorPan();
    controller.updateAccountType(EducationAccountType.bankDetails);
    controller.updateAccountNumber(account);
    controller.updateIfsc(ifsc);
    await controller.verifyTutorBank();
    expect(controller.state.recipientReference, _panReference);
    expect(controller.state.panVerified, isTrue);
    expect(controller.state.bankVerified, isTrue);
  }

  setUp(() {
    repository = _FakeTutorSaveBeneficiaryRepository();
    controller = EducationFeesController(repository: repository);
  });

  tearDown(() {
    controller.dispose();
  });

  group('EducationFeesController._saveTutorBeneficiary guards', () {
    test('missing recipient reference never calls the API', () async {
      controller.updateRecipientName('Ravi Kumar');
      controller.updatePan('ABXPI7963E');
      await controller.verifyTutorPan();
      controller.updateAccountType(EducationAccountType.bankDetails);
      controller.updateAccountNumber('91201000123457911');
      controller.updateIfsc('UBIN0546771');
      await controller.verifyTutorBank();

      // Manually clear the reference by updating PAN (which clears reference)
      controller.updatePan('ABXPI7963F');

      final ok = await controller.saveBeneficiary(unverifiedFlow: true);

      expect(repository.callCount, 0);
      expect(ok, isFalse);
      expect(controller.state.isSavingBeneficiary, isFalse);
      expect(controller.state.saveErrorMessage, 'Please verify PAN details.');
    });

    test('PAN verification incomplete blocks save', () async {
      controller.updateRecipientName('Ravi Kumar');
      controller.updatePan('ABXPI7963E');
      controller.updateAccountType(EducationAccountType.bankDetails);
      controller.updateAccountNumber('91201000123457911');
      controller.updateIfsc('UBIN0546771');

      final ok = await controller.saveBeneficiary(unverifiedFlow: true);

      expect(repository.callCount, 0);
      expect(ok, isFalse);
      expect(controller.state.saveErrorMessage, 'Please verify PAN details.');
    });

    test('bank verification incomplete blocks save', () async {
      controller.updateRecipientName('Ravi Kumar');
      controller.updatePan('ABXPI7963E');
      await controller.verifyTutorPan();
      controller.updateAccountType(EducationAccountType.bankDetails);
      controller.updateAccountNumber('91201000123457911');
      controller.updateIfsc('UBIN0546771');

      final ok = await controller.saveBeneficiary(unverifiedFlow: true);

      expect(repository.callCount, 0);
      expect(ok, isFalse);
      expect(controller.state.saveErrorMessage, 'Please verify bank details.');
    });

    test('recipient reference is sent dynamically', () async {
      await readyForm();

      await controller.saveBeneficiary(unverifiedFlow: true);

      expect(repository.callCount, 1);
      expect(repository.requests.single, _panReference);
    });
  });

  group('EducationFeesController._saveTutorBeneficiary results', () {
    test('success stores beneficiary_id and preserves recipient_reference',
        () async {
      await readyForm();

      final ok = await controller.saveBeneficiary(unverifiedFlow: true);

      expect(ok, isTrue);
      expect(controller.state.isSavingBeneficiary, isFalse);
      expect(controller.state.beneficiaryId, 39);
      expect(controller.state.recipientReference, _panReference);
      expect(controller.state.saveErrorMessage, isNull);
    });

    test('network failure surfaces an error', () async {
      final errorRepository = _FakeTutorSaveBeneficiaryRepository();
      errorRepository.error = DioException(
        type: DioExceptionType.connectionError,
        requestOptions: RequestOptions(path: ''),
      );
      final errorController =
          EducationFeesController(repository: errorRepository);
      await readyFormForController(errorController);

      final ok = await errorController.saveBeneficiary(unverifiedFlow: true);

      expect(ok, isFalse);
      expect(errorController.state.isSavingBeneficiary, isFalse);
      expect(errorController.state.saveErrorMessage, isNotNull);
      errorController.dispose();
    });

    test('response with updated recipient_reference preserves it', () async {
      const newReference = 'EDUTUT180D00AA6BBCBE0C941904F2';
      final updateRepository = _FakeTutorSaveBeneficiaryRepository();
      updateRepository.response = const EducationTutorSaveBeneficiaryResponse(
        status: true,
        message: 'Tutor beneficiary saved successfully.',
        beneficiaryId: 40,
        recipientReference: newReference,
      );
      final updateController =
          EducationFeesController(repository: updateRepository);
      await readyFormForController(updateController);

      final ok = await updateController.saveBeneficiary(unverifiedFlow: true);

      expect(ok, isTrue);
      expect(updateController.state.beneficiaryId, 40);
      expect(updateController.state.recipientReference, newReference);
      updateController.dispose();
    });
  });

  group('EducationFeesController._saveTutorBeneficiary submission safety', () {
    test('a second call while loading does not send another request', () async {
      await readyForm();
      final completer = Completer<EducationTutorSaveBeneficiaryResponse>();

      // Override the repository to hang
      final hangingRepository = _FakeTutorSaveBeneficiaryRepository();
      hangingRepository.response = const EducationTutorSaveBeneficiaryResponse(
        status: true,
        beneficiaryId: 39,
        recipientReference: _panReference,
      );
      final hangingController =
          EducationFeesController(repository: hangingRepository);
      await readyFormForController(hangingController);

      final first = hangingController.saveBeneficiary(unverifiedFlow: true);
      expect(hangingController.state.isSavingBeneficiary, isTrue);
      final second = hangingController.saveBeneficiary(unverifiedFlow: true);

      expect(hangingRepository.callCount, 1);
      completer.complete(
        const EducationTutorSaveBeneficiaryResponse(
          status: true,
          beneficiaryId: 39,
          recipientReference: _panReference,
        ),
      );
      await first;
      await second;

      expect(hangingController.state.beneficiaryId, 39);
      expect(hangingController.state.isSavingBeneficiary, isFalse);
      hangingController.dispose();
    });

    test('re-entry guard blocks duplicate submissions', () async {
      await readyForm();

      final first = controller.saveBeneficiary(unverifiedFlow: true);
      // Immediately try again while first is in flight
      final second = controller.saveBeneficiary(unverifiedFlow: true);

      await first;
      await second;

      expect(repository.callCount, 1);
    });
  });

  group('no regression to registered flow', () {
    test('registered flow does not call tutor save beneficiary', () async {
      final registeredRepository = _FakeTutorSaveBeneficiaryRepository();
      final registeredController =
          EducationFeesController(repository: registeredRepository);
      registeredController.updateRecipientName('Ravi Kumar');
      registeredController.updateMobileInput('9876543210');
      registeredController.updatePan('ABCDE1234F');
      registeredController.updateAccountType(EducationAccountType.bankDetails);
      registeredController.updateAccountNumber('91201000123457911');
      registeredController.updateIfsc('UBIN0546771');
      registeredController.state = registeredController.state.copyWith(
        panVerified: true,
        bankVerified: true,
        showRecipientFields: true,
      );

      final ok = await registeredController.saveBeneficiary(unverifiedFlow: false);

      expect(registeredRepository.callCount, 0);
      registeredController.dispose();
    });
  });
}

/// Helper to ready a different controller instance for the hanging test.
Future<void> readyFormForController(EducationFeesController ctrl) async {
  ctrl.updateRecipientName('SUPRIYA SARANG ITHAPE');
  ctrl.updatePan('ABXPI7963E');
  await ctrl.verifyTutorPan();
  ctrl.updateAccountType(EducationAccountType.bankDetails);
  ctrl.updateAccountNumber('91201000123457911');
  ctrl.updateIfsc('ubin0546771');
  await ctrl.verifyTutorBank();
}
