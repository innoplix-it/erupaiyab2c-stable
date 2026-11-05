import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/k_dialog.dart';
import '../../../widgets/my_app_bar.dart';
import '../components/education_payment_sheets.dart';
import '../components/education_tutor_identity.dart';
import '../controllers/education_fees_controller.dart';
import '../repositories/education_fees_repository.dart';
import '../education_fees_typography.dart';
import '../helpers/education_pay_now.dart';
import '../models/education_fees_responses.dart';

/// Tutor profile screen shown after the tutor accepts the request.
///
/// Mirrors the tutor request card (shared [EducationTutorIdentityCard]) and
/// adds the backend bank details, the optional subject field and the pay CTA.
class EducationTutorProfileView extends ConsumerStatefulWidget {
  const EducationTutorProfileView({
    super.key,
    required this.tutorName,
    required this.accountLine,
    required this.amount,
    required this.amountLabel,
    required this.panDetails,
    required this.accountNumber,
    required this.ifscCode,
    required this.branch,
    this.verified = true,
    this.bankLogoUrl,
    this.bankName,
    this.accountHolderName,
    this.tutorDetails,
    this.subject,
    this.mobile,
  });

  final String tutorName;
  final String accountLine;

  /// Plain amount in rupees, used by the payment-summary API.
  final double amount;
  final String amountLabel;
  final String? panDetails;
  final String? accountNumber;
  final String? ifscCode;
  final String? branch;

  /// Avatar corner tick state on the identity card: green when the tutor is
  /// verified on eRupaiya, gold for a newly-added (unverified) tutor.
  final bool verified;

  /// Bank details from Tutor Details API.
  final String? bankLogoUrl;
  final String? bankName;
  final String? accountHolderName;
  final EducationTutorDetailsData? tutorDetails;

  /// Subject the sender already chose. Shown in the subject field.
  final String? subject;

  /// Tutor mobile, used to re-read `POST /api/education/tutor/details` at pay.
  final String? mobile;

  @override
  ConsumerState<EducationTutorProfileView> createState() =>
      _EducationTutorProfileViewState();
}

class _EducationTutorProfileViewState
    extends ConsumerState<EducationTutorProfileView> {
  final TextEditingController _subjectController = TextEditingController();
  bool _openingSummary = false;

  @override
  void initState() {
    super.initState();
    final subject = widget.subject?.trim() ?? '';
    if (subject.isNotEmpty) {
      _subjectController.text = subject;
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  /// Opens the shared (unmodified) Payment Summary sheet with fresh numbers
  /// from the payment-summary API, then pays through the shared Razorpay flow.
  Future<void> _proceedToPay() async {
    if (_openingSummary) return;
    setState(() => _openingSummary = true);

    final repository = ref.read(educationFeesRepositoryProvider);
    final details = await _tutorDetailsFromApi(repository);
    final amount = details != null && details.amount > 0
        ? details.amount.toDouble()
        : widget.amount;
    EducationPaymentSummaryData? summary;
    try {
      final response = await repository.fetchPaymentSummary(
        amount: amount.round(),
      );
      if (response.status) summary = response.data;
    } catch (_) {
      summary = null;
    }
    if (!mounted) return;
    setState(() => _openingSummary = false);

    if (summary == null) {
      AppSnackbar.show(
        'Payment summary is not available. Please wait or try again.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    final state = ref.read(educationFeesControllerProvider);
    // tutor/details is the only source: tutor_name, account_number, ifsc, amount.
    final recipientName = _filled([details?.tutorName, widget.tutorName]);
    final accountNo = _filled([details?.accountNumber, widget.accountNumber]);
    final ifsc = _filled([details?.ifsc, widget.ifscCode]);
    final feeType = _filled([widget.subject, state.feeType]);
    KDialog.instance.openSheet(
      dialog: EducationPaymentSummarySheet(
        amount: amount,
        initialSummary: summary,
        onPayNow: (payable) => runEducationPayNow(
          context: context,
          ref: ref,
          repository: repository,
          state: state,
          amount: amount,
          payable: payable,
          recipientName: recipientName,
          accountNo: accountNo,
          ifsc: ifsc,
          feeType: feeType,
        ),
      ),
    );
  }

  /// Latest `POST /api/education/tutor/details` body. The screen copy is the
  /// same API from when the profile opened.
  Future<EducationTutorDetailsData?> _tutorDetailsFromApi(
    EducationFeesRepository repository,
  ) async {
    final mobile = widget.mobile?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (mobile.length == 10) {
      try {
        final amount = widget.tutorDetails?.amount ?? widget.amount.round();
        final response = await repository.fetchTutorDetails(
          mobile: mobile,
          amount: amount > 0 ? amount : widget.amount.round(),
        );
        if (response.status && response.data != null) return response.data;
      } catch (_) {
        // Keep the tutor-details payload already on this screen.
      }
    }
    return widget.tutorDetails;
  }

  /// First non-empty value. "NA" is only a display placeholder.
  String _filled(List<String?> values) {
    for (final value in values) {
      final text = value?.trim() ?? '';
      if (text.isEmpty || text.toLowerCase() == 'na') continue;
      return text;
    }
    return '';
  }

  /// Backend values are shown verbatim; a missing (null/empty) field is
  /// rendered as "NA" instead of a made-up value.
  String _value(String? raw) {
    final value = raw?.trim() ?? '';
    return value.isEmpty ? 'NA' : value;
  }

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
          onBack: () => context.pop(),
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
                          name: widget.tutorName,
                          accountLine: widget.accountLine,
                          amountLabel: widget.amountLabel,
                          verified: widget.verified,
                          bankLogoUrl: widget.bankLogoUrl ??
                              widget.tutorDetails?.bankLogo,
                          statusLines: const [
                            EducationTutorStatusLine(
                              text: 'tutor will be saved for future payments',
                              color: Color(0xFF71717A),
                            ),
                          ],
                        ),
                        SizedBox(height: 22 * u),
                        Text(
                          'BANK DETAILS',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12 * u,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4 * u,
                            color: const Color(0xFF52525B),
                          ),
                        ),
                        SizedBox(height: 10 * u),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16 * u),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14 * u),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 14 * u,
                                offset: Offset(0, 4 * u),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: EducationTutorDetailCell(
                                      unit: u,
                                      label: 'PAN Details',
                                      value: _value(widget.panDetails),
                                    ),
                                  ),
                                  Expanded(
                                    child: EducationTutorDetailCell(
                                      unit: u,
                                      label: 'Account Number',
                                      value: _value(widget.accountNumber ??
                                          widget.tutorDetails?.accountNumber),
                                      alignRight: true,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 18 * u),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: EducationTutorDetailCell(
                                      unit: u,
                                      label: 'IFSC Code',
                                      value: _value(widget.ifscCode ??
                                          widget.tutorDetails?.ifsc),
                                    ),
                                  ),
                                  Expanded(
                                    child: EducationTutorDetailCell(
                                      unit: u,
                                      label: 'Branch',
                                      value: _value(widget.branch),
                                      alignRight: true,
                                    ),
                                  ),
                                ],
                              ),
                              if ((widget.bankName != null &&
                                      widget.bankName!.trim().isNotEmpty) ||
                                  (widget.tutorDetails?.bankName
                                          .trim()
                                          .isNotEmpty ==
                                      true)) ...[
                                SizedBox(height: 18 * u),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: EducationTutorDetailCell(
                                        unit: u,
                                        label: 'Bank Name',
                                        value: _value(widget.bankName ??
                                            widget.tutorDetails?.bankName),
                                      ),
                                    ),
                                    if ((widget.accountHolderName != null &&
                                            widget.accountHolderName!
                                                .trim()
                                                .isNotEmpty) ||
                                        (widget.tutorDetails?.accountHolderName
                                                .trim()
                                                .isNotEmpty ==
                                            true))
                                      Expanded(
                                        child: EducationTutorDetailCell(
                                          unit: u,
                                          label: 'Account Holder',
                                          value: _value(
                                              widget.accountHolderName ??
                                                  widget.tutorDetails
                                                      ?.accountHolderName),
                                          alignRight: true,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: 20 * u),
                        Text(
                          'Subject (Optional)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14 * u,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 8 * u),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14 * u,
                            vertical: 4 * u,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12 * u),
                            border: Border.all(color: const Color(0xFFE4E4E7)),
                          ),
                          child: TextField(
                            controller: _subjectController,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14 * u,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 12 * u,
                              ),
                              hintText: 'Enter subject',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 14 * u,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF7C7C7C),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(inset, 0, inset, 24 * u),
                  child: CustomElevatedButton(
                    onPressed: _proceedToPay,
                    label: 'Proceed to Pay',
                    showArrow: false,
                    uppercaseLabel: false,
                    height: 52 * u,
                    backgroundColor: AppColors.primary,
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
