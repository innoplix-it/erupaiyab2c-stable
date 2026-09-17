import 'education_account_type.dart';

class EducationFeesState {
  const EducationFeesState({
    this.amountInput = '',
    this.isValidatingAmount = false,
    this.amountValidated = false,
    this.amountErrorMessage,
    this.mobileInput = '',
    this.isCheckingMobile = false,
    this.mobileErrorMessage,
    this.showRecipientFields = false,
    this.recipientName = '',
    this.pan = '',
    this.isVerifyingPan = false,
    this.panVerified = false,
    this.panErrorMessage,
    this.accountType = EducationAccountType.none,
    this.accountNumber = '',
    this.ifsc = '',
    this.isVerifyingBank = false,
    this.bankVerified = false,
    this.bankErrorMessage,
    this.isSavingBeneficiary = false,
    this.beneficiaryId,
    this.saveErrorMessage,
    this.feeType,
  });

  final String amountInput;
  final bool isValidatingAmount;
  final bool amountValidated;
  final String? amountErrorMessage;

  final String mobileInput;
  final bool isCheckingMobile;
  final String? mobileErrorMessage;
  final bool showRecipientFields;

  final String recipientName;
  final String pan;
  final bool isVerifyingPan;
  final bool panVerified;
  final String? panErrorMessage;
  final EducationAccountType accountType;
  final String accountNumber;
  final String ifsc;
  final bool isVerifyingBank;
  final bool bankVerified;
  final String? bankErrorMessage;
  final bool isSavingBeneficiary;
  final int? beneficiaryId;
  final String? saveErrorMessage;
  final String? feeType;

  static const _sentinel = Object();

  EducationFeesState copyWith({
    String? amountInput,
    bool? isValidatingAmount,
    bool? amountValidated,
    Object? amountErrorMessage = _sentinel,
    String? mobileInput,
    bool? isCheckingMobile,
    Object? mobileErrorMessage = _sentinel,
    bool? showRecipientFields,
    String? recipientName,
    String? pan,
    bool? isVerifyingPan,
    bool? panVerified,
    Object? panErrorMessage = _sentinel,
    EducationAccountType? accountType,
    String? accountNumber,
    String? ifsc,
    bool? isVerifyingBank,
    bool? bankVerified,
    Object? bankErrorMessage = _sentinel,
    bool? isSavingBeneficiary,
    int? beneficiaryId,
    Object? saveErrorMessage = _sentinel,
    Object? feeType = _sentinel,
  }) {
    return EducationFeesState(
      amountInput: amountInput ?? this.amountInput,
      isValidatingAmount: isValidatingAmount ?? this.isValidatingAmount,
      amountValidated: amountValidated ?? this.amountValidated,
      amountErrorMessage: amountErrorMessage == _sentinel
          ? this.amountErrorMessage
          : amountErrorMessage as String?,
      mobileInput: mobileInput ?? this.mobileInput,
      isCheckingMobile: isCheckingMobile ?? this.isCheckingMobile,
      mobileErrorMessage: mobileErrorMessage == _sentinel
          ? this.mobileErrorMessage
          : mobileErrorMessage as String?,
      showRecipientFields: showRecipientFields ?? this.showRecipientFields,
      recipientName: recipientName ?? this.recipientName,
      pan: pan ?? this.pan,
      isVerifyingPan: isVerifyingPan ?? this.isVerifyingPan,
      panVerified: panVerified ?? this.panVerified,
      panErrorMessage: panErrorMessage == _sentinel
          ? this.panErrorMessage
          : panErrorMessage as String?,
      accountType: accountType ?? this.accountType,
      accountNumber: accountNumber ?? this.accountNumber,
      ifsc: ifsc ?? this.ifsc,
      isVerifyingBank: isVerifyingBank ?? this.isVerifyingBank,
      bankVerified: bankVerified ?? this.bankVerified,
      bankErrorMessage: bankErrorMessage == _sentinel
          ? this.bankErrorMessage
          : bankErrorMessage as String?,
      isSavingBeneficiary: isSavingBeneficiary ?? this.isSavingBeneficiary,
      beneficiaryId: beneficiaryId ?? this.beneficiaryId,
      saveErrorMessage: saveErrorMessage == _sentinel
          ? this.saveErrorMessage
          : saveErrorMessage as String?,
      feeType: feeType == _sentinel ? this.feeType : feeType as String?,
    );
  }
}
