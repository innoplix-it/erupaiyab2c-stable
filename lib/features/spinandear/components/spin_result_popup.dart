// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../../constants/file_constants.dart';
import '../models/spin_reward.dart';

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
    // available height (the previous `maxPopupHeight / _cardAspect` formula
    // was dimensionally wrong and made the card too short on short screens).
    final chromeHeight = 14.h + 55.h;
    final availableHeight =
        mq.size.height - mq.padding.top - mq.padding.bottom;
    final maxCardHeight = (availableHeight * 0.85) - chromeHeight;
    final cardWidth = math
        .min(mq.size.width - 24.w, maxCardHeight * _cardAspect)
        .clamp(0.0, double.infinity);

    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      alignment: Alignment.center,
      child: SizedBox(
        width: cardWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCard(cardWidth),
            SizedBox(height: 14.h),
            _buildClaimButton(cardWidth),
          ],
        ),
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
          top: 10.h,
          left: 10.w,
          right: 10.w,
          bottom: 10.h,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Scale the whole content block down if it is ever taller than
              // the card, so it can never overflow the artwork.
              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(height: 26.h),
                      _buildTitle(),
                      SizedBox(height: 6.h),
                      Text(
                        'You Earned',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      _buildEarnedValue(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // X sits at the card's top-right corner; the small negative offsets
        // are relative to the card itself, so the position tracks the popup
        // on every screen size (no device-specific coordinates).
        Positioned(
          top: -10.h,
          right: -10.w,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _close,
            child: Padding(
              padding: EdgeInsets.all(4.r),
              child: SvgPicture.asset(
                FileConstants.spinCloseSvg,
                width: 40.r,
                height: 40.r,
              ),
            ),
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
        Lottie.asset(
          'assets/lottie/star.json',
          width: 22.r,
          height: 22.r,
          fit: BoxFit.contain,
        ),
        Flexible(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              'Congratulations',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                height: 1.0,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Lottie.asset(
          'assets/lottie/star.json',
          width: 22.r,
          height: 22.r,
          fit: BoxFit.contain,
        ),
      ],
    );
  }

  /// Dynamic reward value taken straight from the spin result - never
  /// hardcoded. Coins render inside the 3D coin; the other outcomes keep
  /// their existing result wording.
  Widget _buildEarnedValue() {
    final reward = widget.reward;
    if (reward.type == SpinRewardType.coins) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            FileConstants.coin_3d,
            width: 96.r,
            height: 96.r,
            fit: BoxFit.contain,
          ),
          Text(
            '${reward.coins ?? 0}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28.sp,
              fontWeight: FontWeight.w800,
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

  Widget _buildClaimButton(double width) {
    return SizedBox(
      width: width,
      height: 55.h,
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
          padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 10.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(90.r),
          ),
        ),
        child: Text(
          'Claim Now',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            height: 1.0,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
