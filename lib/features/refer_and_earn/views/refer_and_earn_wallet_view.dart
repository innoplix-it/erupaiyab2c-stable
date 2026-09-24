// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../widgets/app_snackbar.dart';
import '../components/refer_and_earn_app_bar.dart';
import '../components/referral_share_actions.dart';
import '../repositories/referral_wallet_repository.dart';
import 'referral_milestones_view.dart';
import 'track_referrals_view.dart';
import 'withdraw_e_coins_view.dart';

class ReferAndEarnWalletView extends HookWidget {
  const ReferAndEarnWalletView({super.key});

  @override
  Widget build(BuildContext context) {
    final reloadToken = useState(0);
    final future = useMemoized(
      () => ReferralWalletRepository().fetchSummary(),
      [reloadToken.value],
    );
    final snapshot = useFuture(future);
    final activeTab = useState(_WalletTab.myTeam);

    useEffect(() {
      if (!snapshot.hasError) return null;
      Future.microtask(() {
        AppSnackbar.show(
          'Failed to load wallet balance. Pull to refresh.',
          type: AppSnackbarType.error,
        );
      });
      return null;
    }, [snapshot.hasError]);

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
          child: const ReferralShareActions(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ReferAndEarnAppBar(
              title: 'Wallet',
              height: 280.h,
              body: Column(
                children: [
                  SizedBox(height: 32.h),
                  _WalletHeaderBalance(snapshot: snapshot),
                  SizedBox(height: 14.h),
                  InkWell(
                    onTap: () {
                      final balance = snapshot.data?.walletBalance ?? '0';
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WithdrawECoinsView(
                            walletBalance: balance,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(18.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 26.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D4E9E),
                        borderRadius: BorderRadius.circular(18.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            FileConstants.withdrawIcon,
                            width: 16.w,
                            height: 16.w,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Withdraw',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    reloadToken.value++;
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                      child: _buildBody(
                        context,
                        snapshot,
                        activeTab.value,
                        (tab) => activeTab.value = tab,
                      ),
                    ),
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

enum _WalletTab { myTeam, recentReferrals }

class _MilestoneCard extends HookWidget {
  const _MilestoneCard({
    required this.totalReferrals,
    required this.milestones,
  });

  final int totalReferrals;
  final List<ReferralMilestone> milestones;

  @override
  Widget build(BuildContext context) {
    final activeIndex = _activeMilestoneIndex(milestones);
    final activeMilestone = _activeMilestone(milestones);
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.lightBorder.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12.r,
            offset: Offset(0.w, 8.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Unlock Your Next Milestone',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ReferralMilestonesView(),
                    ),
                  );
                },
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE85A2C)),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Text(
                    'View Milestones',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFE85A2C),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            activeMilestone == null
                ? 'Refer friends and earn rewards'
                : 'Refer ${activeMilestone.targetReferrals} Friends And Get ${activeMilestone.rewardCoins} E-Coins Plus Bonus',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.6),
                ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _MilestoneDotRow(
                  count: milestones.isNotEmpty ? milestones.length : 5,
                  activeIndex: activeIndex,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFFE85A2C),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              activeMilestone == null
                  ? 'Refer more friends to unlock rewards'
                  : 'Refer ${_remainingReferrals(totalReferrals, activeMilestone)} More Friends To Unlock Your ${activeMilestone.rewardCoins} E-Coins',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneDotRow extends HookWidget {
  const _MilestoneDotRow({
    required this.count,
    required this.activeIndex,
  });

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final items = List.generate(
      count,
      (index) => (index + 1).toString().padLeft(2, '0'),
    );
    return SizedBox(height: 46.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 12.w,
            right: 12.w,
            top: 10.h,
            child: Container(
              height: 6.h,
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(6.r),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: items.asMap().entries.map((entry) {
              final label = entry.value;
              final active = entry.key == activeIndex;
              return Column(
                children: [
                  Container(
                    width: 28.w,
                    height: 28.w,
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active
                            ? const Color(0xFFE85A2C)
                            : const Color(0xFFD9D9D9),
                        width: 1.4,
                      ),
                    ),
                    child: Center(
                      child: Image.asset(
                        FileConstants.coin_3d,
                        width: 25.w,
                        height: 25.w,
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: active
                              ? const Color(0xFFE85A2C)
                              : AppColors.textPrimary.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TrackReferralsCard extends HookWidget {
  const _TrackReferralsCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        constraints: BoxConstraints(minHeight: 74.h),
        padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.lightBorder.withOpacity(0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10.r,
              offset: Offset(0.w, 6.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Track',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Track Your Referrals',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            Image.asset(
              FileConstants.arrow,
              width: 18.w,
              height: 18.w,
            ),
          ],
        ),
      ),
    );
  }
}

class _EarningsCard extends HookWidget {
  const _EarningsCard({required this.totalEarnings});

  final int totalEarnings;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 74.h),
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F2),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE85A2C)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Earnings',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: 6.h),
                Text(
                  '$totalEarnings E-Coins',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          Center(
            child: Center(
              child: Image.asset(
                FileConstants.coin_3d,
                width: 45.r,
                height: 45.r,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends HookWidget {
  const _SegmentButton({
    required this.label,
    required this.active,
    required this.iconAsset,
    required this.onTap,
  });

  final String label;
  final bool active;
  final String iconAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        height: 40.h,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1A56A1) : const Color(0xFFF1EAEA),
          borderRadius: BorderRadius.circular(20.r),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconAsset,
              width: 18.w,
              height: 18.w,
              color: active ? Colors.white : AppColors.textPrimary,
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: active ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildBody(
  BuildContext context,
  AsyncSnapshot<ReferralWalletSummary> snapshot,
  _WalletTab activeTab,
  ValueChanged<_WalletTab> onTabChanged,
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
          'Wallet Summary',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: 10.h),
        Text(
          'Failed to load wallet summary. Please try again.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary.withOpacity(0.6),
              ),
        ),
      ],
    );
  }

  final data = snapshot.data;
  final totalEarnings = data?.totalEarnings ?? 0;
  final teamCount = data?.teamCount ?? 0;
  final totalTeamEarnings = data?.totalTeamEarnings ?? 0;
  final milestones = data?.milestones ?? const <ReferralMilestone>[];
  final team = data?.myTeam ?? const <TeamMember>[];
  final recentReferrals = data?.recentReferrals ?? const <RecentReferral>[];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _MilestoneCard(
        totalReferrals: teamCount,
        milestones: milestones,
      ),
      SizedBox(height: 14.h),
      Row(
        children: [
          Expanded(
            child: _TrackReferralsCard(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TrackReferralsView(),
                  ),
                );
              },
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(child: _EarningsCard(totalEarnings: totalEarnings)),
        ],
      ),
      SizedBox(height: 14.h),
      Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: 'My Team',
              active: activeTab == _WalletTab.myTeam,
              iconAsset: FileConstants.myTeam,
              onTap: () => onTabChanged(_WalletTab.myTeam),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _SegmentButton(
              label: 'Recent Referrals',
              active: activeTab == _WalletTab.recentReferrals,
              iconAsset: FileConstants.recentReferrals,
              onTap: () => onTabChanged(_WalletTab.recentReferrals),
            ),
          ),
        ],
      ),
      SizedBox(height: 16.h),
      if (activeTab == _WalletTab.myTeam) ...[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Team Earnings',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Image.asset(
                      FileConstants.coin_3d,
                      width: 16.w,
                      height: 16.w,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '$totalTeamEarnings E-Coins',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFFE85A2C),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              'View All',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFE85A2C),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        if (team.isEmpty)
          Text(
            'No team members yet.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.6),
                ),
          )
        else
          ...team.map((member) => _TeamListTile(member: member)),
      ] else ...[
        Text(
          'Recent Referrals',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: 12.h),
        if (recentReferrals.isEmpty)
          Text(
            'No recent referrals yet.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.6),
                ),
          )
        else
          ...recentReferrals
              .map((referral) => _RecentReferralTile(referral: referral)),
      ],
      SizedBox(height: 70.h),
    ],
  );
}

class _WalletHeaderBalance extends HookWidget {
  const _WalletHeaderBalance({required this.snapshot});

  final AsyncSnapshot<ReferralWalletSummary> snapshot;

  @override
  Widget build(BuildContext context) {
    final isLoading = snapshot.connectionState == ConnectionState.waiting ||
        snapshot.connectionState == ConnectionState.active;
    final balance = snapshot.data?.walletBalance ?? '0.00';
    return Column(
      children: [
        Text(
          'Total Balance',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
                fontSize: 18.sp,
              ),
        ),
        SizedBox(height: 8.h),
        isLoading
            ? const _BalanceShimmer()
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Image.asset(
                      FileConstants.coin_3d,
                      width: 36.w,
                      height: 36.w,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    balance,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
      ],
    );
  }
}

class _BalanceShimmer extends HookWidget {
  const _BalanceShimmer();

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final value = controller.value * 3 - 1;
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              colors: [
                Colors.white.withOpacity(0.22),
                Colors.white.withOpacity(0.55),
                Colors.white.withOpacity(0.22),
              ],
              stops: const [0.25, 0.5, 0.75],
              begin: const Alignment(-1, -0.3),
              end: const Alignment(1, 0.3),
              transform: _SlidingGradientTransform(value),
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                width: 96.w,
                height: 24.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);

  final double slidePercent;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

int _activeMilestoneIndex(List<ReferralMilestone> milestones) {
  if (milestones.isEmpty) return 0;
  final index = milestones.indexWhere((m) => !m.completed);
  if (index == -1) return milestones.length - 1;
  return index;
}

ReferralMilestone? _activeMilestone(List<ReferralMilestone> milestones) {
  if (milestones.isEmpty) return null;
  final index = milestones.indexWhere((m) => !m.completed);
  if (index == -1) return milestones.last;
  return milestones[index];
}

int _remainingReferrals(int totalReferrals, ReferralMilestone milestone) {
  final remaining = milestone.targetReferrals - totalReferrals;
  return remaining > 0 ? remaining : 0;
}

class _TeamListTile extends HookWidget {
  const _TeamListTile({required this.member});

  final TeamMember member;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0.w, 6.h),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: const Color(0xFFE0E0E0),
            child: Text(
              member.name
                  .split(' ')
                  .where((e) => e.isNotEmpty)
                  .take(2)
                  .map((e) => e[0])
                  .join()
                  .toUpperCase(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                SizedBox(height: 2.h),
                Text(
                  member.since,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1E8),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Row(
              children: [
                Image.asset(
                  FileConstants.coin_3d,
                  width: 14.w,
                  height: 14.w,
                ),
                SizedBox(width: 6.w),
                Text(
                  '${member.earnings} E-Coins',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(width: 6.w),
          Icon(Icons.more_vert, size: 18.r),
        ],
      ),
    );
  }
}

class _RecentReferralTile extends HookWidget {
  const _RecentReferralTile({required this.referral});

  final RecentReferral referral;

  @override
  Widget build(BuildContext context) {
    final subtitle = referral.joinedMessage.isNotEmpty
        ? referral.joinedMessage
        : referral.joinedOn;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.r,
            offset: Offset(0.w, 6.h),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: const Color(0xFFE0E0E0),
            child: Text(
              referral.name
                  .split(' ')
                  .where((e) => e.isNotEmpty)
                  .take(2)
                  .map((e) => e[0])
                  .join()
                  .toUpperCase(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  referral.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                if (subtitle.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF1B8E36),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1E8),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Row(
              children: [
                Image.asset(
                  FileConstants.coin_3d,
                  width: 14.w,
                  height: 14.w,
                ),
                SizedBox(width: 6.w),
                Text(
                  '${referral.earnings} E-Coins',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(width: 6.w),
          Icon(Icons.more_vert, size: 18.r),
        ],
      ),
    );
  }
}
