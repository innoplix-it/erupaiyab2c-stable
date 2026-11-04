import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../widgets/my_app_bar.dart';
import '../components/education_contact_sheet.dart';
import '../components/education_erupaiya_verifying_overlay.dart';
import '../components/education_tutor_identity.dart';
import '../controllers/education_fees_controller.dart';
import '../education_fees_typography.dart';
import '../models/education_fees_responses.dart';
import 'education_tutor_request_view.dart';
import 'education_tutor_unverified_view.dart';

/// AppBar flow selector on the Add-Tutor contacts screen: picking a contact
/// then runs the matching verified / unverified tutor flow.
enum EducationTutorFlowMode { verified, unverified }

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
    final flowMode = useState(EducationTutorFlowMode.verified);
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

      // Keep the controller inputs in sync so any form opened further down
      // the flow starts prefilled.
      ref.read(educationFeesControllerProvider.notifier).updateMobileInput(
            mobile,
          );
      ref.read(educationFeesControllerProvider.notifier).updateRecipientName(
            name,
          );

      // Verified tutor: the tuition-fees request card (verified identity badge,
      // Cancel / Send Request). Plain Navigator push, no go_router route.
      if (flowMode.value == EducationTutorFlowMode.verified) {
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
        return;
      }

      // Unverified tutor: the Ask for KYC / Add Details screen.
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
                trailing: _TutorFlowToggle(
                  mode: flowMode.value,
                  onChanged: (mode) => flowMode.value = mode,
                ),
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

/// AppBar pill toggle (same styling as the Mobile Prepaid search-mode
/// toggle) that picks which flow a contact pick should run.
class _TutorFlowToggle extends StatelessWidget {
  const _TutorFlowToggle({required this.mode, required this.onChanged});

  final EducationTutorFlowMode mode;
  final ValueChanged<EducationTutorFlowMode> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip({
      required String label,
      required EducationTutorFlowMode value,
      required double width,
    }) {
      final active = mode == value;
      return SizedBox(
        width: width,
        height: 24.h,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Same hit-target structure as the Mobile Prepaid ABC/123 pill:
            // a ~44x44 tap area without enlarging the visible chip.
            Positioned(
              top: -14.h,
              bottom: -14.h,
              left: -4.w,
              right: -4.w,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(value),
                child: const SizedBox.shrink(),
              ),
            ),
            InkWell(
              onTap: () => onChanged(value),
              borderRadius: BorderRadius.circular(90.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: width,
                height: 24.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFDD5428) : Colors.transparent,
                  borderRadius: BorderRadius.circular(90.r),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: active ? Colors.white : const Color(0xFF000000),
                      fontWeight: FontWeight.w500,
                      fontSize: 11.sp,
                      height: 1.0,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return FittedBox(
      // Shrink on very narrow screens instead of overflowing the toolbar.
      fit: BoxFit.scaleDown,
      child: Padding(
        padding: EdgeInsets.only(right: 4.w),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0x21DD5428),
            borderRadius: BorderRadius.circular(90.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 3.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                chip(
                  label: 'Verified',
                  value: EducationTutorFlowMode.verified,
                  width: 62.w,
                ),
                chip(
                  label: 'Unverified',
                  value: EducationTutorFlowMode.unverified,
                  width: 74.w,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
