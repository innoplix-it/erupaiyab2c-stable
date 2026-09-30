import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:go_router/go_router.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/app_snackbar.dart';
import '../../mobile_prepaid/components/recharge_quick_action_card.dart';
import '../../mobile_prepaid/models/latest_transaction.dart';
import 'fetch_provider_metrics.dart';

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
    final sideInset = savedBillersStyle ? FetchProviderMetrics.w(24) : 16.w;
    if (savedBillersStyle) {
      // The Saved Billers heading and "View all" stay visible whatever the
      // data state; only the card row depends on having saved billers.
      final items = recentTransactions.valueOrNull ?? const [];
      final showRow = recentTransactions.isLoading || items.isNotEmpty;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(sideInset, 16.h, sideInset, 0),
            child: _SectionHeader(
              title: title,
              actionText: actionText,
              onAction: onAction,
              savedBillersStyle: true,
            ),
          ),
          SizedBox(height: headerGap),
          if (showRow)
            _RecentRow(
              recentTransactions: recentTransactions.isLoading
                  ? recentTransactions
                  : AsyncValue.data(items),
              onPayNow: onPayNow,
              savedBillersStyle: true,
            ),
        ],
      );
    }
    return recentTransactions.when(
      loading: () => Padding(
        padding: EdgeInsets.only(bottom: sectionBottom),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(sideInset, 16.h, sideInset, 0.h),
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
                padding: EdgeInsets.fromLTRB(sideInset, 16.h, sideInset, 0.h),
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
            fontSize: 13.sp,
            height: 1,
            letterSpacing: -0.02 * 13.sp,
            color: const Color(0xFF000000),
          )
        : Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            );
    final actionStyle = savedBillersStyle
        ? GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w500,
            fontSize: 13.sp,
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
        // Expanded (not Flexible + Spacer, which split the free space in
        // half) so "View all" always sits flush with the right inset.
        if (savedBillersStyle)
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: titleText,
              ),
            ),
          )
        else ...[
          titleText,
          const Spacer(),
        ],
        if (savedBillersStyle) SizedBox(width: 12.w),
        if (actionText.trim().isNotEmpty &&
            (savedBillersStyle || onAction != null))
          InkWell(
            onTap: onAction,
            child: actionLabel,
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

  Widget _savedBillersRow(List<Widget> cards) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      padding: EdgeInsets.fromLTRB(
        FetchProviderMetrics.w(24),
        0,
        FetchProviderMetrics.w(24),
        8.h,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < cards.length; index++) ...[
            if (index > 0) SizedBox(width: 12.w),
            cards[index],
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (savedBillersStyle && recentTransactions.isLoading) {
      return _savedBillersRow(
        const [_SavedBillerCardShimmer(), _SavedBillerCardShimmer()],
      );
    }
    return recentTransactions.when(
      loading: () => SizedBox(
        height: 126.h,
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
          return _savedBillersRow([
            for (final txn in display)
              _SavedBillerCard(txn: txn, onPayNow: () => onPayNow(txn)),
          ]);
        }
        return SizedBox(
          height: 126.h,
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

class _SavedBillerCardShimmer extends StatelessWidget {
  const _SavedBillerCardShimmer();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final fill = AppColors.lightBorder.withValues(alpha: 0.25);
    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(FetchProviderMetrics.r(8)),
          ),
        );
    return _Shimmer(
      child: Container(
        width: _SavedBillerCard.cardWidth(screenWidth),
        height: FetchProviderMetrics.h(131),
        padding: EdgeInsets.symmetric(horizontal: FetchProviderMetrics.w(16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(FetchProviderMetrics.r(16)),
          border: Border.all(color: const Color(0xFFE2E2E2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              children: [
                Container(
                  width: FetchProviderMetrics.r(40),
                  height: FetchProviderMetrics.r(40),
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius:
                        BorderRadius.circular(FetchProviderMetrics.r(12)),
                  ),
                ),
                SizedBox(width: FetchProviderMetrics.w(10)),
                Flexible(
                  child: bar(
                      FetchProviderMetrics.w(180), FetchProviderMetrics.h(12)),
                ),
              ],
            ),
            bar(FetchProviderMetrics.w(200), FetchProviderMetrics.h(12)),
          ],
        ),
      ),
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

  /// Narrow phones get a wider share of the screen so the title isn't cut
  /// too early; elsewhere the card keeps Figma's 325/440 width ratio.
  static double cardWidth(double screenWidth) =>
      screenWidth < 360 ? screenWidth * 0.8 : FetchProviderMetrics.w(325);

  @override
  Widget build(BuildContext context) {
    final billerTitle = txn.billerName.trim();
    final customerName = _capitalizeWords(txn.customerName.trim());
    final consumerNo = (txn.serviceNoFull ?? txn.serviceNo).trim();
    final lastPaid = _formatWasPaidOn(txn);

    final cardWidth = _SavedBillerCard.cardWidth(
      MediaQuery.sizeOf(context).width,
    );
    final titleSize = FetchProviderMetrics.font(14, min: 11);
    final bodySize = FetchProviderMetrics.font(12, min: 10);
    final subtitleStyle = GoogleFonts.plusJakartaSans(
      fontWeight: FontWeight.w500,
      fontSize: bodySize,
      height: 1.2,
      letterSpacing: -0.02 * bodySize,
      color: const Color(0xFF696969),
    );

    return GestureDetector(
      onTap: onPayNow,
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(FetchProviderMetrics.r(16)),
          border: Border.all(color: const Color(0xFFE2E2E2), width: 1),
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
            // Minimum heights (68 + 1 + 62 = 131 on the Figma frame, less the
            // 1px border on each edge) let the rows grow with larger text
            // instead of clipping.
            ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: FetchProviderMetrics.h(68) - 1),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  FetchProviderMetrics.w(16),
                  FetchProviderMetrics.h(10),
                  FetchProviderMetrics.w(12),
                  FetchProviderMetrics.h(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SimCardIconContainer(
                      url: txn.icon.trim().isEmpty ? null : txn.icon.trim(),
                      width: FetchProviderMetrics.r(40),
                      height: FetchProviderMetrics.r(40),
                      borderRadius: FetchProviderMetrics.r(12),
                      padding: FetchProviderMetrics.r(4),
                      borderWidth: 1,
                    ),
                    SizedBox(width: FetchProviderMetrics.w(10)),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            billerTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              fontSize: titleSize,
                              height: 1.2,
                              letterSpacing: -0.02 * titleSize,
                              color: const Color(0xFF000000),
                            ),
                          ),
                          if (customerName.isNotEmpty ||
                              consumerNo.isNotEmpty) ...[
                            SizedBox(height: FetchProviderMetrics.h(4)),
                            Row(
                              children: [
                                if (customerName.isNotEmpty)
                                  Flexible(
                                    child: Text(
                                      customerName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: subtitleStyle,
                                    ),
                                  ),
                                if (customerName.isNotEmpty &&
                                    consumerNo.isNotEmpty)
                                  Container(
                                    width: FetchProviderMetrics.r(5),
                                    height: FetchProviderMetrics.r(5),
                                    margin: EdgeInsets.symmetric(
                                      horizontal: FetchProviderMetrics.w(8),
                                    ),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFD9D9D9),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                if (consumerNo.isNotEmpty)
                                  Flexible(
                                    child: Text(
                                      consumerNo,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: subtitleStyle,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: FetchProviderMetrics.w(8)),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _showSavedBillerActionSheet(context, txn),
                      child: Padding(
                        padding: EdgeInsets.all(FetchProviderMetrics.r(6)),
                        child: const _VerticalDots(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: AppColors.lightBorder.withValues(alpha: 0.7),
            ),
            ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: FetchProviderMetrics.h(62) - 1),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  FetchProviderMetrics.w(16),
                  FetchProviderMetrics.h(10),
                  0,
                  FetchProviderMetrics.h(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AutoPay Active',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              fontSize: bodySize,
                              height: 1.2,
                              letterSpacing: -0.02 * bodySize,
                              color: const Color(0xFFDD5428),
                            ),
                          ),
                          if (lastPaid.isNotEmpty) ...[
                            SizedBox(height: FetchProviderMetrics.h(4)),
                            Text(
                              lastPaid,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w500,
                                fontSize: bodySize,
                                height: 1.2,
                                letterSpacing: -0.02 * bodySize,
                                color: const Color(0xFF000000),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: FetchProviderMetrics.w(8)),
                    const _AutoPayBadge(),
                  ],
                ),
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

  static const _figmaWidth = 78.0;
  static const _figmaHeight = 25.0;

  @override
  Widget build(BuildContext context) {
    final width = FetchProviderMetrics.w(_figmaWidth);
    // Flush with the card's right edge; the artwork rounds only its left side.
    return SvgPicture.asset(
      FileConstants.autoPayBadge,
      width: width,
      height: width * _figmaHeight / _figmaWidth,
      fit: BoxFit.contain,
      semanticsLabel: 'AutoPay',
    );
  }
}

class _VerticalDots extends StatelessWidget {
  const _VerticalDots();

  @override
  Widget build(BuildContext context) {
    final dot = FetchProviderMetrics.r(3.5);
    return SizedBox(
      width: FetchProviderMetrics.r(16),
      height: FetchProviderMetrics.r(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List<Widget>.generate(
          3,
          (_) => Container(
            width: dot,
            height: dot,
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
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showSavedBillerActionSheet(context, txn),
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Icon(
                      Icons.more_vert,
                      color: AppColors.textPrimary.withValues(alpha: 0.45),
                    ),
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
                SizedBox(
                  height: 30.h,
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

void _showSavedBillerActionSheet(
  BuildContext context,
  LatestTransaction txn,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => _SavedBillerActionSheet(txn: txn),
  );
}

class _SavedBillerActionSheet extends StatelessWidget {
  const _SavedBillerActionSheet({required this.txn});

  final LatestTransaction txn;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;

    final billerTitle = txn.billerName.trim();
    final customerName = _capitalizeWords(txn.customerName.trim());
    final fullNumber = (txn.serviceNoFull ?? '').trim();
    final consumerNo = fullNumber.isNotEmpty ? fullNumber : txn.serviceNo.trim();

    return Container(
      width: screenWidth,
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16.r),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24.w,
            20.h,
            24.w,
            20.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Area
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SimCardIconContainer(
                    url: txn.icon.trim().isEmpty ? null : txn.icon.trim(),
                    width: 40.w,
                    height: 40.w,
                    borderRadius: 12.r,
                    padding: 4.w,
                    borderWidth: 1,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          billerTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                            height: 1.25,
                            letterSpacing: -0.02 * 14.sp,
                            color: const Color(0xFF000000),
                          ),
                        ),
                        if (customerName.isNotEmpty || consumerNo.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Row(
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
                                      height: 1.2,
                                      letterSpacing: -0.02 * 12.sp,
                                      color: const Color(0xFF696969),
                                    ),
                                  ),
                                ),
                              if (customerName.isNotEmpty && consumerNo.isNotEmpty)
                                Container(
                                  width: 4.r,
                                  height: 4.r,
                                  margin: EdgeInsets.symmetric(horizontal: 6.w),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFD9D9D9),
                                    shape: BoxShape.circle,
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
                                      height: 1.2,
                                      letterSpacing: -0.02 * 12.sp,
                                      color: const Color(0xFF696969),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: EdgeInsets.all(4.r),
                      child: Icon(
                        Icons.close,
                        size: 24.r,
                        color: const Color(0xFF1E1E1E),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFE2E2E2),
              ),
              // Delete AutoPay Row
              _SavedBillerActionRow(
                iconAsset: FileConstants.deleteAutopaySvg,
                label: 'Delete AutoPay',
                onTap: () {
                  Navigator.of(context).pop();
                  AppSnackbar.show('AutoPay settings updated');
                },
              ),
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFE2E2E2),
              ),
              // View History Row
              _SavedBillerActionRow(
                iconAsset: FileConstants.deleteAutopaySvg,
                label: 'View History',
                onTap: () {
                  Navigator.of(context).pop();
                  context.push(RouteConstants.transactions);
                },
              ),
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFE2E2E2),
              ),
              // Delete Account Row
              _SavedBillerActionRow(
                iconAsset: FileConstants.deleteAccountSvg,
                label: 'Delete Account',
                onTap: () {
                  Navigator.of(context).pop();
                  AppSnackbar.show('Account removed from saved billers');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedBillerActionRow extends StatelessWidget {
  const _SavedBillerActionRow({
    required this.iconAsset,
    required this.label,
    required this.onTap,
  });

  final String iconAsset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.black.withValues(alpha: 0.05),
      highlightColor: Colors.black.withValues(alpha: 0.03),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconAsset,
              width: 24.w,
              height: 24.w,
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w500,
                  fontSize: 14.sp,
                  height: 1.2,
                  color: const Color(0xFF000000),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
