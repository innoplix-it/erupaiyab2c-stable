import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../constants/app_error_messages.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/my_app_bar.dart';
import '../components/education_contact_sheet.dart';
import '../components/education_erupaiya_verifying_overlay.dart';
import '../controllers/education_fees_controller.dart';
import '../education_fees_typography.dart';
import '../helpers/education_pay_now.dart';
import '../models/education_fees_responses.dart';
import 'education_tutor_request_view.dart';
import 'education_tutor_unverified_view.dart';

/// Shown when the Tutor Details call fails after a VERIFIED response, and the
/// backend gave no message of its own. Never routed to the Unverified screen.
const String kEducationTutorDetailsFailureMessage =
    'Unable to load tutor details. Please try again.';

/// Complete saved-tutor account number, or null when the record has none.
String? _savedAccountNumber(EducationBeneficiary? tutor) {
  final account = tutor?.accountNoUnmasked?.trim() ?? '';
  if (account.isEmpty || educationAccountIsMasked(account)) return null;
  return account;
}

/// Backend message when present, otherwise the shared generic error text.
String _tutorApiErrorText(String? message) {
  final trimmed = message?.trim() ?? '';
  return trimmed.isNotEmpty ? trimmed : AppErrorMessages.generic;
}

class EducationSearchRecipientView extends HookConsumerWidget {
  const EducationSearchRecipientView({
    super.key,
    this.verificationDuration,
  });

  /// Override in tests to avoid waiting for the simulated verification.
  final Duration? verificationDuration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVerifying = useState(false);
    final verificationStarted = useRef(false);
    final pickedName = useRef<String?>(null);
    final pickedMobile = useRef<String?>(null);
    final pickedTutor = useRef<EducationBeneficiary?>(null);
    final beneficiaryLookup = useRef<Future<EducationBeneficiary?>?>(null);

    /// Real KYC result of the picked number, resolved while the overlay runs.
    final verifyFuture = useRef<Future<EducationTutorVerifyResponse?>?>(null);

    /// Dismisses the scrim and releases the pick guards, so a failed call can
    /// simply be retried from the same screen.
    void stopVerifying() {
      isVerifying.value = false;
      verificationStarted.value = false;
      verifyFuture.value = null;
    }

    void showError(String message) {
      AppSnackbar.show(message, type: AppSnackbarType.error);
    }

    Future<void> openTutorRequest() async {
      // The overlay stays up until the backend answer is in, so a slow network
      // never routes on a guessed status.
      final verifyResponse = await verifyFuture.value;
      if (!context.mounted) return;
      final name = pickedName.value ?? '';
      final mobile = pickedMobile.value ?? '';
      final amountRaw =
          ref.read(educationFeesControllerProvider).amountInput.trim();
      final amount =
          double.tryParse(amountRaw.replaceAll(RegExp(r'\D'), '')) ?? 0;

      // Keep the controller inputs in sync so any form opened further down
      // the flow starts prefilled.
      ref.read(educationFeesControllerProvider.notifier).updateMobileInput(
            mobile,
          );
      ref.read(educationFeesControllerProvider.notifier).updateRecipientName(
            name,
          );

      // API failure, `status: false` or an unrecognised status: stay on the
      // contacts screen with the error snackbar and never open a tutor screen.
      if (verifyResponse == null ||
          !verifyResponse.status ||
          !verifyResponse.hasKnownVerificationStatus) {
        stopVerifying();
        showError(_tutorApiErrorText(verifyResponse?.message));
        return;
      }

      switch (verifyResponse.verificationStatus) {
        // VERIFIED: fetch the Tutor Details API with the same mobile and the
        // amount from the flow, then show the verified tutor card.
        case EducationTutorVerificationStatus.verified:
          EducationTutorDetailsResponse? detailsResponse;
          try {
            detailsResponse = await ref
                .read(educationFeesControllerProvider.notifier)
                .fetchTutorDetails(
                  mobile: mobile,
                  amount: amount.toInt(),
                );
          } catch (_) {
            // Network/API failure: keep the tutor treated as verified.
            detailsResponse = null;
          }
          if (!context.mounted) return;

          // Mobile is on eRupaiya, but Tutor Details says KYC is not done.
          // That is a real outcome, so continue to Add Details instead of
          // stopping on the contacts screen.
          if (detailsResponse?.isNotVerified == true ||
              detailsResponse?.isNotFound == true) {
            stopVerifying();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => EducationTutorUnverifiedView(
                  tutorName: name,
                  amount: amount,
                  amountLabel: NumberFormat.currency(
                    locale: 'en_IN',
                    symbol: '\u20B9',
                    decimalDigits: 0,
                  ).format(amount),
                ),
              ),
            );
            return;
          }

          final data =
              detailsResponse?.status == true ? detailsResponse?.data : null;
          if (data == null) {
            // A Tutor Details failure is not a verification failure: the tutor
            // stays verified, so the Unverified screen must not be opened and
            // no placeholder bank data is invented. The number stays in the
            // field, so tapping Continue retries.
            stopVerifying();
            showError(
              detailsResponse == null
                  ? kEducationTutorDetailsFailureMessage
                  : _tutorApiErrorText(detailsResponse.message),
            );
            return;
          }

          final savedTutor = await beneficiaryLookup.value;
          if (!context.mounted) return;
          if (savedTutor != null) pickedTutor.value = savedTutor;

          stopVerifying();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => EducationTutorRequestView(
                tutorName: data.tutorName.isNotEmpty ? data.tutorName : name,
                mobile: mobile,
                amount: data.amount > 0 ? data.amount.toDouble() : amount,
                accountNumber: data.accountNumber,
                accountNoUnmasked: _savedAccountNumber(pickedTutor.value),
                ifscCode: data.ifsc,
                // Verified tutor card renders these API values: tutor_name,
                // account_number, bank_name, bank_logo, amount and
                // account_holder_name exactly as returned.
                tutorDetails: data,
                // Saved-tutor extras, still forwarded to the tutor profile.
                maskedAccount: pickedTutor.value?.accountMasked,
                panDetails: pickedTutor.value?.panMasked,
                branch: pickedTutor.value?.branch,
                // Subject/fee type from the amount screen selection.
                subject: ref
                    .read(educationFeesControllerProvider)
                    .feeType
                    ?.trim()
                    .isNotEmpty ==
                    true
                    ? ref.read(educationFeesControllerProvider).feeType!.trim()
                    : null,
              ),
            ),
          );
        // NOT_VERIFIED (KYC pending) and NOT_FOUND (not registered) are both
        // valid business outcomes of a successful API call, and both open the
        // same Ask for KYC / Add Details screen.
        case EducationTutorVerificationStatus.notVerified:
        case EducationTutorVerificationStatus.notFound:
          stopVerifying();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => EducationTutorUnverifiedView(
                tutorName: name,
                amount: amount,
                amountLabel: NumberFormat.currency(
                  locale: 'en_IN',
                  symbol: '\u20B9',
                  decimalDigits: 0,
                ).format(amount),
                verificationStatus: verifyResponse.verificationStatus,
                apiMessage: verifyResponse.message,
              ),
            ),
          );
        // Unrecognised status: never guessed into a flow.
        case EducationTutorVerificationStatus.unknown:
          stopVerifying();
          showError(_tutorApiErrorText(verifyResponse.message));
      }
    }

    void onContactPicked(String mobile, String displayName) {
      if (verificationStarted.value || isVerifying.value) return;
      verificationStarted.value = true;
      pickedMobile.value = mobile;
      pickedName.value = displayName;
      pickedTutor.value = null;
      isVerifying.value = true;

      // Backend tutor KYC check. The request is fired here, while the scrim is
      // already up, and awaited by [openTutorRequest] before routing.
      verifyFuture.value = ref
          .read(educationFeesControllerProvider.notifier)
          .verifyTutor(mobile);

      // Resolved while the loader runs. The unmasked account is forwarded
      // to create-order; the card keeps the masked display value.
      beneficiaryLookup.value = ref
          .read(educationFeesControllerProvider.notifier)
          .findBeneficiaryByMobile(mobile)
          .then((beneficiary) {
        if (beneficiary != null) {
          pickedTutor.value = beneficiary;
        }
        return beneficiary;
      });
    }

    // The processing scrim has to occupy the whole screen, app bar and status
    // bar included, so it is a sibling above the Scaffold rather than a child
    // of the body.
    return Stack(
      children: [
        EducationFeesTheme(
          child: PopScope(
            canPop: !isVerifying.value,
            child: Scaffold(
              backgroundColor: Colors.white,
              appBar: MyAppBar(
                title: '',
                showHelp: true,
                showBharatConnect: false,
                fitTitle: true,
                titleStyle: MyAppBar.sharedTitleStyle(context),
                onBack: isVerifying.value ? null : () => context.pop(),
              ),
              body: Stack(
                children: [
                  SafeArea(
                    top: false,
                    child: SizedBox.expand(
                      child: EducationContactSheet(
                        searchHint: 'enter contact name or number',
                        searchRecipientLayout: true,
                        matchInviteContactAvatarStyle: true,
                        onContactPicked: onContactPicked,
                        onSelect: (_) {},
                        closeOnSelect: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isVerifying.value)
          Positioned.fill(
            child: EducationErupaiyaVerifyingOverlay(
              duration: verificationDuration ??
                  kEducationSimulatedVerificationDuration,
              onCompleted: openTutorRequest,
            ),
          ),
      ],
    );
  }
}
