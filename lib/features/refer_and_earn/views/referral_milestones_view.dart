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
  const ReferralMilestonesView({super.key, this.repository});

  /// Injectable for widget tests; production keeps the real repository.
  @visibleForTesting
  final ReferralMilestonesRepository? repository;

  @override
  Widget build(BuildContext context) {
    final future = useMemoized(
      () => (repository ?? ReferralMilestonesRepository()).fetchMilestones(),
    );
    final snapshot = useFuture(future);

    return Scaffold(
      backgroundColor: Colors.white,
      // Same fixed WhatsApp/Share footer container as Refer & Earn.
      bottomNavigationBar: const ReferralShareFooter(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Figma: nav row (back + help) with the title centred on its own
            // line below it, matching the Track Referrals header.
            ReferAndEarnAppBar(
              title: '',
              height: MediaQuery.paddingOf(context).top + 124.h,
              bottomReserve: 40.h,
              body: Center(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                  child: Text(
                    'Referral Milestones',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20.sp,
                        ),
                  ),
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
                  // Tighter top padding: the intro paragraph sits close to
                  // the sheet's curved edge, as in Figma.
                  padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 18.h),
                  child: Column(
                    children: [
                      _buildContent(context, snapshot),
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

class _MilestoneItem {
  const _MilestoneItem({
    required this.title,
    required this.reward,
    required this.progress,
    required this.completedText,
    required this.completed,
    this.remainingText,
  });

  final String title;
  final String reward;
  final double progress;
  final String completedText;
  final bool completed;
  final String? remainingText;
}

/// Figma intro line: Plus Jakarta Sans Medium 16px, 27px line height,
/// black, wrapping naturally (no hard break).
class _IntroText extends StatelessWidget {
  const _IntroText();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Complete Referral Milestones And Unlock Bonus E-Coins.',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF000000),
            fontWeight: FontWeight.w500,
            fontSize: 16.sp,
            height: 27 / 16,
            letterSpacing: 0,
          ),
    );
  }
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
        const _IntroText(),
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
      const _IntroText(),
      SizedBox(height: 20.h),
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
    completed: item.completed,
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
                  _TimelineNode(
                    completed: items[index].completed,
                    ringKey: ValueKey('milestone-ring-$index'),
                  ),
                  if (!isLast)
                    // Segment between this marker and the next. Segments
                    // touch exactly (no padding gaps), so the track reads
                    // as one continuous line; only the very first top and
                    // very last bottom get rounded caps.
                    Expanded(
                      child: Container(
                        width: 6.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFFB9B9B9),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(index == 0 ? 999 : 0),
                            bottom: Radius.circular(
                              index == items.length - 2 ? 999 : 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16.h),
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
  const _TimelineNode({required this.completed, this.ringKey});

  /// Completed/active milestones get the Figma orange ring; the rest use
  /// the neutral grey ring. Key forwarded to the painted circle for tests.
  final bool completed;
  final Key? ringKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ringKey,
      width: 30.w,
      height: 30.w,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: completed ? const Color(0xFFDD5428) : const Color(0xFFE1E1E1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Center(
        child: Image.asset(
          FileConstants.coin_3d,
          width: 15.w,
          height: 15.w,
        ),
      ),
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
        // Figma: thin light-grey outline, no heavy shadow.
        border: Border.all(color: const Color(0xFFE1E1E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏆'),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF000000),
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                        letterSpacing: 0,
                      ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            item.reward,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF000000),
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                  letterSpacing: 0,
                ),
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: item.progress,
              minHeight: 8.h,
              backgroundColor: const Color(0xFFD0D0D0),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFDD5428)),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            item.completedText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  // Green only when the model says the milestone is truly
                  // complete; everything else keeps the Figma grey.
                  color: item.completed
                      ? const Color(0xFF058337)
                      : const Color(0xFF7C7C7C),
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                  letterSpacing: 0,
                ),
          ),
          if (item.remainingText != null) ...[
            SizedBox(height: 12.h),
            Container(
              height: 1,
              color: const Color(0xFFE1E1E1),
            ),
            SizedBox(height: 12.h),
            Text(
              item.remainingText!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF000000),
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                    letterSpacing: 0,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
