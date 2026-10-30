import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:e_rupaiya/features/educationFees/controllers/education_fees_controller.dart';
import 'package:e_rupaiya/features/educationFees/models/education_account_type.dart';
import 'package:e_rupaiya/features/educationFees/models/education_fees_responses.dart';
import 'package:e_rupaiya/features/educationFees/repositories/education_fees_repository.dart';

/// Records saveBeneficiary invocations; optionally gates the response on a
/// completer so in-flight (duplicate-tap) behaviour can be asserted.
class _FakeRepo extends EducationFeesRepository {
  _FakeRepo({this.response, this.error}) : super();

  EducationSaveBeneficiaryResponse? response;
  final Object? error;

  int callCount = 0;
  Map<String, String>? lastPayload;
  Completer<EducationSaveBeneficiaryResponse>? gate;

  @override
  Future<EducationSaveBeneficiaryResponse> saveBeneficiary({
    required String name,
    required String mobile,
    required String pan,
    required String accountType,
    required String accountNo,
    required String ifsc,
  }) async {
    callCount++;
    lastPayload = {
      'name': name,
      'mobile': mobile,
      'pan': pan,
      'account_type': accountType,
      'account_no': accountNo,
      'ifsc': ifsc,
    };
    final gateCompleter = gate;
    if (gateCompleter != null) return gateCompleter.future;
    if (error != null) throw error!;
    return response ??
        const EducationSaveBeneficiaryResponse(status: true, beneficiaryId: 7);
  }
}

EducationFeesController _controllerWithValidForm(
  _FakeRepo repo, {
  bool showRecipientFields = true,
  bool panVerified = true,
  bool bankVerified = true,
  String accountNumber = '1234567890',
  String ifsc = 'HDFC0001234',
  String mobileInput = '9876543210',
}) {
  final controller = EducationFeesController(repository: repo);
  controller.state = controller.state.copyWith(
    showRecipientFields: showRecipientFields,
    recipientName: 'Ravi Kumar',
    mobileInput: mobileInput,
    pan: 'ABCDE1234F',
    panVerified: panVerified,
    accountType: EducationAccountType.bankDetails,
    accountNumber: accountNumber,
    ifsc: ifsc,
    bankVerified: bankVerified,
  );
  return controller;
}

void main() {
  group('saveBeneficiary flow gate (D1)', () {
    test('unverified Add Details submission reaches the repository', () async {
      final repo = _FakeRepo();
      final controller = _controllerWithValidForm(
        repo,
        showRecipientFields: false,
      );

      final ok = await controller.saveBeneficiary(unverifiedFlow: true);

      expect(ok, isTrue);
      expect(repo.callCount, 1);
      expect(repo.lastPayload!['name'], 'Ravi Kumar');
      expect(repo.lastPayload!['mobile'], '9876543210');
      expect(repo.lastPayload!['pan'], 'ABCDE1234F');
      expect(repo.lastPayload!['account_type'], 'bank');
      expect(repo.lastPayload!['account_no'], '1234567890');
      expect(repo.lastPayload!['ifsc'], 'HDFC0001234');
      expect(controller.state.beneficiaryId, 7);
    });

    test('normal flow still blocks when recipient registration failed',
        () async {
      final repo = _FakeRepo();
      final controller = _controllerWithValidForm(
        repo,
        showRecipientFields: false,
      );

      final ok = await controller.saveBeneficiary();

      expect(ok, isFalse);
      expect(repo.callCount, 0);
      expect(controller.state.saveErrorMessage, isNotNull);
    });

    test('unverified flow still requires PAN verification', () async {
      final repo = _FakeRepo();
      final controller = _controllerWithValidForm(
        repo,
        showRecipientFields: false,
        panVerified: false,
      );

      final ok = await controller.saveBeneficiary(unverifiedFlow: true);

      expect(ok, isFalse);
      expect(repo.callCount, 0);
      expect(controller.state.saveErrorMessage, 'Please verify PAN details.');
    });

    test('unverified flow still requires bank verification', () async {
      final repo = _FakeRepo();
      final controller = _controllerWithValidForm(
        repo,
        showRecipientFields: false,
        bankVerified: false,
      );

      final ok = await controller.saveBeneficiary(unverifiedFlow: true);

      expect(ok, isFalse);
      expect(repo.callCount, 0);
      expect(
        controller.state.saveErrorMessage,
        'Please verify bank details.',
      );
    });

    test('missing required details do not submit', () async {
      final repo = _FakeRepo();
      final controller = _controllerWithValidForm(
        repo,
        accountNumber: '',
      );

      final ok = await controller.saveBeneficiary(unverifiedFlow: true);

      expect(ok, isFalse);
      expect(repo.callCount, 0);
      expect(
        controller.state.saveErrorMessage,
        'Please fill all required details.',
      );
    });

    test('short mobile number does not submit', () async {
      final repo = _FakeRepo();
      final controller = _controllerWithValidForm(
        repo,
        mobileInput: '987654321',
      );

      final ok = await controller.saveBeneficiary(unverifiedFlow: true);

      expect(ok, isFalse);
      expect(repo.callCount, 0);
      expect(
        controller.state.saveErrorMessage,
        'Please fill all required details.',
      );
    });
  });

  group('saveBeneficiary duplicate protection (D3)', () {
    test('second concurrent call is rejected while one request is in flight',
        () async {
      final repo = _FakeRepo()
        ..gate = Completer<EducationSaveBeneficiaryResponse>();
      final controller = _controllerWithValidForm(repo);

      final first = controller.saveBeneficiary();
      // Let the first call reach the repository await.
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.isSavingBeneficiary, isTrue);

      final second = await controller.saveBeneficiary();

      expect(second, isFalse);
      expect(repo.callCount, 1);

      repo.gate!.complete(
        const EducationSaveBeneficiaryResponse(status: true, beneficiaryId: 9),
      );
      expect(await first, isTrue);
      expect(controller.state.isSavingBeneficiary, isFalse);
      expect(controller.state.beneficiaryId, 9);
    });

    test('submission is allowed again after a completed failure', () async {
      final repo = _FakeRepo(
        response: const EducationSaveBeneficiaryResponse(
          status: false,
          message: 'Beneficiary already exists.',
        ),
      );
      final controller = _controllerWithValidForm(repo);

      expect(await controller.saveBeneficiary(), isFalse);
      expect(controller.state.isSavingBeneficiary, isFalse);
      expect(controller.state.saveErrorMessage, 'Beneficiary already exists.');

      // Retry after the server-side issue is resolved: submission succeeds.
      repo.response = const EducationSaveBeneficiaryResponse(
          status: true, beneficiaryId: 5);
      expect(await controller.saveBeneficiary(), isTrue);
      expect(repo.callCount, 2);
    });
  });

  group('saveBeneficiary loading state resets', () {
    test('success resets loading and stores the beneficiary id', () async {
      final repo = _FakeRepo();
      final controller = _controllerWithValidForm(repo);

      expect(await controller.saveBeneficiary(), isTrue);
      expect(controller.state.isSavingBeneficiary, isFalse);
      expect(controller.state.beneficiaryId, 7);
      expect(controller.state.saveErrorMessage, isNull);
    });

    test('server error resets loading and surfaces the message', () async {
      final repo = _FakeRepo(
        response: const EducationSaveBeneficiaryResponse(
          status: false,
          message: 'Account name mismatch.',
        ),
      );
      final controller = _controllerWithValidForm(repo);

      expect(await controller.saveBeneficiary(), isFalse);
      expect(controller.state.isSavingBeneficiary, isFalse);
      expect(controller.state.saveErrorMessage, 'Account name mismatch.');
    });

    test('network exception resets loading without false success', () async {
      final repo = _FakeRepo(error: Exception('Connection failed'));
      final controller = _controllerWithValidForm(repo);

      expect(await controller.saveBeneficiary(), isFalse);
      expect(controller.state.isSavingBeneficiary, isFalse);
      expect(controller.state.saveErrorMessage, isNotNull);
      expect(controller.state.beneficiaryId, isNull);
    });

    test('validation failures never leave the loading flag set', () async {
      final repo = _FakeRepo();
      final controller = _controllerWithValidForm(
        repo,
        showRecipientFields: false,
        panVerified: false,
      );

      expect(await controller.saveBeneficiary(), isFalse);
      expect(controller.state.isSavingBeneficiary, isFalse);

      expect(await controller.saveBeneficiary(unverifiedFlow: true), isFalse);
      expect(controller.state.isSavingBeneficiary, isFalse);
      expect(repo.callCount, 0);
    });
  });
}
