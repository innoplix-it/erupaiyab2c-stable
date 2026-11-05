import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/my_app_bar.dart';
import '../components/education_erupaiya_verifying_overlay.dart';
import '../components/education_tutor_identity.dart';
import '../components/education_tuition_request_popup.dart';
import '../controllers/education_fees_controller.dart';
import '../education_fees_typography.dart';
import '../models/education_fees_responses.dart';
import 'education_tutor_profile_view.dart';

String _formatElapsed(int seconds) {
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

enum _TutorRequestPhase { form, sending, sent, accepted, saveFailed }

class EducationTutorRequestView extends ConsumerStatefulWidget {
  const EducationTutorRequestView({
    super.key,
    required this.tutorName,
    required this.mobile,
    required this.amount,
    this.maskedAccount,
    this.panDetails,
    this.accountNumber,
    this.ifscCode,
    this.branch,
    this.tutorDetails,
    this.subject,
    this.sendDuration = const Duration(milliseconds: 1200),
    this.sentLabelDuration = const Duration(milliseconds: 700),
    this.redirectDuration = const Duration(seconds: 5),
  });

  final String tutorName;
  final String mobile;
  final double amount;
  final String? maskedAccount;

  /// Backend bank details, forwarded to the tutor profile screen.
  final String? panDetails;
  final String? accountNumber;
  final String? ifscCode;
  final String? branch;

  /// `data` of `POST /api/education/tutor/details` for a VERIFIED tutor. When
  /// present its values are what the card shows: name, account number, bank
  /// logo, bank name, account holder name and amount are all taken from the
  /// API exactly as returned. The legacy [maskedAccount] path keeps working
  /// for saved tutors where no details call was made.
  final EducationTutorDetailsData? tutorDetails;

  /// Subject/fee type selected by the user in the amount screen. Passed to
  /// the sendTutorRequest API instead of a hardcoded value.
  final String? subject;

  /// Simulated in-flight time for the send-request call (no backend API
  /// exists yet). Override in tests.
  final Duration sendDuration;

  /// How long "Request sent" stays on the loader before the waiting screen.
  final Duration sentLabelDuration;

  /// How long the "Request accepted successfully" loader is shown before the
  /// tutor profile screen opens (matches its "redirected in 5 sec" caption).
  final Duration redirectDuration;

  @override
  ConsumerState<EducationTutorRequestView> createState() =>
      _EducationTutorRequestViewState();
}

class _EducationTutorRequestViewState
    extends ConsumerState<EducationTutorRequestView> {
  _TutorRequestPhase _phase = _TutorRequestPhase.form;
  String? _overlayLabel;
  String? _overlaySubtitle;
  int _elapsedSeconds = 0;
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _ticker?.cancel();
    final repo = ref.read(educationFeesRepositoryProvider);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);

      // Read request reference from state
      final requestReference = ref.read(educationFeesControllerProvider).requestReference;
      if (requestReference != null &&
          requestReference.isNotEmpty &&
          _elapsedSeconds % 2 == 0) {
        try {
          final statusRes =
              await repo.fetchTutorRequestStatus(requestReference);
          if (!mounted) return;
          if (statusRes.data?.isAccepted == true) {
            _onAccepted();
            return;
          } else if (statusRes.data?.isRejected == true) {
            _onRejected();
            return;
          }
        } catch (_) {}
      }
      
      // NOTE: Backend does not provide an expiry field.
      // Timer continues polling until isAccepted or isRejected becomes true.
      // No hardcoded timeout - relies entirely on backend status.
    });
  }

  void _onRejected() {
    _ticker?.cancel();
    if (_phase == _TutorRequestPhase.accepted) return;
    
    // Show declined popup
    if (mounted) {
      showEducationTuitionRequestPopup(
        context,
        state: EducationTuitionPopupState.declined,
        amount: widget.amount,
        requesterName: widget.tutorName,
      ).then((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  void _onAccepted() {
    _ticker?.cancel();
    if (_phase == _TutorRequestPhase.accepted) return;
    
    // Show accepted popup first
    if (mounted) {
      showEducationTuitionRequestPopup(
        context,
        state: EducationTuitionPopupState.accepted,
        amount: widget.amount,
        requesterName: widget.tutorName,
      ).then((_) {
        if (mounted) {
          setState(() {
            _phase = _TutorRequestPhase.accepted;
            _overlayLabel = 'Request accepted successfully';
            _overlaySubtitle = 'Saving beneficiary details...';
          });
          _saveBeneficiaryAndOpenProfile();
        }
      });
    }
  }

  Future<void> _saveBeneficiaryAndOpenProfile() async {
    final controller = ref.read(educationFeesControllerProvider.notifier);
    final saved = await controller.saveTutorBeneficiaryRegistered();
    if (!mounted) return;

    if (saved) {
      // Only navigate to profile on successful save
      setState(() {
        _overlayLabel = 'Beneficiary saved successfully';
        _overlaySubtitle = 'you will redirected in 5 sec to tutor profile';
      });
      _openProfileAfterRedirect();
    } else {
      // On failure, stay on current screen and show error
      final saveErrorMessage = ref.read(educationFeesControllerProvider).saveErrorMessage;
      setState(() {
        _phase = _TutorRequestPhase.saveFailed;
        _overlayLabel = 'Failed to save beneficiary';
        _overlaySubtitle = saveErrorMessage ?? 'Please retry saving beneficiary details';
      });
      // User can retry by calling _saveBeneficiaryAndOpenProfile again
      // The request remains accepted, so we don't reset to pending
    }
  }

  void _retrySaveBeneficiary() {
    setState(() {
      _phase = _TutorRequestPhase.accepted;
      _overlayLabel = 'Retrying save beneficiary...';
      _overlaySubtitle = 'Please wait';
    });
    _saveBeneficiaryAndOpenProfile();
  }

  Future<void> _openProfileAfterRedirect() async {
    await Future<void>.delayed(widget.redirectDuration);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EducationTutorProfileView(
          tutorName: _tutorName(),
          accountLine: _accountLine(),
          amount: _amount(),
          amountLabel: _amountLabel(),
          panDetails: widget.panDetails,
          accountNumber: _accountNumber(),
          ifscCode: _ifscCode(),
          branch: widget.branch,
          bankLogoUrl: widget.tutorDetails?.bankLogo,
          bankName: widget.tutorDetails?.bankName,
          accountHolderName: widget.tutorDetails?.accountHolderName,
          tutorDetails: widget.tutorDetails,
        ),
      ),
    );
  }

  String _tutorName() {
    final fromApi = widget.tutorDetails?.tutorName.trim() ?? '';
    return fromApi.isNotEmpty ? fromApi : widget.tutorName;
  }

  /// `account_number` exactly as the Tutor Details API returned it; falls back
  /// to the saved tutor's `account_masked`. Never built from the mobile number,
  /// never masked on the client.
  String _accountLine() {
    final fromApi = widget.tutorDetails?.accountNumber.trim() ?? '';
    if (fromApi.isNotEmpty) return fromApi;
    return widget.maskedAccount?.trim() ?? '';
  }

  String _accountNumber() {
    final fromApi = widget.tutorDetails?.accountNumber.trim() ?? '';
    return fromApi.isNotEmpty ? fromApi : (widget.accountNumber ?? '');
  }

  String _ifscCode() {
    final fromApi = widget.tutorDetails?.ifsc.trim() ?? '';
    return fromApi.isNotEmpty ? fromApi : (widget.ifscCode ?? '');
  }

  /// Amount echoed by the Tutor Details API; the amount entered in the flow is
  /// only the fallback when the backend returns no amount at all.
  double _amount() {
    final fromApi = widget.tutorDetails?.amount ?? 0;
    return fromApi > 0 ? fromApi.toDouble() : widget.amount;
  }

  String _amountLabel() {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '\u20B9',
      decimalDigits: 0,
    ).format(_amount());
  }

  /// Bank name and account holder name from the Tutor Details API, rendered
  /// with the card's existing caption style. Absent values are not shown.
  List<EducationTutorStatusLine> _identityStatusLines() {
    final details = widget.tutorDetails;
    if (details == null) return const [];
    final bankName = details.bankName.trim();
    final holderName = details.accountHolderName.trim();
    return [
      if (bankName.isNotEmpty)
        EducationTutorStatusLine(
          text: 'Bank: $bankName',
          color: const Color(0xFF71717A),
        ),
      if (holderName.isNotEmpty)
        EducationTutorStatusLine(
          text: 'Account Holder: $holderName',
          color: const Color(0xFF71717A),
        ),
    ];
  }

  /// Subject typed or passed into this screen, otherwise the fee type
  /// selected on the amount screen. Empty after trim means there is nothing
  /// real to send.
  String? _subjectForRequest() {
    final explicit = widget.subject?.trim() ?? '';
    if (explicit.isNotEmpty) return explicit;
    final selected =
        ref.read(educationFeesControllerProvider).feeType?.trim() ?? '';
    if (selected.isNotEmpty) return selected;
    return null;
  }

  Future<void> _sendRequest() async {
    if (_phase != _TutorRequestPhase.form) return;
    final subject = _subjectForRequest();
    if (subject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a subject before sending the request.'),
        ),
      );
      return;
    }
    final controller = ref.read(educationFeesControllerProvider.notifier);
    controller.updateMobileInput(widget.mobile);
    controller.updateRecipientName(_tutorName());

    setState(() {
      _phase = _TutorRequestPhase.sending;
      _overlayLabel = 'Sending Request';
      _overlaySubtitle = 'Do not close or go back.';
    });

    final repo = ref.read(educationFeesRepositoryProvider);
    try {
      final responseFuture = repo.sendTutorRequest(
        mobile: widget.mobile,
        amount: widget.amount.toInt(),
        subject: subject,
      );
      final results = await Future.wait([
        responseFuture.catchError(
          (_) => const EducationTutorSendRequestResponse(status: false),
        ),
        Future<void>.delayed(widget.sendDuration),
      ]);
      final response = results[0] as EducationTutorSendRequestResponse;
      if (!mounted) return;

      if (response.status && response.data != null) {
        final requestReference = response.data!.requestReference;
        // Store in controller state (single source of truth)
        controller.storeTutorRequestReference(requestReference);
      }

      setState(() => _overlayLabel = 'Request sent');
      await Future<void>.delayed(widget.sentLabelDuration);
      if (!mounted) return;

      setState(() => _phase = _TutorRequestPhase.sent);
      _startTicker();
    } catch (_) {
      if (!mounted) return;
      setState(() => _overlayLabel = 'Request sent');
      await Future<void>.delayed(widget.sentLabelDuration);
      if (!mounted) return;

      setState(() => _phase = _TutorRequestPhase.sent);
      _startTicker();
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = educationTutorUnit(context);
    final inset = 16 * u;
    final amountLabel = _amountLabel();
    final accountLine = _accountLine();
    final isSent = _phase == _TutorRequestPhase.sent ||
        _phase == _TutorRequestPhase.accepted;
    final isLoading = _phase == _TutorRequestPhase.sending ||
        _phase == _TutorRequestPhase.accepted;

    // The processing scrim has to occupy the whole screen, app bar and status
    // bar included, so it is a sibling above the Scaffold rather than a child
    // of the body.
    return Stack(
      children: [
        EducationFeesTheme(
          child: PopScope(
            canPop: _phase != _TutorRequestPhase.sending &&
                _phase != _TutorRequestPhase.accepted,
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
              body: Stack(
                children: [
                  DecoratedBox(
                    decoration: const BoxDecoration(
                        gradient: kEducationTutorBackgroundGradient),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.fromLTRB(
                                  inset, 8 * u, inset, 16 * u),
                              child: Column(
                                children: [
                                  EducationTutorIdentityCard(
                                    unit: u,
                                    name: _tutorName(),
                                    accountLine: accountLine,
                                    amountLabel: amountLabel,
                                    bankLogoUrl: widget.tutorDetails?.bankLogo,
                                    statusLines: [
                                      EducationTutorStatusLine(
                                        text: isSent
                                            ? 'Payment request has been sent successfully'
                                            : 'Please ask your tutor to accept the tuition fees request on erupaiya app',
                                        color: isSent
                                            ? const Color(0xFF16A34A)
                                            : const Color(0xFF71717A),
                                      ),
                                      ..._identityStatusLines(),
                                    ],
                                  ),
                                  SizedBox(height: 20 * u),
                                  // The investment banner image comes from the
                                  // backend; no local asset is rendered here.
                                  if (isSent) ...[
                                    SizedBox(height: 28 * u),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SvgPicture.asset(
                                          FileConstants.tutorTimerIconSvg,
                                          width: 24 * u,
                                          height: 24 * u,
                                        ),
                                        SizedBox(width: 8 * u),
                                        Text(
                                          _formatElapsed(_elapsedSeconds),
                                          key: const ValueKey(
                                              'tutorRequestTimer'),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 24 * u,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFFDD5428),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12 * u),
                                    Text(
                                      'Please wait until request\naccept from tutor',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15 * u,
                                        fontWeight: FontWeight.w500,
                                        height: 1.4,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (isSent)
                            Padding(
                              padding: EdgeInsets.only(bottom: 10 * u),
                              child: Text(
                                'go back and relax , will notify you once accept',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12 * u,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF71717A),
                                ),
                              ),
                            ),
                          Padding(
                            // Figma footer: 24px above the system bottom inset.
                            padding:
                                EdgeInsets.fromLTRB(inset, 0, inset, 24 * u),
                            child: _phase == _TutorRequestPhase.saveFailed
                                ? CustomElevatedButton(
                                    onPressed: _retrySaveBeneficiary,
                                    label: 'Retry Save',
                                    showArrow: false,
                                    uppercaseLabel: false,
                                    height: 52 * u,
                                    backgroundColor: const Color(0xFFDD5428),
                                  )
                                : isSent
                                    ? CustomElevatedButton(
                                        onPressed: () => context.go(
                                          RouteConstants.home,
                                        ),
                                        label: 'Go to Home',
                                        showArrow: false,
                                        uppercaseLabel: false,
                                        height: 52 * u,
                                        backgroundColor: AppColors.primary,
                                      )
                                    : Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () => context.pop(),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    const Color(0xFFDD5428),
                                                side: const BorderSide(
                                                  color: Color(0xFFDD5428),
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 14 * u,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(28 * u),
                                                ),
                                              ),
                                              child: Text(
                                                'Cancel',
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
                                              onPressed: _sendRequest,
                                              label: 'Send Request',
                                              showArrow: false,
                                              uppercaseLabel: false,
                                              height: 48 * u,
                                            ),
                                          ),
                                        ],
                                      ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isLoading)
          Positioned.fill(
            child: EducationErupaiyaVerifyingOverlay(
              duration: const Duration(days: 365),
              label: _overlayLabel ?? 'Sending Request',
              subtitle: _overlaySubtitle ?? 'Do not close or go back.',
            ),
          ),
      ],
    );
  }
}
