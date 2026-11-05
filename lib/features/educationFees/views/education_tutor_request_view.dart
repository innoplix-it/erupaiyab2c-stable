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
import '../components/education_tuition_request_popup.dart';
import '../components/education_tutor_identity.dart';
import '../controllers/education_fees_controller.dart';
import '../education_fees_typography.dart';
import '../models/education_fees_responses.dart';
import 'education_tutor_profile_view.dart';

String _formatElapsed(int seconds) {
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

enum _TutorRequestPhase {
  form,
  sending,
  sent,
  accepted,
  saveFailed,
}

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
    this.redirectDuration = const Duration(milliseconds: 800),
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

  /// `data` of `POST /api/education/tutor/details`
  /// for a VERIFIED tutor.
  final EducationTutorDetailsData? tutorDetails;

  /// Subject/fee type selected by the user in the amount screen.
  final String? subject;

  final Duration sendDuration;
  final Duration sentLabelDuration;

  /// Short pause on "Beneficiary saved" before the profile screen opens.
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

  /// Guards: one status call at a time, accept/reject handled only once.
  bool _polling = false;
  bool _resultHandled = false;

  /// Accept loader sits on this screen so the tutor card stays visible.
  bool _acceptLoader = false;

  /// Fresh tutor details fetched right after the tutor accepts.
  EducationTutorDetailsData? _freshDetails;

  /// Subject returned by the accept status call, when the backend sends one.
  String? _acceptedSubject;

  EducationTutorDetailsData? get _details =>
      _freshDetails ?? widget.tutorDetails;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Polling (sender side).
  // ---------------------------------------------------------------------------

  void _startTicker() {
    _ticker?.cancel();

    final repo = ref.read(educationFeesRepositoryProvider);

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;

      setState(() => _elapsedSeconds++);

      if (_resultHandled || _polling || _elapsedSeconds % 2 != 0) {
        return;
      }

      final requestReference =
          ref.read(educationFeesControllerProvider).requestReference;

      if (requestReference == null || requestReference.isEmpty) {
        return;
      }

      _polling = true;

      try {
        final statusRes =
        await repo.fetchTutorRequestStatus(requestReference);

        if (!mounted || _resultHandled) return;

        // After accept the status API can return 409 when the tutor has no
        // PAN on file. Stop polling and open the profile with tutor/details.
        final panUnavailable = _receiverPanUnavailable(statusRes);

        if (statusRes.data?.isAccepted == true || panUnavailable) {
          _resultHandled = true;
          final subject = statusRes.data?.subject.trim() ?? '';
          if (subject.isNotEmpty) _acceptedSubject = subject;
          _onAccepted();
        } else if (statusRes.data?.isRejected == true) {
          _resultHandled = true;
          unawaited(_onRejected());
        }
      } catch (_) {
        // Keep polling until the backend reports accepted / rejected.
      } finally {
        _polling = false;
      }
    });
  }

  /// Tutor declined: show the declined popup with SENDER wording
  /// ("<Tutor> has declined your tuition fee payment request."), then go back
  /// once the popup is closed (Done / X / tap outside).
  Future<void> _onRejected() async {
    _ticker?.cancel();

    if (!mounted) return;

    await showEducationTuitionRequestPopup(
      context,
      state: EducationTuitionPopupState.declined,
      amount: _amount(),
      requesterName: _tutorName(),
      isSenderView: true,
    );

    if (!mounted) return;

    Navigator.of(context).pop();
  }

  bool _receiverPanUnavailable(EducationTutorRequestStatusResponse response) {
    final message = response.message?.toLowerCase() ?? '';
    return response.status == false &&
        message.contains('receiver pan details are unavailable');
  }

  /// Tutor accepted: same verifying loader on this screen, then the profile.
  void _onAccepted() {
    _ticker?.cancel();

    if (!mounted) return;

    setState(() {
      _acceptLoader = true;
      _overlayLabel = 'Request accepted successfully';
      _overlaySubtitle = 'Do not close or go back.';
    });

    unawaited(_showAcceptedLoaderThenProfile());
  }

  Future<void> _showAcceptedLoaderThenProfile() async {
    try {
      await Future.wait<void>([
        _prepareAcceptedProfile(),
        Future<void>.delayed(widget.redirectDuration),
      ]);
    } catch (_) {
      // Open the profile with whatever details are already on screen.
    }

    if (!mounted) return;

    _openProfile();
  }

  Future<void> _prepareAcceptedProfile() async {
    await _refreshTutorDetails();

    if (!mounted) return;

    try {
      await ref
          .read(educationFeesControllerProvider.notifier)
          .saveTutorBeneficiaryRegistered();
    } catch (_) {
      // The profile still opens with the tutor details already fetched.
    }
  }

  /// Re-fetches tutor/details (bank name, account, IFSC, holder).
  /// Any failure falls back to the details we already have,
  /// so the flow never blocks.
  Future<void> _refreshTutorDetails() async {
    try {
      final repo = ref.read(educationFeesRepositoryProvider);

      final res = await repo.fetchTutorDetails(
        mobile: widget.mobile,
        amount: _amount().toInt(),
      );

      final EducationTutorDetailsData? fresh = res.data;

      if (fresh != null && mounted) {
        _freshDetails = fresh;
      }
    } catch (_) {
      // Keep widget.tutorDetails as fallback.
    }
  }

  void _retrySaveBeneficiary() {
    unawaited(_showAcceptedLoaderThenProfile());
  }

  void _openProfile() {
    final details = _details;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => EducationTutorProfileView(
          tutorName: _tutorName(),
          accountLine: _accountLine(),
          amount: _amount(),
          amountLabel: _amountLabel(),
          panDetails: _pan(),
          accountNumber: _accountNumber(),
          ifscCode: _ifscCode(),
          branch: _branch(),
          subject: _subjectForProfile(),
          bankLogoUrl: details?.bankLogo,
          bankName: details?.bankName,
          accountHolderName: details?.accountHolderName,
          tutorDetails: details,
          mobile: widget.mobile,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Display helpers
  // ---------------------------------------------------------------------------

  String _tutorName() {
    final fromApi = _details?.tutorName.trim() ?? '';

    return fromApi.isNotEmpty ? fromApi : widget.tutorName;
  }

  String _accountLine() {
    final masked = _details?.accountMasked?.trim() ?? '';

    if (masked.isNotEmpty) return masked;

    final widgetMasked = widget.maskedAccount?.trim() ?? '';

    if (widgetMasked.isNotEmpty) return widgetMasked;

    return _accountNumber();
  }

  String? _pan() {
    final masked = _details?.panMasked?.trim() ?? '';

    if (masked.isNotEmpty) return masked;

    final pan = _details?.pan?.trim() ?? '';

    if (pan.isNotEmpty) return pan;

    final widgetPan = widget.panDetails?.trim() ?? '';

    return widgetPan.isEmpty ? null : widgetPan;
  }

  String? _branch() {
    final fromApi = _details?.branch?.trim() ?? '';

    if (fromApi.isNotEmpty) return fromApi;

    final widgetBranch = widget.branch?.trim() ?? '';

    return widgetBranch.isEmpty ? null : widgetBranch;
  }

  String? _subjectForProfile() {
    final accepted = _acceptedSubject?.trim() ?? '';

    if (accepted.isNotEmpty) return accepted;

    return _subjectForRequest();
  }

  String _accountNumber() {
    final fromApi = _details?.accountNumber.trim() ?? '';

    return fromApi.isNotEmpty ? fromApi : (widget.accountNumber ?? '');
  }

  String _ifscCode() {
    final fromApi = _details?.ifsc.trim() ?? '';

    return fromApi.isNotEmpty ? fromApi : (widget.ifscCode ?? '');
  }

  double _amount() {
    final fromApi = _details?.amount ?? 0;

    return fromApi > 0 ? fromApi.toDouble() : widget.amount;
  }

  String _amountLabel() {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(_amount());
  }

  List<EducationTutorStatusLine> _identityStatusLines() {
    final details = _details;

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

  String? _subjectForRequest() {
    final explicit = widget.subject?.trim() ?? '';

    if (explicit.isNotEmpty) return explicit;

    final selected =
        ref.read(educationFeesControllerProvider).feeType?.trim() ?? '';

    if (selected.isNotEmpty) return selected;

    return null;
  }

  // ---------------------------------------------------------------------------
  // Send request
  // ---------------------------------------------------------------------------

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
              (_) => const EducationTutorSendRequestResponse(
            status: false,
          ),
        ),
        Future<void>.delayed(widget.sendDuration),
      ]);

      final response = results[0] as EducationTutorSendRequestResponse;

      if (!mounted) return;

      if (response.status && response.data != null) {
        controller.storeTutorRequestReference(
          response.data!.requestReference,
        );
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

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final u = educationTutorUnit(context);
    final inset = 16 * u;

    final amountLabel = _amountLabel();
    final accountLine = _accountLine();

    final isSent = _phase == _TutorRequestPhase.sent ||
        _phase == _TutorRequestPhase.accepted;

    final isLoading =
        _phase == _TutorRequestPhase.sending || _acceptLoader;

    return Stack(
      children: [
        EducationFeesTheme(
          child: PopScope(
            canPop: _phase != _TutorRequestPhase.sending && !_acceptLoader,
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
                      gradient: kEducationTutorBackgroundGradient,
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.fromLTRB(
                                inset,
                                8 * u,
                                inset,
                                16 * u,
                              ),
                              child: Column(
                                children: [
                                  EducationTutorIdentityCard(
                                    unit: u,
                                    name: _tutorName(),
                                    accountLine: accountLine,
                                    amountLabel: amountLabel,
                                    bankLogoUrl: _details?.bankLogo,
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
                                            'tutorRequestTimer',
                                          ),
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
                              padding: EdgeInsets.only(
                                bottom: 10 * u,
                              ),
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
                            padding: EdgeInsets.fromLTRB(
                              inset,
                              0,
                              inset,
                              24 * u,
                            ),
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
                                        BorderRadius.circular(
                                          28 * u,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style:
                                      GoogleFonts.plusJakartaSans(
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