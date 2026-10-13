// ignore_for_file: deprecated_member_use, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../components/refer_and_earn_app_bar.dart';
import '../components/referral_share_actions.dart';
import '../components/referral_youtube_embed_card.dart';

/// Figma measurements for the blue header on this screen (360-wide design
/// units; each value is scaled exactly once at the call site).
class _Fig {
  const _Fig._();

  /// Video box is 407 x 182 on the 440 Figma frame: always width-driven.
  static const videoRatio = 407 / 182;

  /// Side margin of the box: 16.5 on the 440 frame -> 13.5 design units.
  static const videoSide = 13.5;

  /// Gap between the nav row and the top of the box.
  static const videoTopGap = 7.0;

  /// Gap between the bottom of the box and the top of the white sheet.
  static const videoBottomGap = 18.0;

  /// Height of the white rounded strip ReferAndEarnAppBar draws at its
  /// bottom edge (the visible top of the sheet).
  static const barStrip = 36.0;

  /// Vertical padding the app bar puts around its nav row.
  static const navPadV = 4.0;
}

class ReferralWorksView extends HookWidget {
  const ReferralWorksView({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final topInset = MediaQuery.paddingOf(context).top;

    // The box is width-driven (never .h). The bar height always equals:
    // status inset + nav row + gap + box + gap + the white strip.
    final sideGap = _Fig.videoSide.w;
    final videoHeight = (media.width - 2 * sideGap) / _Fig.videoRatio;
    final navHeight = kMinInteractiveDimension + 2 * _Fig.navPadV.h;
    final bottomReserve = (_Fig.barStrip + _Fig.videoBottomGap).h;
    final barHeight = topInset +
        navHeight +
        _Fig.videoTopGap.h +
        videoHeight +
        bottomReserve;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const ReferralShareFooter(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ReferAndEarnAppBar(
              title: 'How It Works',
              height: barHeight,
              bottomReserve: bottomReserve,
              body: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    sideGap,
                    _Fig.videoTopGap.h,
                    sideGap,
                    0,
                  ),
                  child: const _VideoPlaceholder(),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(0, -26.h),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(26.r),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 18.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._buildBullets(context),
                      SizedBox(height: 12.h),
                      Text(
                        'Example:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      SizedBox(
                        key: const ValueKey('refer-works-illustration'),
                        width: double.infinity,
                        child: SvgPicture.asset(
                          FileConstants.referEarnExampleIllustrationSvg,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        'You → A → B → C',
                        style: _exampleTextStyle(context),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        'You Earn:',
                        style: _exampleTextStyle(context),
                      ),
                      SizedBox(height: 6.h),
                      ..._buildEarnBullets(context),
                      SizedBox(height: 15.h),
                      Text(
                        "There’s No Limit To How Many People Can Join Through "
                            "Your Network — The More Your Network Grows, The More "
                            "E-Coins You Earn!",
                        style: _exampleTextStyle(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Figma typography for the explanation below the illustration: Plus Jakarta
/// Sans Medium 500, 14px with a 25px line height, 0 letter-spacing, black.
TextStyle? _exampleTextStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodyMedium?.copyWith(
    color: const Color(0xFF000000),
    fontFamily: 'Plus Jakarta Sans',
    fontWeight: FontWeight.w500,
    fontSize: 14.sp,
    height: 25 / 14,
    letterSpacing: 0,
  );
}

/// Video box in the blue header (Figma 407 x 182, 16px radius).
///
/// The same fixed 407:182 box is used before AND after the tap, so the
/// header never changes size and no gap appears. Tapping swaps the
/// translucent play placeholder for the project's existing YouTube embed,
/// which is forced to fill the box edge to edge.
class _VideoPlaceholder extends HookWidget {
  const _VideoPlaceholder();

  @override
  Widget build(BuildContext context) {
    final playing = useState(false);

    return AspectRatio(
      key: const ValueKey('refer-works-video'),
      aspectRatio: _Fig.videoRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: playing.value
        // Tight constraints from AspectRatio + SizedBox.expand make the
        // embed fill the whole box with no extra space around it.
            ? const SizedBox.expand(child: ReferralYoutubeEmbedCard())
            : GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => playing.value = true,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0x66FFFFFF),
            child: Center(
              child: SvgPicture.asset(
                FileConstants.referPlayIconSvg,
                width: 50.r,
                height: 50.r,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<Widget> _buildBullets(BuildContext context) {
  final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
    color: AppColors.textPrimary.withOpacity(0.8),
    height: 1.5,
  );
  const bullets = [
    'When Your Friend Joins Using Your Referral Code And\nCompletes Their First Transaction, You Earn 100 E-Coins.',
    'Your Friend Also Earns 100 E-Coins As A Welcome Bonus.',
    'If Your Friend Refers Someone Else, You’ll Continue To\nEarn 20 E-Coins From Each New Referral Made Within\nYour Network.',
    'This Means Even If Your Friend’s Friend (Or Their Next\nReferrals) Joins And Transacts, You Still Get 20 E-Coins\nEvery Time!',
  ];
  return bullets
      .map(
        (text) => Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Container(
              width: 6.w,
              height: 6.w,
              decoration: const BoxDecoration(
                color: AppColors.textPrimary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(child: Text(text, style: textStyle)),
        ],
      ),
    ),
  )
      .toList();
}

List<Widget> _buildEarnBullets(BuildContext context) {
  final textStyle = _exampleTextStyle(context);
  const bullets = [
    '100 E-Coins When A Transacts',
    '20 E-Coins When B Transacts',
    '20 E-Coins When C Transacts',
  ];
  return bullets
      .map(
        (text) => Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Container(
              width: 6.w,
              height: 6.w,
              decoration: const BoxDecoration(
                color: AppColors.textPrimary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(child: Text(text, style: textStyle)),
        ],
      ),
    ),
  )
      .toList();
}