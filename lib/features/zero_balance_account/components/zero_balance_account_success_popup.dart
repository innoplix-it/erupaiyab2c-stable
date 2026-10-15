// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../home/components/zero_balance_account_popup_view.dart';
import '../models/zero_balance_bank.dart';

enum ZeroBalanceSuccessAction { done, viewBalance, close }

/// Shows the account-opened Congratulations popup. Resolves to the action the
/// user took; a barrier tap counts as [ZeroBalanceSuccessAction.close].
Future<ZeroBalanceSuccessAction> showZeroBalanceAccountSuccessPopup(
  BuildContext context, {
  required ZeroBalanceBank bank,
  required num? rewardAmount,
}) async {
  final result = await showDialog<ZeroBalanceSuccessAction>(
    context: context,
    useSafeArea: false,
    builder: (dialogContext) {
      void finish(ZeroBalanceSuccessAction action) =>
          Navigator.of(dialogContext).pop(action);
      return ZeroBalanceAccountSuccessPopup(
        bank: bank,
        rewardAmount: rewardAmount,
        onDone: () => finish(ZeroBalanceSuccessAction.done),
        onViewBalance: () => finish(ZeroBalanceSuccessAction.viewBalance),
        onClose: () => finish(ZeroBalanceSuccessAction.close),
      );
    },
  );
  return result ?? ZeroBalanceSuccessAction.close;
}

/// Figma reference: 440 px wide frame, 392 x 415 card.
class ZeroBalanceAccountSuccessPopup extends StatelessWidget {
  const ZeroBalanceAccountSuccessPopup({
    super.key,
    required this.bank,
    required this.rewardAmount,
    required this.onDone,
    required this.onViewBalance,
    required this.onClose,
  });

  final ZeroBalanceBank bank;

  /// Reward credited by the account-opening API; null (not yet supplied by
  /// the backend) renders as ₹0.
  final num? rewardAmount;
  final VoidCallback onDone;
  final VoidCallback onViewBalance;
  final VoidCallback onClose;

  static const double _frameWidth = 440;
  static const double _frameHeight = 978;
  static const double _cardWidth = 392;

  /// Keeps the card phone-sized on tablets and unfolded foldables.
  static const double _maxCardWidth = 480;

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final insets = MediaQuery.paddingOf(context);
    return Material(
      type: MaterialType.transparency,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth - insets.horizontal;
          final availableHeight = constraints.maxHeight - insets.vertical;

          final cardWidth = math.min(
            availableWidth * _cardWidth / _frameWidth,
            _maxCardWidth,
          );
          // Horizontal metrics follow the card width; vertical rhythm follows
          // the viewport height so short phones compress the gaps first.
          final kw = cardWidth / _cardWidth;
          final kv = math.min(
            math.max(viewport.height / _frameHeight, 0.55),
            kw * 1.1,
          );

          final closeSize = (40 * kw).clamp(40.0, 48.0);
          final closeGap = 24 * kv;
          final verticalMargin = 12 * kv;
          final cardMaxHeight = math.max(
            0.0,
            availableHeight - 2 * verticalMargin - closeSize - closeGap,
          );

          return Padding(
            padding: insets + EdgeInsets.symmetric(vertical: verticalMargin),
            child: Center(
              child: SizedBox(
                width: cardWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: ZeroBalancePopupCloseButton(
                        size: closeSize,
                        onTap: onClose,
                        tapKey: const ValueKey('zeroBalanceSuccessClose'),
                      ),
                    ),
                    SizedBox(height: closeGap),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: cardMaxHeight),
                      child: _SuccessCard(
                        kw: kw,
                        kv: kv,
                        bankName: bank.name,
                        rewardLabel: formatZeroBalanceReward(rewardAmount ?? 0),
                        onDone: onDone,
                        onViewBalance: onViewBalance,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Figma px (440 frame) -> ScreenUtil font size (360 x 690 design size).
double _figmaSp(double px) => (px * 360 / 440).sp;

TextStyle _jakarta({
  required double size,
  required FontWeight weight,
  required double lineHeightPx,
  Color color = AppColors.black,
  FontStyle fontStyle = FontStyle.normal,
}) {
  final fontSize = _figmaSp(size);
  return GoogleFonts.plusJakartaSans(
    fontSize: fontSize,
    fontWeight: weight,
    fontStyle: fontStyle,
    height: lineHeightPx / size,
    letterSpacing: fontSize * -0.02,
    color: color,
  );
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({
    required this.kw,
    required this.kv,
    required this.bankName,
    required this.rewardLabel,
    required this.onDone,
    required this.onViewBalance,
  });

  final double kw;
  final double kv;
  final String bankName;
  final String rewardLabel;
  final VoidCallback onDone;
  final VoidCallback onViewBalance;

  static const List<BoxShadow> _shadows = [
    BoxShadow(color: Color(0x1AABABAB), offset: Offset(0, -5), blurRadius: 11),
    BoxShadow(color: Color(0x17ABABAB), offset: Offset(0, -20), blurRadius: 20),
    BoxShadow(color: Color(0x0DABABAB), offset: Offset(0, -45), blurRadius: 27),
  ];

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16 * kw);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        boxShadow: _shadows,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                FileConstants.zeroBalancePopupBg,
                fit: BoxFit.cover,
                opacity: kZeroBalanceBgOpacity,
              ),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24 * kw, 57 * kv, 24 * kw, 39 * kv),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    FileConstants.mpinSuccessBadge,
                    key: const ValueKey('zeroBalanceSuccessBadge'),
                    width: 80 * kw,
                    height: 80 * kw,
                  ),
                  SizedBox(height: 18 * kv),
                  Text(
                    'Congratulations!',
                    key: const ValueKey('zeroBalanceSuccessHeading'),
                    textAlign: TextAlign.center,
                    style: _jakarta(
                      size: 24,
                      weight: FontWeight.w700,
                      lineHeightPx: 36,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 8 * kv),
                  ConstrainedBox(
                    // Figma wraps the sentence after the first bank word.
                    constraints: BoxConstraints(maxWidth: 260 * kw),
                    child: Text.rich(
                      key: const ValueKey('zeroBalanceSuccessMessage'),
                      TextSpan(
                        style: _jakarta(
                          size: 14,
                          weight: FontWeight.w500,
                          lineHeightPx: 24,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Your zero balance account with ',
                          ),
                          TextSpan(
                            text: bankName,
                            style: const TextStyle(color: AppColors.primary),
                          ),
                          const TextSpan(text: ' is open.'),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 16 * kv),
                  _RewardPill(rewardLabel: rewardLabel),
                  SizedBox(height: 31 * kv),
                  _SuccessActions(
                    height: (46 * kw).clamp(40.0, 56.0),
                    gap: 10 * kw,
                    onDone: onDone,
                    onViewBalance: onViewBalance,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Figma: 319 x 38 pill (FileConstants.zeroBalanceRewardPillBgSvg) with the
/// sentence drawn on top as live text, 17 px from each edge, so the amount
/// stays backend-driven.
class _RewardPill extends StatelessWidget {
  const _RewardPill({required this.rewardLabel});

  final String rewardLabel;

  static const double _frameWidth = 440;
  static const double _frameHeight = 978;

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final base = _jakarta(size: 14, weight: FontWeight.w400, lineHeightPx: 14);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Never wider than the card's content area (tablets, foldables).
        final width = math.min(
          viewport.width * 319 / _frameWidth,
          constraints.maxWidth,
        );
        return ConstrainedBox(
          key: const ValueKey('zeroBalanceSuccessReward'),
          // Minimum only, so a wrapped message at large text scales grows
          // the pill instead of clipping.
          constraints: BoxConstraints.tightFor(width: width).copyWith(
            minHeight: viewport.height * 38 / _frameHeight,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: SvgPicture.asset(
                  FileConstants.zeroBalanceRewardPillBgSvg,
                  key: const ValueKey('zeroBalanceSuccessRewardBg'),
                  fit: BoxFit.fill,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: (17 * 360 / 440).w,
                  // Only visible when the message wraps; a single line sits
                  // inside the 38 px minimum height.
                  vertical: viewport.height * 6 / _frameHeight,
                ),
                child: Text.rich(
                  key: const ValueKey('zeroBalanceSuccessRewardText'),
                  TextSpan(
                    style: base,
                    children: [
                      TextSpan(
                        text: rewardLabel,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(
                        text: ' has been added to your eRupaiya wallet',
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SuccessActions extends StatelessWidget {
  const _SuccessActions({
    required this.height,
    required this.gap,
    required this.onDone,
    required this.onViewBalance,
  });

  final double height;
  final double gap;
  final VoidCallback onDone;
  final VoidCallback onViewBalance;

  @override
  Widget build(BuildContext context) {
    final labelStyle = GoogleFonts.plusJakartaSans(
      fontSize: _figmaSp(16),
      fontWeight: FontWeight.w500,
    );
    return Row(
      children: [
        Expanded(
          child: CustomElevatedButton(
            key: const ValueKey('zeroBalanceSuccessDone'),
            onPressed: onDone,
            label: 'Done',
            height: height,
            isBorder: true,
            uppercaseLabel: false,
            backgroundColor: Colors.white,
            borderColor: AppColors.primary,
            labelColor: AppColors.primary,
            labelStyle: labelStyle,
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: CustomElevatedButton(
            key: const ValueKey('zeroBalanceSuccessViewBalance'),
            onPressed: onViewBalance,
            label: 'View Balance',
            height: height,
            uppercaseLabel: false,
            backgroundColor: AppColors.primary,
            labelStyle: labelStyle,
          ),
        ),
      ],
    );
  }
}
