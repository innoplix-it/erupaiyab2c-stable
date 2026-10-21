// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../widgets/my_app_bar.dart';
import '../components/refer_help_icon_button.dart';
import '../components/referral_share_actions.dart';
import '../repositories/referral_milestones_repository.dart';

// Figma frame is 440×956; ScreenUtil design size is 360×690. Convert once,
// then let ScreenUtil scale once.
double _figmaW(double px) => (px * 360 / 440).w;
double _figmaH(double px) => (px * 690 / 956).h;
double _figmaR(double px) => (px * 360 / 440).r;
double _figmaSp(double px) => (px * 360 / 440).sp;

const Color _kOrange = Color(0xFFE85427);
const Color _kTimeline = Color(0xFFF5C4B0);
const Color _kCardBorder = Color(0xFFE8E8E8);
const Color _kTrack = Color(0xFFE8E8E8);
const Color _kPillGreenBg = Color(0xFFE6F6EC);
const Color _kPillGreenText = Color(0xFF058337);
const Color _kPillGreyBg = Color(0xFFF0F0F0);
const Color _kPillGreyText = Color(0xFF8A8A8A);

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
      // Common MyAppBar title text (16 / w700 / letterSpacing 0.15 / height 1.5).
      // Same Figma `?` glyph as dark Refer & Earn headers (tinted black here).
      appBar: const MyAppBar(
        title: 'Referral Milestone',
        showBharatConnect: false,
        showHelp: false,
        fitTitle: true,
        trailing: ReferHelpIconButton(color: Color(0xFF000000)),
      ),
      // Shared fixed WhatsApp + Share footer used across Refer & Earn screens.
      bottomNavigationBar: const ReferralShareFooter(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final media = MediaQuery.of(context);
          final side = media.size.width < 360 ? _figmaW(16) : _figmaW(20);
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              side,
              _figmaH(16),
              side,
              _figmaH(24) + media.padding.bottom,
            ),
            child: _buildContent(context, snapshot),
          );
        },
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
    required this.statusLabel,
    required this.completed,
  });

  final String title;
  final String reward;
  final double progress;
  final String completedText;
  final String statusLabel;
  final bool completed;
}

/// Figma intro: left-aligned, wraps naturally into two lines at design width.
class _IntroText extends StatelessWidget {
  const _IntroText();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Complete referral milestones and unlock bonus eCoins.',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF000000),
            fontWeight: FontWeight.w500,
            fontSize: _figmaSp(16),
            height: 1.45,
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
    return Padding(
      padding: EdgeInsets.only(top: _figmaH(80)),
      child: const Center(
        child: SpinKitCircle(
          color: AppColors.primary,
          size: 48,
        ),
      ),
    );
  }
  if (snapshot.hasError) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _IntroText(),
        SizedBox(height: _figmaH(12)),
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
      SizedBox(height: _figmaH(20)),
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
  final progress =
      target > 0 ? (current / target).clamp(0.0, 1.0).toDouble() : 0.0;
  final rewardText = item.reward.trim();
  final completedText = item.progressText.trim().isNotEmpty
      ? item.progressText.trim()
      : '$current / $target Completed';
  final percent = (progress * 100).round();
  final statusLabel = item.completed ? 'Completed' : '$percent% Complete';
  return _MilestoneItem(
    title: item.title,
    reward: rewardText,
    progress: progress,
    completedText: completedText,
    statusLabel: statusLabel,
    completed: item.completed,
  );
}

class _MilestonesTimeline extends StatelessWidget {
  const _MilestonesTimeline({required this.items});

  final List<_MilestoneItem> items;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenW = media.size.width;
    // Figma peach rail ≈ 7px on 440 frame (measured vs 30px coin node).
    // Scale with ScreenUtil; slight bump on very narrow phones for visibility.
    final lineWidth =
        (screenW < 340 ? _figmaW(6.5) : _figmaW(7)).clamp(5.0, 8.0);
    final railWidth = _figmaW(30);

    return Column(
      children: List.generate(items.length, (index) {
        final isLast = index == items.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: railWidth,
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Container(
                          width: lineWidth,
                          color: index == 0 ? Colors.transparent : _kTimeline,
                        ),
                      ),
                    ),
                    _TimelineNode(
                      ringKey: ValueKey('milestone-ring-$index'),
                    ),
                    Expanded(
                      child: Center(
                        child: Container(
                          width: lineWidth,
                          color: isLast ? Colors.transparent : _kTimeline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: _figmaW(12)),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : _figmaH(14)),
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

class _TimelineNode extends StatelessWidget {
  const _TimelineNode({this.ringKey});

  final Key? ringKey;

  @override
  Widget build(BuildContext context) {
    final size = _figmaW(30);
    return Container(
      key: ringKey,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: _kOrange, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: _figmaR(6),
            offset: Offset(0, _figmaH(2)),
          ),
        ],
      ),
      child: Center(
        child: Image.asset(
          FileConstants.coinRupeeSmall,
          width: size * 0.55,
          height: size * 0.55,
        ),
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.item});

  final _MilestoneItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        _figmaW(14),
        _figmaH(14),
        _figmaW(14),
        _figmaH(14),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_figmaR(14)),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF000000),
                        fontWeight: FontWeight.w700,
                        fontSize: _figmaSp(15),
                        height: 1.2,
                        letterSpacing: 0,
                      ),
                ),
              ),
              SizedBox(width: _figmaW(8)),
              Image.asset(
                FileConstants.coinRupeeSmall,
                width: _figmaW(21),
                height: _figmaH(20),
              ),
              if (item.reward.isNotEmpty) ...[
                SizedBox(width: _figmaW(4)),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: _figmaW(120)),
                  child: Text(
                    item.reward,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF000000),
                          fontWeight: FontWeight.w500,
                          fontSize: _figmaSp(13),
                          height: 1.0,
                          letterSpacing: 0,
                        ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: _figmaH(12)),
          _MilestoneProgressBar(progress: item.progress),
          SizedBox(height: _figmaH(10)),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.completedText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _kOrange,
                        fontWeight: FontWeight.w500,
                        fontSize: _figmaSp(13),
                        height: 1.2,
                        letterSpacing: 0,
                      ),
                ),
              ),
              SizedBox(width: _figmaW(8)),
              _StatusPill(
                label: item.statusLabel,
                completed: item.completed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Rounded progress track with Figma orange fill. When progress is zero,
/// a small orange starting indicator sits at the leading edge.
class _MilestoneProgressBar extends StatelessWidget {
  const _MilestoneProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final height = _figmaH(8);
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final fill = (progress.clamp(0.0, 1.0) * width);
          final showStartDot = progress <= 0;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: _kTrack,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              if (fill > 0)
                Container(
                  width: fill,
                  height: height,
                  decoration: BoxDecoration(
                    color: _kOrange,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              if (showStartDot)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: height,
                    height: height,
                    decoration: const BoxDecoration(
                      color: _kOrange,
                      shape: BoxShape.circle,
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.completed,
  });

  final String label;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _figmaW(10),
        vertical: _figmaH(5),
      ),
      decoration: BoxDecoration(
        color: completed ? _kPillGreenBg : _kPillGreyBg,
        borderRadius: BorderRadius.circular(_figmaR(8)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: completed ? _kPillGreenText : _kPillGreyText,
              fontWeight: FontWeight.w600,
              fontSize: _figmaSp(11),
              height: 1.1,
              letterSpacing: 0,
            ),
      ),
    );
  }
}
