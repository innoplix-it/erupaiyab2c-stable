import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_error_messages.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/my_app_bar.dart';
import '../components/education_tutor_identity.dart';
import '../controllers/education_fees_controller.dart';
import '../education_fees_typography.dart';
import '../models/education_fees_responses.dart';

/// Unverified-tutor screen (shown after contact pick when the tutor is not
/// yet verified on eRupaiya).
///
/// Reuses the shared [EducationTutorIdentityCard] and the investment banner
/// asset, and offers two CTAs: "Ask for KYC" and "Add Details". "Add Details"
/// opens the existing Enter Recipient Details form.
class EducationTutorUnverifiedView extends HookConsumerWidget {
  const EducationTutorUnverifiedView({
    super.key,
    required this.tutorName,
    required this.amount,
    required this.amountLabel,
    this.verificationStatus = EducationTutorVerificationStatus.notVerified,
    this.apiMessage,
  });

  final String tutorName;

  /// Plain amount in rupees (kept for the future KYC / pay wiring).
  final double amount;
  final String amountLabel;
  final EducationTutorVerificationStatus verificationStatus;
  final String? apiMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = educationTutorUnit(context);
    final inset = 16 * u;
    final asking = useState(false);

    return EducationFeesTheme(
      child: Scaffold(
        backgroundColor: const Color(0xFFB5FFDA),
        appBar: MyAppBar(
          title: '',
          showHelp: true,
          showBharatConnect: false,
          showDivider: false,
          backgroundColor: const Color(0xFFB5FFDA),
          helpIconSize: 20 * u,
          onBack: () => Navigator.of(context).maybePop(),
        ),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: kEducationTutorBackgroundGradient,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(inset, 8 * u, inset, 16 * u),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EducationTutorIdentityCard(
                          unit: u,
                          name: tutorName,
                          // No masked account for an unverified tutor.
                          accountLine: '',
                          amountLabel: amountLabel,
                          verified: false,
                          statusLines: [
                            EducationTutorStatusLine(
                              text: _getStatusText(),
                              color: const Color(0xFFDC2626),
                              weight: FontWeight.w600,
                              fontSize: 14 * u,
                            ),
                            EducationTutorStatusLine(
                              text: _getStatusMessage(),
                              color: const Color(0xFFDC2626),
                              fontSize: 14 * u,
                            ),
                            EducationTutorStatusLine(
                              text: '$tutorName • $amountLabel',
                              color: const Color(0xFF71717A),
                            ),
                          ],
                        ),
                        // Investment banner is served by the backend; no local
                        // asset is rendered here.
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(inset, 0, inset, 24 * u),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: asking.value
                              ? null
                              : () async {
                                  asking.value = true;
                                  final response = await ref
                                      .read(educationFeesControllerProvider
                                          .notifier)
                                      .askTutorForKyc();
                                  asking.value = false;
                                  if (!context.mounted || response == null) {
                                    return;
                                  }
                                  final message =
                                      response.message?.trim() ?? '';
                                  AppSnackbar.show(
                                    message.isNotEmpty
                                        ? message
                                        : (response.status
                                            ? 'KYC reminder notification sent successfully.'
                                            : AppErrorMessages.generic),
                                    backgroundColor: response.status
                                        ? AppColors.primary
                                        : AppColors.red,
                                    textColor: Colors.white,
                                  );
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: EdgeInsets.symmetric(vertical: 14 * u),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28 * u),
                            ),
                          ),
                          child: Text(
                            'Ask for KYC',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 15 * u,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12 * u),
                      Expanded(
                        child: CustomElevatedButton(
                          onPressed: () => context.push(
                            RouteConstants.educationTutorAddDetails,
                          ),
                          label: 'Add Details',
                          showArrow: false,
                          uppercaseLabel: false,
                          height: 52 * u,
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusText() {
    final msg = apiMessage?.toLowerCase() ?? '';
    if (msg.contains('not registered')) {
      return 'Not registered';
    }
    if (msg.contains('verified successfully')) {
      return 'KYC Not Completed';
    }
    if (verificationStatus == EducationTutorVerificationStatus.notVerified) {
      return 'KYC Not Completed';
    }
    return 'Unverified';
  }

  String _getStatusMessage() {
    final msg = apiMessage?.toLowerCase() ?? '';
    if (msg.contains('not registered')) {
      return apiMessage?.trim() ?? 'This mobile number is not registered with eRupaiya. '
          'Ask the recipient to register before you add them as a tutor.';
    }
    if (msg.contains('verified successfully')) {
      return 'Please ask your tutor to accept the tuition '
          'fees \n request on erupaiya app';
    }
    if (verificationStatus == EducationTutorVerificationStatus.notVerified) {
      return 'Please ask your tutor to accept the tuition '
          'fees \n request on erupaiya app';
    }
    return '';
  }
}
