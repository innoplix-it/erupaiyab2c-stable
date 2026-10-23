import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:go_router/go_router.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../utils/date_format_helper.dart';
import '../../../widgets/app_network_image.dart';
import '../../../constants/app_error_messages.dart';
import 'credit_card/credit_card_figma_metrics.dart';
import '../../../utils/error_message_utils.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/screen_wrapper.dart';
import '../../mobile_prepaid/components/recharge_quick_action_card.dart';
import '../../home/models/credit_card_item.dart';
import '../../mobile_prepaid/models/latest_transaction.dart';
import '../models/biller_model.dart';
import '../../profile/models/electricity_card_history_scope.dart';
import '../controllers/biller_detail_controller.dart';
import '../controllers/service_extras_controller.dart';
import 'delete_saved_biller_dialog.dart';
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
    this.serviceCategory,
    this.operatorLogo = false,
    this.operatorBillers = const [],
    this.savedCards = const [],
  });

  final AsyncValue<List<LatestTransaction>> recentTransactions;
  final ValueChanged<LatestTransaction> onPayNow;
  final String title;
  final String actionText;
  final VoidCallback? onAction;
  final bool savedBillersStyle;
  final String? serviceCategory;

  /// Credit-card recent row: 41×41 rounded operator mark instead of a circle.
  final bool operatorLogo;

  /// Billers used to fill the operator logo and bank name on credit-card cards.
  final List<Biller> operatorBillers;

  /// Saved credit cards. Recent rows use their last-paid and due dates when
  /// the latest-transaction payload does not include them.
  final List<CreditCardItem> savedCards;

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
              serviceCategory: serviceCategory,
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
              serviceCategory: serviceCategory,
              operatorLogo: operatorLogo,
              operatorBillers: operatorBillers,
              savedCards: savedCards,
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
                serviceCategory: serviceCategory,
                operatorLogo: operatorLogo,
                operatorBillers: operatorBillers,
                savedCards: savedCards,
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
    this.serviceCategory,
    this.operatorLogo = false,
    this.operatorBillers = const [],
    this.savedCards = const [],
  });

  final AsyncValue<List<LatestTransaction>> recentTransactions;
  final ValueChanged<LatestTransaction> onPayNow;
  final bool savedBillersStyle;
  final String? serviceCategory;
  final bool operatorLogo;
  final List<Biller> operatorBillers;
  final List<CreditCardItem> savedCards;

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
    // Viewport height must cover the card Column. Mixing a short 126.h
    // viewport with .w padding + .h bars caused ~8px bottom overflow.
    // Credit-card cards use a tighter Figma bottom pad, so their row is shorter.
    final recentRowHeight = operatorLogo
        ? _operatorRecentRowHeight(context)
        : _RecentCardShimmer.viewportHeight;
    return recentTransactions.when(
      loading: () => SizedBox(
        height: recentRowHeight,
        child: ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
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
              _SavedBillerCard(
                txn: txn,
                onPayNow: () => onPayNow(txn),
                serviceCategory: serviceCategory,
              ),
          ]);
        }
        return SizedBox(
          height: recentRowHeight,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            itemCount: display.length,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (context, index) {
              final card = _RecentCard(
                txn: display[index],
                onPayNow: () => onPayNow(display[index]),
                serviceCategory: serviceCategory,
                operatorLogo: operatorLogo,
                operatorBillers: operatorBillers,
                savedCards: savedCards,
              );
              // The list cross-axis is tight. Align keeps a one-date card
              // from stretching into the two-date reserve.
              return operatorLogo
                  ? Align(alignment: Alignment.topCenter, child: card)
                  : card;
            },
          ),
        );
      },
    );
  }
}

/// Every saved biller of a service, stacked vertically with the same card as
/// the Saved Billers row, for the "View all" screen.
class SavedBillersList extends StatelessWidget {
  const SavedBillersList({
    super.key,
    required this.savedBillers,
    required this.onPayNow,
    required this.onRetry,
    this.serviceCategory,
  });

  final AsyncValue<List<LatestTransaction>> savedBillers;
  final ValueChanged<LatestTransaction> onPayNow;
  final VoidCallback onRetry;
  final String? serviceCategory;

  @override
  Widget build(BuildContext context) {
    final side = FetchProviderMetrics.w(24);
    final bottom = 16.h + MediaQuery.paddingOf(context).bottom;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth - 2 * side;
        Widget list(int count, Widget Function(int index) item) =>
            ListView.separated(
              padding: EdgeInsets.fromLTRB(side, 16.h, side, bottom),
              itemCount: count,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (_, index) => item(index),
            );
        return savedBillers.when(
          loading: () => list(
            3,
            (_) => _SavedBillerCardShimmer(width: cardWidth),
          ),
          error: (error, _) => ScreenWrapper(
            isFetching: false,
            isEmpty: false,
            emptyMessage: '',
            errorMessage: ErrorMessageUtils.from(
              error,
              fallback: AppErrorMessages.generic,
            ),
            actions: [
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
            child: const SizedBox.shrink(),
          ),
          data: (items) => ScreenWrapper(
            isFetching: false,
            isEmpty: items.isEmpty,
            emptyMessage: 'No saved billers yet',
            child: list(
              items.length,
              (index) => _SavedBillerCard(
                txn: items[index],
                onPayNow: () => onPayNow(items[index]),
                serviceCategory: serviceCategory,
                width: cardWidth,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SavedBillerCardShimmer extends StatelessWidget {
  const _SavedBillerCardShimmer({this.width});

  final double? width;

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
        width: width ?? _SavedBillerCard.cardWidth(screenWidth),
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

/// Credit-card recent row. Header and both date lines use
/// [CreditCardFigmaMetrics], including text scale above 1 so Last Paid and
/// Due On stay inside the horizontal list.
double _operatorRecentRowHeight(BuildContext context) {
  final textScale = MediaQuery.textScalerOf(context).scale(1);
  final grow = textScale > 1 ? textScale : 1.0;
  final titleBlock = (CreditCardFigmaMetrics.myCardTitleSize(context) * 1.2 +
          CreditCardFigmaMetrics.sy(context, 6) +
          CreditCardFigmaMetrics.myCardMaskedSize(context) * 1.2) *
      grow;
  final logo = CreditCardFigmaMetrics.myCardLogoSize(context);
  final menu = CreditCardFigmaMetrics.myCardMenuIconSize(context) +
      CreditCardFigmaMetrics.s(context, 4) * 2;
  final headerInner = titleBlock > logo
      ? (titleBlock > menu ? titleBlock : menu)
      : (logo > menu ? logo : menu);
  final header = CreditCardFigmaMetrics.sy(context, 12) * 2 + headerInner;
  final pad = CreditCardFigmaMetrics.sy(context, 14);
  final bottomPad = CreditCardFigmaMetrics.sy(context, 12);
  final buttonBlock =
      pad + CreditCardFigmaMetrics.payNowButtonHeight(context) + bottomPad;
  final dueLine = CreditCardFigmaMetrics.myCardDueSize(context) * 1.2 * grow;
  final gap = CreditCardFigmaMetrics.sy(context, 4);
  final textBlock = pad +
      CreditCardFigmaMetrics.myCardAmountSize(context) * 1.15 * grow +
      gap +
      dueLine +
      gap +
      dueLine +
      bottomPad;
  final lower = buttonBlock > textBlock ? buttonBlock : textBlock;
  return header + 1 + lower;
}

class _RecentCardShimmer extends StatelessWidget {
  const _RecentCardShimmer();

  /// Horizontal recent-row viewport: pad×4 + icon + divider + pay row + gaps,
  /// all width-scaled so tall phones do not squeeze a short .h viewport.
  static double get viewportHeight =>
      (14.w * 4) + 38.w + 1 + 40.w + 8.w + 10.w + 24.w;

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
          mainAxisSize: MainAxisSize.min,
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 12.w,
                          width: 160.w,
                          decoration: BoxDecoration(
                            color:
                                AppColors.lightBorder.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        SizedBox(height: 8.w),
                        Container(
                          height: 10.w,
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
                    height: 18.w,
                    width: 18.w,
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 16.w,
                          width: 120.w,
                          decoration: BoxDecoration(
                            color:
                                AppColors.lightBorder.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        SizedBox(height: 10.w),
                        Container(
                          height: 10.w,
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
                    height: 30.w,
                    width: 78.w,
                    decoration: BoxDecoration(
                      color: AppColors.lightBorder.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(22.r),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _autoPayOverridesNotifier = ValueNotifier<Map<String, bool>>({});

class _SavedBillerCard extends StatelessWidget {
  const _SavedBillerCard({
    required this.txn,
    required this.onPayNow,
    this.serviceCategory,
    this.width,
  });

  final LatestTransaction txn;
  final VoidCallback onPayNow;
  final String? serviceCategory;

  /// Overrides [cardWidth], e.g. to fill a vertical list.
  final double? width;

  /// Narrow phones get a wider share of the screen so the title isn't cut
  /// too early; elsewhere the card keeps Figma's 325/440 width ratio.
  static double cardWidth(double screenWidth) =>
      screenWidth < 360 ? screenWidth * 0.8 : FetchProviderMetrics.w(325);

  @override
  Widget build(BuildContext context) {
    final billerTitle = txn.billerName.trim();

    final cardWidth =
        width ?? _SavedBillerCard.cardWidth(MediaQuery.sizeOf(context).width);
    final titleSize = FetchProviderMetrics.font(13, min: 10.5);
    final bodySize = FetchProviderMetrics.font(11, min: 9.5);
    final subtitleSize = FetchProviderMetrics.font(11, min: 9.5);
    final subtitleStyle = GoogleFonts.plusJakartaSans(
      fontWeight: FontWeight.w500,
      fontSize: subtitleSize,
      height: 1.2,
      letterSpacing: -0.02 * subtitleSize,
      color: const Color(0xFF696969),
    );

    return ValueListenableBuilder<Map<String, FetchedBillDetails>>(
      valueListenable: fetchedBillCacheNotifier,
      builder: (context, fetchedCache, child) {
        final cached =
            fetchedCache['${txn.billerId}_${txn.primaryConsumerNumber}'] ??
                fetchedCache[txn.billerId];
        final accountHolderName = _capitalizeWords(
          (txn.accountHolderName.isNotEmpty
                  ? txn.accountHolderName
                  : (cached?.accountHolderName.isNotEmpty == true
                      ? cached!.accountHolderName
                      : txn.customerName))
              .trim(),
        );
        final consumerNo = (txn.service_no_full.trim().isNotEmpty
                ? txn.service_no_full
                : txn.primaryConsumerNumber)
            .trim();
        final rawDueDate = (txn.dueDate != null && txn.dueDate!.isNotEmpty)
            ? txn.dueDate
            : (cached?.dueDate.isNotEmpty == true
                ? cached!.dueDate
                : txn.expiresAt);
        final dueLabel = _formatDueDate(rawDueDate);
        final lastPaid = _formatWasPaidOn(txn);
        final amountText = '₹${txn.amount.toStringAsFixed(2)}';

        return ValueListenableBuilder<Map<String, bool>>(
          valueListenable: _autoPayOverridesNotifier,
          builder: (context, autoPayMap, child) {
            final isAutoPay = autoPayMap[txn.id] ?? txn.autoPayActive;
            return GestureDetector(
              onTap: onPayNow,
              child: Container(
                width: cardWidth,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(FetchProviderMetrics.r(16)),
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
                    ConstrainedBox(
                      constraints: BoxConstraints(
                          minHeight: FetchProviderMetrics.h(68) - 1),
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
                              url: txn.icon.trim().isEmpty
                                  ? null
                                  : txn.icon.trim(),
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
                                  if (accountHolderName.isNotEmpty ||
                                      consumerNo.isNotEmpty) ...[
                                    SizedBox(height: FetchProviderMetrics.h(4)),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        if (accountHolderName.isNotEmpty)
                                          Flexible(
                                            child: Text(
                                              accountHolderName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: subtitleStyle,
                                            ),
                                          ),
                                        if (accountHolderName.isNotEmpty &&
                                            consumerNo.isNotEmpty)
                                          Container(
                                            width: 3.r,
                                            height: 3.r,
                                            margin: EdgeInsets.symmetric(
                                              horizontal:
                                                  FetchProviderMetrics.w(6),
                                            ),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF696969),
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
                              onTap: () => _showSavedBillerActionSheet(
                                context,
                                txn,
                                serviceCategory: serviceCategory,
                              ),
                              child: Padding(
                                padding:
                                    EdgeInsets.all(FetchProviderMetrics.r(6)),
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
                      constraints: BoxConstraints(
                          minHeight: FetchProviderMetrics.h(62) - 1),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          FetchProviderMetrics.w(16),
                          FetchProviderMetrics.h(10),
                          isAutoPay ? 0 : FetchProviderMetrics.w(16),
                          FetchProviderMetrics.h(10),
                        ),
                        child: isAutoPay
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          SizedBox(
                                              height:
                                                  FetchProviderMetrics.h(4)),
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
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          amountText,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w700,
                                            fontSize: FetchProviderMetrics.font(
                                                18,
                                                min: 14),
                                            height: 1.2,
                                            letterSpacing: -0.02 *
                                                FetchProviderMetrics.font(18,
                                                    min: 14),
                                            color: const Color(0xFF000000),
                                          ),
                                        ),
                                        if (dueLabel.isNotEmpty) ...[
                                          SizedBox(
                                              height:
                                                  FetchProviderMetrics.h(5)),
                                          Text(
                                            dueLabel,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w600,
                                              fontSize:
                                                  FetchProviderMetrics.font(9.5,
                                                      min: 8),
                                              height: 1.1,
                                              letterSpacing: -0.02 *
                                                  FetchProviderMetrics.font(9.5,
                                                      min: 8),
                                              color: const Color(0xFFD30000),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: FetchProviderMetrics.w(8)),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      // Single scaling: ScreenUtil via
                                      // FetchProviderMetrics; LayoutBuilder is
                                      // used only to clamp to the local
                                      // available width (overflow guard).
                                      final payBtnWidth =
                                          FetchProviderMetrics.w(88)
                                              .clamp(
                                                FetchProviderMetrics.w(74),
                                                constraints.maxWidth > 0
                                                    ? constraints.maxWidth
                                                    : double.infinity,
                                              )
                                              .toDouble();
                                      final payBtnHeight =
                                          FetchProviderMetrics.h(28);
                                      final payBtnFont =
                                          FetchProviderMetrics.font(11.5,
                                              min: 10);

                                      return GestureDetector(
                                        onTap: onPayNow,
                                        child: Container(
                                          width: payBtnWidth,
                                          height: payBtnHeight,
                                          padding: EdgeInsets.fromLTRB(
                                              FetchProviderMetrics.w(10),
                                              FetchProviderMetrics.h(4),
                                              FetchProviderMetrics.w(10),
                                              FetchProviderMetrics.h(4)),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDD5428),
                                            borderRadius:
                                                BorderRadius.circular(50.r),
                                          ),
                                          alignment: Alignment.center,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              'Pay Now',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.w500,
                                                fontSize: payBtnFont,
                                                height: 1.2,
                                                color: const Color(0xFFFFFFFF),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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

/// Full recent list behind "View all". Same cards and the same
/// [serviceLatestTransactionsProvider] as the carousel.
class ServiceRecentAllView extends ConsumerWidget {
  const ServiceRecentAllView({
    super.key,
    required this.categoryName,
    required this.onPayNow,
    this.operatorLogo = false,
    this.operatorBillers = const [],
    this.savedCards = const [],
  });

  final String categoryName;
  final ValueChanged<LatestTransaction> onPayNow;
  final bool operatorLogo;
  final List<Biller> operatorBillers;
  final List<CreditCardItem> savedCards;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(serviceLatestTransactionsProvider(categoryName));
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Recent',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
      ),
      body: recent.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(
              serviceLatestTransactionsProvider(categoryName),
            ),
            child: const Text('Retry'),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No recent cards'));
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
            itemCount: items.length,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final txn = items[index];
              return _RecentCard(
                txn: txn,
                width: double.infinity,
                operatorLogo: operatorLogo,
                operatorBillers: operatorBillers,
                savedCards: savedCards,
                serviceCategory: categoryName,
                onPayNow: () => onPayNow(txn),
              );
            },
          );
        },
      ),
    );
  }
}

class _OperatorLogoTile extends StatelessWidget {
  const _OperatorLogoTile({required this.iconUrl, this.fallbackLabel = ''});

  final String iconUrl;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    final side = CreditCardFigmaMetrics.myCardLogoSize(context);
    final radius = CreditCardFigmaMetrics.myCardLogoRadius(context);
    final url = iconUrl.trim();
    final initial = fallbackLabel.trim().isEmpty
        ? ''
        : fallbackLabel.trim()[0].toUpperCase();
    final fallback = Center(
      child: Text(
        initial,
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: CreditCardFigmaMetrics.s(context, 16),
          color: AppColors.primary,
        ),
      ),
    );
    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: CreditCardFigmaMetrics.providerLogoBorderColor,
          width: CreditCardFigmaMetrics.providerLogoBorderWidth(context),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? fallback
          : Padding(
              padding: EdgeInsets.all(CreditCardFigmaMetrics.s(context, 6)),
              child: AppNetworkImage(
                url: url,
                width: side,
                height: side,
                fit: BoxFit.contain,
                showShimmer: false,
                placeholder: fallback,
                errorWidget: fallback,
              ),
            ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({
    required this.txn,
    required this.onPayNow,
    this.serviceCategory,
    this.operatorLogo = false,
    this.operatorBillers = const [],
    this.savedCards = const [],
    this.width,
  });

  final LatestTransaction txn;
  final VoidCallback onPayNow;
  final String? serviceCategory;
  final bool operatorLogo;
  final List<Biller> operatorBillers;
  final List<CreditCardItem> savedCards;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final title = txn.billerName.trim();
    final amount = txn.amount;
    final subtitleStyle = GoogleFonts.plusJakartaSans(
      fontWeight: FontWeight.w500,
      fontSize: 11.sp,
      height: 1.2,
      letterSpacing: -0.02 * 11.sp,
      color: const Color(0xFF696969),
    );

    return ValueListenableBuilder<Map<String, FetchedBillDetails>>(
      valueListenable: fetchedBillCacheNotifier,
      builder: (context, fetchedCache, child) {
        final cached =
            fetchedCache['${txn.billerId}_${txn.primaryConsumerNumber}'] ??
                fetchedCache[txn.billerId];
        final accountHolderName = _capitalizeWords(
          (txn.accountHolderName.isNotEmpty
                  ? txn.accountHolderName
                  : (cached?.accountHolderName.isNotEmpty == true
                      ? cached!.accountHolderName
                      : txn.customerName))
              .trim(),
        );
        final consumerNo = (txn.service_no_full.trim().isNotEmpty
                ? txn.service_no_full
                : txn.primaryConsumerNumber)
            .trim();
        final matchedCard =
            operatorLogo ? _matchSavedCreditCard(txn, savedCards) : null;
        final rawDueDate = (txn.dueDate != null && txn.dueDate!.isNotEmpty)
            ? txn.dueDate
            : (cached?.dueDate.isNotEmpty == true
                ? cached!.dueDate
                : matchedCard?.dueDate);
        final dueLabel = operatorLogo
            ? _formatCreditDue(rawDueDate)
            : _formatDueDate(rawDueDate);
        final lastPaidLabel = operatorLogo
            ? _formatLastPaidOn(_firstFilled([
                txn.lastPaidDate,
                matchedCard?.lastPaidDate,
                txn.transactionTime,
                txn.createdAt,
              ]))
            : '';
        final matched =
            operatorLogo ? _matchOperatorBiller(txn, operatorBillers) : null;
        final bankName = (matched?.billerName.trim().isNotEmpty ?? false)
            ? matched!.billerName.trim()
            : title;
        final logoUrl = _operatorIconUrl(txn.icon) ?? matched?.iconUrl;
        final masked = _maskedCardNumber(consumerNo);

        return Container(
          // 342 on the 440 frame is the same carousel width as the old 280
          // ScreenUtil px on a 360-wide screen.
          width: width ??
              (operatorLogo ? CreditCardFigmaMetrics.s(context, 342) : 280.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              operatorLogo
                  ? CreditCardFigmaMetrics.myCardRadius(context)
                  : 16.r,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: operatorLogo
                    ? CreditCardFigmaMetrics.myCardShadowBlur(context)
                    : 12.r,
                offset: operatorLogo
                    ? Offset(
                        0,
                        CreditCardFigmaMetrics.myCardShadowOffsetY(context),
                      )
                    : Offset(0.w, 6.h),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: operatorLogo
                    ? CreditCardFigmaMetrics.myCardHeaderPadding(context)
                    : EdgeInsets.all(13.w),
                child: Row(
                  children: [
                    operatorLogo
                        ? _OperatorLogoTile(
                            iconUrl: logoUrl ?? '',
                            fallbackLabel: bankName,
                          )
                        : Container(
                            height: 38.w,
                            width: 38.w,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.08),
                              ),
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
                    SizedBox(
                      width: operatorLogo
                          ? CreditCardFigmaMetrics.s(context, 12)
                          : 12.w,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            operatorLogo ? bankName : title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: operatorLogo
                                ? CreditCardFigmaMetrics.myCardTitleStyle(
                                    context)
                                : Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                          ),
                          if (operatorLogo && masked.isNotEmpty) ...[
                            SizedBox(
                                height: CreditCardFigmaMetrics.sy(context, 6)),
                            Text(
                              masked,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CreditCardFigmaMetrics.myCardMaskedStyle(
                                context,
                              ),
                            ),
                          ] else if (!operatorLogo &&
                              (accountHolderName.isNotEmpty ||
                                  consumerNo.isNotEmpty)) ...[
                            SizedBox(height: 2.w),
                            Row(
                              children: [
                                if (accountHolderName.isNotEmpty)
                                  Flexible(
                                    child: Text(
                                      accountHolderName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: subtitleStyle,
                                    ),
                                  ),
                                if (accountHolderName.isNotEmpty &&
                                    consumerNo.isNotEmpty)
                                  Container(
                                    width: 4.r,
                                    height: 4.r,
                                    margin:
                                        EdgeInsets.symmetric(horizontal: 4.w),
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
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _showSavedBillerActionSheet(
                        context,
                        txn,
                        serviceCategory: serviceCategory,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(
                          operatorLogo
                              ? CreditCardFigmaMetrics.s(context, 4)
                              : 4.w,
                        ),
                        child: Icon(
                          Icons.more_vert,
                          size: operatorLogo
                              ? CreditCardFigmaMetrics.myCardMenuIconSize(
                                  context)
                              : null,
                          color: const Color(0xFF000000),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                  height: 1,
                  color: AppColors.lightBorder.withValues(alpha: 0.7)),
              Padding(
                padding: operatorLogo
                    ? EdgeInsets.fromLTRB(
                        CreditCardFigmaMetrics.s(context, 14),
                        CreditCardFigmaMetrics.sy(context, 14),
                        CreditCardFigmaMetrics.s(context, 12),
                        CreditCardFigmaMetrics.sy(context, 12),
                      )
                    : EdgeInsets.all(14.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            operatorLogo
                                ? _formatInr(amount)
                                : '₹${amount.toStringAsFixed(2)}',
                            style: operatorLogo
                                ? CreditCardFigmaMetrics.myCardAmountStyle(
                                    context)
                                : Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textPrimary,
                                    ),
                          ),
                          if (lastPaidLabel.isNotEmpty) ...[
                            SizedBox(
                              height: CreditCardFigmaMetrics.sy(context, 4),
                            ),
                            Text(
                              lastPaidLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CreditCardFigmaMetrics.myCardDueStyle(
                                context,
                                isDue: false,
                              ),
                            ),
                          ],
                          if (dueLabel.isNotEmpty) ...[
                            SizedBox(
                              height: operatorLogo
                                  ? CreditCardFigmaMetrics.sy(context, 4)
                                  : 4.w,
                            ),
                            Text(
                              dueLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: operatorLogo
                                  ? CreditCardFigmaMetrics.myCardDueStyle(
                                      context,
                                      isDue: true,
                                    )
                                  : Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.red.shade600,
                                        fontWeight: FontWeight.w700,
                                      ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(
                      width: operatorLogo
                          ? CreditCardFigmaMetrics.s(context, 12)
                          : 12.w,
                    ),
                    operatorLogo
                        ? SizedBox(
                            width: CreditCardFigmaMetrics.payNowButtonWidth(
                              context,
                            ),
                            height: CreditCardFigmaMetrics.payNowButtonHeight(
                              context,
                            ),
                            child: ElevatedButton(
                              onPressed: onPayNow,
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                backgroundColor:
                                    CreditCardFigmaMetrics.payNowButtonColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    CreditCardFigmaMetrics.payNowButtonRadius(
                                      context,
                                    ),
                                  ),
                                ),
                              ),
                              child: Text(
                                'Pay Now',
                                style: CreditCardFigmaMetrics
                                    .payNowButtonLabelStyle(context),
                              ),
                            ),
                          )
                        : SizedBox(
                            height: 30.w,
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
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
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
      },
    );
  }
}

String _formatWasPaidOn(LatestTransaction txn) {
  final raw = (txn.transactionTime ?? txn.createdAt ?? '').trim();
  final amountText = '₹${txn.amount.toStringAsFixed(2)}';
  if (raw.isEmpty) return amountText;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return '$amountText Paid On $raw';
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
  return '$amountText Paid On $day$suffix ${months[parsed.month - 1]} ${parsed.year}';
}

String? _firstFilled(List<String?> values) {
  for (final value in values) {
    final text = (value ?? '').trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
  }
  return null;
}

String _formatLastPaidOn(String? raw) {
  final value = _firstFilled([raw]);
  if (value == null) return '';
  return 'Last Paid On ${DateFormatHelper.formatDisplayDateWithYear(value)}';
}

CreditCardItem? _matchSavedCreditCard(
  LatestTransaction txn,
  List<CreditCardItem> cards,
) {
  if (cards.isEmpty) return null;
  final digits = txn.primaryConsumerNumber.replaceAll(RegExp(r'\D'), '');
  final last4 = digits.length >= 4 ? digits.substring(digits.length - 4) : '';
  final billerId = txn.billerId.trim().toLowerCase();
  final sameBiller = <CreditCardItem>[];
  for (final card in cards) {
    final cardDigits = '${card.last4Digit ?? ''}${card.maskedIdentifier ?? ''}'
        .replaceAll(RegExp(r'\D'), '');
    final cardLast4 = cardDigits.length >= 4
        ? cardDigits.substring(cardDigits.length - 4)
        : '';
    final billerMatches = billerId.isNotEmpty &&
        (card.billerId ?? '').trim().toLowerCase() == billerId;
    if (billerMatches) sameBiller.add(card);
    if (last4.isNotEmpty &&
        cardLast4 == last4 &&
        (billerMatches || billerId.isEmpty)) {
      return card;
    }
  }
  if (sameBiller.length == 1) return sameBiller.first;
  return null;
}

String _formatCreditDue(String? raw) {
  final value = (raw ?? '').trim();
  if (value.isEmpty || value.toLowerCase() == 'null') return '';
  return 'Due On ${DateFormatHelper.formatDisplayDateWithYear(value)}';
}

String _formatInr(num amount) {
  final parts = amount.toStringAsFixed(2).split('.');
  final digits = parts[0];
  if (digits.length <= 3) return '₹$digits.${parts[1]}';
  final last3 = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);
  return '₹${groups.join(',')},$last3.${parts[1]}';
}

String _formatDueDate(String? raw, {bool shortMonth = false}) {
  final value = (raw ?? '').trim();
  if (value.isEmpty || value.toLowerCase() == 'null') return '';
  final parsed = DateTime.tryParse(value);
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  const shortMonths = [
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
    'Dec',
  ];
  if (parsed == null) return 'Due On $value';
  final m = (shortMonth ? shortMonths : months)[parsed.month - 1];
  return 'Due On ${parsed.day} $m ${parsed.year}';
}

Biller? _matchOperatorBiller(LatestTransaction txn, List<Biller> billers) {
  final id = txn.billerId.trim().toLowerCase();
  final name = txn.billerName.trim().toLowerCase();
  for (final biller in billers) {
    if (id.isNotEmpty && biller.billerId.trim().toLowerCase() == id) {
      return biller;
    }
  }
  for (final biller in billers) {
    if (name.isNotEmpty && biller.billerName.trim().toLowerCase() == name) {
      return biller;
    }
  }
  return null;
}

String? _operatorIconUrl(String raw) {
  return Biller(billerId: '', billerName: '', icon: raw).iconUrl;
}

String _maskedCardNumber(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';
  final suffix =
      digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
  return 'XXXX$suffix';
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

enum _SavedBillerAction { deleteAccount, toggleAutoPay, viewHistory }

Future<void> _showSavedBillerActionSheet(
  BuildContext context,
  LatestTransaction txn, {
  String? serviceCategory,
}) async {
  Animation<double>? sheetAnimation;
  final action = await showModalBottomSheet<_SavedBillerAction>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      sheetAnimation = ModalRoute.of(sheetContext)?.animation;
      return _SavedBillerActionSheet(
        txn: txn,
        serviceCategory: serviceCategory,
      );
    },
  );
  if (action == null || !context.mounted) return;

  if (action == _SavedBillerAction.toggleAutoPay) {
    final current =
        _autoPayOverridesNotifier.value[txn.id] ?? txn.autoPayActive;
    _autoPayOverridesNotifier.value = {
      ..._autoPayOverridesNotifier.value,
      txn.id: !current,
    };
    AppSnackbar.show('AutoPay settings updated');
    return;
  }

  if (action == _SavedBillerAction.viewHistory) {
    // Dismiss the sheet fully, then navigate on this stable outer context.
    // Doing pop -> push inline on the (soon-deactivated) sheet context raced
    // the modal teardown and intermittently dropped the navigation.
    await _untilDismissed(sheetAnimation);
    if (!context.mounted) return;
    // Electricity Saved Biller card-scoped flow: the exact dynamic
    // `service_no_full` of THIS card becomes the history scope. No
    // fallbacks (service_no / masked / mobile / params) are used.
    if (ElectricityCardHistoryScope.isElectricityCategory(serviceCategory)) {
      final scope = ElectricityCardHistoryScope.fromTransaction(
        txn,
        serviceCategory: serviceCategory,
      );
      if (scope == null || !scope.isValid) {
        AppSnackbar.show('Consumer number not available for this card');
        return;
      }
      context.push(
        RouteConstants.transactions,
        extra: scope.toNavigationExtra(),
      );
      return;
    }
    final creditCardHaystack =
        '${serviceCategory ?? ''} ${txn.paymentType} ${txn.billerName}'
            .toLowerCase();
    if (creditCardHaystack.contains('credit card') ||
        creditCardHaystack.contains('creditcard')) {
      context.push(
        RouteConstants.transactions,
        extra: const {
          'service': 'Credit Card',
          'paymentType': 'Credit Card',
          'creditCardScoped': true,
        },
      );
      return;
    }
    final filterService = (serviceCategory?.trim().isNotEmpty == true)
        ? serviceCategory!.trim()
        : (txn.paymentType.trim().isNotEmpty
            ? txn.paymentType.trim()
            : (txn.billerName.toLowerCase().contains('electric')
                ? 'Electricity'
                : null));
    final consumerId = txn.primaryConsumerNumber.trim();
    final extra = <String, dynamic>{};
    if (filterService != null && filterService.isNotEmpty) {
      extra['service'] = filterService;
    }
    if (consumerId.isNotEmpty && consumerId.toLowerCase() != 'null') {
      extra['consumerId'] = consumerId;
    }
    context.push(
      RouteConstants.transactions,
      extra: extra.isEmpty ? filterService : extra,
    );
    return;
  }

  if (action != _SavedBillerAction.deleteAccount) return;

  // The confirmation must not appear over the sheet while it slides away.
  await _untilDismissed(sheetAnimation);
  if (!context.mounted) return;

  final confirmed = await showDeleteSavedBillerDialog(context);
  if (confirmed) {
    AppSnackbar.show('Account removed from saved billers');
  }
}

Future<void> _untilDismissed(Animation<double>? animation) {
  if (animation == null || animation.status == AnimationStatus.dismissed) {
    return Future.value();
  }
  final done = Completer<void>();
  void listener(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      animation.removeStatusListener(listener);
      done.complete();
    }
  }

  animation.addStatusListener(listener);
  return done.future;
}

class _SavedBillerActionSheet extends StatelessWidget {
  const _SavedBillerActionSheet({
    required this.txn,
    this.serviceCategory,
  });

  final LatestTransaction txn;
  final String? serviceCategory;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;

    final billerTitle = txn.billerName.trim();
    final customerName = _capitalizeWords(
      (txn.accountHolderName.isNotEmpty
              ? txn.accountHolderName
              : txn.customerName)
          .trim(),
    );
    final consumerNo = txn.primaryConsumerNumber;
    final isAutoPay =
        _autoPayOverridesNotifier.value[txn.id] ?? txn.autoPayActive;

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
                        if (customerName.isNotEmpty ||
                            consumerNo.isNotEmpty) ...[
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
                              if (customerName.isNotEmpty &&
                                  consumerNo.isNotEmpty)
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
                    child: SizedBox(
                      // Touch-target ergonomic floor (>=44dp); kept unscaled so
                      // it stays >=44 on every device. Visible icon unchanged.
                      width: 44,
                      height: 44,
                      child: Center(
                        child: Icon(
                          Icons.close,
                          size: 24.r,
                          color: const Color(0xFF1E1E1E),
                        ),
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
              // AutoPay Action Row
              if (isAutoPay)
                _SavedBillerActionRow(
                  iconAsset: FileConstants.deleteAutopaySvg,
                  label: 'Delete AutoPay',
                  onTap: () => Navigator.of(context)
                      .pop(_SavedBillerAction.toggleAutoPay),
                )
              else
                _SavedBillerActionRow(
                  iconData: Icons.autorenew,
                  label: 'Add Auto Pay',
                  onTap: () => Navigator.of(context)
                      .pop(_SavedBillerAction.toggleAutoPay),
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
                onTap: () =>
                    Navigator.of(context).pop(_SavedBillerAction.viewHistory),
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
                onTap: () =>
                    Navigator.of(context).pop(_SavedBillerAction.deleteAccount),
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
    this.iconAsset,
    this.iconData,
    required this.label,
    required this.onTap,
  });

  final String? iconAsset;
  final IconData? iconData;
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
            if (iconAsset != null)
              SvgPicture.asset(
                iconAsset!,
                width: 24.w,
                height: 24.w,
              )
            else if (iconData != null)
              Icon(
                iconData,
                size: 24.r,
                color: const Color(0xFF000000),
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
