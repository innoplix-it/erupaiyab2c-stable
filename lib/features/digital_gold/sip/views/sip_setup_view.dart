// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/file_constants.dart';
import '../../../../constants/routes_constant.dart';
import '../../../../widgets/custom_elevated_button.dart';
import '../../components/digital_gold_title_live_bar.dart';
import '../components/sip_segmented_control.dart';
import '../models/sip_draft.dart';
import '../models/sip_frequency.dart';
import '../models/sip_unit.dart';

class DigitalGoldSipSetupView extends HookConsumerWidget {
  const DigitalGoldSipSetupView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const background = Color(0xFFFFFAF2);
    const accent = Color(0xFFE85A2C);
    const headerHeight = 280.0;

    final draft = useState(
      const SipDraft(
        isSip: true,
        frequency: SipFrequency.daily,
        unit: SipUnit.rupees,
        amount: 25,
        agreedToTerms: false,
        investInBoth: false,
        goldSplitPercent: 20,
        weeklyDay: 1,
        monthlyDay: 1,
      ),
    );

    double roundToStep(double value, double step) {
      if (step <= 0) return value;
      return (value / step).round() * step;
    }

    final isSip = draft.value.isSip;
    final effectiveUnit = isSip ? SipUnit.rupees : draft.value.unit;
    final sliderStep = effectiveUnit == SipUnit.rupees ? 25.0 : 0.1;
    final sliderMax = effectiveUnit == SipUnit.rupees ? 30000.0 : 100.0;
    final sliderDivisions = (sliderMax / sliderStep).round();

    void setAmount(double next) {
      final clamped = next.clamp(0.0, sliderMax);
      final stepped = roundToStep(clamped, sliderStep);
      draft.value = draft.value.copyWith(amount: stepped);
    }

    final amountText = effectiveUnit == SipUnit.rupees
        ? '₹${draft.value.amount.toStringAsFixed(0)}'
        : '${draft.value.amount.toStringAsFixed(1)}gm';

    String weekdayLabel(int day) {
      const names = <String>[
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final idx = (day - 1).clamp(0, 6);
      return names[idx];
    }

    String ordinal(int value) {
      final v = value.abs();
      if (v % 100 >= 11 && v % 100 <= 13) return '${value}th';
      switch (v % 10) {
        case 1:
          return '${value}st';
        case 2:
          return '${value}nd';
        case 3:
          return '${value}rd';
        default:
          return '${value}th';
      }
    }

    Future<void> pickWeeklyDay() async {
      final picked = await showModalBottomSheet<int>(
        context: context,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
        ),
        builder: (context) {
          return SafeArea(
            top: false,
            child: ListView(
              shrinkWrap: true,
              children: [
                SizedBox(height: 10.h),
                Center(
                  child: Container(
                    width: 36.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                for (int i = 1; i <= 7; i++)
                  ListTile(
                    title: Text(
                      weekdayLabel(i),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    trailing: i == draft.value.weeklyDay
                        ? const Icon(Icons.check, color: accent)
                        : null,
                    onTap: () => Navigator.of(context).pop(i),
                  ),
              ],
            ),
          );
        },
      );
      if (picked == null) return;
      draft.value = draft.value.copyWith(weeklyDay: picked);
    }

    Future<void> pickMonthlyDay() async {
      final picked = await showModalBottomSheet<int>(
        context: context,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
        ),
        builder: (context) {
          return SafeArea(
            top: false,
            child: ListView(
              shrinkWrap: true,
              children: [
                SizedBox(height: 10.h),
                Center(
                  child: Container(
                    width: 36.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                for (int i = 1; i <= 28; i++)
                  ListTile(
                    title: Text(
                      ordinal(i),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    trailing: i == draft.value.monthlyDay
                        ? const Icon(Icons.check, color: accent)
                        : null,
                    onTap: () => Navigator.of(context).pop(i),
                  ),
              ],
            ),
          );
        },
      );
      if (picked == null) return;
      draft.value = draft.value.copyWith(monthlyDay: picked);
    }

    final payLabel = isSip ? 'Setup Autopay' : 'Proceed';

    return Scaffold(
      backgroundColor: background,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(bottom: 190.h),
              primary: false,
              children: [
                SizedBox(
                  height: headerHeight.h + 26.h,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        top: 14.h,
                        child: const _SipBgHeader(height: headerHeight),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        child: SafeArea(
                          bottom: false,
                          child: DigitalGoldTitleLiveBar(
                            title: 'SIP',
                            rateText: '16,144.25/gm',
                            onBack: () => context.pop(),
                            onHelp: () {},
                            chipLeading: Image.asset(
                              FileConstants.liveSignal,
                              width: 12.r,
                              height: 12.r,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: -26.h,
                        child: Center(
                          child: Container(
                            width: 240.w,
                            padding: EdgeInsets.all(4.r),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.06),
                                  blurRadius: 18.r,
                                  offset: Offset(0.w, 10.h),
                                ),
                              ],
                            ),
                            child: SipSegmentedControl<bool>(
                              value: isSip,
                              items: const [
                                SipSegmentItem(value: true, label: 'Gold SIP'),
                                SipSegmentItem(value: false, label: 'One Time'),
                              ],
                              onChanged: (v) =>
                                  draft.value = draft.value.copyWith(
                                isSip: v,
                                unit: v ? SipUnit.rupees : draft.value.unit,
                              ),
                              activeColor: accent,
                              inactiveColor: const Color(0xFFF3F4F6),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    children: [
                      SizedBox(height: 30.h),
                      if (!isSip) ...[
                        Center(
                          child: SizedBox(width: 280.w,
                            child: SipSegmentedControl<SipUnit>(
                              value: effectiveUnit,
                              items: const [
                                SipSegmentItem(
                                    value: SipUnit.rupees, label: 'In Rupees'),
                                SipSegmentItem(
                                    value: SipUnit.grams, label: 'In Grams'),
                              ],
                              onChanged: (v) =>
                                  draft.value = draft.value.copyWith(unit: v),
                              activeColor: accent,
                              inactiveColor: const Color(0xFFF3F4F6),
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),
                      ] else ...[
                        SizedBox(height: 8.h),
                      ],
                      if (isSip) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final f in SipFrequency.values) ...[
                              _Chip(
                                label: f.label,
                                selected: draft.value.frequency == f,
                                onTap: () => draft.value =
                                    draft.value.copyWith(frequency: f),
                              ),
                              if (f != SipFrequency.monthly)
                                SizedBox(width: 10.w),
                            ],
                          ],
                        ),
                        SizedBox(height: 14.h),
                      ],
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: const Color(0xffF2F2F2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: draft.value.investInBoth,
                              onChanged: (v) => draft.value = draft.value
                                  .copyWith(investInBoth: v ?? false),
                              activeColor: accent,
                              side: const BorderSide(
                                  color: AppColors.lightBorder),
                            ),
                            Expanded(
                              child: Text(
                                'Invest in both gold and silver automatically.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black.withOpacity(0.75),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSip &&
                          (draft.value.frequency == SipFrequency.weekly ||
                              draft.value.frequency ==
                                  SipFrequency.monthly)) ...[
                        SizedBox(height: 10.h),
                        Center(
                          child: GestureDetector(
                            onTap: draft.value.frequency == SipFrequency.weekly
                                ? pickWeeklyDay
                                : pickMonthlyDay,
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  draft.value.frequency == SipFrequency.weekly
                                      ? 'On Every '
                                      : 'On Every ',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black.withOpacity(0.55),
                                      ),
                                ),
                                Text(
                                  draft.value.frequency == SipFrequency.weekly
                                      ? weekdayLabel(draft.value.weeklyDay)
                                      : ordinal(draft.value.monthlyDay),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: accent,
                                      ),
                                ),
                                SizedBox(width: 6.w),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.black.withOpacity(0.55),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (draft.value.investInBoth) ...[
                        SizedBox(height: 14.h),
                        _GoldSilverSplit(
                          goldPercent: draft.value.goldSplitPercent,
                          onChanged: (v) => draft.value =
                              draft.value.copyWith(goldSplitPercent: v),
                        ),
                      ],
                      SizedBox(height: 18.h),
                      Row(
                        children: [
                          _RoundIconButton(
                            icon: Icons.remove,
                            enabled: draft.value.amount > 0,
                            onTap: () =>
                                setAmount(draft.value.amount - sliderStep),
                          ),
                          Expanded(
                            child: Text(
                              amountText,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                            ),
                          ),
                          _RoundIconButton(
                            icon: Icons.add,
                            enabled: true,
                            onTap: () =>
                                setAmount(draft.value.amount + sliderStep),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: accent,
                          inactiveTrackColor: Colors.black.withOpacity(0.08),
                          trackHeight: 4.h,
                          thumbColor: accent,
                          overlayColor: accent.withOpacity(0.12),
                          thumbShape:
                              RoundSliderThumbShape(enabledThumbRadius: 10.r),
                        ),
                        child: Slider(
                          value: draft.value.amount.clamp(0, sliderMax),
                          min: 0,
                          max: sliderMax,
                          divisions: sliderDivisions,
                          onChanged: (v) => setAmount(v),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: background,
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: draft.value.agreedToTerms,
                    activeColor: accent,
                    onChanged: (v) => draft.value =
                        draft.value.copyWith(agreedToTerms: v ?? false),
                    side: const BorderSide(color: AppColors.lightBorder),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black.withOpacity(0.6),
                              fontWeight: FontWeight.w800,
                            ),
                        children: const [
                          TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Terms & Conditions',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Container(
                    width: 40.r,
                    height: 40.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: AppColors.lightBorder),
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: accent),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: CustomElevatedButton(
                      onPressed: draft.value.agreedToTerms
                          ? () => context
                              .push(RouteConstants.digitalGoldSipPortfolio)
                          : null,
                      label: payLabel,
                      uppercaseLabel: false,
                      height: 40.h,
                      backgroundColor: accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SipBgHeader extends StatelessWidget {
  const _SipBgHeader({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18.r),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(FileConstants.sipBg, fit: BoxFit.cover),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                SizedBox(height: 28.h),
                Text(
                  'Approx Return In 5 Years',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black.withOpacity(0.55),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                SizedBox(height: 10.h),
                Text(
                  '₹54,000',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.only(bottom: 30.h),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Divider(color: Color(0xFFF2B9A7), thickness: 1),
                      ),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 12.w),
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 9.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(999.r),
                          border: Border.all(
                            color: AppColors.lightBorder.withOpacity(0.6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Investment: ₹32,000',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black.withOpacity(0.7),
                                  ),
                            ),
                            SizedBox(width: 14.w),
                            Text(
                              'Earnings: ₹22,000',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF0B8A3B),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const Expanded(
                        child: Divider(color: Color(0xFFF2B9A7), thickness: 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldSilverSplit extends StatelessWidget {
  const _GoldSilverSplit({
    required this.goldPercent,
    required this.onChanged,
  });

  final double goldPercent;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeGold = goldPercent.clamp(0.0, 100.0);
    final silverPercent = 100 - safeGold;

    double positionToPercent(Offset local, Size size) {
      final center = Offset(size.width / 2, size.height / 2);
      final v = local - center;
      var angle = math.atan2(v.dy, v.dx);
      angle = angle + (math.pi / 2);
      if (angle < 0) angle += math.pi * 2;
      final normalized = (angle % (math.pi * 2)) / (math.pi * 2);
      return (normalized * 100).clamp(0.0, 100.0);
    }

    Widget coin({
      required double percent,
      required Color activeRing,
      required String asset,
      VoidCallback? onPan,
      ValueChanged<double>? onSetPercent,
    }) {
      final size = 78.r;
      final inner = size - 14.r;
      return GestureDetector(
        onPanDown: onSetPercent == null
            ? null
            : (details) {
                onSetPercent(
                  positionToPercent(details.localPosition, Size(size, size)),
                );
              },
        onPanUpdate: onSetPercent == null
            ? null
            : (details) {
                onSetPercent(
                  positionToPercent(details.localPosition, Size(size, size)),
                );
              },
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _SplitRingPainter(
                  percent: percent,
                  activeColor: activeRing,
                  inactiveColor: const Color(0xFFE5E7EB),
                  strokeWidth: 6.r,
                ),
              ),
              Container(
                width: inner,
                height: inner,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                padding: EdgeInsets.all(1.r),
                child: ClipOval(
                  child: Image.asset(
                    asset,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Text(
                '${percent.round()}%',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            coin(
              percent: safeGold,
              activeRing: const Color(0xFFE8C14A),
              asset: FileConstants.goldCoin,
              onSetPercent: (v) => onChanged(v),
            ),
            SizedBox(width: 12.w),
            Text(
              '+',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.black.withOpacity(0.45),
                  ),
            ),
            SizedBox(width: 12.w),
            coin(
              percent: silverPercent,
              activeRing: const Color(0xFF9CA3AF),
              asset: FileConstants.silverCoin,
            ),
          ],
        ),
      ],
    );
  }
}

class _SplitRingPainter extends CustomPainter {
  const _SplitRingPainter({
    required this.percent,
    required this.activeColor,
    required this.inactiveColor,
    required this.strokeWidth,
  });

  final double percent;
  final Color activeColor;
  final Color inactiveColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = strokeWidth / 2;
    final arcRect = Rect.fromLTWH(
      rect.left + inset,
      rect.top + inset,
      rect.width - strokeWidth,
      rect.height - strokeWidth,
    );

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = inactiveColor;
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2, false, basePaint);

    final sweep = (math.pi * 2) * (percent.clamp(0.0, 100.0) / 100.0);
    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = activeColor;
    canvas.drawArc(arcRect, -math.pi / 2, sweep, false, activePaint);
  }

  @override
  bool shouldRepaint(covariant _SplitRingPainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999.r),
      child: Container(
        width: 44.r,
        height: 44.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? const Color(0xFFFDE7DE) : const Color(0xFFF3F4F6),
          border: Border.all(color: AppColors.lightBorder.withOpacity(0.7)),
        ),
        child: Icon(
          icon,
          color: enabled ? const Color(0xFFE85A2C) : Colors.black26,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFDE7DE) : Colors.white,
          borderRadius: BorderRadius.circular(999.r),
          border: Border.all(
            color: selected ? const Color(0xFFE85A2C) : AppColors.lightBorder,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selected ? const Color(0xFFE85A2C) : Colors.black54,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}
