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

// The Figma frame for this screen is 440 x 956 while ScreenUtil's design size
// is 360 x 690. Figma pixel values are converted once here and then scaled
// exactly once by ScreenUtil (never both), so a 440-wide phone renders the
// Figma pixel size and every other width scales proportionally.
double _figmaW(double px) => (px * 360 / 440).w;
double _figmaH(double px) => (px * 690 / 956).h;
double _figmaR(double px) => (px * 360 / 440).r;
double _figmaSp(double px) => (px * 360 / 440).sp;

/// Figma bottom bar shadows (CSS box-shadow, all pointing upwards).
List<BoxShadow> get _bottomBarShadows => [
  BoxShadow(
    color: const Color(0x1ACFCFCF),
    offset: Offset(0, -_figmaH(3)),
    blurRadius: _figmaR(7),
  ),
  BoxShadow(
    color: const Color(0x17CFCFCF),
    offset: Offset(0, -_figmaH(13)),
    blurRadius: _figmaR(13),
  ),
  BoxShadow(
    color: const Color(0x0DCFCFCF),
    offset: Offset(0, -_figmaH(29)),
    blurRadius: _figmaR(17),
  ),
  BoxShadow(
    color: const Color(0x03CFCFCF),
    offset: Offset(0, -_figmaH(51)),
    blurRadius: _figmaR(21),
  ),
  BoxShadow(
    color: const Color(0x00CFCFCF),
    offset: Offset(0, -_figmaH(80)),
    blurRadius: _figmaR(22),
  ),
];

class TrackReferralsView extends HookWidget {
  const TrackReferralsView({super.key, this.repository});

  /// Injectable for widget tests; production keeps the real repository.
  @visibleForTesting
  final ReferralTrackRepository? repository;

  @override
  Widget build(BuildContext context) {
    final future = useMemoized(
      () => (repository ?? ReferralTrackRepository()).fetchTrack(),
    );
    final snapshot = useFuture(future);

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: _bottomBarShadows,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              _figmaW(16),
              _figmaH(20),
              _figmaW(16),
              _figmaH(20),
            ),
            child: SizedBox(
              height: _figmaH(56),
              child: const ReferralShareActions(),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Figma: nav row (back + help) then the centred title on its own
            // line, with the curved white sheet overlapping the bar bottom.
            ReferAndEarnAppBar(
              title: '',
              // Taller bar: the extra height lands under the centred title,
              // adding breathing space between it and the curved sheet.
              height: MediaQuery.paddingOf(context).top + 124.h,
              bottomReserve: 40.h,
              body: Center(
                child: Padding(
                  // Side padding stays 16.w; the extra bottom padding opens
                  // up space under the title without moving the text far.
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                  child: Text(
                    'Track Your Referrals',
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            // Figma: bold black label above a regular-weight value.
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
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
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.lightBorder.withOpacity(0.8)),
      ),
      child: Column(
        children: [
          // --- Top section: avatar, name, joining date, Super Referrer.
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20.r,
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
                      Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        entry.since,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary.withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                ),
                // Shown only when the API marks this member as a super
                // referrer (trophy + orange label on the right).
                if (entry.tag != null) ...[
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.emoji_events,
                    size: 18.r,
                    color: const Color(0xFFE8A33D),
                  ),
                  SizedBox(width: 4.w),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 120.w),
                    child: Text(
                      entry.tag!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: const Color(0xFFE85A2C),
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // --- Thin light-grey divider spanning the inner card width.
          Container(height: 1, color: const Color(0xFFEFEFEF)),
          // --- Bottom section: commission label + peach E-Coins pill.
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
            child: LayoutBuilder(
              builder: (context, constraints) => Row(
                children: [
                  Expanded(
                    child: Text(
                      'Your Commission',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // On very narrow screens the pill's natural width can
                  // exceed the row; cap it so the amount ellipsises instead
                  // of overflowing.
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * 0.55,
                    ),
                    child: _CommissionPill(
                      amount: '${entry.commission} E-Coins',
                    ),
                  ),
                ],
              ),
            ),
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18.sp,
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
              value: '$total ${total == 1 ? 'Friend' : 'Friends'} Joined',
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
      SizedBox(height: 24.h),
      Text(
        'My Referrals',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18.sp,
            ),
      ),
      SizedBox(height: 16.h),
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

class _CommissionPill extends HookWidget {
  const _CommissionPill({required this.amount});

  final String amount;

  @override
  Widget build(BuildContext context) {
    // Figma: light-peach pill on the right with the coin icon and the
    // dynamic commission amount.
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE9E0),
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            FileConstants.coin_3d,
            width: 18.r,
            height: 18.r,
          ),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              amount,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
