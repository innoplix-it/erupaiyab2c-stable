import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../widgets/my_app_bar.dart';
import '../components/education_contact_sheet.dart';
import '../components/education_erupaiya_verifying_overlay.dart';
import '../components/education_tutor_identity.dart';
import '../controllers/education_fees_controller.dart';
import '../education_fees_typography.dart';
import '../models/education_fees_responses.dart';
import 'education_tutor_request_view.dart';
import 'education_tutor_unverified_view.dart';

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

    // TEMPORARY (testing only): manual tutor verification toggle shown in the
    // app bar. Remove once the verification status arrives from the API.
    final isTutorVerified = useState(false);

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

      // TEMPORARY (testing only): unverified tutors land on the Ask-for-KYC /
      // Add-Details screen; verified tutors keep the request flow. Replace the
      // branch with the real API verification status later.
      if (!isTutorVerified.value) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => EducationTutorUnverifiedView(
              tutorName: name,
              amount: amount,
              amountLabel: '\u20B9${amount.toStringAsFixed(0)}',
            ),
          ),
        );
        return;
      }

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
      ref
          .read(educationFeesControllerProvider.notifier)
          .findBeneficiaryByMobile(mobile)
          .then((beneficiary) {
        if (beneficiary != null) {
          pickedTutor.value = beneficiary;
        }
      });
    }

    // The processing scrim has to occupy the whole screen, app bar and status
    // bar included, so it is a sibling above the Scaffold rather than a child
    // of the body.
    final u = educationTutorUnit(context);

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
                // TEMPORARY (testing only): Verified / Unverified toggle.
                trailing: _VerificationToggle(
                  unit: u,
                  isVerified: isTutorVerified.value,
                  onChanged: (verified) => isTutorVerified.value = verified,
                ),
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

/// TEMPORARY (testing only): a two-option Verified / Unverified control for
/// the Add Tutor app bar. The selected label turns green. Delete this once the
/// tutor verification status is returned by the API.
class _VerificationToggle extends StatelessWidget {
  const _VerificationToggle({
    required this.unit,
    required this.isVerified,
    required this.onChanged,
  });

  final double unit;
  final bool isVerified;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _VerificationChip(
          unit: u,
          label: 'Verified',
          selected: isVerified,
          onTap: () => onChanged(true),
        ),
        SizedBox(width: 6 * u),
        _VerificationChip(
          unit: u,
          label: 'Unverified',
          selected: !isVerified,
          onTap: () => onChanged(false),
        ),
      ],
    );
  }
}

class _VerificationChip extends StatelessWidget {
  const _VerificationChip({
    required this.unit,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final double unit;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    const green = Color(0xFF16A34A);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10 * u, vertical: 5 * u),
        decoration: BoxDecoration(
          color: selected ? green : const Color(0xFFF4F4F5),
          borderRadius: BorderRadius.circular(20 * u),
          border: Border.all(
            color: selected ? green : const Color(0xFFE4E4E7),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12 * u,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF71717A),
          ),
        ),
      ),
    );
  }
}
