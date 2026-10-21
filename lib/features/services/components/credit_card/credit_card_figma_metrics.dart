import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Credit Card module (440×956 Figma) → dp via [MediaQuery.sizeOf].
/// No ScreenUtil `.w`/`.h` on top of these values (avoids double scaling).
abstract final class CreditCardFigmaMetrics {
  static const double frameWidth = 440;
  static const double frameHeight = 956;

  /// Width-based scale (horizontal layout, radii, font sizes).
  static double scaleOf(BuildContext context) =>
      (MediaQuery.sizeOf(context).width / frameWidth).clamp(0.72, 1.12);

  /// Height-based scale (vertical spacing and heights).
  static double heightScaleOf(BuildContext context) =>
      (MediaQuery.sizeOf(context).height / frameHeight).clamp(0.72, 1.12);

  static double s(BuildContext context, double figmaPx) =>
      figmaPx * scaleOf(context);

  /// Vertical Figma px — always use for heights and vertical gaps.
  static double sy(BuildContext context, double figmaPx) =>
      figmaPx * heightScaleOf(context);

  static EdgeInsets screenPadding(BuildContext context) => EdgeInsets.fromLTRB(
        s(context, 20),
        sy(context, 16),
        s(context, 20),
        sy(context, 16),
      );

  static EdgeInsets bottomBarPadding(
          BuildContext context, double bottomInset) =>
      EdgeInsets.fromLTRB(
        s(context, 20),
        0,
        s(context, 20),
        sy(context, 16) + bottomInset,
      );

  /// Figma primary CTA height (Proceed / Add New Card).
  static double primaryButtonHeight(BuildContext context) => sy(context, 56);

  /// Figma 16px label − 2px product tweak.
  static double primaryButtonFontSize(BuildContext context) => s(context, 14);

  static TextStyle primaryButtonLabelStyle(
    BuildContext context, {
    Color color = Colors.white,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
        fontSize: primaryButtonFontSize(context),
        height: 1,
        color: color,
      );

  // ── Provider row (RBL Credit Card + Change) ──

  static double providerCardRadius(BuildContext context) => s(context, 16);

  static EdgeInsets providerCardPadding(BuildContext context) =>
      EdgeInsets.symmetric(
        horizontal: s(context, 16),
        vertical: sy(context, 14),
      );

  /// Figma bank logo frame: 50×50, rx 19.5, 30×30 logo inset 10, stroke #E2E2E2.
  static double providerLogoBox(BuildContext context) => s(context, 50);

  static double providerLogoRadius(BuildContext context) => s(context, 19.5);

  static double providerLogoInnerPad(BuildContext context) => s(context, 10);

  static double providerLogoBorderWidth(BuildContext context) =>
      s(context, 0.5).clamp(0.5, 1.5);

  static const Color providerLogoBorderColor = Color(0xFFE2E2E2);

  static double providerTitleFontSize(BuildContext context) => s(context, 15);

  static double providerGapAfterLogo(BuildContext context) => s(context, 12);

  static double providerGapBeforeChange(BuildContext context) => s(context, 10);

  static double changeButtonHeight(BuildContext context) => sy(context, 30);

  static double changeButtonFontSize(BuildContext context) => s(context, 11);

  static double changeButtonMinWidth(BuildContext context) => s(context, 76);

  static double changeButtonHorizontalPad(BuildContext context) =>
      s(context, 16);

  static double changeButtonRadius(BuildContext context) => s(context, 20);

  /// Figma Pay Now pill (79×29, rx 14.5, #DD5428).
  static double payNowButtonWidth(BuildContext context) => s(context, 79);

  static double payNowButtonHeight(BuildContext context) => sy(context, 29);

  static double payNowButtonRadius(BuildContext context) => s(context, 14.5);

  static const Color payNowButtonColor = Color(0xFFDD5428);

  static Size payNowButtonSize(BuildContext context) => Size(
        payNowButtonWidth(context),
        payNowButtonHeight(context),
      );

  static TextStyle providerTitleStyle(BuildContext context) =>
      GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
        fontSize: providerTitleFontSize(context),
        height: 1.15,
        color: const Color(0xFF000000),
      );

  static TextStyle changeButtonLabelStyle(BuildContext context) =>
      GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
        fontSize: changeButtonFontSize(context),
        height: 1,
        color: Colors.white,
      );

  static TextStyle payNowButtonLabelStyle(BuildContext context) =>
      GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
        fontSize: s(context, 11),
        height: 1,
        letterSpacing: 0,
        color: Colors.white,
      );

  // ── My Cards list tile (full width; same language as Recent carousel) ──

  static double myCardRadius(BuildContext context) => s(context, 12);

  static double myCardListGap(BuildContext context) => sy(context, 14);

  static double myCardAfterBannerGap(BuildContext context) => sy(context, 14);

  static EdgeInsets myCardHeaderPadding(BuildContext context) =>
      EdgeInsets.fromLTRB(s(context, 14), sy(context, 12), s(context, 8), sy(context, 12));

  static EdgeInsets myCardBillPadding(BuildContext context) =>
      EdgeInsets.fromLTRB(s(context, 14), sy(context, 12), s(context, 12), sy(context, 12));

  /// Figma operator mark: 41×41, rx 12.25, 0.5 stroke #E2E2E2.
  static double myCardLogoSize(BuildContext context) => s(context, 41);

  static double myCardLogoRadius(BuildContext context) => s(context, 12.25);

  static double myCardLogoIconSize(BuildContext context) => s(context, 29);

  static double myCardTitleSize(BuildContext context) => s(context, 14);

  static double myCardMaskedSize(BuildContext context) => s(context, 12);

  static double myCardAmountSize(BuildContext context) => s(context, 16);

  static double myCardDueSize(BuildContext context) => s(context, 12);

  static double myCardMenuIconSize(BuildContext context) => s(context, 20);

  static double myCardMenuTapTarget(BuildContext context) => s(context, 32);

  static double myCardShadowBlur(BuildContext context) => s(context, 8);

  static double myCardShadowOffsetY(BuildContext context) => sy(context, 2);

  static double myCardsBannerHeightForWidth(BuildContext context, double width) =>
      (width * 120 / 360).clamp(sy(context, 88), sy(context, 140));

  static TextStyle myCardTitleStyle(BuildContext context) =>
      GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        fontSize: myCardTitleSize(context),
        color: const Color(0xFF3A1D12),
        height: 1.2,
      );

  static TextStyle myCardMaskedStyle(BuildContext context) =>
      GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w500,
        fontSize: myCardMaskedSize(context),
        color: const Color(0xFF71717A),
        height: 1.2,
      );

  static TextStyle myCardAmountStyle(BuildContext context) =>
      GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        fontSize: myCardAmountSize(context),
        color: const Color(0xFF3A1D12),
        height: 1.15,
      );

  static TextStyle myCardDueStyle(BuildContext context, {required bool isDue}) =>
      GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
        fontSize: myCardDueSize(context),
        color: isDue ? const Color(0xFFDB0101) : const Color(0xFFDD5428),
        height: 1.2,
      );
}
