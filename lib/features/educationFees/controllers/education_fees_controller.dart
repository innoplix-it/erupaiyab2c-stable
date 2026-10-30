import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../utils/error_message_utils.dart';
import '../../../helpers/kyc_helpers.dart';
import '../../../services/logger_service.dart';
import '../../../services/push_notification_service.dart';
import '../models/education_account_type.dart';
import '../models/education_fees_responses.dart';
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

  /// Identifies the newest PAN verification so responses for numbers the user
  /// has already edited away from are discarded instead of being shown.
  int _panVerifyRequestId = 0;

  /// Discards stale [checkMobile] responses when the user edits the mobile number.
  int _checkMobileRequestId = 0;

  static const String unregisteredMobileMessage =
      'This mobile number is not registered with eRupaiya. '
      'Ask the recipient to register before you add them as a tutor.';

  String _normalizeMobile(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10 && digits.startsWith('91')) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  void reset() {
    // Invalidate any in-flight PAN verification so a late response cannot
    // write state after the flow has been cleared.
    _panVerifyRequestId++;
    state = const EducationFeesState();
  }

  /// Clears the per-beneficiary identity/bank fields so a new entry starts
  /// with empty PAN / Account Number / IFSC. Mobile, name and every other
  /// flow field are intentionally preserved, and no already-saved backend
  /// beneficiary data is touched. Called when a fresh add-beneficiary form is
  /// opened.
  void clearBeneficiaryDetails() {
    // Invalidate any in-flight PAN verification so a late response cannot
    // re-mark the freshly-cleared form as verified.
    _panVerifyRequestId++;
    state = state.copyWith(
      pan: '',
      isVerifyingPan: false,
      panVerified: false,
      panErrorMessage: null,
      accountNumber: '',
      ifsc: '',
      isVerifyingBank: false,
      bankVerified: false,
      bankErrorMessage: null,
      saveErrorMessage: null,
    );
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

  /// Reads the backend min/max caption. Does not accept or reject an amount.
  Future<void> prefetchAmountLimits() async {
    try {
      final response = await _repository.validateAmount(0);
      final message = response.message?.trim();
      final messageIsLimit = message != null &&
          message.toLowerCase().contains('min') &&
          message.toLowerCase().contains('max');
      final hint = response.limitHint ?? (messageIsLimit ? message : null);
      if (response.minAmount == null &&
          response.maxAmount == null &&
          (hint == null || hint.isEmpty)) {
        return;
      }
      state = state.copyWith(
        minAmount: response.minAmount ?? state.minAmount,
        maxAmount: response.maxAmount ?? state.maxAmount,
        amountLimitHint: hint ?? state.amountLimitHint,
      );
    } catch (_) {
      // Caption is display-only; ignore prefetch failures.
    }
  }

  Future<bool> validateAmount() async {
    final raw = state.amountInput.trim();
    final amount = int.tryParse(raw.replaceAll(RegExp(r'\D'), '')) ?? 0;
    state = state.copyWith(isValidatingAmount: true, amountErrorMessage: null);
    try {
      final response = await _repository.validateAmount(amount);
      if (response.status) {
        state = state.copyWith(
          isValidatingAmount: false,
          amountValidated: true,
          amountErrorMessage: null,
          minAmount: response.minAmount ?? state.minAmount,
          maxAmount: response.maxAmount ?? state.maxAmount,
          amountLimitHint: response.limitHint ?? state.amountLimitHint,
        );
        return true;
      }
      state = state.copyWith(
        isValidatingAmount: false,
        amountValidated: false,
        amountErrorMessage: response.message ?? 'Invalid amount.',
        minAmount: response.minAmount ?? state.minAmount,
        maxAmount: response.maxAmount ?? state.maxAmount,
        amountLimitHint: response.limitHint ?? state.amountLimitHint,
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
    if (normalized != state.mobileInput) {
      _checkMobileRequestId++;
    }
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

  /// Saved-tutor record for [mobile], used to show the backend `account_masked`
  /// on the tutor request screen. Returns null when the number is not a saved
  /// tutor or the lookup fails, so callers can keep their own fallback.
  Future<EducationBeneficiary?> findBeneficiaryByMobile(String mobile) async {
    final digits = _normalizeMobile(mobile).replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return null;
    try {
      final response = await _repository.fetchBeneficiaries();
      if (!response.status) return null;
      for (final beneficiary in response.beneficiaries) {
        final candidate =
            _normalizeMobile(beneficiary.mobile).replaceAll(RegExp(r'\D'), '');
        if (candidate == digits) return beneficiary;
      }
      return null;
    } catch (_) {
      // Display-only lookup; a failure must not block the request flow.
      return null;
    }
  }

  Future<void> checkMobile() async {
    final digits =
        _normalizeMobile(state.mobileInput).replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return;

    final requestId = ++_checkMobileRequestId;
    state = state.copyWith(
      isCheckingMobile: true,
      mobileErrorMessage: null,
      showRecipientFields: false,
    );
    try {
      final response = await _repository.checkMobile(digits);
      if (requestId != _checkMobileRequestId) return;
      if (_normalizeMobile(state.mobileInput).replaceAll(RegExp(r'\D'), '') !=
          digits) {
        return;
      }

      if (response.confirmsRegisteredUser) {
        state = state.copyWith(
          isCheckingMobile: false,
          showRecipientFields: true,
          mobileErrorMessage: null,
        );
        return;
      }

      final notRegistered = response.status && !response.exists;
      state = state.copyWith(
        isCheckingMobile: false,
        showRecipientFields: false,
        mobileErrorMessage: notRegistered
            ? (response.message ?? unregisteredMobileMessage)
            : (response.message ??
                'Unable to verify this mobile number. Please try again.'),
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
    } catch (e) {
      if (requestId != _checkMobileRequestId) return;
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
      bankVerified: false,
      bankErrorMessage: null,
      saveErrorMessage: null,
    );
  }

  /// Verifies the recipient PAN.
  ///
  /// The request is only allowed once the PAN is complete and well formed, so
  /// a partially typed or malformed number never reaches the backend. Only the
  /// most recent request may update the state, so a slow response for a
  /// previous value can never be shown against the current one.
  Future<void> verifyPan() async {
    final name = state.recipientName.trim();
    final pan = state.pan.trim().toUpperCase();
    if (name.isEmpty || !isValidPanFormat(pan)) return;

    final requestId = ++_panVerifyRequestId;
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
      if (requestId != _panVerifyRequestId) return;
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
      if (requestId != _panVerifyRequestId) return;
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

  Future<bool> saveBeneficiary({bool unverifiedFlow = false}) async {
    logger.info(
      'EDU_SAVE SAVE_BENEFICIARY_ENTERED unverifiedFlow=$unverifiedFlow',
    );
    logger.info(
      'EDU_SAVE PAN_VERIFICATION_STATUS verified=${state.panVerified} '
      'BANK_VERIFICATION_STATUS verified=${state.bankVerified}',
    );
    // Re-entry guard: never issue a second request while one is in flight.
    if (state.isSavingBeneficiary) {
      logger.info('EDU_SAVE SAVE_GUARD_BLOCKED reason=in_flight');
      return false;
    }
    // Registration gate: enforced for the normal registered-recipient flow
    // only. The unverified "Add Details" flow bypasses it because the tutor
    // is by definition not a registered user; every validation below still
    // applies unchanged.
    if (!unverifiedFlow && !state.showRecipientFields) {
      logger.info('EDU_SAVE SAVE_GUARD_BLOCKED reason=registration');
      state = state.copyWith(
        saveErrorMessage: state.mobileErrorMessage ??
            'Please verify the recipient mobile number first.',
      );
      return false;
    }
    if (!state.panVerified) {
      logger.info('EDU_SAVE SAVE_GUARD_BLOCKED reason=pan_not_verified');
      state = state.copyWith(
        saveErrorMessage: 'Please verify PAN details.',
      );
      return false;
    }
    if (state.accountType != EducationAccountType.bankDetails) {
      logger.info('EDU_SAVE SAVE_GUARD_BLOCKED reason=account_type');
      state = state.copyWith(
        saveErrorMessage: 'Please select bank details.',
      );
      return false;
    }
    if (!state.bankVerified) {
      logger.info('EDU_SAVE SAVE_GUARD_BLOCKED reason=bank_not_verified');
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
      logger.info('EDU_SAVE SAVE_GUARD_BLOCKED reason=missing_fields');
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
      logger.info('EDU_SAVE REPOSITORY_CALLED');
      final response = await _repository.saveBeneficiary(
        name: name,
        mobile: mobile,
        pan: pan,
        accountType: accountType,
        accountNo: accountNo,
        ifsc: ifsc,
      );
      if (response.status) {
        logger.info('EDU_SAVE SAVE_SUCCESS');
        state = state.copyWith(
          isSavingBeneficiary: false,
          beneficiaryId: response.beneficiaryId,
          saveErrorMessage: null,
        );
        return true;
      }
      logger.info('EDU_SAVE SAVE_FAILED reason=server_status');
      state = state.copyWith(
        isSavingBeneficiary: false,
        saveErrorMessage:
            response.message ?? 'Failed to save beneficiary details.',
      );
      return false;
    } catch (e) {
      logger.info(
        'EDU_SAVE SAVE_FAILED reason=exception type=${e.runtimeType}',
      );
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
