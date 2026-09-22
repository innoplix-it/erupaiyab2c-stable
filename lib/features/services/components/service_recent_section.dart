import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/app_network_image.dart';
import '../../mobile_prepaid/components/recharge_quick_action_card.dart';
import '../../mobile_prepaid/models/latest_transaction.dart';

class ServiceRecentSection extends StatelessWidget {
  const ServiceRecentSection({
    super.key,
    required this.recentTransactions,
    required this.onPayNow,
    this.title = 'Recent',
    this.actionText = 'View all',
    this.onAction,
    this.savedBillersStyle = false,
  });

  final AsyncValue<List<LatestTransaction>> recentTransactions;
  final ValueChanged<LatestTransaction> onPayNow;
  final String title;
  final String actionText;
  final VoidCallback? onAction;
  final bool savedBillersStyle;

  @override
  Widget build(BuildContext context) {
    final sectionBottom = savedBillersStyle ? 0.0 : 16.h;
    final headerGap = savedBillersStyle ? 12.h : 10.h;
    return recentTransactions.when(
      loading: () => Padding(
        padding: EdgeInsets.only(bottom: sectionBottom),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0.h),
              child: _SectionHeader(
                title: title,
                actionText: actionText,
                onAction: onAction,
                savedBillersStyle: savedBillersStyle,
              ),
            ),
            SizedBox(height: headerGap),
            _RecentRow(
              recentTransactions: recentTransactions,
              onPayNow: onPayNow,
              savedBillersStyle: savedBillersStyle,
            ),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.only(bottom: sectionBottom),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0.h),
                child: _SectionHeader(
                  title: title,
                  actionText: actionText,
                  onAction: onAction,
                  savedBillersStyle: savedBillersStyle,
                ),
              ),
              SizedBox(height: headerGap),
              _RecentRow(
                recentTransactions: AsyncValue.data(items),
                onPayNow: onPayNow,
                savedBillersStyle: savedBillersStyle,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionText,
    required this.onAction,
    this.savedBillersStyle = false,
  });

  final String title;
  final String actionText;
  final VoidCallback? onAction;
  final bool savedBillersStyle;

  @override
  Widget build(BuildContext context) {
    final titleStyle = savedBillersStyle
        ? GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 18.sp,
            height: 1,
            letterSpacing: -0.02 * 18.sp,
            color: const Color(0xFF000000),
          )
        : Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            );
    final actionStyle = savedBillersStyle
        ? GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w500,
            fontSize: 16.sp,
            height: 1,
            letterSpacing: 0,
            color: const Color(0xFFDD5428),
            decoration: TextDecoration.underline,
            decorationColor: const Color(0xFFDD5428),
            decorationThickness: 1,
          )
        : Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFE85A2C),
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
            );

    final titleText = Text(
      savedBillersStyle ? _capitalizeWords(title) : title,
      maxLines: 1,
      overflow: TextOverflow.visible,
      style: titleStyle,
    );
    final actionLabel = Text(
      actionText,
      textAlign: TextAlign.right,
      maxLines: 1,
      overflow: TextOverflow.visible,
      style: actionStyle,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (savedBillersStyle)
          SizedBox(width: 106.w,
            height: 23.h,
            child: Align(
              alignment: Alignment.centerLeft,
              child: titleText,
            ),
          )
        else
          titleText,
        const Spacer(),
        if (actionText.trim().isNotEmpty &&
            (savedBillersStyle || onAction != null))
          InkWell(
            onTap: onAction,
            child: savedBillersStyle
                ? SizedBox(width: 58.w,
                    height: 20.h,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: actionLabel,
                    ),
                  )
                : actionLabel,
          ),
      ],
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.recentTransactions,
    required this.onPayNow,
    this.savedBillersStyle = false,
  });

  final AsyncValue<List<LatestTransaction>> recentTransactions;
  final ValueChanged<LatestTransaction> onPayNow;
  final bool savedBillersStyle;

  @override
  Widget build(BuildContext context) {
    return recentTransactions.when(
      loading: () => SizedBox(height: 126.h,
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 10.h),
          clipBehavior: Clip.none,
          scrollDirection: Axis.horizontal,
          itemCount: 2,
          separatorBuilder: (_, __) => SizedBox(width: 12.w),
          itemBuilder: (_, __) => const _RecentCardShimmer(),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final display = items.take(10).toList();
        if (savedBillersStyle) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: EdgeInsets.fromLTRB(16.w, 0.h, 16.w, 8.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < display.length; index++) ...[
                  if (index > 0) SizedBox(width: 12.w),
                  _SavedBillerCard(
                    txn: display[index],
                    onPayNow: () => onPayNow(display[index]),
                  ),
                ],
              ],
            ),
          );
        }
        return SizedBox(height: 126.h,
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 10.h),
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            itemCount: display.length,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (context, index) => _RecentCard(
              txn: display[index],
              onPayNow: () => onPayNow(display[index]),
            ),
          ),
        );
      },
    );
  }
}

class _RecentCardShimmer extends StatelessWidget {
  const _RecentCardShimmer();

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: 280.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 12.r,
              offset: Offset(0.w, 6.h),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(14.w),
              child: Row(
                children: [
                  Container(
                    height: 38.w,
                    width: 38.w,
                    decoration: BoxDecoration(
                      color: AppColors.lightBorder.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 12.h,
                          width: 160.w,
                          decoration: BoxDecoration(
                            color:
                                AppColors.lightBorder.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          height: 10.h,
                          width: 110.w,
                          decoration: BoxDecoration(
                            color:
                                AppColors.lightBorder.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Container(
                    height: 18.h,
                    width: 18.h,
                    decoration: BoxDecoration(
                      color: AppColors.lightBorder.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
                height: 1, color: AppColors.lightBorder.withValues(alpha: 0.7)),
            Padding(
              padding: EdgeInsets.all(14.w),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16.h,
                          width: 120.w,
                          decoration: BoxDecoration(
                            color:
                                AppColors.lightBorder.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Container(
                          height: 10.h,
                          width: 130.w,
                          decoration: BoxDecoration(
                            color:
                                AppColors.lightBorder.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Container(
                    height: 30.h,
                    width: 78.w,
                    decoration: BoxDecoration(
                      color: AppColors.lightBorder.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(22.r),
                    ),
                  ),
                ],
              ),
            ),
            // Prevent tiny RenderFlex overflow due to fractional dp rounding.
            SizedBox(height: 1.h),
          ],
        ),
      ),
    );
  }
}


class _SavedBillerCard extends StatelessWidget {
  const _SavedBillerCard({
    required this.txn,
    required this.onPayNow,
  });

  final LatestTransaction txn;
  final VoidCallback onPayNow;

  @override
  Widget build(BuildContext context) {
    final billerTitle = txn.billerName.trim();
    final customerName = _capitalizeWords(txn.customerName.trim());
    final consumerNo = (txn.serviceNoFull ?? txn.serviceNo).trim();
    final lastPaid = _formatWasPaidOn(txn);

    return GestureDetector(
      onTap: onPayNow,
      child: Container(
        width: 328.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFE2E2E2), width: 1.w),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 12.r,
              offset: Offset(0, 6.h),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 10.h, 8.w, 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SimCardIconContainer(
                    url: txn.icon.trim().isEmpty ? null : txn.icon.trim(),
                    width: 42.w,
                    height: 38.h,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 18.h,
                          child: Text(
                            billerTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                              height: 1,
                              letterSpacing: -0.02 * 14.sp,
                              color: const Color(0xFF000000),
                            ),
                          ),
                        ),
                        if (customerName.isNotEmpty ||
                            consumerNo.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          SizedBox(height: 15.h,
                            child: Row(
                              children: [
                                if (customerName.isNotEmpty)
                                  Flexible(
                                    child: Text(
                                      customerName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12.sp,
                                        height: 1,
                                        letterSpacing: -0.02 * 12.sp,
                                        color: const Color(0xFF696969),
                                      ),
                                    ),
                                  ),
                                if (customerName.isNotEmpty &&
                                    consumerNo.isNotEmpty)
                                  Text(
                                    '  •  ',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12.sp,
                                      height: 1,
                                      color: const Color(0xFF696969),
                                    ),
                                  ),
                                if (consumerNo.isNotEmpty)
                                  Flexible(
                                    child: Text(
                                      consumerNo,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12.sp,
                                        height: 1,
                                        letterSpacing: -0.02 * 12.sp,
                                        color: const Color(0xFF696969),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    child: const _VerticalDots(),
                    onSelected: (value) {
                      if (value == 'pay') onPayNow();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(
                        value: 'pay',
                        child: Text('Pay Now'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(
              height: 1.h,
              thickness: 1.h,
              color: AppColors.lightBorder.withValues(alpha: 0.7),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 15.h,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'AutoPay Active',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 12.sp,
                                height: 1,
                                letterSpacing: -0.02 * 12.sp,
                                color: const Color(0xFFDD5428),
                              ),
                            ),
                          ),
                        ),
                        if (lastPaid.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          SizedBox(height: 14.h,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                lastPaid,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11.sp,
                                  height: 1,
                                  letterSpacing: -0.02 * 11.sp,
                                  color: const Color(0xFF000000),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  const _AutoPayBadge(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AutoPayBadge extends StatelessWidget {
  const _AutoPayBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 25.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF058337),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bolt,
            size: 12.sp,
            color: const Color(0xFFFFFFFF),
          ),
          SizedBox(width: 4.w),
          Text(
            'AutoPay',
            maxLines: 1,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 10.sp,
              height: 1,
              letterSpacing: -0.02 * 10.sp,
              color: const Color(0xFFFFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDots extends StatelessWidget {
  const _VerticalDots();

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 16.w,
      height: 14.17.h,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List<Widget>.generate(
          3,
          (_) => Container(
            width: 2.5.w,
            height: 2.5.w,
            decoration: const BoxDecoration(
              color: Color(0xFF000000),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

String _capitalizeWords(String value) {
  return value
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) =>
          '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
      .join(' ');
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.txn, required this.onPayNow});

  final LatestTransaction txn;
  final VoidCallback onPayNow;

  @override
  Widget build(BuildContext context) {
    final title = txn.billerName.trim();
    final serviceNo = txn.serviceNo.trim();
    final amount = txn.amount;
    final dueLabel = _formatDueDate(txn.dueDate);

    return Container(
      width: 280.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12.r,
            offset: Offset(0.w, 6.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(13.w),
            child: Row(
              children: [
                Container(
                  height: 38.w,
                  width: 38.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: Colors.black.withValues(alpha: 0.08)),
                  ),
                  child: ClipOval(
                    child: txn.icon.trim().isEmpty
                        ? Icon(
                            Icons.bolt,
                            size: 18.sp,
                            color: AppColors.primary,
                          )
                        : AppNetworkImage(
                            url: txn.icon,
                            fit: BoxFit.contain,
                            showShimmer: false,
                          ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        serviceNo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  AppColors.textPrimary.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.more_vert,
                  color: AppColors.textPrimary.withValues(alpha: 0.45),
                ),
              ],
            ),
          ),
          Divider(
              height: 1, color: AppColors.lightBorder.withValues(alpha: 0.7)),
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${amount.toStringAsFixed(2)}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                      ),
                      if (dueLabel.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          dueLabel,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.red.shade600,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                SizedBox(height: 30.h,
                  child: ElevatedButton(
                    onPressed: onPayNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE85A2C),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(horizontal: 18.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22.r),
                      ),
                    ),
                    child: Text(
                      'Pay Now',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
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

String _formatWasPaidOn(LatestTransaction txn) {
  final raw = (txn.transactionTime ?? txn.createdAt ?? '').trim();
  if (raw.isEmpty) return '';
  final parsed = DateTime.tryParse(raw);
  final amountText = '₹${txn.amount.toStringAsFixed(2)}';
  if (parsed == null) return '$amountText Was Paid On $raw';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sept',
    'Oct',
    'Nov',
    'Dec',
  ];
  final day = parsed.day;
  final suffix = (day >= 11 && day <= 13)
      ? 'th'
      : switch (day % 10) {
          1 => 'st',
          2 => 'nd',
          3 => 'rd',
          _ => 'th',
        };
  return '$amountText Was Paid On $day$suffix ${months[parsed.month - 1]} ${parsed.year}';
}

String _formatDueDate(String? raw) {
  final value = (raw ?? '').trim();
  if (value.isEmpty || value.toLowerCase() == 'null') return '';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return 'Due On $value';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  final m = months[parsed.month - 1];
  return 'Due On ${parsed.day} $m ${parsed.year}';
}

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});

  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = _controller.value * 3 - 1;
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              colors: [
                AppColors.lightBorder.withValues(alpha: 0.2),
                AppColors.lightBorder.withValues(alpha: 0.6),
                AppColors.lightBorder.withValues(alpha: 0.2),
              ],
              stops: const [0.25, 0.5, 0.75],
              begin: const Alignment(-1, -0.3),
              end: const Alignment(1, 0.3),
              transform: _SlidingGradientTransform(value),
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
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
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}
