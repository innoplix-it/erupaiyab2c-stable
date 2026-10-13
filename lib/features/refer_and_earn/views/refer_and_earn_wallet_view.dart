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

// The Figma frame for this screen is 440 x 956 while ScreenUtil's design size
// is 360 x 690. Figma pixel values are converted once here and then scaled
// exactly once by ScreenUtil (never both), so a 440-wide phone renders the
// Figma pixel size and every other width scales proportionally.
double _figmaW(double px) => (px * 360 / 440).w;
double _figmaH(double px) => (px * 690 / 956).h;
double _figmaR(double px) => (px * 360 / 440).r;
double _figmaSp(double px) => (px * 360 / 440).sp;

/// Figma measurements, expressed in the 360-wide design units used by
/// ScreenUtilInit. Every value is scaled exactly once at the call site
/// (.w horizontal, .h vertical, .r radius/icon, .sp text), so nothing is
/// scaled twice and nothing is a raw pixel value.
class _Fig {
  const _Fig._();

  static const font = 'Plus Jakarta Sans';

  // Colours
  static const orange = Color(0xFFDD5428);
  static const navy = Color(0xFF06458F);
  static const withdrawBlue = Color(0xFF1D4E9E);
  static const track = Color(0xFFB9B9B9);
  static const ringIdle = Color(0xFFD9D9D9);
  static const hairline = Color(0xFFE6E6E6);
  static const chipBg = Color(0xFFFDEDE6);
  static const tabIdle = Color(0xFFEBEBEB);
  static const avatarBg = Color(0xFFE0E0E0);

  // Layout
  static const pageX = 14.0;
  static const heroBelowNav = 221.0;
  static const heroReserve = 40.0;
  static const sheetTop = 10.0;
  static const sheetLift = 26.0;

  // Hero
  static const coinHero = 32.0;
  static const balanceFont = 34.0;
  static const balanceLabelFont = 11.5;
  static const withdrawFont = 11.5;

  // Milestone card
  static const cardRadius = 16.0;
  static const dot = 25.0;
  static const trackH = 6.0;
  static const bannerRadius = 8.0;

  // Stat cards / tabs
  static const statMinH = 55.0;
  static const statRadius = 12.0;
  static const tabH = 41.0;

  // Rows
  static const avatarR = 18.5;
}

class ReferAndEarnWalletView extends HookWidget {
  const ReferAndEarnWalletView({super.key, this.repository});

  /// Injectable for widget tests; production keeps the real repository.
  @visibleForTesting
  final ReferralWalletRepository? repository;

  @override
  Widget build(BuildContext context) {
    final reloadToken = useState(0);
    final future = useMemoized(
          () => (repository ?? ReferralWalletRepository()).fetchSummary(),
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
            ReferAndEarnAppBar(
              title: 'Wallet',
              centerTitle: true,
              // Status inset + Figma hero (nav row, balance block, Withdraw).
              height: MediaQuery.paddingOf(context).top + _Fig.heroBelowNav.h,
              bottomReserve: _Fig.heroReserve.h,
              body: Column(
                children: [
                  // Flexible gaps collapse first when the system text scale
                  // grows, so the balance block never overflows the hero.
                  Flexible(child: SizedBox(height: 2.h)),
                  _WalletHeaderBalance(snapshot: snapshot),
                  Flexible(child: SizedBox(height: 14.h)),
                  _WithdrawButton(
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
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: Offset(0, -_Fig.sheetLift.h),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(_Fig.sheetLift.r),
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
                      padding: EdgeInsets.fromLTRB(
                        _Fig.pageX.w,
                        _Fig.sheetTop.h,
                        _Fig.pageX.w,
                        16.h,
                      ),
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

/// Theme text style with one explicit, ScreenUtil-scaled size.
TextStyle _style(
    BuildContext context,
    double size,
    FontWeight weight,
    Color color, {
      String? family,
      double? height,
    }) {
  return (Theme.of(context).textTheme.bodySmall ?? const TextStyle()).copyWith(
    fontSize: size.sp,
    fontWeight: weight,
    color: color,
    fontFamily: family,
    height: height,
    letterSpacing: 0,
  );
}

class _WithdrawButton extends StatelessWidget {
  const _WithdrawButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _Fig.withdrawBlue,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                FileConstants.withdrawIcon,
                width: 14.w,
                height: 14.w,
              ),
              SizedBox(width: 8.w),
              Text(
                'Withdraw',
                style: _style(
                  context,
                  _Fig.withdrawFont,
                  FontWeight.w600,
                  Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_Fig.cardRadius.r),
        border: Border.all(color: AppColors.lightBorder.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + subtitle on the left, dotted button on the right, all
          // in ONE row. FittedBox keeps the title on a single line at every
          // width / text scale instead of wrapping.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Unlock Your Next Milestone',
                        maxLines: 1,
                        softWrap: false,
                        style: _style(
                          context,
                          12,
                          FontWeight.w900,
                          AppColors.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        activeMilestone == null
                            ? 'Refer friends and earn rewards'
                            : 'Refer ${activeMilestone.targetReferrals} Friends And Get ${activeMilestone.rewardCoins} E-Coins Plus Bonus',
                        maxLines: 1,
                        softWrap: false,
                        style: _style(
                          context,
                          9.5,
                          FontWeight.w400,
                          AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
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
                child: _DottedBox(
                  radius: 13,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 7.h,
                    ),
                    child: Text(
                      'View Milestones',
                      maxLines: 1,
                      softWrap: false,
                      style: _style(
                        context,
                        9,
                        FontWeight.w700,
                        _Fig.navy,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          // Render exactly the milestones the backend configured; 5 is only
          // the empty-state fallback, never fake rows.
          _MilestoneDotRow(
            count: milestones.isNotEmpty ? milestones.length : 5,
            activeIndex: activeIndex,
          ),
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: _Fig.orange,
              borderRadius: BorderRadius.circular(_Fig.bannerRadius.r),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                activeMilestone == null
                    ? 'Refer more friends to unlock rewards'
                    : 'Refer ${_remainingReferrals(totalReferrals, activeMilestone)} More Friends To Unlock Your ${activeMilestone.rewardCoins} E-Coins',
                maxLines: 1,
                softWrap: false,
                // Figma: Plus Jakarta Sans Regular, 100% line height.
                style: _style(
                  context,
                  10,
                  FontWeight.w400,
                  Colors.white,
                  family: 'Plus Jakarta Sans',
                  height: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneDotRow extends StatelessWidget {
  const _MilestoneDotRow({
    required this.count,
    required this.activeIndex,
  });

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final dot = _Fig.dot.w;
    final trackH = _Fig.trackH.h;
    final labels = List.generate(
      count,
          (index) => (index + 1).toString().padLeft(2, '0'),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: dot,
          child: Stack(
            children: [
              // The track runs from the centre of the first dot to the
              // centre of the last one, vertically centred on the dots.
              Positioned(
                left: dot / 2,
                right: dot / 2,
                top: (dot - trackH) / 2,
                child: Container(
                  height: trackH,
                  decoration: BoxDecoration(
                    color: _Fig.track,
                    borderRadius: BorderRadius.circular(trackH),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < count; i++)
                    Container(
                      width: dot,
                      height: dot,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: i == activeIndex
                              ? _Fig.orange
                              : _Fig.ringIdle,
                          width: 1.5.w,
                        ),
                      ),
                      child: Center(
                        child: Image.asset(
                          FileConstants.coin_3d,
                          width: dot * 0.66,
                          height: dot * 0.66,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 4.h),
        // Each label sits in a dot-wide slot so it stays centred under its
        // dot regardless of the label's own width.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < count; i++)
              SizedBox(
                width: dot,
                child: Text(
                  labels[i],
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  textAlign: TextAlign.center,
                  // Figma: active milestone is Plus Jakarta Sans Bold
                  // #DD5428, inactive are Medium black; styling follows
                  // whichever milestone is currently selected.
                  style: _style(
                    context,
                    10,
                    i == activeIndex ? FontWeight.w700 : FontWeight.w500,
                    i == activeIndex ? _Fig.orange : const Color(0xFF000000),
                    family: 'Plus Jakarta Sans',
                    height: 1.0,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _TrackReferralsCard extends StatelessWidget {
  const _TrackReferralsCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(_Fig.statRadius.r);
    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: Container(
        constraints: BoxConstraints(minHeight: _Fig.statMinH.h),
        padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius,
          border: Border.all(color: AppColors.lightBorder.withOpacity(0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10.r,
              offset: Offset(0, 5.h),
            ),
          ],
        ),
        child: Row(
          // Figma: the arrow sits top-right, level with the small label.
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Track',
                    maxLines: 1,
                    style: _style(
                      context,
                      10,
                      FontWeight.w400,
                      AppColors.textPrimary.withOpacity(0.7),
                      family: _Fig.font,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Track Your Referrals',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _style(
                      context,
                      12,
                      FontWeight.w500,
                      const Color(0xFF000000),
                      family: _Fig.font,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 4.w),
            // Slightly larger than before (14 -> 16) and forced to black.
            // The arrow is a raster/asset image, so it has no stroke-width
            // property to set; see notes.
            Image.asset(
              FileConstants.arrow,
              width: 16.w,
              height: 16.w,
              color: const Color(0xFF000000),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  const _EarningsCard({required this.totalEarnings});

  final int totalEarnings;

  @override
  Widget build(BuildContext context) {
    // Figma: white card with a dotted #DD5428 outline.
    return _DottedBox(
      radius: _Fig.statRadius,
      child: Container(
        constraints: BoxConstraints(minHeight: _Fig.statMinH.h),
        padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 8.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Earnings',
                    maxLines: 1,
                    style: _style(
                      context,
                      10,
                      FontWeight.w500,
                      AppColors.textPrimary.withOpacity(0.7),
                      family: _Fig.font,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '$totalEarnings E-Coins',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _style(
                      context,
                      12,
                      FontWeight.w500,
                      const Color(0xFF000000),
                      family: _Fig.font,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 4.w),
            Image.asset(
              FileConstants.coin_3d,
              width: 30.r,
              height: 30.r,
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
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
    final fg = active ? Colors.white : AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      customBorder: const StadiumBorder(),
      child: Container(
        height: _Fig.tabH.h,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: active ? _Fig.navy : _Fig.tabIdle,
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              iconAsset,
              width: 15.w,
              height: 15.w,
              color: fg,
            ),
            SizedBox(width: 6.w),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: _style(context, 10.5, FontWeight.w600, fg),
                ),
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
    return Center(
      child: SpinKitCircle(
        color: AppColors.primary,
        size: 40.r,
      ),
    );
  }
  if (snapshot.hasError) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wallet Summary',
          style: _style(
            context,
            13,
            FontWeight.w700,
            AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          'Failed to load wallet summary. Please try again.',
          style: _style(
            context,
            10.5,
            FontWeight.w400,
            AppColors.textPrimary.withOpacity(0.6),
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
      SizedBox(height: 15.h),
      // IntrinsicHeight + stretch: both stat cards share the taller one's
      // height, so they line up like the Figma pair.
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            SizedBox(width: _Fig.pageX.w),
            Expanded(child: _EarningsCard(totalEarnings: totalEarnings)),
          ],
        ),
      ),
      SizedBox(height: 17.h),
      // The full-bleed hairline runs behind the two pills, as in Figma.
      SizedBox(
        height: _Fig.tabH.h,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -_Fig.pageX.w,
              right: -_Fig.pageX.w,
              top: _Fig.tabH.h / 2,
              child: Container(height: 1.r, color: _Fig.hairline),
            ),
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
                SizedBox(width: _Fig.pageX.w),
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
          ],
        ),
      ),
      SizedBox(height: 22.h),
      if (activeTab == _WalletTab.myTeam) ...[
        Row(
          // Figma: "View All" sits on the heading line.
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Team Earnings',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _style(
                      context,
                      18,
                      FontWeight.w500,
                      const Color(0xFF000000),
                      family: _Fig.font,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Image.asset(
                        FileConstants.coin_3d,
                        width: 16.w,
                        height: 16.w,
                      ),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '$totalTeamEarnings E-Coins',
                            maxLines: 1,
                            softWrap: false,
                            style: _style(
                              context,
                              12,
                              FontWeight.w700,
                              _Fig.orange,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: Text(
                'View All',
                maxLines: 1,
                textAlign: TextAlign.right,
                style: _style(
                  context,
                  11.5,
                  FontWeight.w500,
                  _Fig.orange,
                  family: _Fig.font,
                  height: 1.0,
                ).copyWith(
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.solid,
                  decorationColor: _Fig.orange,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        if (team.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Text(
              'No team members yet.',
              style: _style(
                context,
                10.5,
                FontWeight.w400,
                AppColors.textPrimary.withOpacity(0.6),
              ),
            ),
          )
        else
          ...team.map(
                (member) => _PersonRow(
              name: member.name,
              subtitle: member.since,
              subtitleColor: AppColors.textPrimary.withOpacity(0.55),
              earnings: member.earnings,
            ),
          ),
      ] else ...[
        Text(
          'Recent Referrals',
          style: _style(
            context,
            13,
            FontWeight.w800,
            AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 6.h),
        if (recentReferrals.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Text(
              'No recent referrals yet.',
              style: _style(
                context,
                10.5,
                FontWeight.w400,
                AppColors.textPrimary.withOpacity(0.6),
              ),
            ),
          )
        else
          ...recentReferrals.map(
                (referral) => _PersonRow(
              name: referral.name,
              subtitle: referral.joinedMessage.isNotEmpty
                  ? referral.joinedMessage
                  : referral.joinedOn,
              subtitleColor: const Color(0xFF1B8E36),
              earnings: referral.earnings,
            ),
          ),
      ],
      SizedBox(height: 16.h),
    ],
  );
}

class _WalletHeaderBalance extends StatelessWidget {
  const _WalletHeaderBalance({required this.snapshot});

  final AsyncSnapshot<ReferralWalletSummary> snapshot;

  @override
  Widget build(BuildContext context) {
    final isLoading = snapshot.connectionState == ConnectionState.waiting ||
        snapshot.connectionState == ConnectionState.active;
    final balance = snapshot.data?.walletBalance ?? '0.00';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Total Balance',
          style: _style(
            context,
            12,
            FontWeight.w500,
            Colors.white.withOpacity(0.85),
          ),
        ),
        SizedBox(height: 14.h),
        isLoading
            ? const _BalanceShimmer()
            : Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              FileConstants.coin_3d,
              width: _Fig.coinHero.w,
              height: _Fig.coinHero.w,
            ),
            SizedBox(width: 8.w),
            Text(
              balance,
              // Figma: Plus Jakarta Sans ExtraBold, 100% line height,
              // zero letter spacing.
              style: _style(
                context,
                _Fig.balanceFont,
                FontWeight.w800,
                Colors.white,
                family: 'Plus Jakarta Sans',
                height: 1.0,
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: _Fig.coinHero.w,
                height: _Fig.coinHero.w,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                width: 90.w,
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

String _initials(String name) {
  return name
      .split(' ')
      .where((e) => e.isNotEmpty)
      .take(2)
      .map((e) => e[0])
      .join()
      .toUpperCase();
}

/// Flat list row used by both tabs: avatar, name + subtitle, earnings pill,
/// overflow dots, and a hairline divider underneath (Figma team list).
class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.name,
    required this.subtitle,
    required this.subtitleColor,
    required this.earnings,
  });

  final String name;
  final String subtitle;
  final Color subtitleColor;
  final Object earnings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 13.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: _Fig.hairline, width: 1.r),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: _Fig.avatarR.r,
            backgroundColor: _Fig.avatarBg,
            child: Text(
              _initials(name),
              style: _style(
                context,
                12,
                FontWeight.w600,
                AppColors.textPrimary.withOpacity(0.75),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _style(
                    context,
                    11.5,
                    FontWeight.w700,
                    AppColors.textPrimary,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _style(
                      context,
                      9.5,
                      FontWeight.w500,
                      subtitleColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 6.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: ShapeDecoration(
              color: _Fig.chipBg,
              shape: const StadiumBorder(),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  FileConstants.coin_3d,
                  width: 15.w,
                  height: 15.w,
                ),
                SizedBox(width: 6.w),
                Text(
                  '$earnings E-Coins',
                  maxLines: 1,
                  style: _style(
                    context,
                    10,
                    FontWeight.w500,
                    AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 4.w),
          Icon(Icons.more_vert, size: 18.r, color: Colors.black),
        ],
      ),
    );
  }
}

/// Wraps [child] in the Figma orange dotted rounded outline. [radius] is in
/// design units and is scaled once here, together with dot size and spacing.
class _DottedBox extends StatelessWidget {
  const _DottedBox({required this.child, required this.radius});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedRRectPainter(
        color: _Fig.orange,
        radius: radius.r,
        dotSize: 1.3.r,
        spacing: 3.0.r,
      ),
      child: child,
    );
  }
}

/// Paints evenly spaced round dots along a rounded rectangle. The spacing is
/// adjusted per outline so the dots close the loop without a visible seam.
class _DottedRRectPainter extends CustomPainter {
  const _DottedRRectPainter({
    required this.color,
    required this.radius,
    required this.dotSize,
    required this.spacing,
  });

  final Color color;
  final double radius;
  final double dotSize;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final inset = dotSize / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        inset,
        inset,
        size.width - dotSize,
        size.height - dotSize,
      ),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      final count = (metric.length / spacing).round().clamp(1, 100000);
      final step = metric.length / count;
      for (var i = 0; i < count; i++) {
        final tangent = metric.getTangentForOffset(i * step);
        if (tangent != null) {
          canvas.drawCircle(tangent.position, dotSize / 2, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_DottedRRectPainter old) =>
      old.color != color ||
          old.radius != radius ||
          old.dotSize != dotSize ||
          old.spacing != spacing;
}