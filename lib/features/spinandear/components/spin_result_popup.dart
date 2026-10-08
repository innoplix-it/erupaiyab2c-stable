// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../../constants/file_constants.dart';
import '../models/spin_reward.dart';

/// The gold `star.json` sparkle with a blink: it continuously scales down
/// and back up (pulse). Purely decorative, so it never absorbs taps.
class _BlinkingStar extends HookWidget {
  const _BlinkingStar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    return IgnorePointer(
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.6, end: 1.15).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeInOut),
        ),
        child: Lottie.asset(
          'assets/lottie/star.json',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

/// Post-spin "Congratulations" popup (Figma).
///
/// Layout order: X close -> spinpopup.png card (⭐ Congratulations ⭐ /
/// You Earned / dynamic reward value) -> Claim Now CTA. The card size is
/// derived from the supplied artwork's aspect ratio and clamped by the
/// available height, so the popup stays fully visible on short screens.
/// All dimensions use ScreenUtil (.w/.h/.r/.sp) against the 360x690 design
/// frame; MediaQuery only supplies the structural max-height clamp, so
/// nothing is ever double-scaled.
class SpinResultPopup extends StatefulWidget {
  const SpinResultPopup({
    super.key,
    required this.reward,
    required this.onPrimaryTap,
  });

  final SpinReward reward;
  final Future<void> Function() onPrimaryTap;

  @override
  State<SpinResultPopup> createState() => _SpinResultPopupState();
}

class _SpinResultPopupState extends State<SpinResultPopup> {
  bool _isSubmitting = false;

  // assets/images/png/spinpopup.png is 784x536.
  static const double _cardAspect = 784 / 536;

  void _close() => Navigator.of(context, rootNavigator: true).pop();

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // Structural available space only (SafeArea-aware); sizes come from
    // ScreenUtil. The card is sized so that card + gap + CTA always fit the
    // available height.
    final chromeHeight = 16.h;
    final availableHeight = mq.size.height - mq.padding.top - mq.padding.bottom;
    final maxCardHeight = (availableHeight * 0.75) - chromeHeight;
    final cardWidth = math
        .min(mq.size.width - 32.w, maxCardHeight * _cardAspect)
        .clamp(0.0, double.infinity);

    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Sunburst glow behind the whole popup (card + CTA).
          Positioned.fill(
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/png/sunburst.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Extra clearance so the X sits above the card (Figma),
                // not overlapping its top edge.
                SizedBox(height: 54.h),
                _buildCard(cardWidth),
                SizedBox(height: 16.h),
                _buildClaimButton(cardWidth),
              ],
            ),
          ),
          Positioned(
            top: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
              child: Padding(
                padding: EdgeInsets.all(8.r),
                child: SvgPicture.asset(
                  FileConstants.spinCloseSvg,
                  width: 36.r,
                  height: 36.r,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(double cardWidth) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Image.asset(
            'assets/images/png/spinpopup.png',
            width: cardWidth,
            height: cardWidth / _cardAspect,
            fit: BoxFit.fill,
          ),
        ),
        Positioned(
          top: 12.h,
          left: 12.w,
          right: 12.w,
          bottom: 12.h,
          child: widget.reward.type == SpinRewardType.coins
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    // Scale the whole content block down if it is ever taller
                    // than the card, so it can never overflow the artwork.
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            SizedBox(height: 30.h),
                            _buildTitle(),
                            SizedBox(height: 12.h),
                            Text(
                              'You\'ve Earned',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            _buildEarnedValue(),
                          ],
                        ),
                      ),
                    );
                  },
                )
              // Non-coin outcomes (better luck / extra spin / jackpot):
              // no "Congratulations" / "You Earned" - the result message and
              // its subtitle are centered in the middle of the card.
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildOutcomeMessage(),
                            SizedBox(height: 12.h),
                            _buildOutcomeSubtitle(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _BlinkingStar(size: 24.r),
        Flexible(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Text(
              'Congratulations',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                height: 1.0,
                color: Colors.white,
              ),
            ),
          ),
        ),
        _BlinkingStar(size: 24.r),
      ],
    );
  }

  /// Non-coin outcome text with blinking `star.json` sparkles on the left and
  /// right, styled like the "Congratulations" title. The wording is derived
  /// from the spin result (reward type), never hardcoded per-instance.
  /// For surprise and extra spin types, the left star is replaced with their
  /// respective icons (with circle background like spin close).
  Widget _buildOutcomeMessage() {
    final message = switch (widget.reward.type) {
      SpinRewardType.extraSpin => 'Extra Spin!',
      SpinRewardType.jackpot => 'Jackpot Spin!',
      SpinRewardType.surprise => 'Surprise!',
      _ => 'Better Luck Next Time!',
    };
    Widget? leftIcon;
    if (widget.reward.type == SpinRewardType.surprise) {
      leftIcon = SvgPicture.asset(
        FileConstants.surpriseIconSvg,
        width: 24.r,
        height: 24.r,
        fit: BoxFit.contain,
      );
    } else if (widget.reward.type == SpinRewardType.extraSpin) {
      leftIcon = SvgPicture.asset(
        FileConstants.extraSpinIconSvg,
        width: 24.r,
        height: 24.r,
        fit: BoxFit.contain,
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leftIcon ?? _BlinkingStar(size: 24.r),
          Flexible(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          _BlinkingStar(size: 24.r),
        ],
      ),
    );
  }

  /// Supporting line shown under the non-coin outcome title.
  Widget _buildOutcomeSubtitle() {
    final subtitle = switch (widget.reward.type) {
      SpinRewardType.extraSpin => 'You won an extra spin! Give it another go.',
      SpinRewardType.jackpot => 'You\'ve unlocked the Jackpot spin!',
      SpinRewardType.surprise => 'A surprise reward is waiting for you!',
      _ => 'No coins this time. Keep spinning and try again!',
    };
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Text(
        subtitle,
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          height: 1.2,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Dynamic reward value taken straight from the spin result - never
  /// hardcoded. Coins render inside the SVG coin; the other outcomes keep
  /// their existing result wording.
  Widget _buildEarnedValue() {
    final reward = widget.reward;
    if (reward.type == SpinRewardType.coins) {
      return Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(
            FileConstants.spinCoinSvg,
            width: 96.r,
            height: 96.r,
            fit: BoxFit.contain,
            // If the SVG ever fails to load (e.g. a stale asset bundle),
            // fall back to a gold coin disc instead of rendering nothing.
            errorBuilder: (context, error, stackTrace) => Container(
              width: 96.r,
              height: 96.r,
              decoration: const BoxDecoration(
                color: Color(0xFFFFCC33),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Text(
            '${reward.coins ?? 0}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
              height: 1.0,
              color: const Color(0xFF8A4A12),
            ),
          ),
        ],
      );
    }
    final message = switch (reward.type) {
      SpinRewardType.extraSpin => 'Extra Spin!',
      SpinRewardType.jackpot => 'Jackpot Spin!',
      _ => 'Better Luck Next Time!',
    };
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18.sp,
          fontWeight: FontWeight.w800,
          height: 1.2,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Primary button label varies with the outcome:
  /// coins -> Claim Now, extra spin -> Spin Again, jackpot -> Spin Now,
  /// better luck -> Try Again.
  String get _primaryLabel {
    return switch (widget.reward.type) {
      SpinRewardType.coins => 'Claim Now',
      SpinRewardType.extraSpin => 'Spin Again',
      SpinRewardType.jackpot => 'Spin Now',
      SpinRewardType.betterLuck => 'Try Again',
      SpinRewardType.surprise => 'Claim Now',
    };
  }

  Widget _buildClaimButton(double width) {
    return SizedBox(
      width: width,
      height: 42.h,
      child: ElevatedButton(
        onPressed: _isSubmitting
            ? null
            : () async {
                setState(() => _isSubmitting = true);
                try {
                  // Existing claim/refresh callback - unchanged behaviour:
                  // run it, then close the popup back to the spin screen.
                  await widget.onPrimaryTap();
                  if (!context.mounted) return;
                  _close();
                } finally {
                  if (mounted) setState(() => _isSubmitting = false);
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDD5428),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28.r),
          ),
        ),
        child: Text(
          _primaryLabel,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            height: 1.0,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
