// ignore_for_file: deprecated_member_use

import 'package:e_rupaiya/constants/file_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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
import '../../home/controllers/home_controller.dart';
import '../../home/models/credit_card_item.dart';
import '../../profile/controllers/profile_controller.dart';
import '../components/credit_card/credit_card_figma_metrics.dart';
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
    final savedCards = ref.watch(homeControllerProvider).creditCardActions ??
        const <CreditCardItem>[];

    useEffect(() {
      Future.microtask(() {
        ref
            .read(billerListingControllerProvider.notifier)
            .fetchBillers(categoryName: categoryName, searchQuery: '');
        searchController.clear();
        if (ref.read(homeControllerProvider).creditCardActions == null) {
          ref.read(homeControllerProvider.notifier).fetchCreditCardActions();
        }
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

      final digits = txn.serviceNo.replaceAll(RegExp(r'\D'), '');
      final last4 =
          digits.length >= 4 ? digits.substring(digits.length - 4) : '';
      final mobile =
          (profileState.profile?.mobile ?? '').replaceAll(RegExp(r'\D'), '');

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
            showHelp: true,
            // Match the common app bar (Transaction History): default title
            // style + 52x25 Bharat Connect + 20px help icon.
            bharatConnectWidth: 52,
            bharatConnectHeight: 25,
            helpIconSize: 20,
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
                fontSize: CreditCardFigmaMetrics.s(context, 14),
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
                              child: Text(
                                'Retry',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                  fontSize: CreditCardFigmaMetrics.s(
                                    context,
                                    14,
                                  ),
                                ),
                              ),
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
                                CreditCardFigmaMetrics.s(context, 24),
                                CreditCardFigmaMetrics.sy(context, 4),
                                CreditCardFigmaMetrics.s(context, 24),
                                CreditCardFigmaMetrics.sy(context, 16) +
                                    MediaQuery.paddingOf(context).bottom,
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
                                          categoryName: biller.billerName
                                                  .trim()
                                                  .isNotEmpty
                                              ? biller.billerName.trim()
                                              : categoryName,
                                        );
                                    context.push(
                                      RouteConstants.billerDetail,
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
                                );
                              },
                            )
                          : SingleChildScrollView(
                              primary: false,
                              padding: EdgeInsets.only(
                                bottom: CreditCardFigmaMetrics.sy(context, 16) +
                                    MediaQuery.paddingOf(context).bottom,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ServiceRecentSection(
                                    recentTransactions: recentTransactions,
                                    onPayNow: openBillerFromRecent,
                                    serviceCategory: categoryName,
                                    operatorLogo: true,
                                    operatorBillers: billers,
                                    savedCards: savedCards,
                                    onAction: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => ServiceRecentAllView(
                                            categoryName: categoryName,
                                            operatorLogo: true,
                                            operatorBillers: billers,
                                            savedCards: savedCards,
                                            onPayNow: openBillerFromRecent,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal:
                                          CreditCardFigmaMetrics.s(context, 24),
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
                                        SizedBox(
                                            height: CreditCardFigmaMetrics.sy(
                                                context, 12)),
                                        LayoutBuilder(
                                          builder: (context, constraints) {
                                            final spacing =
                                                CreditCardFigmaMetrics.s(
                                              context,
                                              12,
                                            );
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
                                                              categoryName: biller
                                                                      .billerName
                                                                      .trim()
                                                                      .isNotEmpty
                                                                  ? biller
                                                                      .billerName
                                                                      .trim()
                                                                  : categoryName,
                                                            );
                                                        context.push(
                                                          RouteConstants
                                                              .billerDetail,
                                                          extra:
                                                              BillerDetailArgs(
                                                            biller: biller,
                                                            isCreditCard: true,
                                                            paymentType: biller
                                                                    .billerName
                                                                    .trim()
                                                                    .isNotEmpty
                                                                ? biller
                                                                    .billerName
                                                                    .trim()
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
                                          SizedBox(
                                              height: CreditCardFigmaMetrics.sy(
                                                  context, 18)),
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
                                          SizedBox(
                                              height: CreditCardFigmaMetrics.sy(
                                                  context, 12)),
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
                                                          categoryName: biller
                                                                  .billerName
                                                                  .trim()
                                                                  .isNotEmpty
                                                              ? biller
                                                                  .billerName
                                                                  .trim()
                                                              : categoryName,
                                                        );
                                                    context.push(
                                                      RouteConstants
                                                          .billerDetail,
                                                      extra: BillerDetailArgs(
                                                        biller: biller,
                                                        isCreditCard: true,
                                                        paymentType: biller
                                                                .billerName
                                                                .trim()
                                                                .isNotEmpty
                                                            ? biller.billerName
                                                                .trim()
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
                                        SizedBox(
                                            height: CreditCardFigmaMetrics.sy(
                                                context, 12)),
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
    final pad = CreditCardFigmaMetrics.s(context, 10);
    final iconSize = CreditCardFigmaMetrics.s(context, 44);
    final gap = CreditCardFigmaMetrics.s(context, 10);
    final textHeight = CreditCardFigmaMetrics.s(context, 32);
    final tileHeight = pad * 2 + iconSize + gap + textHeight;
    final logoSize = CreditCardFigmaMetrics.s(context, 38);

    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(CreditCardFigmaMetrics.s(context, 16)),
      child: Container(
        height: tileHeight,
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(CreditCardFigmaMetrics.s(context, 16)),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: CreditCardFigmaMetrics.s(context, 12),
              offset: Offset(CreditCardFigmaMetrics.s(context, 0),
                  CreditCardFigmaMetrics.sy(context, 6)),
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
                borderRadius: BorderRadius.circular(
                    CreditCardFigmaMetrics.s(context, 14)),
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
    final borderWidth = 1.0;
    final cardSize = CreditCardFigmaMetrics.s(context, 50);
    final cardPadding = CreditCardFigmaMetrics.s(context, 4);
    final logoSize = cardSize - 2 * (cardPadding + borderWidth);
    final arrowSize = CreditCardFigmaMetrics.s(context, 24);
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
                  borderRadius: BorderRadius.circular(
                      CreditCardFigmaMetrics.s(context, 16)),
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
                  borderRadius: BorderRadius.circular(
                      CreditCardFigmaMetrics.s(context, 12)),
                ),
              ),
              SizedBox(width: CreditCardFigmaMetrics.s(context, 10)),
              Expanded(
                child: Text(
                  displayName,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w500,
                    fontSize: CreditCardFigmaMetrics.s(context, 13),
                    height: 1.35,
                    letterSpacing: 0,
                    color: const Color(0xFF000000),
                  ),
                ),
              ),
              SizedBox(width: CreditCardFigmaMetrics.s(context, 10)),
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
                  borderRadius: BorderRadius.circular(
                      CreditCardFigmaMetrics.s(context, 14)),
                  border: Border.all(color: AppColors.lightBorder),
                ),
                padding: EdgeInsets.symmetric(
                    horizontal: CreditCardFigmaMetrics.s(context, 14)),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.textPrimary),
                    SizedBox(width: CreditCardFigmaMetrics.s(context, 10)),
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
                        CreditCardFigmaMetrics.s(context, 24),
                        CreditCardFigmaMetrics.sy(context, 4),
                        CreditCardFigmaMetrics.s(context, 24),
                        CreditCardFigmaMetrics.sy(context, 16) +
                            MediaQuery.paddingOf(context).bottom,
                      ),
                      itemCount: _mockBillers.length,
                      itemBuilder: (_, index) => _BillerListTile(
                        biller: _mockBillers[index],
                        onTap: () {},
                      ),
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        CreditCardFigmaMetrics.s(context, 24),
                        0,
                        CreditCardFigmaMetrics.s(context, 24),
                        CreditCardFigmaMetrics.sy(context, 16) +
                            MediaQuery.paddingOf(context).bottom,
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
                          SizedBox(
                              height: CreditCardFigmaMetrics.sy(context, 12)),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final spacing = CreditCardFigmaMetrics.s(
                                context,
                                12,
                              );
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
                          SizedBox(
                              height: CreditCardFigmaMetrics.sy(context, 18)),
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
                          SizedBox(
                              height: CreditCardFigmaMetrics.sy(context, 12)),
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
            horizontal: CreditCardFigmaMetrics.s(context, 24),
            vertical: CreditCardFigmaMetrics.sy(context, 12),
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
      padding: EdgeInsets.all(CreditCardFigmaMetrics.s(context, 3)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(CreditCardFigmaMetrics.s(context, 18)),
        border: Border.all(color: AppColors.lightBorder, width: 1),
      ),
      child: child,
    );
  }
}
