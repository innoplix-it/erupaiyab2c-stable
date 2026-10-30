import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/file_constants.dart';

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
  });

  final String text;
  final Color color;
  final FontWeight weight;
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
    this.verified = true,
  });

  final double unit;
  final String name;
  final String accountLine;
  final String amountLabel;
  final List<EducationTutorStatusLine> statusLines;

  /// Drives the avatar corner tick: green check when verified, gold when not.
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final u = unit;
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
              // The masked account is API data (`account_masked`); it is never
              // derived from the mobile number, so an empty value hides the row.
              if (accountLine.trim().isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      FileConstants.homeBank,
                      width: 18 * u,
                      height: 18 * u,
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
              SizedBox(height: 14 * u),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 18 * u,
                  vertical: 8 * u,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(24 * u),
                ),
                child: Text(
                  amountLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18 * u,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 16 * u),
              for (final line in statusLines) ...[
                Text(
                  line.text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12 * u,
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
