// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../components/refer_and_earn_app_bar.dart';
import '../components/referral_share_actions.dart';
import '../repositories/referral_track_repository.dart';

class TrackReferralsView extends HookWidget {
  const TrackReferralsView({super.key});

  @override
  Widget build(BuildContext context) {
    final future = useMemoized(
      () => ReferralTrackRepository().fetchTrack(),
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
              title: 'Track Your Referrals',
              height: 140.h,
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

class _MetricCard extends HookWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F2),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE85A2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _ReferralEntry {
  const _ReferralEntry({
    required this.name,
    required this.since,
    required this.commission,
    this.tag,
  });

  final String name;
  final String since;
  final int commission;
  final String? tag;
}

class _ReferralCard extends HookWidget {
  const _ReferralCard(this.entry);

  final _ReferralEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.lightBorder.withOpacity(0.8)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: const Color(0xFFE85A2C),
                child: Text(
                  entry.name
                      .split(' ')
                      .where((e) => e.isNotEmpty)
                      .take(2)
                      .map((e) => e[0])
                      .join()
                      .toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          entry.name,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                        ),
                        if (entry.tag != null) ...[
                          SizedBox(width: 8.w),
                          Image.asset(
                            FileConstants.coin_3d,
                            width: 12.w,
                            height: 12.w,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            entry.tag!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFFE85A2C),
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      entry.since,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.more_vert, size: 18.r),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _EarningsPill(
                  title: 'Your Commission',
                  amount: '${entry.commission} E-Coins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _buildContent(
  BuildContext context,
  AsyncSnapshot<ReferralTrackResponse> snapshot,
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
          'My Referrals',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: 10.h),
        Text(
          'Failed to load referrals. Please try again.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary.withOpacity(0.6),
              ),
        ),
      ],
    );
  }

  final data = snapshot.data;
  final total = data?.totalReferrals ?? 0;
  final monthEarnings = data?.thisMonthEarnings ?? 0;
  final referrals = data?.referrals ?? const <ReferralUser>[];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: _MetricCard(
              title: 'Total Referrals',
              value: '$total Friends Joined',
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _MetricCard(
              title: 'This Month Earnings',
              value: '$monthEarnings E-Coins',
            ),
          ),
        ],
      ),
      SizedBox(height: 16.h),
      Text(
        'My Referrals',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
      ),
      SizedBox(height: 10.h),
      if (referrals.isEmpty)
        Text(
          'No referrals yet.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary.withOpacity(0.6),
              ),
        )
      else
        ...referrals.map((entry) => _ReferralCard(_mapReferral(entry))),
    ],
  );
}

_ReferralEntry _mapReferral(ReferralUser user) {
  final rawSince = user.since.trim();
  final sinceText = rawSince.isEmpty
      ? 'Since -'
      : (rawSince.toLowerCase().startsWith('since')
          ? rawSince
          : 'Since $rawSince');
  return _ReferralEntry(
    name: user.name,
    since: sinceText,
    commission: user.commission,
    tag: user.badge,
  );
}

class _EarningsPill extends HookWidget {
  const _EarningsPill({required this.title, required this.amount});

  final String title;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F2),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Image.asset(
                FileConstants.coin_3d,
                width: 14.w,
                height: 14.w,
              ),
              SizedBox(width: 6.w),
              Text(
                amount,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
