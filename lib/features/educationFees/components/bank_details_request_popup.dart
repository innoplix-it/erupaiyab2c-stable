import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../constants/file_constants.dart';
import '../../home/controllers/notifications_controller.dart';
import '../../home/repositories/notifications_repository.dart';
import '../constants/tutor_notification_constants.dart';
import '../controllers/education_fees_controller.dart';
import '../views/bank_details_terms_view.dart';
import 'education_tutor_identity.dart';


class BankDetailsRequestPopup extends StatefulWidget {
  const BankDetailsRequestPopup({
    super.key,
    this.requesterName,
    this.feeType,
    this.amount,
    this.paymentPurpose,
    this.paymentMethod,
    this.paymentStatus,
    this.requestReference,
    this.notificationId,
    this.onClose,
    this.onDecline,
    this.onShareDetails,
  });

  /// Requester display name from the request payload.
  final String? requesterName;

  /// Fee type from the request payload. Highlighted in the sentence.
  final String? feeType;

  final double? amount;
  final String? paymentPurpose;
  final String? paymentMethod;
  final String? paymentStatus;

  /// When set, Share Details and Decline use the existing
  /// POST /api/education/tutor/respond-request call.
  final String? requestReference;

  /// Notification ID from Alerts. Used to delete the notification after
  /// successful Respond API call.
  final String? notificationId;

  /// When set, the close button uses this instead of popping the route.
  final VoidCallback? onClose;

  final VoidCallback? onDecline;
  final VoidCallback? onShareDetails;

  @override
  State<BankDetailsRequestPopup> createState() =>
      _BankDetailsRequestPopupState();
}

class _BankDetailsRequestPopupState extends State<BankDetailsRequestPopup> {
  bool _agreed = false;
  bool _isSubmitting = false;

  String get _name {
    final raw = widget.requesterName?.trim() ?? '';
    if (raw.isEmpty) return '';
    return raw
        .split(RegExp(r'\s+'))
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String? get _feeType {
    final value = widget.feeType?.trim() ?? '';
    return value.isEmpty ? null : value;
  }

  String? get _amountLabel {
    final amount = widget.amount;
    if (amount == null) return null;
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(amount);
  }

  Future<void> _openTerms() async {
    final agreed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const BankDetailsTermsView(),
      ),
    );
    if (!mounted || agreed == null) return;
    setState(() => _agreed = agreed);
  }

  Future<void> _respond(bool share) async {
    final reference = widget.requestReference?.trim() ?? '';
    if (reference.isEmpty) {
      // No request reference - just close the popup
      if (!mounted) return;
      if (share) {
        (widget.onShareDetails ?? () => Navigator.of(context).pop(true))();
      } else {
        (widget.onDecline ?? () => Navigator.of(context).pop(false))();
      }
      return;
    }

    if (_isSubmitting) return; // Prevent duplicate submissions
    setState(() => _isSubmitting = true);

    try {
      final response = await ProviderScope.containerOf(context)
          .read(educationFeesRepositoryProvider)
          .respondToTutorRequest(
            requestReference: reference,
            action: share
                ? TutorNotificationConstants.statusAccepted
                : TutorNotificationConstants.statusRejected,
          );

      if (!mounted) return;

      // Handle already-responded case
      if (!response.status) {
        final requestStatus = response.requestStatus?.trim().toUpperCase();
        if (requestStatus == 'ACCEPTED' || requestStatus == 'REJECTED') {
          // Already responded - use the actual backend status
          // Still delete the notification since it's already handled
          await _deleteNotification();
          if (share) {
            (widget.onShareDetails ?? () => Navigator.of(context).pop(true))();
          } else {
            (widget.onDecline ?? () => Navigator.of(context).pop(false))();
          }
          return;
        }
        // Other error - keep popup open for retry
        setState(() => _isSubmitting = false);
        return;
      }

      // Successful response
      await _deleteNotification();

      if (share) {
        (widget.onShareDetails ?? () => Navigator.of(context).pop(true))();
      } else {
        (widget.onDecline ?? () => Navigator.of(context).pop(false))();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteNotification() async {
    final notificationId = widget.notificationId?.trim() ?? '';
    if (notificationId.isEmpty) return;

    try {
      final notificationsRepo = ProviderScope.containerOf(context)
          .read(notificationsRepositoryProvider);
      await notificationsRepo.deleteNotification(notificationId);
    } catch (_) {
      // Delete failure - don't block the flow, just log
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = educationTutorUnit(context);
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final verticalInset = math.max(
      24 * u,
      math.max(viewPadding.top, viewPadding.bottom) + 8 * u,
    );
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.fromLTRB(
        20 * u,
        verticalInset,
        20 * u,
        verticalInset + keyboard,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28 * u),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20 * u, 16 * u, 20 * u, 20 * u),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: widget.onClose ?? () => Navigator.of(context).pop(),
                      child: SvgPicture.asset(
                        FileConstants.tuitionPopupCloseSvg,
                        width: 28 * u,
                        height: 28 * u,
                      ),
                    ),
                  ),
                  SizedBox(height: 4 * u),
                  _TeacherDisc(unit: u),
                  SizedBox(height: 16 * u),
                  Text(
                    'Bank Details Request',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18 * u,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: const Color(0xFF18181B),
                    ),
                  ),
                  SizedBox(height: 8 * u),
                  _RequestSentence(
                    unit: u,
                    name: _name,
                    feeType: _feeType,
                  ),
                  SizedBox(height: 16 * u),
                  const _NoticeBox(),
                  SizedBox(height: 10 * u),
                  _PaymentBox(
                    unit: u,
                    amount: _amountLabel,
                    purpose: widget.paymentPurpose,
                    method: widget.paymentMethod,
                    status: widget.paymentStatus,
                  ),
                  SizedBox(height: 16 * u),
                  _AgreementRow(
                    unit: u,
                    agreed: _agreed,
                    onOpenTerms: _openTerms,
                  ),
                  SizedBox(height: 16 * u),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _respond(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDD5428),
                            side: BorderSide(
                              color: const Color(0xFFDD5428),
                              width: 1.2 * u,
                            ),
                            minimumSize: Size.fromHeight(48 * u),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28 * u),
                            ),
                          ),
                          child: Text(
                            'Decline',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15 * u,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12 * u),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _agreed ? () => _respond(true) : null,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFFDD5428),
                            disabledBackgroundColor: const Color(0xFFE4E4E7),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: const Color(0xFFA1A1AA),
                            minimumSize: Size.fromHeight(48 * u),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28 * u),
                            ),
                          ),
                          child: Text(
                            'Share Details',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15 * u,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Shows the popup. `true` = Share Details, `false` = Decline, `null` = closed.
Future<bool?> showBankDetailsRequestPopup(
  BuildContext context, {
  String? requesterName,
  String? feeType,
  double? amount,
  String? paymentPurpose,
  String? paymentMethod,
  String? paymentStatus,
  String? requestReference,
  String? notificationId,
}) {
  return showDialog<bool>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (dialogContext) => BankDetailsRequestPopup(
      requesterName: requesterName,
      feeType: feeType,
      amount: amount,
      paymentPurpose: paymentPurpose,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      requestReference: requestReference,
      notificationId: notificationId,
      onDecline: () => Navigator.of(dialogContext).pop(false),
      onShareDetails: () => Navigator.of(dialogContext).pop(true),
    ),
  );
}

class _RequestSentence extends StatelessWidget {
  const _RequestSentence({
    required this.unit,
    required this.name,
    required this.feeType,
  });

  final double unit;
  final String name;
  final String? feeType;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    final body = GoogleFonts.plusJakartaSans(
      fontSize: 14 * u,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: const Color(0xFF27272A),
    );
    // Name sits one weight step under a bold title (w700 -> w600).
    final nameStyle = body.copyWith(fontWeight: FontWeight.w600);
    final feeStyle = body.copyWith(color: const Color(0xFFDD5428));
    final lead = name.isEmpty
        ? 'Your bank details were requested'
        : '';
    return Text.rich(
      TextSpan(
        style: body,
        children: [
          if (name.isNotEmpty) TextSpan(text: name, style: nameStyle),
          if (name.isNotEmpty)
            const TextSpan(text: ' has requested your bank details'),
          if (name.isEmpty) TextSpan(text: lead),
          if (feeType != null) ...[
            const TextSpan(text: ' to transfer '),
            TextSpan(text: feeType, style: feeStyle),
          ],
          const TextSpan(text: ' to you.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _NoticeBox extends StatelessWidget {
  const _NoticeBox();

  @override
  Widget build(BuildContext context) {
    final u = educationTutorUnit(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10 * u),
      decoration: BoxDecoration(
        color: const Color(0x0F17AE67),
        borderRadius: BorderRadius.circular(6 * u),
        border: Border.all(color: const Color(0xFF17AE67), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 16 * u,
            color: const Color(0xFF17AE67),
          ),
          SizedBox(width: 10 * u),
          Expanded(
            child: Text(
              'Your complete bank account number and IFSC code will be shared with the requester. Your details will be masked.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11 * u,
                fontWeight: FontWeight.w500,
                height: 1.35,
                color: const Color(0xFF3F3F46),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentBox extends StatelessWidget {
  const _PaymentBox({
    required this.unit,
    this.amount,
    this.purpose,
    this.method,
    this.status,
  });

  final double unit;
  final String? amount;
  final String? purpose;
  final String? method;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    final rows = <Widget>[];
    void add(String label, String? value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) return;
      if (rows.isNotEmpty) rows.add(SizedBox(height: 14 * u));
      rows.add(_row(u, label, text));
    }

    add('Requested Payment Amount', amount);
    add('Payment Purpose', purpose);
    add('Payment Method', method);
    add('Payment Status', status);
    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16 * u, vertical: 16 * u),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12 * u),
        gradient: const LinearGradient(
          begin: Alignment(-1, -0.08),
          end: Alignment(1, 0.08),
          colors: [Color(0xFFF8F8F8), Color(0xFFF5F5F5)],
        ),
      ),
      child: Column(children: rows),
    );
  }

  Widget _row(double u, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13 * u,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF71717A),
            ),
          ),
        ),
        SizedBox(width: 8 * u),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13 * u,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF18181B),
            ),
          ),
        ),
      ],
    );
  }
}

class _AgreementRow extends StatelessWidget {
  const _AgreementRow({
    required this.unit,
    required this.agreed,
    required this.onOpenTerms,
  });

  final double unit;
  final bool agreed;
  final VoidCallback onOpenTerms;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    return GestureDetector(
      key: const ValueKey('bank-details-agreement'),
      onTap: onOpenTerms,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          agreed
              ? Container(
                  key: const ValueKey('bank-details-checkbox-checked'),
                  width: 20 * u,
                  height: 20 * u,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDD5428),
                    borderRadius: BorderRadius.circular(4 * u),
                  ),
                  child: Icon(Icons.check, size: 14 * u, color: Colors.white),
                )
              : SvgPicture.asset(
                  FileConstants.bankDetailsCheckboxSvg,
                  key: const ValueKey('bank-details-checkbox'),
                  width: 20 * u,
                  height: 20 * u,
                ),
          SizedBox(width: 8 * u),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'I agree ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13 * u,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF18181B),
                  ),
                ),
                Text(
                  'Terms & conditions',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13 * u,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFDD5428),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherDisc extends StatelessWidget {
  const _TeacherDisc({required this.unit});

  final double unit;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    const svgCircleOrigin = Offset(29, 6);
    const svgCircleSize = 138.0;
    final disc = 76 * u;
    final scale = disc / svgCircleSize;
    return Container(
      width: disc,
      height: disc,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0x14000000),
            blurRadius: 12 * u,
            offset: Offset(0, 4 * u),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: -svgCircleOrigin.dx * scale,
            top: -svgCircleOrigin.dy * scale,
            width: 196 * scale,
            height: 244 * scale,
            child: SvgPicture.asset(
              FileConstants.tuitionFeeHeroSvg,
              width: 196 * scale,
              height: 244 * scale,
              fit: BoxFit.fill,
            ),
          ),
        ],
      ),
    );
  }
}
