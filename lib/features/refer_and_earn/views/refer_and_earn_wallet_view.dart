// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../widgets/app_snackbar.dart';
import '../components/refer_and_earn_app_bar.dart';
import '../components/referral_share_actions.dart';
import '../components/refer_and_earn_figma_metrics.dart';
import '../repositories/referral_wallet_repository.dart';
import 'referral_milestones_view.dart';

/// Figma measurements (440×956) scaled once via [ReferAndEarnFigmaMetrics].

class _Fig {
  const _Fig._();

  static const font = 'Plus Jakarta Sans';

  // Colours
  static const orange = Color(0xFFDD5428);
  static const navy = Color(0xFF06458F);
  static const track = Color(0xFFF8D0C5);
  static const hairline = Color(0xFFE6E6E6);
  static const chipBg = Color(0xFFFFEEE9);
  static const avatarBg = Color(0xFFFCECE7);

  // Layout
  static const pageX = 14.0;
  static const heroBelowNav = 221.0;
  static const heroReserve = 40.0;
  static const sheetTop = 10.0;
  static const sheetLift = 26.0;

  // Hero (Figma rupee coin 52×50 beside balance)
  static const coinHeroW = 52.0;
  static const coinHeroH = 50.0;

  /// Balance numeral — visually matches hero coin height (Figma).
  static const balanceFont = 48.0;

  /// Label → coin/amount row (Figma wallet hero).
  static const balanceLabelGap = 16.0;

  /// Breathing room below coin + amount before the white sheet (Figma).
  static const balanceBelowGap = 20.0;

  /// Section headings + matching row primary text (name, eCoins value).
  static const sectionTitleWeight = FontWeight.w500;
  static const balanceYellowStart = Color(0xFFFBDA3E);
  static const balanceYellowEnd = Color(0xFFFAD836);

  // Milestone card (Figma 440 frame, scaled with MediaQuery).
  static const cardRadius = 22.0;
  static const milestonePadX = 16.0;
  static const milestonePadTop = 16.0;
  static const milestonePadBottom = 16.0;
  static const milestoneTitle = 16.0;
  static const milestoneSubtitle = 12.0;
  static const milestoneTitleGap = 4.0;
  static const milestoneCtaFont = 12.0;
  static const milestoneCtaRadius = 20.0;
  static const milestoneCtaPadX = 14.0;
  static const milestoneCtaPadY = 8.0;
  static const milestoneHeaderGap = 10.0;
  static const milestoneHeaderToTrack = 20.0;
  static const dot = 38.0;
  static const trackH = 8.0;
  static const milestoneLabelGap = 6.0;
  static const milestoneLabel = 12.0;
  static const milestoneTrackToBox = 16.0;
  static const referMoreDottedRadius = 14.0;
  static const milestoneBoxPadX = 12.0;
  static const milestoneBoxPadY = 12.0;
  static const milestoneBoxFont = 13.0;
  static const milestoneBoxIconW = 28.0;
  static const milestoneBoxIconH = 22.0;
  static const milestoneBoxIconGap = 10.0;
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
      bottomNavigationBar: const ReferralShareFooter(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final heroHeight = MediaQuery.paddingOf(context).top +
              context.referH(_Fig.heroBelowNav);
          final sheetTop = heroHeight - context.referH(_Fig.sheetLift);
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
                    bottomReserve: context.referH(_Fig.heroReserve),
                    // Parent DecoratedBox owns the dark Figma gradient.
                    skipBackground: true,
                    hideBottomStrip: true,
                    body: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: context.referH(_Fig.balanceBelowGap),
                        ),
                        child: _WalletHeaderBalance(snapshot: snapshot),
                      ),
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
                      top: Radius.circular(context.referR(_Fig.sheetLift)),
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
                          context.referW(_Fig.pageX),
                          context.referH(_Fig.sheetTop),
                          context.referW(_Fig.pageX),
                          context.referH(18),
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

/// Theme text style with one Figma-scaled size (no double scaling).
TextStyle _style(
  BuildContext context,
  double size,
  FontWeight weight,
  Color color, {
  String? family,
  double? height,
}) {
  return (Theme.of(context).textTheme.bodySmall ?? const TextStyle()).copyWith(
    fontSize: ReferAndEarnFigmaMetrics.sp(context, size),
    fontWeight: weight,
    color: color,
    fontFamily: family ?? _Fig.font,
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
      padding: EdgeInsets.fromLTRB(
        context.referW(_Fig.milestonePadX),
        context.referH(_Fig.milestonePadTop),
        context.referW(_Fig.milestonePadX),
        context.referH(_Fig.milestonePadBottom),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.referR(_Fig.cardRadius)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: context.referR(16),
            offset: Offset(0, context.referH(4)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + subtitle on the left, dotted pill on the right.
          // FittedBox keeps each line on one row at every width and text scale.
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
                          _Fig.milestoneTitle,
                          FontWeight.w500,
                          const Color(0xFF000000),
                        ),
                      ),
                    ),
                    SizedBox(height: context.referH(_Fig.milestoneTitleGap)),
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
                          _Fig.milestoneSubtitle,
                          FontWeight.w500,
                          const Color(0xFF000000),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.referW(_Fig.milestoneHeaderGap)),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ReferralMilestonesView(),
                    ),
                  );
                },
                child: _DottedBox(
                  radius: _Fig.milestoneCtaRadius,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.referW(_Fig.milestoneCtaPadX),
                      vertical: context.referH(_Fig.milestoneCtaPadY),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * 0.38,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'View Milestones',
                          maxLines: 1,
                          softWrap: false,
                          style: _style(
                            context,
                            _Fig.milestoneCtaFont,
                            FontWeight.w500,
                            _Fig.navy,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.referH(_Fig.milestoneHeaderToTrack)),
          // Design row is always 5 coins. Extra API milestones still show.
          _MilestoneDotRow(
            count: math.max(milestones.length, 5),
            activeIndex: activeIndex,
            nextArc: _nextMilestoneArc(totalReferrals, milestones, activeIndex),
          ),
          SizedBox(height: context.referH(_Fig.milestoneTrackToBox)),
          _DottedBox(
            radius: _Fig.referMoreDottedRadius,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                context.referW(_Fig.milestoneBoxPadX),
                context.referH(_Fig.milestoneBoxPadY),
                context.referW(_Fig.milestoneBoxPadX),
                context.referH(_Fig.milestoneBoxPadY),
              ),
              child: Row(
                children: [
                  Image.asset(
                    FileConstants.referMoreFriendsIcon,
                    width: context.referW(_Fig.milestoneBoxIconW),
                    height: context.referH(_Fig.milestoneBoxIconH),
                    fit: BoxFit.contain,
                  ),
                  SizedBox(width: context.referW(_Fig.milestoneBoxIconGap)),
                  Expanded(
                    child: Text(
                      activeMilestone == null
                          ? 'Refer more friends to unlock rewards'
                          : 'Refer ${_remainingReferrals(totalReferrals, activeMilestone)} more friends to unlock your ${activeMilestone.rewardCoins} eCoins',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _style(
                        context,
                        _Fig.milestoneBoxFont,
                        FontWeight.w500,
                        const Color(0xFF111111),
                        family: 'Plus Jakarta Sans',
                        height: 1.2,
                      ),
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

class _MilestoneDotRow extends StatelessWidget {
  const _MilestoneDotRow({
    required this.count,
    required this.activeIndex,
    required this.nextArc,
  });

  final int count;
  final int activeIndex;

  /// 0–1 sweep drawn on the coin after [activeIndex].
  final double nextArc;

  @override
  Widget build(BuildContext context) {
    final dot = context.referW(_Fig.dot);
    final trackH = context.referH(_Fig.trackH);
    final stroke = context.referW(1.6);
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
              // Peach rail from the centre of the first coin to the last.
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
                    _MilestoneCoin(
                      size: dot,
                      stroke: stroke,
                      ring: i == activeIndex
                          ? _CoinRing.full
                          : (i == activeIndex + 1 && nextArc > 0
                              ? _CoinRing.arc
                              : _CoinRing.none),
                      arc: i == activeIndex + 1 ? nextArc : 0,
                    ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: context.referH(_Fig.milestoneLabelGap)),
        // Each label sits in a dot-wide slot so it stays centred under its coin.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < count; i++)
              SizedBox(
                width: dot,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    labels[i],
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    // Active step is Plus Jakarta Sans Bold #DD5428.
                    style: _style(
                      context,
                      _Fig.milestoneLabel,
                      i == activeIndex ? FontWeight.w700 : FontWeight.w500,
                      i == activeIndex ? _Fig.orange : const Color(0xFF000000),
                      family: 'Plus Jakarta Sans',
                      height: 1.0,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

enum _CoinRing { none, full, arc }

class _MilestoneCoin extends StatelessWidget {
  const _MilestoneCoin({
    required this.size,
    required this.stroke,
    required this.ring,
    required this.arc,
  });

  final double size;
  final double stroke;
  final _CoinRing ring;
  final double arc;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: ring == _CoinRing.none
                  ? Border.all(color: const Color(0xFFEFEFEF), width: stroke)
                  : null,
            ),
            child: SizedBox(width: size, height: size),
          ),
          Image.asset(
            FileConstants.coinRupeeSmall,
            width: size * 0.62,
            height: size * 0.62,
            fit: BoxFit.contain,
          ),
          if (ring != _CoinRing.none)
            CustomPaint(
              size: Size(size, size),
              painter: _CoinRingPainter(
                color: _Fig.orange,
                strokeWidth: stroke,
                full: ring == _CoinRing.full,
                sweep: arc,
              ),
            ),
        ],
      ),
    );
  }
}

class _CoinRingPainter extends CustomPainter {
  const _CoinRingPainter({
    required this.color,
    required this.strokeWidth,
    required this.full,
    required this.sweep,
  });

  final Color color;
  final double strokeWidth;
  final bool full;
  final double sweep;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    if (full) {
      canvas.drawArc(rect, 0, math.pi * 2, false, paint);
    } else if (sweep > 0) {
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CoinRingPainter oldDelegate) {
    return oldDelegate.sweep != sweep ||
        oldDelegate.full != full ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.color != color;
  }
}

Widget _buildBody(
  BuildContext context,
  AsyncSnapshot<ReferralWalletSummary> snapshot,
) {
  if (snapshot.connectionState == ConnectionState.waiting) {
    return Padding(
      padding: EdgeInsets.only(top: context.referH(40)),
      child: Center(
        child:
            SpinKitCircle(color: AppColors.primary, size: context.referR(40)),
      ),
    );
  }
  if (snapshot.hasError) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.referH(28)),
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
      SizedBox(height: context.referH(24)),
      Text(
        'Recent Referrals',
        style: _style(
          context,
          16,
          _Fig.sectionTitleWeight,
          const Color(0xFF090909),
          family: _Fig.font,
          height: 1.15,
        ),
      ),
      SizedBox(height: context.referH(18)),
      Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: context.referW(18)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.referR(18)),
          boxShadow: [
            BoxShadow(
              color: const Color(0x10000000),
              blurRadius: context.referR(24),
              offset: Offset(0, context.referH(8)),
            ),
          ],
        ),
        child: recentReferrals.isEmpty
            ? Padding(
                padding: EdgeInsets.symmetric(vertical: context.referH(24)),
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
      SizedBox(height: context.referH(18)),
    ],
  );
}

class _WalletHeaderBalance extends StatelessWidget {
  const _WalletHeaderBalance({required this.snapshot});

  final AsyncSnapshot<ReferralWalletSummary> snapshot;

  @override
  Widget build(BuildContext context) {
    final isLoading =
        snapshot.connectionState == ConnectionState.waiting ||
            snapshot.connectionState == ConnectionState.active;

    final balance = snapshot.data?.walletBalance ?? '0.00';
    final screenWidth = MediaQuery.sizeOf(context).width;

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.bottomCenter,
      child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(
            right: context.referW(12),
          ),
          child: Text(
            'Total Balance',
            textAlign: TextAlign.center,
            style: _style(
              context,
              16,
              FontWeight.w500,
              Colors.white.withOpacity(0.85),
              family: _Fig.font,
            ),
          ),
        ),

        SizedBox(
          height: context.referH(_Fig.balanceLabelGap),
        ),

        if (isLoading)
          const _BalanceShimmer()
        else
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: screenWidth * 0.82,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    FileConstants.coinRupeeSmall,
                    width: context.referW(_Fig.coinHeroW),
                    height: context.referH(_Fig.coinHeroH),
                    fit: BoxFit.contain,
                  ),

                  SizedBox(
                    width: context.referW(8),
                  ),

                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) =>
                        const LinearGradient(
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
            ),
          ),
      ],
      ),
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
                width: context.referW(_Fig.coinHeroW),
                height: context.referH(_Fig.coinHeroH),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(context.referR(8)),
                ),
              ),
              SizedBox(width: context.referW(8)),
              Container(
                width: context.referW(90),
                height: context.referH(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(context.referR(10)),
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

/// How far the user is through the active milestone, drawn as an arc on the
/// next coin (full ring stays on the current step).
double _nextMilestoneArc(
  int totalReferrals,
  List<ReferralMilestone> milestones,
  int activeIndex,
) {
  if (milestones.isEmpty || activeIndex >= milestones.length - 1) return 0;
  final goal = milestones[activeIndex].targetReferrals;
  final start =
      activeIndex == 0 ? 0 : milestones[activeIndex - 1].targetReferrals;
  final span = goal - start;
  if (span <= 0) return 0;
  return ((totalReferrals - start) / span).clamp(0.0, 1.0);
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
      padding: EdgeInsets.symmetric(vertical: context.referH(14)),
      decoration: showDivider
          ? BoxDecoration(
              border: Border(
                bottom:
                    BorderSide(color: _Fig.hairline, width: context.referR(1)),
              ),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: context.referR(20),
            backgroundColor: _Fig.avatarBg,
            child: Text(
              _initials(referral.name),
              style: _style(context, 13, FontWeight.w700, _Fig.orange),
            ),
          ),
          SizedBox(width: context.referW(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  referral.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _style(
                    context,
                    14,
                    _Fig.sectionTitleWeight,
                    const Color(0xFF000000),
                    family: _Fig.font,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: context.referH(3)),
                Text(
                  _statusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _style(
                    context,
                    11,
                    FontWeight.w500,
                    joined ? const Color(0xFF078A36) : const Color(0xFF970D0D),
                    height: 1.25,
                  ),
                ),
                if (dateText.isNotEmpty) ...[
                  SizedBox(height: context.referH(4)),
                  Text(
                    dateText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _style(
                      context,
                      10,
                      FontWeight.w400,
                      const Color(0xFF858585),
                      height: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: context.referW(8)),
          if (joined)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.referW(10),
                vertical: context.referH(6),
              ),
              decoration: const ShapeDecoration(
                color: _Fig.chipBg,
                shape: StadiumBorder(),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    FileConstants.coin_3d,
                    width: context.referW(18),
                    height: context.referW(18),
                    fit: BoxFit.contain,
                  ),
                  SizedBox(width: context.referW(6)),
                  Text(
                    '${referral.earnings} eCoins',
                    maxLines: 1,
                    softWrap: false,
                    style: _style(
                      context,
                      12,
                      _Fig.sectionTitleWeight,
                      const Color(0xFF000000),
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: context.referW(10), vertical: context.referH(8)),
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

class _DottedBox extends StatelessWidget {
  const _DottedBox({required this.child, required this.radius});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedRRectPainter(
        color: _Fig.orange,
        radius: context.referR(radius),
        dotSize: context.referR(1.3),
        spacing: context.referR(3.0),
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
