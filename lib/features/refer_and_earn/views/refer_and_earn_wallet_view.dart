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


// The Figma frame for this screen is 440 x 956 while ScreenUtil's design size
// is 360 x 690. Figma pixel values are converted once here and then scaled
// exactly once by ScreenUtil (never both), so a 440-wide phone renders the
// Figma pixel size and every other width scales proportionally.

double _figmaW(double px) => (px * 360 / 440).w;

double _figmaH(double px) => (px * 690 / 956).h;

double _figmaR(double px) => (px * 360 / 440).r;

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
  static const track = Color(0xFFF8D0C5);
  static const ringIdle = Color(0xFFD9D9D9);
  static const hairline = Color(0xFFE6E6E6);
  static const chipBg = Color(0xFFFFEEE9);
  static const avatarBg = Color(0xFFFCECE7);

  // Layout
  static const pageX = 14.0;
  static const heroBelowNav = 221.0;
  static const heroReserve = 40.0;
  static const sheetTop = 10.0;
  static const sheetLift = 26.0;

  // Hero
  static const coinHero = 32.0;
  static const balanceFont = 34.0;
  static const balanceYellowStart = Color(0xFFFBDA3E);
  static const balanceYellowEnd = Color(0xFFFAD836);

  // Milestone card
  static const cardRadius = 16.0;
  static const dot = 25.0;
  static const trackH = 6.0;
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final heroHeight =
              MediaQuery.paddingOf(context).top + _Fig.heroBelowNav.h;
          final sheetTop = heroHeight - _Fig.sheetLift.h;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: heroHeight,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color(0xFF000000),
                        Color(0xFF300B00),
                        Color(0xFF611700),
                      ],
                      stops: [0.0, 0.4821, 0.9642],
                    ),
                  ),
                  child: ReferAndEarnAppBar(
                    // The design uses only back/help actions on this row.
                    title: '',
                    centerTitle: true,
                    height: heroHeight,
                    bottomReserve: _Fig.heroReserve.h,
                    // Parent DecoratedBox owns the dark Figma gradient.
                    skipBackground: true,
                    hideBottomStrip: true,
                    body: Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: _WalletHeaderBalance(snapshot: snapshot),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: sheetTop,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCFCFC),
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
                          18.h,
                        ),
                        child: _buildBody(context, snapshot),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

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
                            : 'Refer ${activeMilestone.targetReferrals} friends and get ${activeMilestone.rewardCoins} eCoins plus bonus',
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
          // Icon + text only — no border, no background fill.
          Row(
            children: [
              Image.asset(
                FileConstants.referMoreFriendsIcon,
                width: 26.w,
                height: 20.h,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  activeMilestone == null
                      ? 'Refer more friends to unlock rewards'
                      : 'Refer ${_remainingReferrals(totalReferrals, activeMilestone)} more friends to unlock your ${activeMilestone.rewardCoins} eCoins',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _style(
                    context,
                    10,
                    FontWeight.w600,
                    const Color(0xFF111111),
                    family: 'Plus Jakarta Sans',
                    height: 1.15,
                  ),
                ),
              ),
            ],
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final progress = count <= 1
                        ? 0.0
                        : (activeIndex.clamp(0, count - 1) / (count - 1));
                    return Stack(
                      children: [
                        Container(
                          height: trackH,
                          decoration: BoxDecoration(
                            color: _Fig.track,
                            borderRadius: BorderRadius.circular(trackH),
                          ),
                        ),
                        if (progress > 0)
                          FractionallySizedBox(
                            widthFactor: progress,
                            child: Container(
                              height: trackH,
                              decoration: BoxDecoration(
                                color: _Fig.orange,
                                borderRadius: BorderRadius.circular(trackH),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
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
                          color: i <= activeIndex
                              ? _Fig.orange
                              : _Fig.ringIdle,
                          width: 1.5.w,
                        ),
                      ),
                      child: Center(
                        child: Image.asset(
                          FileConstants.coinRupeeSmall,
                          width: dot * 0.72,
                          height: dot * 0.72,
                          fit: BoxFit.contain,
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      labels[i],
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      textAlign: TextAlign.center,
                      // Figma: active milestone is Plus Jakarta Sans Bold
                      // #DD5428, inactive are Medium black.
                      style: _style(
                        context,
                        10,
                        i == activeIndex ? FontWeight.w700 : FontWeight.w500,
                        i == activeIndex
                            ? _Fig.orange
                            : const Color(0xFF000000),
                        family: 'Plus Jakarta Sans',
                        height: 1.0,
                      ),
                    ),
                    if (i == activeIndex) ...[
                      SizedBox(height: 2.h),
                      Container(
                        width: 14.w,
                        height: 1.5.h,
                        decoration: BoxDecoration(
                          color: _Fig.orange,
                          borderRadius: BorderRadius.circular(1.r),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<ReferralWalletSummary> snapshot,
    ) {
  if (snapshot.connectionState == ConnectionState.waiting) {
    return Padding(
      padding: EdgeInsets.only(top: 40.h),
      child: Center(
        child: SpinKitCircle(color: AppColors.primary, size: 40.r),
      ),
    );
  }
  if (snapshot.hasError) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 28.h),
      child: Text(
        'Failed to load wallet summary. Please pull to refresh.',
        style: _style(
          context,
          11,
          FontWeight.w400,
          AppColors.textPrimary.withOpacity(0.65),
        ),
      ),
    );
  }
  final data = snapshot.data;
  final totalReferrals = data?.teamCount ?? 0;
  final milestones = data?.milestones ?? const <ReferralMilestone>[];
  final recentReferrals = data?.recentReferrals ?? const <RecentReferral>[];
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _MilestoneCard(
        totalReferrals: totalReferrals,
        milestones: milestones,
      ),
      SizedBox(height: 24.h),
      Text(
        'Recent Referrals',
        style: _style(
          context,
          16,
          FontWeight.w500,
          const Color(0xFF090909),
          family: _Fig.font,
          height: 1.15,
        ),
      ),
      SizedBox(height: 18.h),
      Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 18.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0x10000000),
              blurRadius: 24.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: recentReferrals.isEmpty
            ? Padding(
          padding: EdgeInsets.symmetric(vertical: 24.h),
          child: Center(
            child: Text(
              'No recent referrals yet.',
              style: _style(
                context,
                11,
                FontWeight.w400,
                AppColors.textPrimary.withOpacity(0.6),
              ),
            ),
          ),
        )
            : Column(
          children: [
            for (var i = 0; i < recentReferrals.length; i++)
              _RecentReferralRow(
                referral: recentReferrals[i],
                showDivider: i != recentReferrals.length - 1,
              ),
          ],
        ),
      ),
      SizedBox(height: 18.h),
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
            14,
            FontWeight.w600,
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
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _Fig.balanceYellowStart,
                  _Fig.balanceYellowEnd,
                ],
              ).createShader(bounds),
              child: Text(
                balance,
                maxLines: 1,
                softWrap: false,
                style: _style(
                  context,
                  _Fig.balanceFont,
                  FontWeight.w800,
                  Colors.white,
                  family: 'Plus Jakarta Sans',
                  height: 1.0,
                ).copyWith(
                  shadows: const [
                    Shadow(
                      color: Color(0x1A000000),
                      offset: Offset(0, 8),
                      blurRadius: 18,
                    ),
                    Shadow(
                      color: Color(0x17000000),
                      offset: Offset(0, 33),
                      blurRadius: 33,
                    ),
                    Shadow(
                      color: Color(0x0D000000),
                      offset: Offset(0, 74),
                      blurRadius: 45,
                    ),
                    Shadow(
                      color: Color(0x03000000),
                      offset: Offset(0, 132),
                      blurRadius: 53,
                    ),
                  ],
                ),
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

/// Referral row matching the joined / pending states in the wallet design.

class _RecentReferralRow extends StatelessWidget {
  const _RecentReferralRow({
    required this.referral,
    required this.showDivider,
  });
  final RecentReferral referral;
  final bool showDivider;
  bool get _isJoined {
    final value = referral.joinedMessage.trim().toLowerCase();
    if (value.isEmpty ||
        value.contains('not joined') ||
        value.contains('pending') ||
        value.contains('not eligible')) {
      return false;
    }
    return value.contains('joined') || value.contains('success');
  }
  String get _statusText {
    final value = referral.joinedMessage.trim();
    if (value.isEmpty) return 'Not joined yet';
    return value;
  }
  @override
  Widget build(BuildContext context) {
    final joined = _isJoined;
    final dateText = referral.joinedOn.trim();
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      decoration: showDivider
          ? BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _Fig.hairline, width: 1.r),
        ),
      )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: _figmaR(20),
            backgroundColor: _Fig.avatarBg,
            child: Text(
              _initials(referral.name),
              style: _style(context, 13, FontWeight.w600, _Fig.orange),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    referral.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _style(
                      context,
                      13,
                      FontWeight.w700,
                      const Color(0xFF080808),
                      family: _Fig.font,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    _statusText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _style(
                      context,
                      11,
                      FontWeight.w500,
                      joined
                          ? const Color(0xFF078A36)
                          : const Color(0xFF970D0D),
                    ),
                  ),
                  if (dateText.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      dateText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _style(
                        context,
                        10,
                        FontWeight.w400,
                        const Color(0xFF858585),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(width: 8.w),
          if (joined)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
              decoration: const ShapeDecoration(
                color: _Fig.chipBg,
                shape: StadiumBorder(),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    FileConstants.coin_3d,
                    width: 15.w,
                    height: 15.w,
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    '${referral.earnings} eCoins',
                    maxLines: 1,
                    softWrap: false,
                    style: _style(
                      context,
                      10,
                      FontWeight.w600,
                      const Color(0xFF111111),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: const ShapeDecoration(
                color: Color(0xFFFFF0F0),
                shape: StadiumBorder(),
              ),
              child: Text(
                'Joining Pending',
                maxLines: 1,
                softWrap: false,
                style: _style(
                  context,
                  9.5,
                  FontWeight.w600,
                  const Color(0xFFD71920),
                ),
              ),
            ),
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
