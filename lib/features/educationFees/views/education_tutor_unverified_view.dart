import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/my_app_bar.dart';
import '../components/education_tutor_identity.dart';
import '../education_fees_typography.dart';

/// Unverified-tutor screen (shown after contact pick when the tutor is not
/// yet verified on eRupaiya).
///
/// Reuses the shared [EducationTutorIdentityCard] and the investment banner
/// asset, and offers two CTAs: "Ask for KYC" and "Add Details". "Add Details"
/// opens the existing Enter Recipient Details form.
class EducationTutorUnverifiedView extends StatelessWidget {
  const EducationTutorUnverifiedView({
    super.key,
    required this.tutorName,
    required this.amount,
    required this.amountLabel,
  });

  final String tutorName;

  /// Plain amount in rupees (kept for the future KYC / pay wiring).
  final double amount;
  final String amountLabel;

  @override
  Widget build(BuildContext context) {
    final u = educationTutorUnit(context);
    final inset = 16 * u;

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
                          statusLines: const [
                            EducationTutorStatusLine(
                              text: 'Unverified',
                              color: Color(0xFF71717A),
                              weight: FontWeight.w600,
                            ),
                            EducationTutorStatusLine(
                              text:
                                  'Please ask your tutor to accept the tuition '
                                  'fees \n request on erupaiya app',
                              color: Color(0xFF71717A),
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
                          // TODO(testing): wire to the real KYC request API.
                          onPressed: () => AppSnackbar.show(
                            'Ask for KYC — placeholder',
                            backgroundColor: AppColors.primary,
                            textColor: Colors.white,
                          ),
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
}
