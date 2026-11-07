import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/my_app_bar.dart';
import '../components/education_tutor_identity.dart';

/// Terms shown before the tutor shares bank details.
///
/// `I Agree` pops `true`. `I Disagree` pops `false`. No new API is called.
class BankDetailsTermsView extends StatelessWidget {
  const BankDetailsTermsView({super.key});

  static const _sections = <(String, String)>[
    (
      '1. Purpose of Payment',
      'The requested bank details will be used only to facilitate the tuition fee payment for the specified student.',
    ),
    (
      '2. Student Relationship',
      'I confirm that the requester is associated with my student and the payment is being made towards tuition fees.',
    ),
    (
      '3. Bank Details Sharing',
      'I voluntarily authorize sharing my complete, unmasked bank account details, including account number and IFSC code, with the requester.',
    ),
    (
      '4. Information Accuracy',
      'I confirm that the bank information provided is accurate and belongs to me or an authorized account holder.',
    ),
    (
      '5. Payment Confirmation',
      'I understand that sharing bank details does not mean payment has been received. Payment will remain pending until successfully completed.',
    ),
    (
      '6. Data Privacy',
      'My bank details will be shared with the requester only for the stated payment purpose.',
    ),
    (
      '7. Security',
      'I will never share my OTP, UPI PIN, ATM PIN or banking password with anyone.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final u = educationTutorUnit(context);
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: MyAppBar(
          title: '',
          showHelp: true,
          showBharatConnect: false,
          showDivider: false,
          helpIconSize: 22,
          onBack: () => Navigator.of(context).pop(),
        ),
        body: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20 * u, 12 * u, 20 * u, 16 * u),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Terms & Conditions',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22 * u,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF18181B),
                            ),
                          ),
                          SizedBox(height: 10 * u),
                          Text(
                            'Please read and accept the following terms before sharing your bank details.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14 * u,
                              fontWeight: FontWeight.w400,
                              height: 1.45,
                              color: const Color(0xFF71717A),
                            ),
                          ),
                          SizedBox(height: 22 * u),
                          for (final section in _sections) ...[
                            Text(
                              section.$1,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15 * u,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF18181B),
                              ),
                            ),
                            SizedBox(height: 8 * u),
                            Text(
                              section.$2,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14 * u,
                                fontWeight: FontWeight.w400,
                                height: 1.45,
                                color: const Color(0xFF71717A),
                              ),
                            ),
                            SizedBox(height: 18 * u),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16 * u, 12 * u, 16 * u, 16 * u + bottom),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDD5428),
                        side: BorderSide(color: const Color(0xFFDD5428), width: 1.2 * u),
                        minimumSize: Size.fromHeight(52 * u),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28 * u),
                        ),
                      ),
                      child: Text(
                        'I Disagree',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15 * u,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 14 * u),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFFDD5428),
                        foregroundColor: Colors.white,
                        minimumSize: Size.fromHeight(52 * u),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28 * u),
                        ),
                      ),
                      child: Text(
                        'I Agree',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15 * u,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
