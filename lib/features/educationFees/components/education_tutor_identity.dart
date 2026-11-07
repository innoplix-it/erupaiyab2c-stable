import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/file_constants.dart';
import '../../../widgets/app_network_image.dart';

/// Shared sizing unit for the tutor screens (Figma frame is 448 wide).
const double kEducationTutorFigmaW = 448.0;
const double kEducationTutorMaxContentW = 560.0;

double educationTutorUnit(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  return w.clamp(320.0, kEducationTutorMaxContentW) / kEducationTutorFigmaW;
}

const LinearGradient kEducationTutorBackgroundGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFB5FFDA), Color(0xFFFFFFFF)],
  stops: [0.0, 0.6631],
);

String educationTutorInitials(String name) {
  final parts =
  name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final word = parts.first;
    return word.length >= 2
        ? word.substring(0, 2).toUpperCase()
        : word.toUpperCase();
  }
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

/// One caption line under the amount pill on the tutor cards.
class EducationTutorStatusLine {
  const EducationTutorStatusLine({
    required this.text,
    required this.color,
    this.weight = FontWeight.w400,
    this.fontSize,
  });

  final String text;
  final Color color;
  final FontWeight weight;
  final double? fontSize;
}

/// White identity card (avatar, name, masked account, amount, status lines)
/// with the "Tutor" badge on its top-left corner.
///
/// Shared by the tutor request screen and the tutor profile screen so both
/// stay pixel-identical.
class EducationTutorIdentityCard extends StatelessWidget {
  const EducationTutorIdentityCard({
    super.key,
    required this.unit,
    required this.name,
    required this.accountLine,
    required this.amountLabel,
    required this.statusLines,
    this.statusAboveAmount,
    this.highlightAmount = false,
    this.verified = true,
    this.bankLogoUrl,
  });

  final double unit;
  final String name;
  final String accountLine;
  final String amountLabel;
  final List<EducationTutorStatusLine> statusLines;

  /// Short status shown between the name and the rupee amount
  /// (e.g. "KYC Not Completed", "Not registered").
  final String? statusAboveAmount;

  /// Orange amount pill: `#DD5428` at 10% background, `#DD5428` text.
  final bool highlightAmount;

  /// Drives the avatar corner tick: green check when verified, gold when not.
  final bool verified;

  /// Backend `bank_logo` URL for the account row. When null or empty the
  /// shared generic bank glyph is kept, so no branding is ever invented.
  final String? bankLogoUrl;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    final logo = bankLogoUrl?.trim() ?? '';
    // Existing generic bank glyph, reused as the placeholder and error state.
    final genericBankGlyph = Image.asset(
      FileConstants.homeBank,
      width: 18 * u,
      height: 18 * u,
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(16 * u, 28 * u, 16 * u, 20 * u),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16 * u),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18 * u,
                offset: Offset(0, 6 * u),
              ),
            ],
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Gradient circular avatar with the verified badge baked in
                  // (replaces the flat peach circle + separate badge).
                  SvgPicture.asset(
                    verified
                        ? FileConstants.tutorProfileAvatarSvg
                        : FileConstants.tutorProfileAvatarUnverifiedSvg,
                    width: 72 * u,
                    height: 72 * u,
                  ),
                  Text(
                    educationTutorInitials(name),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22 * u,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12 * u),
              Text(
                name,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16 * u,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8 * u),
              // The account row is API data (`account_number` as returned, or
              // `account_masked` on saved tutors); it is never derived from the
              // mobile number, so an empty value hides the row.
              if (accountLine.trim().isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    logo.isEmpty
                        ? genericBankGlyph
                        : AppNetworkImage(
                      url: logo,
                      width: 18 * u,
                      height: 18 * u,
                      fit: BoxFit.contain,
                      showShimmer: false,
                      placeholder: genericBankGlyph,
                      errorWidget: genericBankGlyph,
                    ),
                    SizedBox(width: 6 * u),
                    Text(
                      accountLine,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13 * u,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF71717A),
                      ),
                    ),
                  ],
                ),
              ],
              if ((statusAboveAmount ?? '').trim().isNotEmpty) ...[
                SizedBox(height: 6 * u),
                Text(
                  statusAboveAmount!.trim(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14 * u,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                    color: const Color(0xFFA3A3A3),
                  ),
                ),
                SizedBox(height: 10 * u),
              ] else
                SizedBox(height: 14 * u),
              // Amount pill hugs its content (IntrinsicWidth) instead of
              // stretching to the full card width. Hidden when empty.
              if (amountLabel.trim().isNotEmpty) ...[
                IntrinsicWidth(
                  child: Container(
                    height: highlightAmount ? 32 * u : null,
                    padding: EdgeInsets.symmetric(
                      horizontal: highlightAmount ? 16 * u : 18 * u,
                      vertical: highlightAmount ? 0 : 8 * u,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: highlightAmount
                          ? const Color(0xFFDD5428).withValues(alpha: 0.1)
                          : const Color(0xFFF4F4F5),
                      borderRadius: BorderRadius.circular(
                        highlightAmount ? 16 * u : 24 * u,
                      ),
                    ),
                    child: Text(
                      amountLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: highlightAmount ? 14 * u : 18 * u,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        color: highlightAmount
                            ? const Color(0xFFDD5428)
                            : Colors.black,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16 * u),
              ],
              for (final line in statusLines) ...[
                Text(
                  line.text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: line.fontSize ?? 12 * u,
                    fontWeight: line.weight,
                    height: 1.35,
                    color: line.color,
                  ),
                ),
                SizedBox(height: 6 * u),
              ],
            ],
          ),
        ),
        // Measured from Figma: badge left edge is flush with the card edge
        // (inset 0) and its top sits 17px below the card's top edge.
        Positioned(
          top: 17 * u,
          left: 0,
          child: SvgPicture.asset(
            FileConstants.tutorRequestBadgeSvg,
            width: 55 * u,
            height: 26 * u,
          ),
        ),
      ],
    );
  }
}

/// Label / value pair used by the bank-details grid.
/// [alignRight] keeps the right column flush against the card edge.
class EducationTutorDetailCell extends StatelessWidget {
  const EducationTutorDetailCell({
    super.key,
    required this.unit,
    required this.label,
    required this.value,
    this.alignRight = false,
  });

  final double unit;
  final String label;
  final String value;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    return Column(
      crossAxisAlignment:
      alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12 * u,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF71717A),
          ),
        ),
        SizedBox(height: 4 * u),
        Text(
          value,
          textAlign: alignRight ? TextAlign.end : TextAlign.start,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14 * u,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}