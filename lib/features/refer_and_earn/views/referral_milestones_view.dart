// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../components/refer_and_earn_app_bar.dart';
import '../components/referral_share_actions.dart';
import '../repositories/referral_milestones_repository.dart';

class ReferralMilestonesView extends HookWidget {
  const ReferralMilestonesView({super.key});

  @override
  Widget build(BuildContext context) {
    final future = useMemoized(
      () => ReferralMilestonesRepository().fetchMilestones(),
    );
    final snapshot = useFuture(future);

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
            ReferAndEarnAppBar(
              title: 'Referral Milestones',
              height: 200.h,
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
                  padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 18.h),
                  child: Column(
                    children: [
                      _buildContent(context, snapshot),
                      SizedBox(height: 70.h),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }
}

class _MilestoneItem {
  const _MilestoneItem({
    required this.title,
    required this.reward,
    required this.progress,
    required this.completedText,
    this.remainingText,
  });

  final String title;
  final String reward;
  final double progress;
  final String completedText;
  final String? remainingText;
}

Widget _buildContent(
  BuildContext context,
  AsyncSnapshot<ReferralMilestonesResponse> snapshot,
) {
  if (snapshot.connectionState == ConnectionState.waiting) {
    return const Center(
      child: SpinKitCircle(
        color: AppColors.primary,
        size: 48,
      ),
    );
  }
  if (snapshot.hasError) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Complete Referral Milestones And Unlock\nBonus E-Coins.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
        ),
        SizedBox(height: 10.h),
        Text(
          'Failed to load milestones. Please try again.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary.withOpacity(0.6),
              ),
        ),
      ],
    );
  }

  final data = snapshot.data;
  final milestones = data?.milestones ?? const <ReferralMilestoneItem>[];
  final items = milestones.map(_mapMilestone).toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Complete Referral Milestones And Unlock\nBonus E-Coins.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
      ),
      SizedBox(height: 14.h),
      if (items.isEmpty)
        Text(
          'No milestones available yet.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary.withOpacity(0.6),
              ),
        )
      else
        _MilestonesTimeline(items: items),
    ],
  );
}

_MilestoneItem _mapMilestone(ReferralMilestoneItem item) {
  final target = item.progressTarget;
  final current = item.progressCurrent;
  final progress = target > 0 ? (current / target).clamp(0, 1).toDouble() : 0.0;
  final rewardText = item.reward.trim();
  final completedText = item.progressText.trim().isNotEmpty
      ? item.progressText.trim()
      : '$current / $target Completed';
  String? remainingText;
  final remaining = target - current;
  if (!item.completed && remaining > 0) {
    remainingText = '$remaining More Referrals To Unlock The Rewards';
  }
  return _MilestoneItem(
    title: item.title,
    reward: rewardText.isEmpty ? '' : 'Reward $rewardText',
    progress: progress,
    completedText: completedText,
    remainingText: remainingText,
  );
}

class _MilestonesTimeline extends HookWidget {
  const _MilestonesTimeline({required this.items});

  final List<_MilestoneItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(items.length, (index) {
        final isLast = index == items.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const _TimelineNode(),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 3.w,
                        color: const Color(0xFFD0D0D0),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 14.h),
                  child: _MilestoneCard(item: items[index]),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _TimelineNode extends HookWidget {
  const _TimelineNode();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 24.w,
          height: 24.w,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE85A2C)),
          ),
          child: Center(
            child: Image.asset(
              FileConstants.coin_3d,
              width: 12.w,
              height: 12.w,
            ),
          ),
        ),
      ],
    );
  }
}

class _MilestoneCard extends HookWidget {
  const _MilestoneCard({required this.item});

  final _MilestoneItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.lightBorder.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0.w, 6.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏆'),
              SizedBox(width: 6.w),
              Text(
                item.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            item.reward,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: item.progress,
              minHeight: 6.h,
              backgroundColor: const Color(0xFFD9D9D9),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFE85A2C)),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            item.completedText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: item.progress >= 1
                      ? const Color(0xFF1B8E36)
                      : AppColors.textPrimary.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (item.remainingText != null) ...[
            SizedBox(height: 6.h),
            Container(
              height: 1,
              color: AppColors.lightBorder.withOpacity(0.6),
            ),
            SizedBox(height: 6.h),
            Text(
              item.remainingText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.7),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
