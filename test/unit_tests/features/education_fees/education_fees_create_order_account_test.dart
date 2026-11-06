import 'package:flutter_test/flutter_test.dart';

import 'package:e_rupaiya/features/educationFees/helpers/education_pay_now.dart';
import 'package:e_rupaiya/features/educationFees/models/education_fees_responses.dart';

const _completeAccount = '10000000000001';
const _maskedAccount = 'XXXXXXXX0001';

void main() {
  test('create-order serializer puts the complete account in account_no', () {
    final payload = const EducationCreateOrderRequest(
      recipientName: 'TEST TUTOR',
      accountNo: _completeAccount,
      ifsc: 'TEST0000001',
      amount: 2000,
    ).toJson();

    expect(payload['account_no'], _completeAccount);
    expect(educationAccountIsMasked(payload['account_no'] as String), isFalse);
    expect(payload.containsKey('account_no_unmasked'), isFalse);
    expect(payload['ifsc'], 'TEST0000001');
    expect(payload['amount'], 2000);
    expect(payload['recipient_name'], 'TEST TUTOR');
  });

  test('a masked account_no is replaced by the stored complete number', () {
    final payload = const EducationCreateOrderRequest(
      recipientName: 'TEST TUTOR',
      accountNo: _maskedAccount,
      accountNoUnmasked: _completeAccount,
      ifsc: 'TEST0000001',
      amount: 2000,
    ).toJson();

    expect(payload['account_no'], _completeAccount);
    expect(payload['account_no_unmasked'], _completeAccount);
    expect(payload['account_no'], isNot(_maskedAccount));
    expect(payload['ifsc'], 'TEST0000001');
    expect(payload['amount'], 2000);
  });

  test('payment account skips masks and does not rebuild them', () {
    expect(
      completeEducationAccountNumber([
        _maskedAccount,
        '****0001',
        _completeAccount,
      ]),
      _completeAccount,
    );
    expect(
      completeEducationAccountNumber([_maskedAccount, '****0001']),
      isEmpty,
    );
    expect(maskEducationAccount(_completeAccount), '****0001');
  });

  test('a masked account_no_unmasked is not kept as the payment account', () {
    final masked = EducationBeneficiary.fromJson(const {
      'id': '1',
      'name': 'TEST TUTOR',
      'account_no_unmasked': _maskedAccount,
      'account_masked': _maskedAccount,
    });
    expect(masked.accountNoUnmasked, isNull);
    expect(masked.accountMasked, _maskedAccount);

    final complete = EducationBeneficiary.fromJson(const {
      'id': '2',
      'name': 'TEST TUTOR',
      'account_no_unmasked': _completeAccount,
      'account_masked': _maskedAccount,
    });
    expect(complete.accountNoUnmasked, _completeAccount);
    expect(complete.accountMasked, _maskedAccount);
  });

  test('tutor details keeps the masked display and the complete source apart',
      () {
    final maskedOnly = EducationTutorDetailsData.fromJson(const {
      'account_number': _maskedAccount,
      'tutor_name': 'TEST TUTOR',
    });
    expect(maskedOnly.accountNumber, _maskedAccount);
    expect(maskedOnly.accountNoUnmasked, isNull);

    final both = EducationTutorDetailsData.fromJson(const {
      'account_number': _maskedAccount,
      'account_no_unmasked': _completeAccount,
      'tutor_name': 'TEST TUTOR',
    });
    expect(both.accountNumber, _maskedAccount);
    expect(both.accountNoUnmasked, _completeAccount);
    expect(
      completeEducationAccountNumber([
        both.accountNumber,
        both.accountNoUnmasked,
      ]),
      _completeAccount,
    );
  });
}
