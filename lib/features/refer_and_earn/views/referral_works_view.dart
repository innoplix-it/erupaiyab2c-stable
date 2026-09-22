// ignore_for_file: deprecated_member_use, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../components/refer_and_earn_app_bar.dart';
import '../components/referral_share_actions.dart';
import '../components/referral_youtube_embed_card.dart';

class ReferralWorksView extends HookWidget {
  const ReferralWorksView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
          child: const ReferralShareActions(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ReferAndEarnAppBar(title: 'How It Works', height: 160.h),
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
                      // _VideoPreviewCard(),
                      // SizedBox(height: 16.h),
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
                      const ReferralYoutubeEmbedCard(),
                      // SizedBox(height: 16.h),
                      // _ExampleFlowCard(),
                      SizedBox(height: 12.h),
                      Text(
                        'You → A → B → C',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'You Earn:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      SizedBox(height: 6.h),
                      ..._buildEarnBullets(context),
                      SizedBox(height: 12.h),
                      Text(
                        "There’s No Limit To How Many People Can Join Through\n"
                        "Your Network – The More Your Network Grows, The More\n"
                        "E-Coins You Earn!",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary.withOpacity(0.7),
                              height: 1.4,
                            ),
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
  final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppColors.textPrimary.withOpacity(0.8),
        height: 1.5,
      );
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

class _ExampleFlowCard extends HookWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.lightBorder.withOpacity(0.8)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const _ExampleNode(label: 'Refer A\nFriend'),
              Expanded(
                child: Image.asset(
                  FileConstants.arrow,
                  height: 26.h,
                  fit: BoxFit.contain,
                ),
              ),
              const _ExampleNode(label: 'You Will Get\n100 E-Coins'),
              Expanded(
                child: Image.asset(
                  FileConstants.arrow,
                  height: 26.h,
                  fit: BoxFit.contain,
                ),
              ),
              const _ExampleNode(label: 'Your Friend Will\nGet 100 E-Coins'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExampleNode extends HookWidget {
  const _ExampleNode({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.lightBorder.withOpacity(0.8)),
          ),
          child: Center(
            child: Image.asset(
              FileConstants.coin_3d,
              width: 18.w,
              height: 18.w,
            ),
          ),
        ),
        SizedBox(height: 6.h),
        SizedBox(width: 80.w,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
