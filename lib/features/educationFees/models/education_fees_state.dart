import 'education_account_type.dart';

class EducationFeesState {
  const EducationFeesState({
    this.amountInput = '',
    this.isValidatingAmount = false,
    this.amountValidated = false,
    this.amountErrorMessage,
    this.minAmount,
    this.maxAmount,
    this.amountLimitHint,
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
    this.recipientReference,
    this.panMasked,
    this.verifiedPanName,
    this.bankAccountMasked,
    this.bankVerifiedIfsc,
    this.bankTransactionReference,
    this.saveErrorMessage,
    this.feeType,
    this.requestReference,
  });

  final String amountInput;
  final bool isValidatingAmount;
  final bool amountValidated;
  final String? amountErrorMessage;
  final double? minAmount;
  final double? maxAmount;
  final String? amountLimitHint;

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

  /// Tutor recipient reference returned by PAN verify. Required by the next
  /// tutor bank-verification request. Kept separate from [beneficiaryId].
  final String? recipientReference;

  /// Masked PAN from tutor PAN verify. The raw PAN is not copied here.
  final String? panMasked;

  /// Name returned by tutor PAN verify.
  final String? verifiedPanName;

  /// Masked account number returned by tutor bank verify, preserved exactly
  /// as the backend sent it. The raw typed account number stays only in
  /// [accountNumber] for the form itself.
  final String? bankAccountMasked;

  /// IFSC echoed back by tutor bank verify.
  final String? bankVerifiedIfsc;

  /// Numeric transaction reference of the backend bank verification.
  final int? bankTransactionReference;
  final String? saveErrorMessage;
  final String? feeType;

  /// Request reference from Tutor Send Request API. Used for registered/verified
  /// tutor Save Beneficiary API.
  final String? requestReference;

  static const _sentinel = Object();

  EducationFeesState copyWith({
    String? amountInput,
    bool? isValidatingAmount,
    bool? amountValidated,
    Object? amountErrorMessage = _sentinel,
    Object? minAmount = _sentinel,
    Object? maxAmount = _sentinel,
    Object? amountLimitHint = _sentinel,
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
    Object? beneficiaryId = _sentinel,
    Object? recipientReference = _sentinel,
    Object? panMasked = _sentinel,
    Object? verifiedPanName = _sentinel,
    Object? bankAccountMasked = _sentinel,
    Object? bankVerifiedIfsc = _sentinel,
    Object? bankTransactionReference = _sentinel,
    Object? saveErrorMessage = _sentinel,
    Object? feeType = _sentinel,
    Object? requestReference = _sentinel,
  }) {
    return EducationFeesState(
      amountInput: amountInput ?? this.amountInput,
      isValidatingAmount: isValidatingAmount ?? this.isValidatingAmount,
      amountValidated: amountValidated ?? this.amountValidated,
      amountErrorMessage: amountErrorMessage == _sentinel
          ? this.amountErrorMessage
          : amountErrorMessage as String?,
      minAmount: minAmount == _sentinel ? this.minAmount : minAmount as double?,
      maxAmount: maxAmount == _sentinel ? this.maxAmount : maxAmount as double?,
      amountLimitHint: amountLimitHint == _sentinel
          ? this.amountLimitHint
          : amountLimitHint as String?,
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
      beneficiaryId: identical(beneficiaryId, _sentinel)
          ? this.beneficiaryId
          : beneficiaryId as int?,
      recipientReference: identical(recipientReference, _sentinel)
          ? this.recipientReference
          : recipientReference as String?,
      panMasked: identical(panMasked, _sentinel)
          ? this.panMasked
          : panMasked as String?,
      verifiedPanName: identical(verifiedPanName, _sentinel)
          ? this.verifiedPanName
          : verifiedPanName as String?,
      bankAccountMasked: identical(bankAccountMasked, _sentinel)
          ? this.bankAccountMasked
          : bankAccountMasked as String?,
      bankVerifiedIfsc: identical(bankVerifiedIfsc, _sentinel)
          ? this.bankVerifiedIfsc
          : bankVerifiedIfsc as String?,
      bankTransactionReference: identical(bankTransactionReference, _sentinel)
          ? this.bankTransactionReference
          : bankTransactionReference as int?,
      saveErrorMessage: saveErrorMessage == _sentinel
          ? this.saveErrorMessage
          : saveErrorMessage as String?,
      feeType: feeType == _sentinel ? this.feeType : feeType as String?,
      requestReference: identical(requestReference, _sentinel)
          ? this.requestReference
          : requestReference as String?,
    );
  }
}
