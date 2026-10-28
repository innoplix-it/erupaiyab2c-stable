import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../widgets/my_app_bar.dart';
import '../components/education_contact_sheet.dart';
import '../components/education_erupaiya_verifying_overlay.dart';
import '../controllers/education_fees_controller.dart';
import '../education_fees_typography.dart';
import '../models/education_fees_responses.dart';
import 'education_tutor_request_view.dart';

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

    void openTutorRequest() {
      if (!context.mounted) return;
      final name = pickedName.value ?? '';
      final mobile = pickedMobile.value ?? '';
      final amountRaw =
          ref.read(educationFeesControllerProvider).amountInput.trim();
      final amount =
          double.tryParse(amountRaw.replaceAll(RegExp(r'\D'), '')) ?? 0;

      isVerifying.value = false;
      verificationStarted.value = false;

      ref.read(educationFeesControllerProvider.notifier).updateMobileInput(
            mobile,
          );
      ref.read(educationFeesControllerProvider.notifier).updateRecipientName(
            name,
          );

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EducationTutorRequestView(
            tutorName: name,
            mobile: mobile,
            amount: amount,
            // Backend `account_masked` under the name; the screen falls back
            // to the mobile-derived mask when the tutor is not saved yet.
            maskedAccount: pickedTutor.value?.accountMasked,
            panDetails: pickedTutor.value?.panMasked,
            accountNumber: pickedTutor.value?.accountNoUnmasked,
            ifscCode: pickedTutor.value?.ifsc,
            branch: pickedTutor.value?.branch,
          ),
        ),
      );
    }

    void onContactPicked(String mobile, String displayName) {
      if (verificationStarted.value || isVerifying.value) return;
      verificationStarted.value = true;
      pickedMobile.value = mobile;
      pickedName.value = displayName;
      pickedTutor.value = null;
      isVerifying.value = true;

      // Resolved while the loader runs; purely display data.
      ref.read(educationFeesControllerProvider.notifier)
          .findBeneficiaryByMobile(mobile)
          .then((beneficiary) {
        if (beneficiary != null) {
          pickedTutor.value = beneficiary;
        }
      });
    }

    return EducationFeesTheme(
      child: PopScope(
        canPop: !isVerifying.value,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: MyAppBar(
            title: '',
            showHelp: true,
            showBharatConnect: false,
            showDivider: false,
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
              if (isVerifying.value)
                EducationErupaiyaVerifyingOverlay(
                  duration: verificationDuration ??
                      kEducationSimulatedVerificationDuration,
                  onCompleted: openTutorRequest,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
