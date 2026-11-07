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

  /// Identifies the newest tutor recipient PAN verification.
  int _tutorPanVerifyRequestId = 0;

  /// Identifies the newest tutor recipient bank verification so a response
  /// for an account/IFSC the user already edited away from is discarded.
  int _tutorBankVerifyRequestId = 0;

  /// One Ask-for-KYC at a time, so a second tap cannot send another request.
  bool _askKycInFlight = false;

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

  /// PAN records are uppercase. Spacing and letter case do not count as a
  /// different spelling.
  bool _tutorPanNamesMatch(String typed, String fromApi) {
    String normalize(String value) {
      return value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
    }

    final entered = normalize(typed);
    final recorded = normalize(fromApi);
    return entered.isNotEmpty && recorded.isNotEmpty && entered == recorded;
  }

  void reset() {
    // Invalidate any in-flight PAN verification so a late response cannot
    // write state after the flow has been cleared.
    _panVerifyRequestId++;
    _tutorPanVerifyRequestId++;
    _tutorBankVerifyRequestId++;
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
    _tutorPanVerifyRequestId++;
    _tutorBankVerifyRequestId++;
    state = state.copyWith(
      pan: '',
      isVerifyingPan: false,
      panVerified: false,
      panErrorMessage: null,
      recipientReference: null,
      panMasked: null,
      verifiedPanName: null,
      beneficiaryId: null,
      bankAccountMasked: null,
      bankVerifiedIfsc: null,
      bankTransactionReference: null,
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

  /// Tutor KYC check for the Add-Tutor flow (`POST /api/education/tutor/verify`).
  ///
  /// Returns null when the number is incomplete or the request failed so the
  /// caller can fail closed instead of guessing a verification status. The
  /// tutor outcome itself lives in [EducationTutorVerifyResponse.verificationStatus];
  /// `status` only reports whether the API call succeeded.
  Future<EducationTutorVerifyResponse?> verifyTutor(String mobile) async {
    final digits = _normalizeMobile(mobile).replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return null;
    try {
      return await _repository.verifyTutor(digits);
    } catch (_) {
      // The service already logged and rethrew. A failed check is never
      // treated as an unverified tutor.
      return null;
    }
  }

  /// Fetches verified tutor details after successful verification.
  ///
  /// Calls `POST /api/education/tutor/details` with the verified mobile number
  /// and the current tuition amount from the flow.
  Future<EducationTutorDetailsResponse?> fetchTutorDetails({
    required String mobile,
    required int amount,
  }) async {
    final digits = _normalizeMobile(mobile).replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return null;
    try {
      return await _repository.fetchTutorDetails(
          mobile: digits, amount: amount);
    } catch (e) {
      // The service already logged and rethrew.
      logger.error('Failed to fetch tutor details: $e', error: e);
      rethrow;
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
      _tutorPanVerifyRequestId++;
      _tutorBankVerifyRequestId++;
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
        recipientReference: null,
        panMasked: null,
        verifiedPanName: null,
        beneficiaryId: null,
        bankAccountMasked: null,
        bankVerifiedIfsc: null,
        bankTransactionReference: null,
        accountType: EducationAccountType.none,
        accountNumber: '',
        ifsc: '',
        bankVerified: false,
        bankErrorMessage: null,
      );
    } catch (e) {
      if (requestId != _checkMobileRequestId) return;
      _tutorPanVerifyRequestId++;
      _tutorBankVerifyRequestId++;
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
        recipientReference: null,
        panMasked: null,
        verifiedPanName: null,
        beneficiaryId: null,
        bankAccountMasked: null,
        bankVerifiedIfsc: null,
        bankTransactionReference: null,
        accountType: EducationAccountType.none,
        accountNumber: '',
        ifsc: '',
        bankVerified: false,
        bankErrorMessage: null,
      );
    }
  }

  void updateRecipientName(String value) {
    final nameChanged = value != state.recipientName;
    if (nameChanged) {
      _tutorPanVerifyRequestId++;
      _tutorBankVerifyRequestId++;
    }
    state = state.copyWith(
      recipientName: value,
      isVerifyingPan: false,
      panVerified: false,
      panErrorMessage: null,
      recipientReference: nameChanged ? null : state.recipientReference,
      panMasked: nameChanged ? null : state.panMasked,
      verifiedPanName: nameChanged ? null : state.verifiedPanName,
      beneficiaryId: nameChanged ? null : state.beneficiaryId,
      bankAccountMasked: nameChanged ? null : state.bankAccountMasked,
      bankVerifiedIfsc: nameChanged ? null : state.bankVerifiedIfsc,
      bankTransactionReference:
          nameChanged ? null : state.bankTransactionReference,
      bankVerified: false,
      bankErrorMessage: null,
      saveErrorMessage: null,
    );
  }

  void updatePan(String value) {
    final panChanged = value != state.pan;
    if (panChanged) {
      _tutorPanVerifyRequestId++;
      _tutorBankVerifyRequestId++;
    }
    state = state.copyWith(
      pan: value,
      isVerifyingPan: false,
      panVerified: false,
      panErrorMessage: null,
      recipientReference: panChanged ? null : state.recipientReference,
      panMasked: panChanged ? null : state.panMasked,
      verifiedPanName: panChanged ? null : state.verifiedPanName,
      beneficiaryId: panChanged ? null : state.beneficiaryId,
      bankAccountMasked: panChanged ? null : state.bankAccountMasked,
      bankVerifiedIfsc: panChanged ? null : state.bankVerifiedIfsc,
      bankTransactionReference:
          panChanged ? null : state.bankTransactionReference,
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

  /// Verifies a tutor recipient PAN via
  /// `POST /api/education/tutor/recipient/verify-pan`.
  ///
  /// Only a complete PAN in the existing format is sent. A second call while
  /// that request is running is ignored. [recipientReference] is kept for the
  /// following tutor bank-verification request.
  Future<void> verifyTutorPan() async {
    final pan = state.pan.trim().toUpperCase();
    if (!isValidPanFormat(pan)) return;
    if (state.isVerifyingPan) return;

    final requestId = ++_tutorPanVerifyRequestId;
    state = state.copyWith(
      isVerifyingPan: true,
      panErrorMessage: null,
      panVerified: false,
    );
    try {
      final response = await _repository.verifyTutorPan(pan);
      if (requestId != _tutorPanVerifyRequestId) return;
      final data = response.data;
      if (response.confirmsVerifiedPan && data != null) {
        final apiName = data.name.trim();
        if (!_tutorPanNamesMatch(state.recipientName, apiName)) {
          state = state.copyWith(
            isVerifyingPan: false,
            panVerified: false,
            panErrorMessage: apiName.isEmpty
                ? 'Name does not match the name on PAN.'
                : 'Name does not match the PAN name. Enter $apiName.',
            recipientReference: null,
            beneficiaryId: null,
            panMasked: null,
            verifiedPanName: null,
          );
          return;
        }
        state = state.copyWith(
          isVerifyingPan: false,
          panVerified: true,
          panErrorMessage: null,
          recipientReference: data.recipientReference,
          beneficiaryId: data.beneficiaryId,
          panMasked: data.panMasked,
          verifiedPanName: data.name,
        );
        return;
      }
      state = state.copyWith(
        isVerifyingPan: false,
        panVerified: false,
        panErrorMessage:
            response.message ?? 'PAN verification failed. Please try again.',
        recipientReference: null,
        beneficiaryId: null,
        panMasked: null,
        verifiedPanName: null,
      );
    } catch (e) {
      if (requestId != _tutorPanVerifyRequestId) return;
      state = state.copyWith(
        isVerifyingPan: false,
        panVerified: false,
        panErrorMessage: ErrorMessageUtils.from(
          e,
          fallback: 'Unable to verify PAN. Please try again.',
        ),
        recipientReference: null,
        beneficiaryId: null,
        panMasked: null,
        verifiedPanName: null,
      );
    }
  }

  /// Verifies a tutor recipient bank account via
  /// `POST /api/education/tutor/recipient/verify-bank`.
  ///
  /// Runs only for the unverified Add Details flow and only with the
  /// [recipientReference] stored by a successful PAN verification, so a
  /// missing or stale reference can never reach the backend and the
  /// beneficiary id is never used in its place. Account number and IFSC are
  /// read live from the form fields. A second call while a request is
  /// running is ignored and only the newest response may write state.
  /// Business success requires `status == true`, usable `data` and
  /// `bank_verified == true`; the backend message is surfaced otherwise.
  /// The raw account number is never logged.
  Future<void> verifyTutorBank() async {
    if (state.accountType != EducationAccountType.bankDetails) return;
    final recipientReference = state.recipientReference;
    if (recipientReference == null || recipientReference.isEmpty) return;
    final accountNo = state.accountNumber.trim();
    final ifsc = state.ifsc.trim().toUpperCase();
    if (accountNo.isEmpty || ifsc.isEmpty) return;
    // Re-entry guard: never issue a second request while one is in flight.
    if (state.isVerifyingBank) return;

    final requestId = ++_tutorBankVerifyRequestId;
    state = state.copyWith(
      isVerifyingBank: true,
      bankErrorMessage: null,
      bankVerified: false,
      bankAccountMasked: null,
      bankVerifiedIfsc: null,
      bankTransactionReference: null,
    );
    try {
      final response = await _repository.verifyTutorBank(
        recipientReference: recipientReference,
        accountNo: accountNo,
        ifsc: ifsc,
      );
      if (requestId != _tutorBankVerifyRequestId) return;
      final data = response.data;
      logger.info(
        'EDU_BANK VERIFY_RESULT status=${response.status} '
        'hasData=${data != null} '
        'bankVerified=${data?.bankVerified} '
        'confirms=${response.confirmsVerifiedBank}',
      );
      if (response.confirmsVerifiedBank && data != null) {
        state = state.copyWith(
          isVerifyingBank: false,
          bankVerified: true,
          bankErrorMessage: null,
          recipientReference: data.recipientReference.isNotEmpty
              ? data.recipientReference
              : state.recipientReference,
          beneficiaryId: data.beneficiaryId ?? state.beneficiaryId,
          verifiedPanName:
              data.name.isNotEmpty ? data.name : state.verifiedPanName,
          bankAccountMasked: data.accountNumber,
          bankVerifiedIfsc: data.ifsc,
          bankTransactionReference: data.transactionReference,
        );
        return;
      }
      state = state.copyWith(
        isVerifyingBank: false,
        bankVerified: false,
        bankErrorMessage:
            response.message ?? 'Bank verification failed. Please try again.',
      );
    } catch (e) {
      if (requestId != _tutorBankVerifyRequestId) return;
      logger.info('EDU_BANK VERIFY_FAILED type=${e.runtimeType}');
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

  void updateAccountType(EducationAccountType value) {
    state = state.copyWith(
      accountType: value,
      bankVerified: false,
      bankAccountMasked: null,
      bankVerifiedIfsc: null,
      bankTransactionReference: null,
      bankErrorMessage: null,
      saveErrorMessage: null,
    );
  }

  void updateAccountNumber(String value) {
    // Same text (focus loss, formatter replay) must not wipe a verification
    // that already succeeded for this account number.
    if (value == state.accountNumber) return;
    _tutorBankVerifyRequestId++;
    state = state.copyWith(
      accountNumber: value,
      // Editing releases the in-flight flag (same convention as updatePan)
      // so the newest value can always be verified again.
      isVerifyingBank: false,
      bankVerified: false,
      bankAccountMasked: null,
      bankVerifiedIfsc: null,
      bankTransactionReference: null,
      bankErrorMessage: null,
      saveErrorMessage: null,
    );
  }

  void updateIfsc(String value) {
    if (value == state.ifsc) return;
    _tutorBankVerifyRequestId++;
    state = state.copyWith(
      ifsc: value,
      isVerifyingBank: false,
      bankVerified: false,
      bankAccountMasked: null,
      bankVerifiedIfsc: null,
      bankTransactionReference: null,
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

    // Unverified tutor flow: use the tutor-specific save beneficiary API
    // which only requires the recipient_reference from PAN verification.
    if (unverifiedFlow) {
      return _saveTutorBeneficiary();
    }

    // Registered recipient flow: use the existing save beneficiary API
    // with full details.
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
          beneficiaryId: response.beneficiaryId ?? state.beneficiaryId,
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

  /// Saves a tutor beneficiary for the unverified "Add Details" flow.
  ///
  /// Requires successful PAN and bank verification, and a valid
  /// [recipientReference] stored by the PAN verification. Uses the
  /// tutor-specific save beneficiary API which only sends the
  /// recipient_reference to the backend.
  Future<bool> _saveTutorBeneficiary() async {
    logger.info('EDU_TUTOR_SAVE SAVE_BENEFICIARY_ENTERED');
    final recipientReference = state.recipientReference;
    if (recipientReference == null || recipientReference.isEmpty) {
      logger.info('EDU_TUTOR_SAVE SAVE_GUARD_BLOCKED reason=no_recipient_reference');
      state = state.copyWith(
        saveErrorMessage: 'PAN verification incomplete. Please verify PAN.',
      );
      return false;
    }

    state = state.copyWith(
      isSavingBeneficiary: true,
      saveErrorMessage: null,
    );
    try {
      logger.info('EDU_TUTOR_SAVE REPOSITORY_CALLED');
      final response = await _repository.saveTutorBeneficiary(
        recipientReference: recipientReference,
      );
      if (response.status) {
        logger.info('EDU_TUTOR_SAVE SAVE_SUCCESS');
        state = state.copyWith(
          isSavingBeneficiary: false,
          beneficiaryId: response.beneficiaryId ?? state.beneficiaryId,
          recipientReference:
              response.recipientReference?.isNotEmpty == true
                  ? response.recipientReference
                  : state.recipientReference,
          saveErrorMessage: null,
        );
        return true;
      }
      logger.info('EDU_TUTOR_SAVE SAVE_FAILED reason=server_status');
      state = state.copyWith(
        isSavingBeneficiary: false,
        saveErrorMessage:
            response.message ?? 'Failed to save beneficiary details.',
      );
      return false;
    } catch (e) {
      logger.info(
        'EDU_TUTOR_SAVE SAVE_FAILED reason=exception type=${e.runtimeType}',
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

  Future<EducationTutorSendRequestResponse?> _createTutorRequestReference() async {
    final mobile =
        _normalizeMobile(state.mobileInput).replaceAll(RegExp(r'\D'), '');
    final amountText =
        state.amountInput.replaceAll(RegExp(r'[^\d.]'), '').split('.').first;
    final amount = int.tryParse(amountText) ?? 0;
    final subject = state.feeType?.trim() ?? '';
    if (mobile.length != 10 || amount <= 0 || subject.isEmpty) {
      logger.info('EDU_ASK_KYC BLOCKED reason=missing_request_reference');
      return null;
    }
    return _repository.sendTutorRequest(
      mobile: mobile,
      amount: amount,
      subject: subject,
      feeType: subject,
      senderName: state.recipientName,
    );
  }

  /// Stores the request reference from Tutor Send Request in state.
  ///
  /// This should be called immediately after a successful Tutor Send Request
  /// API response. The [requestReference] comes from `data.request_reference`
  /// in the Send Request response.
  void storeTutorRequestReference(String requestReference) {
    logger.info('EDU_TUTOR_REQUEST STORE_REFERENCE');
    state = state.copyWith(
      requestReference: requestReference,
    );
  }

  /// Sends a KYC reminder (`POST /api/education/tutor/ask-kyc`).
  ///
  /// The body is only `request_reference`. When this flow has not stored one
  /// yet, the existing send-request call creates it first. The mobile is
  /// never sent to ask-kyc.
  Future<EducationTutorAskKycResponse?> askTutorForKyc() async {
    if (_askKycInFlight) return null;
    _askKycInFlight = true;
    try {
      var reference = state.requestReference?.trim() ?? '';
      if (reference.isEmpty) {
        final created = await _createTutorRequestReference();
        if (created == null) {
          return const EducationTutorAskKycResponse(
            status: false,
            message: 'Request reference is required.',
          );
        }
        if (!created.status ||
            (created.data?.requestReference.trim().isEmpty ?? true)) {
          final message = created.message?.trim() ?? '';
          return EducationTutorAskKycResponse(
            status: false,
            message: message.isNotEmpty
                ? message
                : 'Request reference is required.',
          );
        }
        reference = created.data!.requestReference.trim();
        storeTutorRequestReference(reference);
      }

      logger.info('EDU_ASK_KYC');
      return await _repository.askTutorForKyc(
        requestReference: reference,
      );
    } catch (e) {
      logger.info('EDU_ASK_KYC FAILED type=${e.runtimeType}');
      return EducationTutorAskKycResponse(
        status: false,
        message: ErrorMessageUtils.from(
          e,
          fallback: 'Failed to send KYC reminder. Please try again.',
        ),
      );
    } finally {
      _askKycInFlight = false;
    }
  }

  /// Saves a registered/verified tutor beneficiary after request acceptance.
  ///
  /// The request reference is read from [state.requestReference], which was
  /// stored immediately after the Tutor Send Request API response. It is never
  /// hardcoded, reconstructed or replaced by recipient_reference or beneficiary_id.
  ///
  /// This should be called after the tutor accepts the payment request, before
  /// navigating to the tutor profile screen.
  Future<bool> saveTutorBeneficiaryRegistered() async {
    logger.info('EDU_TUTOR_SAVE_REGISTERED SAVE_BENEFICIARY_ENTERED');
    final requestReference = state.requestReference;
    if (requestReference == null || requestReference.isEmpty) {
      logger.info(
        'EDU_TUTOR_SAVE_REGISTERED SAVE_GUARD_BLOCKED reason=no_request_reference',
      );
      state = state.copyWith(
        saveErrorMessage: 'Request reference missing. Please try again.',
      );
      return false;
    }

    if (state.isSavingBeneficiary) {
      logger.info(
        'EDU_TUTOR_SAVE_REGISTERED SAVE_GUARD_BLOCKED reason=in_flight',
      );
      return false;
    }

    state = state.copyWith(
      isSavingBeneficiary: true,
      saveErrorMessage: null,
    );
    try {
      logger.info('EDU_TUTOR_SAVE_REGISTERED REPOSITORY_CALLED');
      final response = await _repository.saveTutorBeneficiaryRegistered(
        requestReference: requestReference,
      );
      if (response.status && response.data != null) {
        logger.info('EDU_TUTOR_SAVE_REGISTERED SAVE_SUCCESS');
        state = state.copyWith(
          isSavingBeneficiary: false,
          beneficiaryId: response.data!.beneficiaryId,
          recipientReference: response.data!.recipientReference,
          saveErrorMessage: null,
        );
        return true;
      }
      logger.info('EDU_TUTOR_SAVE_REGISTERED SAVE_FAILED reason=server_status');
      state = state.copyWith(
        isSavingBeneficiary: false,
        saveErrorMessage:
            response.message ?? 'Failed to save beneficiary details.',
      );
      return false;
    } catch (e) {
      logger.info(
        'EDU_TUTOR_SAVE_REGISTERED SAVE_FAILED reason=exception type=${e.runtimeType}',
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
