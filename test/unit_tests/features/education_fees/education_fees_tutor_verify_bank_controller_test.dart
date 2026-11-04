import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_rupaiya/features/educationFees/controllers/education_fees_controller.dart';
import 'package:e_rupaiya/features/educationFees/models/education_account_type.dart';
import 'package:e_rupaiya/features/educationFees/models/education_fees_responses.dart';
import 'package:e_rupaiya/features/educationFees/repositories/education_fees_repository.dart';

const _panReference = 'EDUTUT180D00AA6BBCBE0C941904F1';

class _FakeTutorBankRepository extends EducationFeesRepository {
  _FakeTutorBankRepository() : super();

  Object? error;
  EducationTutorVerifyBankResponse? response;
  int callCount = 0;
  final requests = <EducationTutorVerifyBankRequest>[];
  int verifyBankCallCount = 0;
  int verifyTutorPanCallCount = 0;

  bool hangNext = false;
  final inFlight = <Completer<EducationTutorVerifyBankResponse>>[];

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
    callCount++;
    requests.add(
      EducationTutorVerifyBankRequest(
        recipientReference: recipientReference,
        accountNo: accountNo,
        ifsc: ifsc,
      ),
    );
    if (hangNext) {
      final completer = Completer<EducationTutorVerifyBankResponse>();
      inFlight.add(completer);
      return completer.future;
    }
    final thrown = error;
    if (thrown != null) throw thrown;
    return response ??
        const EducationTutorVerifyBankResponse(
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
  Future<EducationVerifyBankResponse> verifyBank({
    required String accountNo,
    required String ifsc,
    required String recipientName,
  }) async {
    verifyBankCallCount++;
    return const EducationVerifyBankResponse(status: true);
  }

  @override
  Future<EducationVerifyPanResponse> verifyPan({
    required String name,
    required String pan,
    required String deviceId,
  }) async {
    return const EducationVerifyPanResponse(status: true);
  }
}

void main() {
  late _FakeTutorBankRepository repository;
  late EducationFeesController controller;

  /// Drives the controller into the exact state the Add Details form
  /// reaches after a successful tutor PAN verification.
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
    expect(controller.state.recipientReference, _panReference);
  }

  setUp(() {
    repository = _FakeTutorBankRepository();
    controller = EducationFeesController(repository: repository);
  });

  tearDown(() {
    controller.dispose();
  });

  group('EducationFeesController.verifyTutorBank guards', () {
    test('a missing recipient reference never calls the API', () async {
      controller.updateRecipientName('Ravi Kumar');
      controller.updateAccountType(EducationAccountType.bankDetails);
      controller.updateAccountNumber('91201000123457911');
      controller.updateIfsc('UBIN0546771');

      await controller.verifyTutorBank();

      expect(repository.callCount, 0);
      expect(controller.state.isVerifyingBank, isFalse);
      expect(controller.state.bankVerified, isFalse);
    });

    test('empty account or IFSC never calls the API', () async {
      await readyForm();
      controller.updateAccountNumber('');
      await controller.verifyTutorBank();
      controller.updateAccountNumber('91201000123457911');
      controller.updateIfsc('');
      await controller.verifyTutorBank();

      expect(repository.callCount, 0);
    });

    test('the bank details account type is required', () async {
      await readyForm();
      controller.updateAccountType(EducationAccountType.none);

      await controller.verifyTutorBank();

      expect(repository.callCount, 0);
    });

    test('all three values are sent dynamically and IFSC is uppercased',
        () async {
      await readyForm(ifsc: 'ubin0546771');

      await controller.verifyTutorBank();

      expect(repository.callCount, 1);
      expect(repository.requests.single.toJson(), {
        'recipient_reference': _panReference,
        'account_no': '91201000123457911',
        'ifsc': 'UBIN0546771',
      });
      // The stored PAN-verification reference is reused verbatim; the
      // beneficiary id is never substituted for it.
      expect(repository.requests.single.recipientReference, _panReference);
      expect(repository.verifyBankCallCount, 0);
    });
  });

  group('EducationFeesController.verifyTutorBank results', () {
    test('success preserves every returned value', () async {
      await readyForm();

      await controller.verifyTutorBank();

      expect(controller.state.isVerifyingBank, isFalse);
      expect(controller.state.bankVerified, isTrue);
      expect(controller.state.bankErrorMessage, isNull);
      expect(controller.state.recipientReference, _panReference);
      expect(controller.state.beneficiaryId, 39);
      expect(controller.state.verifiedPanName, 'SUPRIYA SARANG ITHAPE');
      // Masked account number preserved exactly as the backend returned it.
      expect(controller.state.bankAccountMasked, 'XXXXXX7911');
      expect(controller.state.bankVerifiedIfsc, 'UBIN0546771');
      expect(controller.state.bankTransactionReference, 1474338350);
    });

    test('status false surfaces the backend message and clears results',
        () async {
      repository.response = const EducationTutorVerifyBankResponse(
        status: false,
        message: 'Account number and IFSC do not match.',
        data: EducationTutorVerifyBankData(
          recipientReference: _panReference,
          beneficiaryId: 39,
          name: 'SUPRIYA SARANG ITHAPE',
          accountNumber: 'XXXXXX7911',
          ifsc: 'UBIN0546771',
          transactionReference: 1,
          bankVerified: true,
        ),
      );
      await readyForm();

      await controller.verifyTutorBank();

      expect(controller.state.bankVerified, isFalse);
      expect(
        controller.state.bankErrorMessage,
        'Account number and IFSC do not match.',
      );
      expect(controller.state.bankAccountMasked, isNull);
      expect(controller.state.bankTransactionReference, isNull);
      expect(controller.state.isVerifyingBank, isFalse);
      // The PAN reference itself stays valid for a corrected retry.
      expect(controller.state.recipientReference, _panReference);
    });

    test('bank_verified false is not business success', () async {
      repository.response = const EducationTutorVerifyBankResponse(
        status: true,
        message: 'Bank could not be verified.',
        data: EducationTutorVerifyBankData(
          recipientReference: 'EDUTUTSHOULDNOTBEUSED',
          beneficiaryId: 8,
          name: 'OTHER NAME',
          accountNumber: 'XXXXXX0000',
          ifsc: 'XDFS0000000',
          transactionReference: 2,
          bankVerified: false,
        ),
      );
      await readyForm();

      await controller.verifyTutorBank();

      expect(controller.state.bankVerified, isFalse);
      expect(controller.state.bankErrorMessage, 'Bank could not be verified.');
      expect(controller.state.bankAccountMasked, isNull);
      expect(controller.state.beneficiaryId, 39);
      expect(controller.state.recipientReference, _panReference);
    });

    test('missing data is not treated as success', () async {
      repository.response = const EducationTutorVerifyBankResponse(
        status: true,
        message: 'Tutor recipient bank account verified successfully.',
      );
      await readyForm();

      await controller.verifyTutorBank();

      expect(controller.state.bankVerified, isFalse);
      expect(controller.state.bankAccountMasked, isNull);
    });

    test('network failure surfaces an error without echoing the account',
        () async {
      repository.error = DioException(
        type: DioExceptionType.connectionError,
        requestOptions: RequestOptions(path: ''),
      );
      await readyForm();

      await controller.verifyTutorBank();

      expect(controller.state.bankVerified, isFalse);
      expect(controller.state.isVerifyingBank, isFalse);
      expect(controller.state.bankErrorMessage, isNotNull);
      expect(
        controller.state.bankErrorMessage,
        isNot(contains('91201000123457911')),
      );
    });
  });

  group('EducationFeesController.verifyTutorBank submission safety', () {
    test('a second call while loading does not send another request', () async {
      await readyForm();
      repository.hangNext = true;

      final first = controller.verifyTutorBank();
      expect(controller.state.isVerifyingBank, isTrue);
      final second = controller.verifyTutorBank();

      expect(repository.callCount, 1);
      repository.inFlight.single.complete(
        const EducationTutorVerifyBankResponse(
          status: true,
          data: EducationTutorVerifyBankData(
            recipientReference: _panReference,
            beneficiaryId: 39,
            name: 'SUPRIYA SARANG ITHAPE',
            accountNumber: 'XXXXXX7911',
            ifsc: 'UBIN0546771',
            transactionReference: 1474338350,
            bankVerified: true,
          ),
        ),
      );
      await first;
      await second;

      expect(controller.state.bankVerified, isTrue);
      expect(controller.state.isVerifyingBank, isFalse);
    });

    test('a late response for an edited account cannot mark success', () async {
      await readyForm();
      repository.hangNext = true;

      final first = controller.verifyTutorBank();
      controller.updateAccountNumber('12345678901234');

      repository.inFlight.single.complete(
        const EducationTutorVerifyBankResponse(
          status: true,
          data: EducationTutorVerifyBankData(
            recipientReference: _panReference,
            beneficiaryId: 39,
            name: 'SUPRIYA SARANG ITHAPE',
            accountNumber: 'XXXXXX7911',
            ifsc: 'UBIN0546771',
            transactionReference: 1474338350,
            bankVerified: true,
          ),
        ),
      );
      await first;
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.bankVerified, isFalse);
      expect(controller.state.bankAccountMasked, isNull);

      // The edited account can still be verified with a fresh request.
      repository.hangNext = false;
      await controller.verifyTutorBank();
      expect(repository.callCount, 2);
      expect(controller.state.bankVerified, isTrue);
    });

    test('editing the PAN drops the reference and blocks bank verify',
        () async {
      await readyForm();
      await controller.verifyTutorBank();
      expect(controller.state.bankVerified, isTrue);

      controller.updatePan('ABXPI7963F');

      // A new PAN has no reference yet, so the stale one can never be sent.
      await controller.verifyTutorBank();
      expect(repository.callCount, 1);
      expect(controller.state.recipientReference, isNull);
      expect(controller.state.bankVerified, isFalse);
      expect(controller.state.bankAccountMasked, isNull);
      expect(controller.state.bankVerifiedIfsc, isNull);
      expect(controller.state.bankTransactionReference, isNull);
    });

    test('editing the recipient name drops the reference and bank results',
        () async {
      await readyForm();
      await controller.verifyTutorBank();

      controller.updateRecipientName('SOME OTHER NAME');

      expect(controller.state.recipientReference, isNull);
      expect(controller.state.bankAccountMasked, isNull);
      expect(controller.state.bankVerifiedIfsc, isNull);
      expect(controller.state.bankTransactionReference, isNull);

      await controller.verifyTutorBank();
      expect(repository.callCount, 1);
    });

    test('clearing beneficiary details drops reference and bank results',
        () async {
      await readyForm();
      await controller.verifyTutorBank();

      controller.clearBeneficiaryDetails();

      expect(controller.state.recipientReference, isNull);
      expect(controller.state.bankAccountMasked, isNull);
      expect(controller.state.bankVerifiedIfsc, isNull);
      expect(controller.state.bankTransactionReference, isNull);
      expect(controller.state.bankVerified, isFalse);
    });
  });

  group('no regression to legacy paths', () {
    test('legacy verifyBank never calls the tutor bank endpoint', () async {
      controller.updateRecipientName('Ravi Kumar');
      controller.updateAccountType(EducationAccountType.bankDetails);
      controller.updateAccountNumber('91201000123457911');
      controller.updateIfsc('UBIN0546771');

      await controller.verifyBank();

      expect(repository.verifyBankCallCount, 1);
      expect(repository.callCount, 0);
      expect(controller.state.bankVerified, isTrue);
      expect(controller.state.bankAccountMasked, isNull);
    });

    test('legacy verifyPan does not store a recipient reference', () async {
      controller.updateRecipientName('Ravi Kumar');
      controller.updatePan('ABCDE1234F');

      await controller.verifyPan();

      expect(repository.verifyTutorPanCallCount, 0);
      expect(controller.state.panVerified, isTrue);
      expect(controller.state.recipientReference, isNull);
    });
  });
}
