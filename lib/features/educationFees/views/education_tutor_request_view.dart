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
import '../controllers/education_fees_controller.dart';
import '../education_fees_typography.dart';
import 'education_tutor_profile_view.dart';

String _formatElapsed(int seconds) {
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

enum _TutorRequestPhase { form, sending, sent, accepted }

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
    this.sendDuration = const Duration(milliseconds: 1200),
    this.sentLabelDuration = const Duration(milliseconds: 700),
    this.acceptAfterSeconds = 10,
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

  /// Simulated in-flight time for the send-request call (no backend API
  /// exists yet). Override in tests.
  final Duration sendDuration;

  /// How long "Request sent" stays on the loader before the waiting screen.
  final Duration sentLabelDuration;

  /// Seconds the waiting timer runs before the accept signal is simulated.
  /// Replace with the real accept event once the backend/push arrives.
  final int acceptAfterSeconds;

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
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
      // Placeholder for the real accept signal: the timer stops and the
      // accepted loader starts as soon as it reaches [acceptAfterSeconds].
      if (_elapsedSeconds >= widget.acceptAfterSeconds) {
        _onAccepted();
      }
    });
  }

  void _onAccepted() {
    _ticker?.cancel();
    if (_phase == _TutorRequestPhase.accepted) return;
    setState(() {
      _phase = _TutorRequestPhase.accepted;
      _overlayLabel = 'Request accepted successfully';
      _overlaySubtitle = 'you will redirected in 5 sec to tutor profile';
    });
    _openProfileAfterRedirect();
  }

  Future<void> _openProfileAfterRedirect() async {
    await Future<void>.delayed(widget.redirectDuration);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EducationTutorProfileView(
          tutorName: widget.tutorName,
          accountLine: _accountLine(),
          amount: widget.amount,
          amountLabel: _amountLabel(),
          panDetails: widget.panDetails,
          accountNumber: widget.accountNumber,
          ifscCode: widget.ifscCode,
          branch: widget.branch,
        ),
      ),
    );
  }

  /// `account_masked` exactly as the API returned it — never built from the
  /// mobile number, so an absent value stays absent.
  String _accountLine() => widget.maskedAccount?.trim() ?? '';

  String _amountLabel() {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '\u20B9',
      decimalDigits: 0,
    ).format(widget.amount);
  }

  Future<void> _sendRequest() async {
    if (_phase != _TutorRequestPhase.form) return;
    final controller =
        ref.read(educationFeesControllerProvider.notifier);
    controller.updateMobileInput(widget.mobile);
    controller.updateRecipientName(widget.tutorName);

    setState(() {
      _phase = _TutorRequestPhase.sending;
      _overlayLabel = 'Sending Request';
      _overlaySubtitle = 'Do not close or go back.';
    });

    // Simulated request round-trip until the send-request API is wired up.
    await Future<void>.delayed(widget.sendDuration);
    if (!mounted) return;

    setState(() => _overlayLabel = 'Request sent');
    await Future<void>.delayed(widget.sentLabelDuration);
    if (!mounted) return;

    setState(() => _phase = _TutorRequestPhase.sent);
    _startTicker();
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

    return EducationFeesTheme(
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
                decoration:
                    const BoxDecoration(gradient: kEducationTutorBackgroundGradient),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding:
                              EdgeInsets.fromLTRB(inset, 8 * u, inset, 16 * u),
                          child: Column(
                            children: [
                              EducationTutorIdentityCard(
                                unit: u,
                                name: widget.tutorName,
                                accountLine: accountLine,
                                amountLabel: amountLabel,
                                statusLines: [
                                  EducationTutorStatusLine(
                                    text: isSent
                                        ? 'Payment request has been sent successfully'
                                        : 'Please ask your tutor to accept the tuition fees request on erupaiya app',
                                    color: isSent
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFF71717A),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20 * u),
                              // The investment banner image comes from the
                              // backend; no local asset is rendered here.
                              if (isSent) ...[
                                SizedBox(height: 28 * u),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      FileConstants.tutorTimerIconSvg,
                                      width: 24 * u,
                                      height: 24 * u,
                                    ),
                                    SizedBox(width: 8 * u),
                                    Text(
                                      _formatElapsed(_elapsedSeconds),
                                      key: const ValueKey('tutorRequestTimer'),
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
                        padding: EdgeInsets.fromLTRB(inset, 0, inset, 24 * u),
                        child: isSent
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
              if (isLoading)
                EducationErupaiyaVerifyingOverlay(
                  duration: const Duration(days: 365),
                  label: _overlayLabel ?? 'Sending Request',
                  subtitle: _overlaySubtitle ?? 'Do not close or go back.',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
