import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';

// ---------------------------------------------------------------------------
// Bank Account tab UI (Figma: empty state + saved account)
//
// Data-agnostic: plain strings + callbacks, so both the Personal Details
// "Bank Account" tab (profile_view.dart) and BankAccountsSection
// (bank_accounts_view.dart) render the exact same Figma look.
//
// Sizes are percentages of the screen (Figma frame 390 x 844):
//   width %  = figmaValue / 390 * 100
//   height % = figmaValue / 844 * 100
// ---------------------------------------------------------------------------

extension _BankUiContext on BuildContext {
  double wp(double percent) => MediaQuery.sizeOf(this).width * percent / 100;
  double hp(double percent) => MediaQuery.sizeOf(this).height * percent / 100;
}

const Color _kTextDark = Color(0xFF1C1C1E);
const Color _kCardBorder = Color(0xFFE4E4E4);
const Color _kDanger = Color(0xFFB20003);

/// Bank tile avatar when the backend sends no logo (Figma: solid blue
/// circle with a white building glyph).
const Color _kLogoFallbackBg = Color(0xFF1A56A1);

TextStyle _ts(
  double size,
  FontWeight weight,
  Color color, {
  double? height,
}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: size.sp,
    fontWeight: weight,
    color: color,
    height: height,
  );
}

/// Small pill button used inside the bank cards (filled or outlined).
class _BankPillButton extends StatelessWidget {
  const _BankPillButton({
    required this.label,
    required this.onTap,
    this.color = AppColors.primary,
    this.outlined = false,
    this.height,
    this.fontSize = 14,
  });

  final String label;
  final VoidCallback? onTap;
  final Color color;
  final bool outlined;
  final double? height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(context.wp(100));
    return Material(
      color: outlined ? Colors.white : color,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: outlined ? BorderSide(color: color, width: 1.2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: SizedBox(
          height: height ?? context.hp(5.21),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              style: _ts(
                fontSize,
                FontWeight.w500,
                outlined ? color : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty state: bank illustration, title, subtitle and "+ Add Bank Account".
class BankEmptyState extends StatelessWidget {
  const BankEmptyState({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    // Asset is 104 x 100 — keep the ratio, only scale the width.
    final illustrationWidth = context.wp(22);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.wp(8)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              FileConstants.bankEmptyStateSvg,
              width: illustrationWidth,
              height: illustrationWidth * 100 / 104,
              fit: BoxFit.contain,
            ),
            SizedBox(height: context.hp(2.4)),
            Text(
              'Add Bank Account',
              textAlign: TextAlign.center,
              style: _ts(18, FontWeight.w600, const Color(0xFF09090B)),
            ),
            SizedBox(height: context.hp(0.9)),
            Text(
              'Link your bank account to manage\nsettlements securely',
              textAlign: TextAlign.center,
              style: _ts(13, FontWeight.w400, const Color(0xFF71717A), height: 1.5),
            ),
            SizedBox(height: context.hp(2.9)),
            SizedBox(
              width: context.wp(52),
              child: _BankPillButton(
                label: '+ Add Bank Account',
                onTap: onAdd,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Saved account: summary card (logo / name / masked no. / View) and a
/// details card (Bank Name, Holder, IFSC, Branch + Delete / Change).
///
/// The details card only appears once the user taps View ([showDetails]).
class BankAccountCard extends StatelessWidget {
  const BankAccountCard({
    super.key,
    required this.bankName,
    required this.maskedAccount,
    required this.holderName,
    required this.ifsc,
    required this.branch,
    this.logo,
    this.showDetails = true,
    this.onView,
    this.onDelete,
    this.onChange,
  });

  final String bankName;
  final String maskedAccount;
  final String holderName;
  final String ifsc;
  final String branch;
  final Widget? logo;
  final bool showDetails;
  final VoidCallback? onView;
  final VoidCallback? onDelete;
  final VoidCallback? onChange;

  Widget _detail(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.hp(1.9)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: _ts(12, FontWeight.w400, const Color(0xFF52525B)),
          ),
          SizedBox(height: context.hp(0.3)),
          Text(
            value.trim().isEmpty ? '--' : value.trim(),
            style: _ts(14, FontWeight.w500, const Color(0xFF18181B)),
          ),
        ],
      ),
    );
  }

  // Figma: 1px solid #E4E4E4 hairline around both cards.
  BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(context.wp(3.08)),
    border: Border.all(color: _kCardBorder, width: 1),
  );

  @override
  Widget build(BuildContext context) {
    final logoSize = context.wp(9.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- Summary card ----
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: context.wp(3.59),
            vertical: context.hp(1.5),
          ),
          decoration: _cardDecoration(context),
          child: Row(
            // Logo / text block / View pill share one centred row.
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipOval(
                child: SizedBox(
                  width: logoSize,
                  height: logoSize,
                  child: logo ??
                      Container(
                        color: _kLogoFallbackBg,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.account_balance,
                          size: logoSize * 0.5,
                          color: Colors.white,
                        ),
                      ),
                ),
              ),
              SizedBox(width: context.wp(3.08)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bankName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _ts(14, FontWeight.w600, _kTextDark),
                    ),
                    SizedBox(height: context.hp(0.3)),
                    Text(
                      maskedAccount,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _ts(13, FontWeight.w400, const Color(0xFF3F3F46)),
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.wp(2.05)),
              SizedBox(
                width: context.wp(21),
                child: _BankPillButton(
                  label: 'View',
                  height: context.hp(3.9),
                  fontSize: 13,
                  onTap: onView,
                ),
              ),
            ],
          ),
        ),
        // ---- Details card ---- (revealed by the View pill)
        if (showDetails) ...[
          SizedBox(height: context.hp(1.9)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              context.wp(4.1),
              context.hp(2.1),
              context.wp(4.1),
              context.hp(1.9),
            ),
            decoration: _cardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detail(context, 'Bank Name', bankName),
                _detail(context, 'Account Holder Name', holderName),
                _detail(context, 'IFSC Code', ifsc),
                _detail(context, 'Branch', branch),
                SizedBox(height: context.hp(0.4)),
                Row(
                  children: [
                    Expanded(
                      child: _BankPillButton(
                        label: 'Delete',
                        color: _kDanger,
                        outlined: true,
                        onTap: onDelete,
                      ),
                    ),
                    SizedBox(width: context.wp(3.08)),
                    Expanded(
                      child: _BankPillButton(label: 'Change', onTap: onChange),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
