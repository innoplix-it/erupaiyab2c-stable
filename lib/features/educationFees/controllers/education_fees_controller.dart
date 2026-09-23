import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_error_messages.dart';
import '../../../utils/error_message_utils.dart';
import '../../../services/push_notification_service.dart';
import '../models/education_account_type.dart';
import '../models/education_fees_state.dart';
import '../repositories/education_fees_repository.dart';

final educationFeesRepositoryProvider = Provider<EducationFeesRepository>(
  (ref) => EducationFeesRepository(),
);

final educationFeesControllerProvider =
    StateNotifierProvider<EducationFeesController, EducationFeesState>(
  (ref) => EducationFeesController(
    repository: ref.watch(educationFeesRepositoryProvider),
  ),
);

class EducationFeesController extends StateNotifier<EducationFeesState> {
  EducationFeesController({required EducationFeesRepository repository})
      : _repository = repository,
        super(const EducationFeesState());

  final EducationFeesRepository _repository;

  String _normalizeMobile(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10 && digits.startsWith('91')) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  void reset() {
    state = const EducationFeesState();
  }

  void updateFeeType(String? feeType) {
    state = state.copyWith(feeType: feeType);
  }

  void updateAmountInput(String value) {
    state = state.copyWith(
      amountInput: value,
      amountErrorMessage: null,
      amountValidated: false,
    );
  }

  Future<bool> validateAmount() async {
    final raw = state.amountInput.trim();
    final amount = int.tryParse(raw.replaceAll(RegExp(r'\D'), '')) ?? 0;
    if (amount <= 0) {
      state = state.copyWith(amountErrorMessage: 'Enter a valid amount.');
      return false;
    }
    if (isCappedPayViaCreditCardFee(state.feeType) && amount > 100000) {
      state = state.copyWith(
        amountValidated: false,
        amountErrorMessage: AppErrorMessages.maxAmount100000,
      );
      return false;
    }
    state = state.copyWith(isValidatingAmount: true, amountErrorMessage: null);
    try {
      final response = await _repository.validateAmount(amount);
      if (response.status) {
        state = state.copyWith(
          isValidatingAmount: false,
          amountValidated: true,
          amountErrorMessage: null,
        );
        return true;
      }
      state = state.copyWith(
        isValidatingAmount: false,
        amountValidated: false,
        amountErrorMessage: response.message ?? 'Invalid amount.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isValidatingAmount: false,
        amountValidated: false,
        amountErrorMessage: ErrorMessageUtils.from(
          e,
          fallback: 'Failed to validate amount. Please try again.',
        ),
      );
      return false;
    }
  }

  void updateMobileInput(String value) {
    final normalized = _normalizeMobile(value);
    state = state.copyWith(
      mobileInput: normalized,
      mobileErrorMessage: null,
      saveErrorMessage: null,
    );
    if (normalized.replaceAll(RegExp(r'\D'), '').length < 10) {
      state = state.copyWith(
        showRecipientFields: false,
        recipientName: '',
        pan: '',
        isVerifyingPan: false,
        panVerified: false,
        panErrorMessage: null,
        accountType: EducationAccountType.none,
        accountNumber: '',
        ifsc: '',
        bankVerified: false,
        bankErrorMessage: null,
      );
    }
  }

  Future<void> checkMobile() async {
    final digits =
        _normalizeMobile(state.mobileInput).replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return;
    state = state.copyWith(
      isCheckingMobile: true,
      mobileErrorMessage: null,
    );
    try {
      final response = await _repository.checkMobile(digits);
      if (response.status) {
        state = state.copyWith(
          isCheckingMobile: false,
          showRecipientFields: true,
          mobileErrorMessage: null,
        );
      } else {
        state = state.copyWith(
          isCheckingMobile: false,
          showRecipientFields: false,
          mobileErrorMessage: response.message ?? 'Mobile verification failed.',
          recipientName: '',
          pan: '',
          isVerifyingPan: false,
          panVerified: false,
          panErrorMessage: null,
          accountType: EducationAccountType.none,
          accountNumber: '',
          ifsc: '',
          bankVerified: false,
          bankErrorMessage: null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isCheckingMobile: false,
        showRecipientFields: false,
        mobileErrorMessage: ErrorMessageUtils.from(
          e,
          fallback: 'Failed to verify mobile. Please try again.',
        ),
        recipientName: '',
        pan: '',
        isVerifyingPan: false,
        panVerified: false,
        panErrorMessage: null,
        accountType: EducationAccountType.none,
        accountNumber: '',
        ifsc: '',
        bankVerified: false,
        bankErrorMessage: null,
      );
    }
  }

  void updateRecipientName(String value) {
    state = state.copyWith(
      recipientName: value,
      isVerifyingPan: false,
      panVerified: false,
      panErrorMessage: null,
      accountType: EducationAccountType.none,
      accountNumber: '',
      ifsc: '',
      bankVerified: false,
      bankErrorMessage: null,
      saveErrorMessage: null,
    );
  }

  void updatePan(String value) {
    state = state.copyWith(
      pan: value,
      isVerifyingPan: false,
      panVerified: false,
      panErrorMessage: null,
      accountType: EducationAccountType.none,
      accountNumber: '',
      ifsc: '',
      bankVerified: false,
      bankErrorMessage: null,
      saveErrorMessage: null,
    );
  }

  Future<void> verifyPan() async {
    final name = state.recipientName.trim();
    final pan = state.pan.trim().toUpperCase();
    if (name.isEmpty || pan.isEmpty) return;
    state = state.copyWith(
      isVerifyingPan: true,
      panErrorMessage: null,
      panVerified: false,
    );
    final deviceId = PushNotificationService.latestToken;
    try {
      final response = await _repository.verifyPan(
        name: name,
        pan: pan,
        deviceId: (deviceId == null || deviceId.isEmpty) ? '' : deviceId,
      );
      if (response.status) {
        state = state.copyWith(
          isVerifyingPan: false,
          panVerified: true,
          panErrorMessage: null,
        );
      } else {
        state = state.copyWith(
          isVerifyingPan: false,
          panVerified: false,
          panErrorMessage:
              response.message ?? 'PAN verification failed. Please try again.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isVerifyingPan: false,
        panVerified: false,
        panErrorMessage: ErrorMessageUtils.from(
          e,
          fallback: 'Unable to verify PAN. Please try again.',
        ),
      );
    }
  }

  void updateAccountType(EducationAccountType value) {
    state = state.copyWith(
      accountType: value,
      accountNumber: '',
      ifsc: '',
      bankVerified: false,
      bankErrorMessage: null,
      saveErrorMessage: null,
    );
  }

  void updateAccountNumber(String value) {
    state = state.copyWith(
      accountNumber: value,
      bankVerified: false,
      bankErrorMessage: null,
      saveErrorMessage: null,
    );
  }

  void updateIfsc(String value) {
    state = state.copyWith(
      ifsc: value,
      bankVerified: false,
      bankErrorMessage: null,
      saveErrorMessage: null,
    );
  }

  Future<void> verifyBank() async {
    if (state.accountType != EducationAccountType.bankDetails) return;
    final accountNo = state.accountNumber.trim();
    final ifsc = state.ifsc.trim().toUpperCase();
    final recipientName = state.recipientName.trim();
    if (accountNo.isEmpty || ifsc.isEmpty) return;
    state = state.copyWith(
      isVerifyingBank: true,
      bankErrorMessage: null,
    );
    try {
      final response = await _repository.verifyBank(
        accountNo: accountNo,
        ifsc: ifsc,
        recipientName: recipientName,
      );
      if (response.status) {
        state = state.copyWith(
          isVerifyingBank: false,
          bankVerified: true,
          bankErrorMessage: null,
        );
      } else {
        state = state.copyWith(
          isVerifyingBank: false,
          bankVerified: false,
          bankErrorMessage: response.message ?? 'Invalid bank details.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isVerifyingBank: false,
        bankVerified: false,
        bankErrorMessage: ErrorMessageUtils.from(
          e,
          fallback: 'Failed to verify bank details.',
        ),
      );
    }
  }

  Future<bool> saveBeneficiary() async {
    if (!state.panVerified) {
      state = state.copyWith(
        saveErrorMessage: 'Please verify PAN details.',
      );
      return false;
    }
    if (state.accountType != EducationAccountType.bankDetails ||
        !state.bankVerified) {
      state = state.copyWith(
        saveErrorMessage: 'Please verify bank details.',
      );
      return false;
    }
    final name = state.recipientName.trim();
    final mobile = _normalizeMobile(state.mobileInput);
    final pan = state.pan.trim().toUpperCase();
    const accountType = 'bank';
    final accountNo = state.accountNumber.trim();
    final ifsc = state.ifsc.trim().toUpperCase();
    if (name.isEmpty ||
        mobile.length != 10 ||
        pan.isEmpty ||
        accountNo.isEmpty ||
        ifsc.isEmpty) {
      state = state.copyWith(
        saveErrorMessage: 'Please fill all required details.',
      );
      return false;
    }
    state = state.copyWith(
      isSavingBeneficiary: true,
      saveErrorMessage: null,
    );
    try {
      final response = await _repository.saveBeneficiary(
        name: name,
        mobile: mobile,
        pan: pan,
        accountType: accountType,
        accountNo: accountNo,
        ifsc: ifsc,
      );
      if (response.status) {
        state = state.copyWith(
          isSavingBeneficiary: false,
          beneficiaryId: response.beneficiaryId,
          saveErrorMessage: null,
        );
        return true;
      }
      state = state.copyWith(
        isSavingBeneficiary: false,
        saveErrorMessage:
            response.message ?? 'Failed to save beneficiary details.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isSavingBeneficiary: false,
        saveErrorMessage: ErrorMessageUtils.from(
          e,
          fallback: 'Failed to save beneficiary details.',
        ),
      );
      return false;
    }
  }
}

bool isCappedPayViaCreditCardFee(String? feeType) {
  final value = (feeType ?? '').trim().toLowerCase();
  return value.contains('school') ||
      value.contains('college') ||
      value.contains('tuition') ||
      value.contains('tution') ||
      value.contains('house rent') ||
      value.contains('shop rent');
}
