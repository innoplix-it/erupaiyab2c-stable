import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:e_rupaiya/features/educationFees/controllers/education_fees_controller.dart';
import 'package:e_rupaiya/features/educationFees/models/education_account_type.dart';
import 'package:e_rupaiya/features/educationFees/models/education_fees_responses.dart';
import 'package:e_rupaiya/features/educationFees/repositories/education_fees_repository.dart';

class _FakeEducationRepository extends EducationFeesRepository {
  _FakeEducationRepository({this.checkMobileResponse});

  EducationCheckMobileResponse? checkMobileResponse;
  Object? checkMobileError;
  int checkMobileCallCount = 0;
  int saveBeneficiaryCallCount = 0;

  @override
  Future<EducationCheckMobileResponse> checkMobile(String mobile) async {
    checkMobileCallCount++;
    if (checkMobileError != null) {
      throw checkMobileError!;
    }
    await Future<void>.delayed(Duration.zero);
    return checkMobileResponse ??
        const EducationCheckMobileResponse(status: false, exists: false);
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
    saveBeneficiaryCallCount++;
    return const EducationSaveBeneficiaryResponse(status: true, beneficiaryId: 1);
  }
}

EducationFeesController _controller(_FakeEducationRepository repo) =>
    EducationFeesController(repository: repo);

void main() {
  group('EducationFeesController.checkMobile registration gate', () {
    test('registered user enables Add Tutor fields', () async {
      final repo = _FakeEducationRepository(
        checkMobileResponse: const EducationCheckMobileResponse(
          status: true,
          exists: true,
        ),
      );
      final controller = _controller(repo);

      controller.updateMobileInput('9876543210');
      await controller.checkMobile();

      expect(repo.checkMobileCallCount, 1);
      expect(controller.state.showRecipientFields, isTrue);
      expect(controller.state.mobileErrorMessage, isNull);
    });

    test('unregistered user is blocked with registration message', () async {
      final repo = _FakeEducationRepository(
        checkMobileResponse: const EducationCheckMobileResponse(
          status: true,
          exists: false,
          message: 'User not on platform',
        ),
      );
      final controller = _controller(repo);

      controller.updateMobileInput('9876543210');
      await controller.checkMobile();

      expect(controller.state.showRecipientFields, isFalse);
      expect(controller.state.mobileErrorMessage, 'User not on platform');
    });

    test('network failure does not enable fields', () async {
      final repo = _FakeEducationRepository()
        ..checkMobileError = Exception('timeout');
      final controller = _controller(repo);

      controller.updateMobileInput('9876543210');
      await controller.checkMobile();

      expect(controller.state.showRecipientFields, isFalse);
      expect(controller.state.mobileErrorMessage, isNotNull);
      expect(
        controller.state.mobileErrorMessage,
        isNot(EducationFeesController.unregisteredMobileMessage),
      );
    });

    test('status false without exists treats as verification failure', () async {
      final repo = _FakeEducationRepository(
        checkMobileResponse: const EducationCheckMobileResponse(
          status: false,
          exists: false,
          message: 'Invalid request',
        ),
      );
      final controller = _controller(repo);

      controller.updateMobileInput('9876543210');
      await controller.checkMobile();

      expect(controller.state.showRecipientFields, isFalse);
      expect(controller.state.mobileErrorMessage, 'Invalid request');
    });

    test('stale check-mobile response is ignored after mobile edit', () async {
      final responseGate = Completer<EducationCheckMobileResponse>();
      var call = 0;
      final delayedRepo = _DelayedCheckMobileRepository(
        onCall: () async {
          call++;
          if (call == 1) {
            return responseGate.future;
          }
          return const EducationCheckMobileResponse(
            status: true,
            exists: true,
          );
        },
      );
      final controller = EducationFeesController(repository: delayedRepo);

      controller.updateMobileInput('9876543210');
      final first = controller.checkMobile();
      controller.updateMobileInput('9876543211');
      await controller.checkMobile();

      responseGate.complete(
        const EducationCheckMobileResponse(status: true, exists: true),
      );
      await first;

      expect(controller.state.mobileInput, '9876543211');
      expect(controller.state.showRecipientFields, isTrue);
    });

    test('saveBeneficiary is not called when registration failed', () async {
      final repo = _FakeEducationRepository(
        checkMobileResponse: const EducationCheckMobileResponse(
          status: true,
          exists: false,
        ),
      );
      final controller = _controller(repo);

      controller.updateMobileInput('9876543210');
      await controller.checkMobile();
      controller.updateRecipientName('Tutor');
      controller.updatePan('ABCDE1234F');
      controller.state = controller.state.copyWith(panVerified: true);
      controller.state = controller.state.copyWith(
        accountType: EducationAccountType.bankDetails,
        bankVerified: true,
        accountNumber: '1234567890',
        ifsc: 'HDFC0001234',
      );

      final saved = await controller.saveBeneficiary();

      expect(saved, isFalse);
      expect(repo.saveBeneficiaryCallCount, 0);
    });
  });
}

class _DelayedCheckMobileRepository extends EducationFeesRepository {
  _DelayedCheckMobileRepository({required this.onCall});

  final Future<EducationCheckMobileResponse> Function() onCall;

  @override
  Future<EducationCheckMobileResponse> checkMobile(String mobile) => onCall();
}
