// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/custom_elevated_button.dart';

/// Shows the Zero Balance Account popup over the current route (the Home
/// screen stays mounted underneath). Resolves to true when "Open Account" is
/// tapped; false for "Maybe Later", the close icon or a barrier tap.
Future<bool> showZeroBalanceAccountPopup(
  BuildContext context, {
  required num rewardAmount,
}) async {
  final result = await showDialog<bool>(
    context: context,
    useSafeArea: false,
    builder: (dialogContext) => ZeroBalanceAccountPopupView(
      rewardAmount: rewardAmount,
      onOpenAccount: () => Navigator.of(dialogContext).pop(true),
      onClose: () => Navigator.of(dialogContext).pop(false),
    ),
  );
  return result ?? false;
}

/// GoRouter page for [RouteConstants.zeroBalanceOffer]: a see-through dialog
/// route, so the pushing screen (Home) stays mounted and visible under the
/// dimmed barrier. `extra` carries the reward amount. Pops true for
/// "Open Account"; false (or null on a barrier tap) otherwise.
Page<bool> buildZeroBalanceOfferPage(
  BuildContext context,
  GoRouterState state,
) {
  final extra = state.extra;
  return CustomTransitionPage<bool>(
    key: state.pageKey,
    opaque: false,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: const Duration(milliseconds: 150),
    reverseTransitionDuration: const Duration(milliseconds: 150),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
    child: Builder(
      builder: (pageContext) => ZeroBalanceAccountPopupView(
        rewardAmount: extra is num ? extra : 0,
        onOpenAccount: () => pageContext.pop(true),
        onClose: () => pageContext.pop(false),
      ),
    ),
  );
}

/// Softens `zerobalancebg.png` wherever the Zero Balance flow paints it.
const Animation<double> kZeroBalanceBgOpacity = AlwaysStoppedAnimation(0.75);

bool _zeroBalanceOfferOpen = false;

/// Home "Zero Balance Account" entry: pushes the offer popup route over Home
/// and, on "Open Account", opens Choose Your Bank once the popup has closed.
/// Taps that arrive while the flow is already open are ignored.
Future<void> openZeroBalanceAccountOffer(
  BuildContext context, {
  required num rewardAmount,
}) async {
  if (_zeroBalanceOfferOpen) return;
  _zeroBalanceOfferOpen = true;
  try {
    final openAccount = await context.push<bool>(
      RouteConstants.zeroBalanceOffer,
      extra: rewardAmount,
    );
    if (openAccount != true || !context.mounted) return;
    context.push(RouteConstants.zeroBalanceChooseBank, extra: rewardAmount);
  } finally {
    _zeroBalanceOfferOpen = false;
  }
}

/// "₹100", "₹1,000", "₹49.5" — Indian digit grouping, at most 2 decimals.
String formatZeroBalanceReward(num amount) {
  final format = NumberFormat.decimalPattern('en_IN')
    ..maximumFractionDigits = 2;
  return '₹${format.format(amount)}';
}

/// Figma reference: 440 x 978 frame, 392 x 555 card centred in it.
class ZeroBalanceAccountPopupView extends StatelessWidget {
  const ZeroBalanceAccountPopupView({
    super.key,
    required this.rewardAmount,
    required this.onOpenAccount,
    required this.onClose,
  });

  final num rewardAmount;
  final VoidCallback onOpenAccount;
  final VoidCallback onClose;

  static const double _frameWidth = 440;
  static const double _frameHeight = 978;
  static const double _cardWidth = 392;
  static const double _cardHeight = 555;

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
          final closeGap = 20 * kv;
          final verticalMargin = 12 * kv;
          final closeBlock = closeSize + closeGap;
          // Mirror the close-icon block below the card so the card itself
          // stays centred (as in Figma) whenever there is room for it.
          final balanceCard = availableHeight >=
              _cardHeight * kw + 2 * (closeBlock + verticalMargin);
          final cardMaxHeight = math.max(
            0.0,
            availableHeight -
                2 * verticalMargin -
                closeBlock -
                (balanceCard ? closeBlock : 0),
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
                      ),
                    ),
                    SizedBox(height: closeGap),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: cardMaxHeight),
                      child: _PopupCard(
                        kw: kw,
                        kv: kv,
                        rewardLabel: formatZeroBalanceReward(rewardAmount),
                        onMaybeLater: onClose,
                        onOpenAccount: onOpenAccount,
                      ),
                    ),
                    if (balanceCard) SizedBox(height: closeBlock),
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

/// Translucent circular close (X) button shared by the Zero Balance popups.
class ZeroBalancePopupCloseButton extends StatelessWidget {
  const ZeroBalancePopupCloseButton({
    super.key,
    required this.size,
    required this.onTap,
    this.tapKey = const ValueKey('zeroBalancePopupClose'),
  });

  final double size;
  final VoidCallback onTap;
  final Key tapKey;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Close',
      child: Material(
        color: Colors.white.withOpacity(0.3),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: tapKey,
          onTap: onTap,
          child: SizedBox.square(
            dimension: size,
            child: Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: size * 0.6,
            ),
          ),
        ),
      ),
    );
  }
}

class _PopupCard extends StatelessWidget {
  const _PopupCard({
    required this.kw,
    required this.kv,
    required this.rewardLabel,
    required this.onMaybeLater,
    required this.onOpenAccount,
  });

  final double kw;
  final double kv;
  final String rewardLabel;
  final VoidCallback onMaybeLater;
  final VoidCallback onOpenAccount;

  static const List<BoxShadow> _shadows = [
    BoxShadow(color: Color(0x1AABABAB), offset: Offset(0, -5), blurRadius: 11),
    BoxShadow(color: Color(0x17ABABAB), offset: Offset(0, -20), blurRadius: 20),
    BoxShadow(color: Color(0x0DABABAB), offset: Offset(0, -45), blurRadius: 27),
    BoxShadow(color: Color(0x03ABABAB), offset: Offset(0, -81), blurRadius: 32),
    BoxShadow(
      color: Color(0x00ABABAB),
      offset: Offset(0, -126),
      blurRadius: 35,
    ),
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
                alignment: Alignment.center,
                opacity: kZeroBalanceBgOpacity,
              ),
            ),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 1,
                child: ColoredBox(color: Colors.white),
              ),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24 * kw, 52 * kv, 24 * kw, 37 * kv),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PopupHeading(rewardLabel: rewardLabel),
                  SizedBox(height: 14 * kv),
                  _PopupDescription(rewardLabel: rewardLabel),
                  SizedBox(height: 28 * kv),
                  _TrustedPartners(kw: kw, kv: kv),
                  SizedBox(height: 16 * kv),
                  _ZeroPercentIllustration(width: 195 * kw),
                  SizedBox(height: 20 * kv),
                  _PopupActions(
                    height: (46 * kv).clamp(40.0, 56.0),
                    gap: 10 * kw,
                    onMaybeLater: onMaybeLater,
                    onOpenAccount: onOpenAccount,
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

/// Figma px (440 frame) -> ScreenUtil font size (360 design), floored so the
/// smallest supported phones stay readable.
double _figmaSp(double px, {required double min}) =>
    math.max((px * 360 / 440).sp, min);

class _PopupHeading extends StatelessWidget {
  const _PopupHeading({required this.rewardLabel});

  final String rewardLabel;

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.plusJakartaSans(
      fontSize: _figmaSp(26, min: 18),
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      height: 1.6,
      color: AppColors.black,
    );
    return Text.rich(
      key: const ValueKey('zeroBalancePopupHeading'),
      TextSpan(
        style: style,
        children: [
          const TextSpan(text: 'Get Up to '),
          TextSpan(
            text: rewardLabel,
            style: style.copyWith(color: AppColors.primary),
          ),
          const TextSpan(text: ' instant in\nyour Wallet'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _PopupDescription extends StatelessWidget {
  const _PopupDescription({required this.rewardLabel});

  final String rewardLabel;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Open a zero balance savings account with our trusted banking '
      'partners and get up to $rewardLabel instant cash in your eRupaiya app.',
      key: const ValueKey('zeroBalancePopupDescription'),
      textAlign: TextAlign.center,
      style: GoogleFonts.plusJakartaSans(
        fontSize: _figmaSp(14, min: 11),
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: AppColors.black,
      ),
    );
  }
}

class _TrustedPartners extends StatelessWidget {
  const _TrustedPartners({required this.kw, required this.kv});

  final double kw;
  final double kv;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Trusted Partners',
          style: GoogleFonts.plusJakartaSans(
            fontSize: _figmaSp(12, min: 10),
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: AppColors.black,
          ),
        ),
        SizedBox(height: 9 * kv),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PartnerLogo(
                asset: FileConstants.airtelLogoSvg,
                width: 131 * kw,
                aspectRatio: 131 / 20,
              ),
              // Kotak's artwork carries ~8 px of transparent side padding, so
              // 16 + 8 gives the 24 px visual gap from Figma.
              SizedBox(width: 16 * kw),
              _PartnerLogo(
                asset: FileConstants.kotakLogoSvg,
                width: 100 * kw,
                aspectRatio: 100 / 50,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PartnerLogo extends StatelessWidget {
  const _PartnerLogo({
    required this.asset,
    required this.width,
    required this.aspectRatio,
  });

  final String asset;
  final double width;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: width,
      height: width / aspectRatio,
      fit: BoxFit.contain,
    );
  }
}

class _ZeroPercentIllustration extends StatelessWidget {
  const _ZeroPercentIllustration({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      FileConstants.zeroPercentBadgeSvg,
      width: width,
      height: width * 130 / 195,
      fit: BoxFit.contain,
    );
  }
}

class _PopupActions extends StatelessWidget {
  const _PopupActions({
    required this.height,
    required this.gap,
    required this.onMaybeLater,
    required this.onOpenAccount,
  });

  final double height;
  final double gap;
  final VoidCallback onMaybeLater;
  final VoidCallback onOpenAccount;

  @override
  Widget build(BuildContext context) {
    final labelStyle = GoogleFonts.plusJakartaSans(
      fontSize: _figmaSp(16, min: 12),
      fontWeight: FontWeight.w500,
    );
    return Row(
      children: [
        Expanded(
          child: CustomElevatedButton(
            key: const ValueKey('zeroBalancePopupMaybeLater'),
            onPressed: onMaybeLater,
            label: 'Maybe Later',
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
            key: const ValueKey('zeroBalancePopupOpenAccount'),
            onPressed: onOpenAccount,
            label: 'Open Account',
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
