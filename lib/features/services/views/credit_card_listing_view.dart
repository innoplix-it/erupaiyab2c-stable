// ignore_for_file: deprecated_member_use

import 'package:e_rupaiya/constants/file_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/infinite_scroll_listener.dart';
import '../../../widgets/my_app_bar.dart';
import '../../../widgets/screen_wrapper.dart';
import '../../../widgets/app_search_bar.dart';
import '../../mobile_prepaid/models/latest_transaction.dart';
import '../../profile/controllers/profile_controller.dart';
import '../components/fetch_provider_metrics.dart';
import '../components/service_recent_section.dart';
import '../controllers/biller_detail_controller.dart';
import '../controllers/biller_listing_controller.dart';
import '../controllers/service_extras_controller.dart';
import '../models/biller_detail_args.dart';
import '../models/biller_model.dart';

class CreditCardListingView extends HookConsumerWidget {
  const CreditCardListingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingState = ref.watch(billerListingControllerProvider);
    final searchController = useTextEditingController();
    useListenable(searchController);
    final profileState = ref.watch(profileControllerProvider);
    final categoryName = 'Credit Card';
    final recentTransactions = ref.watch(
      serviceLatestTransactionsProvider(categoryName),
    );

    useEffect(() {
      Future.microtask(() {
        ref
            .read(billerListingControllerProvider.notifier)
            .fetchBillers(categoryName: categoryName, searchQuery: '');
        searchController.clear();
      });
      return null;
    }, const []);

    final billers = listingState.billers;
    final isSearching = searchController.text.trim().isNotEmpty;
    final topPicks = isSearching ? <Biller>[] : billers.take(6).toList();
    final remaining =
        isSearching ? <Biller>[] : billers.skip(topPicks.length).toList();

    void openBillerFromRecent(LatestTransaction txn) {
      final normalizedBiller = txn.billerName.trim().toLowerCase();
      if (normalizedBiller.isEmpty) return;

      final match = billers.where((b) {
        return b.billerName.trim().toLowerCase() == normalizedBiller;
      }).toList();
      if (match.isEmpty) {
        AppSnackbar.show('Provider not found. Please select from the list.');
        return;
      }

      final digits = txn.serviceNo.replaceAll(RegExp(r'\\D'), '');
      final last4 =
          digits.length >= 4 ? digits.substring(digits.length - 4) : '';
      final mobile =
          (profileState.profile?.mobile ?? '').replaceAll(RegExp(r'\\D'), '');

      final canAutoFetch = mobile.length >= 10 && last4.length == 4;
      if (!canAutoFetch) {
        AppSnackbar.show(
          'Unable to auto fetch bill. Please enter details again.',
        );
      }

      final biller = match.first;
      ref.read(billerDetailControllerProvider.notifier).selectBiller(
            biller,
            categoryName: biller.billerName.trim().isNotEmpty
                ? biller.billerName.trim()
                : categoryName,
          );
      context.push(
        RouteConstants.billerDetail,
        extra: BillerDetailArgs(
          biller: biller,
          isCreditCard: true,
          paymentType: biller.billerName.trim().isNotEmpty
              ? biller.billerName.trim()
              : categoryName,
          mobileNumber: mobile.isNotEmpty ? mobile : null,
          cardLast4: last4.length == 4 ? last4 : null,
          autoFetchBill: canAutoFetch,
          autoOpenPaymentSheet: false,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          MyAppBar(
            title: 'Select Your Bank',
            onBack: () => context.pop(),
          ),
          Padding(
            // Same pinned gap as Transaction History (sticky above the list).
            padding: AppSearchBar.pinnedPadding,
            child: AppSearchBar(
              // Same bar styling as Electricity Fetch Your Provider.
              hintText: 'Search by billers',
              controller: searchController,
              textStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
                color: Colors.black,
              ),
              onChanged: (value) => ref
                  .read(billerListingControllerProvider.notifier)
                  .updateSearch(value),
            ),
          ),
          Expanded(
            child: listingState.isFetching &&
                    billers.isEmpty &&
                    listingState.errorMessage == null
                ? _CreditCardListingSkeleton(isSearching: isSearching)
                : ScreenWrapper(
                    isFetching: false,
                    isEmpty: billers.isEmpty,
                    emptyMessage: 'No providers found',
                    errorMessage: listingState.errorMessage,
                    actions: listingState.errorMessage != null
                        ? [
                            TextButton(
                              onPressed: () => ref
                                  .read(
                                      billerListingControllerProvider.notifier)
                                  .fetchBillers(categoryName: categoryName),
                              child: const Text('Retry'),
                            ),
                          ]
                        : null,
                    child: InfiniteScrollListener(
                      isLoading: listingState.isFetchingMore,
                      hasMore: listingState.hasMore,
                      onEndReached: () => ref
                          .read(billerListingControllerProvider.notifier)
                          .fetchNextPage(),
                      child: isSearching
                          ? ListView.builder(
                              primary: false,
                              padding: EdgeInsets.fromLTRB(
                                FetchProviderMetrics.w(24),
                                FetchProviderMetrics.h(4),
                                FetchProviderMetrics.w(24),
                                16.h + MediaQuery.paddingOf(context).bottom,
                              ),
                              itemCount: billers.length +
                                  (listingState.isFetchingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index >= billers.length) {
                                  return const _CreditCardListingFooterSkeleton();
                                }
                                final biller = billers[index];
                                return _BillerListTile(
                                  biller: biller,
                                  onTap: () {
                                    ref
                                        .read(
                                          billerDetailControllerProvider
                                              .notifier,
                                        )
                                        .selectBiller(
                                          biller,
                                          categoryName: biller.billerName.trim().isNotEmpty
                                              ? biller.billerName.trim()
                                              : categoryName,
                                        );
                                    context.push(
                                      RouteConstants.billerDetail,
                                      extra: BillerDetailArgs(
                                        biller: biller,
                                        isCreditCard: true,
                                        paymentType: biller.billerName.trim().isNotEmpty
                                            ? biller.billerName.trim()
                                            : categoryName,
                                      ),
                                    );
                                  },
                                );
                              },
                            )
                          : SingleChildScrollView(
                              primary: false,
                              padding: EdgeInsets.only(
                                bottom: 16.h +
                                    MediaQuery.paddingOf(context).bottom,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ServiceRecentSection(
                                    recentTransactions: recentTransactions,
                                    onPayNow: openBillerFromRecent,
                                    onAction: () {},
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: FetchProviderMetrics.w(24),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Popular Banks',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.textPrimary,
                                              ),
                                        ),
                                        SizedBox(height: 12.h),
                                        LayoutBuilder(
                                          builder: (context, constraints) {
                                            const spacing = 12.0;
                                            const columns = 3;
                                            final tileWidth = (constraints
                                                        .maxWidth -
                                                    (spacing * (columns - 1))) /
                                                columns;
                                            return Wrap(
                                              spacing: spacing,
                                              runSpacing: spacing,
                                              children: [
                                                for (final biller in topPicks)
                                                  SizedBox(
                                                    width: tileWidth,
                                                    child: _BillerGridTile(
                                                      biller: biller,
                                                      onTap: () {
                                                        ref
                                                            .read(
                                                              billerDetailControllerProvider
                                                                  .notifier,
                                                            )
                                                            .selectBiller(
                                                              biller,
                                                              categoryName:
                                                                  biller.billerName.trim().isNotEmpty
                                                                      ? biller.billerName.trim()
                                                                      : categoryName,
                                                            );
                                                        context.push(
                                                          RouteConstants
                                                              .billerDetail,
                                                          extra:
                                                              BillerDetailArgs(
                                                            biller: biller,
                                                            isCreditCard: true,
                                                            paymentType:
                                                                biller.billerName.trim().isNotEmpty
                                                                    ? biller.billerName.trim()
                                                                    : categoryName,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                              ],
                                            );
                                          },
                                        ),
                                        if (remaining.isNotEmpty) ...[
                                          SizedBox(height: 18.h),
                                          Text(
                                            'All Banks',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.textPrimary,
                                                ),
                                          ),
                                          SizedBox(height: 12.h),
                                          Column(
                                            children: [
                                              for (final biller in remaining)
                                                _BillerListTile(
                                                  biller: biller,
                                                  onTap: () {
                                                    ref
                                                        .read(
                                                          billerDetailControllerProvider
                                                              .notifier,
                                                        )
                                                        .selectBiller(
                                                          biller,
                                                          categoryName:
                                                              biller.billerName.trim().isNotEmpty
                                                                  ? biller.billerName.trim()
                                                                  : categoryName,
                                                        );
                                                    context.push(
                                                      RouteConstants
                                                          .billerDetail,
                                                      extra: BillerDetailArgs(
                                                        biller: biller,
                                                        isCreditCard: true,
                                                        paymentType:
                                                            biller.billerName.trim().isNotEmpty
                                                                ? biller.billerName.trim()
                                                                : categoryName,
                                                      ),
                                                    );
                                                  },
                                                ),
                                            ],
                                          ),
                                        ],
                                        if (listingState.isFetchingMore)
                                          const _CreditCardListingFooterSkeleton(),
                                        SizedBox(height: 12.h),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BillerGridTile extends StatelessWidget {
  const _BillerGridTile({required this.biller, this.onTap});

  final Biller biller;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Height is derived from width-scaled children (not a fixed 112 + .h),
    // so tall/wide phones cannot RenderFlex-overflow the Column.
    final pad = 10.w;
    final iconSize = 44.r;
    final gap = 10.w;
    final textHeight = 32.w;
    final tileHeight = pad * 2 + iconSize + gap + textHeight;
    final logoSize = 38.r;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        height: tileHeight,
        padding: EdgeInsets.all(pad),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ProviderIconFrame(
              size: iconSize,
              child: _BillerIcon(
                name: biller.billerName,
                iconUrl: biller.iconUrl,
                size: logoSize,
                backgroundColor: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            SizedBox(height: gap),
            SizedBox(
              height: textHeight,
              child: Text(
                biller.billerName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillerListTile extends StatelessWidget {
  const _BillerListTile({required this.biller, this.onTap});

  final Biller biller;
  final VoidCallback? onTap;

  /// Matches Electricity Fetch Your Provider operator rows: 50x50 logo card,
  /// 13sp Plus Jakarta name, square 24 arrow, width-scaled row gap.
  @override
  Widget build(BuildContext context) {
    final borderWidth = 1.w;
    final cardSize = FetchProviderMetrics.r(50);
    final cardPadding = FetchProviderMetrics.r(4);
    final logoSize = cardSize - 2 * (cardPadding + borderWidth);
    final arrowSize = FetchProviderMetrics.r(24);
    // Same Figma row gap rule as Electricity (screen width, not .h).
    final screenWidth = MediaQuery.sizeOf(context).width;
    final rowGap = screenWidth * 20 / 440;
    final name = biller.billerName.trim();
    final displayName = name
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: rowGap / 2),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: cardSize),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: cardSize,
                height: cardSize,
                padding: EdgeInsets.all(cardPadding),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(FetchProviderMetrics.r(16)),
                  border: Border.all(
                    color: AppColors.lightBorder2,
                    width: borderWidth,
                  ),
                ),
                child: _BillerIcon(
                  name: biller.billerName,
                  iconUrl: biller.iconUrl,
                  size: logoSize,
                  backgroundColor: Colors.white,
                  borderRadius:
                      BorderRadius.circular(FetchProviderMetrics.r(12)),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  displayName,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w500,
                    fontSize: 13.sp,
                    height: 1.35,
                    letterSpacing: 0,
                    color: const Color(0xFF000000),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Image.asset(
                FileConstants.tiltArrow,
                width: arrowSize,
                height: arrowSize,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BillerIcon extends StatelessWidget {
  const _BillerIcon({
    required this.name,
    required this.iconUrl,
    required this.size,
    required this.backgroundColor,
    required this.borderRadius,
  });

  final String name;
  final String? iconUrl;
  final double size;
  final Color backgroundColor;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '';
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );

    if (iconUrl == null || iconUrl!.isEmpty) {
      return fallback;
    }

    return AppNetworkImage(
      url: iconUrl,
      width: size,
      height: size,
      fit: BoxFit.contain,
      borderRadius: borderRadius,
      placeholder: fallback,
      errorWidget: fallback,
    );
  }
}

class _CreditCardListingSkeleton extends StatelessWidget {
  const _CreditCardListingSkeleton({required this.isSearching});

  final bool isSearching;

  static const _mockBillers = [
    Biller(billerId: '1', billerName: 'IndusInd Credit Card'),
    Biller(billerId: '2', billerName: 'HDFC Credit Card'),
    Biller(billerId: '3', billerName: 'SBI Credit Card'),
    Biller(billerId: '4', billerName: 'Axis Credit Card'),
    Biller(billerId: '5', billerName: 'ICICI Credit Card'),
    Biller(billerId: '6', billerName: 'Kotak Credit Card'),
  ];

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: IgnorePointer(
        child: Column(
          children: [
            Padding(
              padding: AppSearchBar.pinnedPadding,
              child: Container(
                height: AppSearchBar.height,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: AppColors.lightBorder),
                ),
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.textPrimary),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'Search by billers',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: isSearching
                  ? ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        FetchProviderMetrics.w(24),
                        FetchProviderMetrics.h(4),
                        FetchProviderMetrics.w(24),
                        16.h + MediaQuery.paddingOf(context).bottom,
                      ),
                      itemCount: _mockBillers.length,
                      itemBuilder: (_, index) => _BillerListTile(
                        biller: _mockBillers[index],
                        onTap: () {},
                      ),
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        FetchProviderMetrics.w(24),
                        0,
                        FetchProviderMetrics.w(24),
                        16.h + MediaQuery.paddingOf(context).bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Popular Banks',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          SizedBox(height: 12.h),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              const spacing = 12.0;
                              const columns = 3;
                              final tileWidth = (constraints.maxWidth -
                                      (spacing * (columns - 1))) /
                                  columns;
                              return Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: [
                                  for (final biller in _mockBillers.take(6))
                                    SizedBox(
                                      width: tileWidth,
                                      child: _BillerGridTile(
                                        biller: biller,
                                        onTap: () {},
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          SizedBox(height: 18.h),
                          Text(
                            'All Banks',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          SizedBox(height: 12.h),
                          for (final biller in _mockBillers)
                            _BillerListTile(biller: biller, onTap: () {}),
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

class _CreditCardListingFooterSkeleton extends StatelessWidget {
  const _CreditCardListingFooterSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: IgnorePointer(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: FetchProviderMetrics.w(24),
            vertical: 12.h,
          ),
          child: _BillerListTile(
            biller: Biller(billerId: '1', billerName: 'Loading Credit Card'),
            onTap: null,
          ),
        ),
      ),
    );
  }
}

class _ProviderIconFrame extends StatelessWidget {
  const _ProviderIconFrame({
    required this.child,
    required this.size,
  });

  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.lightBorder, width: 1),
      ),
      child: child,
    );
  }
}
