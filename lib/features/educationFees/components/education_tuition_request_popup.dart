import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../constants/file_constants.dart';
import '../../../widgets/custom_elevated_button.dart';
import 'education_tutor_identity.dart';

/// Visual states of the shared Tuition Fee Request popup.
///
/// * [request]   — avatar header variant (initials + verified badge).
/// * [received]  — teacher-illustration header variant.
/// * [accepted]  — green success circle + Done.
/// * [declined]  — dark-red cross circle + Done.
enum EducationTuitionPopupState { request, received, accepted, declined }

/// Reusable Tuition Fee Request popup, shared by the verified and the
/// unverified tutor flows. Accept/Decline currently just close the popup —
/// the real routing is wired in later.
class EducationTuitionRequestPopup extends StatelessWidget {
  const EducationTuitionRequestPopup({
    super.key,
    required this.state,
    required this.amount,
    this.requesterName,
    this.onAccept,
    this.onDecline,
  });

  final EducationTuitionPopupState state;

  /// Plain amount in rupees; rendered with the shared en_IN currency format.
  final double amount;

  /// Who raised the request ("Requested By ..."). Hidden when empty.
  final String? requesterName;

  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  bool get _isResult =>
      state == EducationTuitionPopupState.accepted ||
      state == EducationTuitionPopupState.declined;

  bool get _accepted => state == EducationTuitionPopupState.accepted;

  String get _amountLabel => NumberFormat.currency(
        locale: 'en_IN',
        symbol: '\u20B9',
        decimalDigits: 0,
      ).format(amount);

  String get _requester => requesterName?.trim() ?? '';

  @override
  Widget build(BuildContext context) {
    final u = educationTutorUnit(context);
    // Keep the card inside the usable viewport: horizontal margins scale with
    // the screen, vertical margins respect notches/gesture bars (safe areas)
    // and fall back to the Material 40px default when there is no inset.
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final verticalInset =
        math.max(40 * u, math.max(viewPadding.top, viewPadding.bottom) + 8 * u);
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(
        horizontal: 20 * u,
        vertical: verticalInset,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24 * u),
      ),
      child: SingleChildScrollView(
        // Top gap above the close (X) icon kept equal to the Done-button
        // bottom gap (24) so the header is not cramped against the card edge.
        padding: EdgeInsets.fromLTRB(20 * u, 24 * u, 20 * u, 24 * u),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: _CloseButton(
                unit: u,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            ...(_isResult ? _resultBody(context, u) : _requestBody(context, u)),
          ],
        ),
      ),
    );
  }

  /// Image-2/image-3 body: header art, amount, details card, action row.
  List<Widget> _requestBody(BuildContext context, double u) {
    final isAvatar = state == EducationTuitionPopupState.request;
    return [
      if (isAvatar)
        _AvatarHeader(unit: u, name: _requester)
      else
        _IllustrationHeader(unit: u),
      SizedBox(height: 12 * u),
      Text(
        isAvatar ? 'Tuition Fee Amount' : 'Tuition Fee Request',
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 17 * u,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      if (!isAvatar) ...[
        SizedBox(height: 6 * u),
        Text(
          'You have received a new payment request',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13 * u,
            fontWeight: FontWeight.w400,
            // zinc-800 per Figma.
            color: const Color(0xFF27272A),
          ),
        ),
      ],
      SizedBox(height: 8 * u),
      Text(
        _amountLabel,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 26 * u,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
      // Static "Pending" status badge (SVG) — becomes status-aware later.
      SizedBox(height: 10 * u),
      SvgPicture.asset(
        FileConstants.tuitionPendingBadgeSvg,
        width: 60 * u,
        height: 21 * u,
      ),
      if (_requester.isNotEmpty) ...[
        SizedBox(height: 12 * u),
        Text(
          'Requested By $_requester',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14 * u,
            fontWeight: FontWeight.w500,
            // zinc-950 per Figma.
            color: const Color(0xFF09090B),
          ),
        ),
      ],
      SizedBox(height: 10 * u),
      Text(
        'Please review the details before accepting this request.',
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13 * u,
          fontWeight: FontWeight.w400,
          // zinc-700 per Figma.
          color: const Color(0xFF3F3F46),
        ),
      ),
      SizedBox(height: 16 * u),
      // Separator above the details card (zinc-100, 1px per Figma).
      Container(
        height: 1,
        width: double.infinity,
        color: const Color(0xFFF4F4F5),
      ),
      SizedBox(height: 16 * u),
      _DetailsCard(unit: u),
      SizedBox(height: 20 * u),
      Row(
        children: [
          Expanded(
            child: _OutlineButton(
              unit: u,
              label: 'Decline',
              // TODO(routing): wire to the decline-request API later.
              onPressed: onDecline ?? () => Navigator.of(context).pop(),
            ),
          ),
          SizedBox(width: 12 * u),
          Expanded(
            child: CustomElevatedButton(
              // TODO(routing): wire to the accept-request API later.
              onPressed: onAccept ?? () => Navigator.of(context).pop(),
              label: 'Accept Request',
              showArrow: false,
              uppercaseLabel: false,
              height: 48 * u,
              labelStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 15 * u,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ];
  }

  /// Image-4/image-5 body: status icon, copy, amount pill, Done.
  List<Widget> _resultBody(BuildContext context, double u) {
    return [
      SvgPicture.asset(
        _accepted
            ? FileConstants.successCheckmarkIconSvg
            : FileConstants.errorCrossIconSvg,
        width: 88 * u,
        height: 88 * u,
      ),
      SizedBox(height: 18 * u),
      Text(
        _accepted ? 'Request Accepted Successfully' : 'Request Declined',
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18 * u,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      SizedBox(height: 8 * u),
      Text(
        _accepted
            ? 'You have accepted the tuition fee payment request from $_requester.'
            : 'You have declined the tuition fee payment request from $_requester.',
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13 * u,
          fontWeight: FontWeight.w400,
          height: 1.4,
          // zinc-800 per Figma.
          color: const Color(0xFF27272A),
        ),
      ),
      SizedBox(height: 14 * u),
      Text(
        _amountLabel,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 26 * u,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      SizedBox(height: 10 * u),
      _Pill(
        unit: u,
        text: _accepted ? 'Request Accepted' : 'Request Declined',
        background:
            _accepted ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        foreground:
            _accepted ? const Color(0xFF16A34A) : const Color(0xFF870002),
      ),
      SizedBox(height: 16 * u),
      Text(
        _accepted
            ? 'You can now proceed with the next step.\nContinue'
            : '$_requester will be notified about your decision.',
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13 * u,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: const Color(0xFF71717A),
        ),
      ),
      SizedBox(height: 22 * u),
      SizedBox(
        width: double.infinity,
        child: CustomElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          label: 'Done',
          showArrow: false,
          uppercaseLabel: false,
          height: 48 * u,
        ),
      ),
    ];
  }
}

/// Shows the shared popup; returns true on Accept, false on Decline and
/// null when dismissed via the close button or the barrier.
Future<bool?> showEducationTuitionRequestPopup(
  BuildContext context, {
  required EducationTuitionPopupState state,
  required double amount,
  String? requesterName,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => EducationTuitionRequestPopup(
      state: state,
      amount: amount,
      requesterName: requesterName,
      onAccept: () => Navigator.of(dialogContext).pop(true),
      onDecline: () => Navigator.of(dialogContext).pop(false),
    ),
  );
}

/// Gradient circular close (X) button at the popup's top-right corner.
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.unit, required this.onTap});

  final double unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    return GestureDetector(
      key: const ValueKey('tuitionPopupClose'),
      onTap: onTap,
      child: SvgPicture.asset(
        FileConstants.tuitionPopupCloseSvg,
        width: 32 * u,
        height: 32 * u,
      ),
    );
  }
}

/// Circular avatar with initials and the green verified badge, same look as
/// the tutor identity card.
class _AvatarHeader extends StatelessWidget {
  const _AvatarHeader({required this.unit, required this.name});

  final double unit;
  final String name;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        SvgPicture.asset(
          FileConstants.tutorProfileAvatarSvg,
          width: 88 * u,
          height: 88 * u,
        ),
        Text(
          educationTutorInitials(name),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24 * u,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

/// Circular teacher-illustration header (image 3).
class _IllustrationHeader extends StatelessWidget {
  const _IllustrationHeader({required this.unit});

  final double unit;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    // The hero asset packs the teacher into a 138px white circle sitting at the
    // top of a 196x244 canvas. Rendering it with `contain` shrinks that circle
    // and shifts it up, and because it is white-on-white it vanishes against the
    // dialog. Crop to the circle so the teacher fills a defined disc, and give
    // the disc its own soft shadow so the card reads (matches Figma).
    const svgCircleOrigin = Offset(29, 6); // circle rect origin inside the SVG
    const svgCircleSize = 138.0; // circle diameter inside the SVG
    final disc = 96 * u;
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
            blurRadius: 20 * u,
            offset: Offset(0, 8 * u),
          ),
        ],
      ),
      child: ClipOval(
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
      ),
    );
  }
}

/// Payment Purpose / Method / Status rows on the gray card.
/// Placeholder values until the request-details API provides real ones.
class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.unit});

  final double unit;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16 * u, vertical: 6 * u),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(14 * u),
      ),
      child: Column(
        children: [
          _detailRow(u, 'Payment Purpose', 'Tuition Fees'),
          SizedBox(height: 14 * u),
          _detailRow(u, 'Payment Method', 'Credit Card'),
          SizedBox(height: 14 * u),
          _detailRow(u, 'Request Status', 'Awaiting Your Approval'),
          SizedBox(height: 6 * u),
        ],
      ),
    );
  }

  Widget _detailRow(double u, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Flexible (not fixed) so the pair wraps instead of overflowing on
        // narrow viewports; identical single-line look at normal sizes.
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13 * u,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF71717A),
            ),
          ),
        ),
        SizedBox(width: 12 * u),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13 * u,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

/// Small rounded status pill (Pending / Request Accepted / Request Declined).
class _Pill extends StatelessWidget {
  const _Pill({
    required this.unit,
    required this.text,
    required this.background,
    required this.foreground,
  });

  final double unit;
  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14 * u, vertical: 5 * u),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20 * u),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12 * u,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}

/// Orange outlined pill button (Decline), matching the request-screen Cancel.
class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.unit,
    required this.label,
    required this.onPressed,
  });

  final double unit;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFDD5428),
        side: const BorderSide(color: Color(0xFFDD5428)),
        padding: EdgeInsets.symmetric(vertical: 13 * u),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26 * u),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          fontSize: 15 * u,
        ),
      ),
    );
  }
}
