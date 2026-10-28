// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../home/controllers/home_tab_controller.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/app_search_bar.dart';
import '../../../widgets/infinite_scroll_listener.dart';
import '../../../widgets/my_app_bar.dart';
import '../../../widgets/screen_wrapper.dart';
import '../controllers/transaction_history_controller.dart';
import '../models/electricity_card_history_scope.dart';
import '../models/transaction_history_entry.dart';
import '../models/transaction_history_filter.dart';
import 'transaction_filter_screen.dart';

// --- Figma (440x956 frame) -> ScreenUtil single-scaling helpers -----------
// Same approved pre-compensation pattern as AppSearchBar / HomeServiceCircle:
// the value is first converted from the 440 frame to the 360 design width and
// then scaled exactly once by ScreenUtil, so a 440-wide phone renders the
// Figma pixel size and every other width scales proportionally.
double _figmaW(double px) => (px * 360 / 440).w;
double _figmaH(double px) => (px * 690 / 956).h;
double _figmaR(double px) => (px * 360 / 440).r;

/// Display-only "first letter of each word" casing (e.g. MOBILE PREPAID FOR
/// -> Mobile Prepaid For). Underlying entry data is never mutated.
String _capitalizeWords(String value) {
  if (value.isEmpty) return value;
  return value.toLowerCase().split(' ').map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1);
  }).join(' ');
}

/// The exact 5-layer box-shadow stack from the Figma card style:
/// 0/11/24 #DBDBDB1A, 0/43/43 #DBDBDB17, 0/97/58 #DBDBDB0D,
/// 0/172/69 #DBDBDB03, 0/270/75 #DBDBDB00.
/// CSS blur is 2 sigma, so Flutter blurRadius = figmaBlur / 2 (the same
/// conversion Figma's own Flutter export uses); offsets keep their values.
List<BoxShadow> _figmaCardShadow() => [
      BoxShadow(
        color: const Color(0x1ADBDBDB),
        offset: Offset(0, _figmaH(11)),
        blurRadius: _figmaR(12),
      ),
      BoxShadow(
        color: const Color(0x17DBDBDB),
        offset: Offset(0, _figmaH(43)),
        blurRadius: _figmaR(21.5),
      ),
      BoxShadow(
        color: const Color(0x0DDBDBDB),
        offset: Offset(0, _figmaH(97)),
        blurRadius: _figmaR(29),
      ),
      BoxShadow(
        color: const Color(0x03DBDBDB),
        offset: Offset(0, _figmaH(172)),
        blurRadius: _figmaR(34.5),
      ),
      BoxShadow(
        color: const Color(0x00DBDBDB),
        offset: Offset(0, _figmaH(270)),
        blurRadius: _figmaR(37.5),
      ),
    ];

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({
    super.key,
    this.initialServiceFilter,
    this.initialPaymentTypeFilter,
    this.initialConsumerIdFilter,
    this.initialElectricityCardScoped = false,
    this.initialCreditCardScoped = false,
  });

  final String? initialServiceFilter;
  final String? initialPaymentTypeFilter;
  final String? initialConsumerIdFilter;

  /// True only when opened from an Electricity Saved Biller card
  /// (3 dots -> View History). Generic/main history always uses false.
  final bool initialElectricityCardScoped;

  /// True only when opened from a Credit Card's History action.
  /// Requests `service=Credit Card` and `payment_type=Credit Card`.
  final bool initialCreditCardScoped;

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _monthCompletionScheduled = false;
  List<TransactionHistoryEntry>? _cachedItems;
  String _cachedQuery = '';
  List<_TxnSection> _cachedSections = const [];

  void _handleBack() {
    // Electricity card-scoped View History returns directly to the
    // Electricity Fetch Your Provider screen (the Saved Billers flow that
    // opened it). Generic history keeps its existing behavior below.
    if (widget.initialElectricityCardScoped) {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
        return;
      }
      context.go(
        RouteConstants.billerListing,
        extra: ElectricityCardHistoryScope.backFallbackCategory,
      );
      return;
    }
    if (widget.initialCreditCardScoped) {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
        return;
      }
      context.go(RouteConstants.creditCardMyCards);
      return;
    }
    final location = GoRouterState.of(context).matchedLocation;
    if (location == RouteConstants.transactions) {
      context.go(RouteConstants.home);
      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    ref.read(homeTabControllerProvider).jumpToTab(0);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Electricity card-scoped mode: fetch ALL pages for the selected card's
    // exact service_no_full. Generic history keeps the existing branches.
    if (widget.initialElectricityCardScoped) {
      final serviceNoFull = widget.initialConsumerIdFilter?.trim() ?? '';
      if (serviceNoFull.isNotEmpty) {
        Future.microtask(
          () => ref
              .read(transactionHistoryControllerProvider.notifier)
              .fetchElectricityCardHistory(serviceNoFull: serviceNoFull),
        );
        return;
      }
    }
    if (widget.initialCreditCardScoped) {
      final service = widget.initialServiceFilter?.trim();
      final paymentType = widget.initialPaymentTypeFilter?.trim();
      Future.microtask(
        () =>
            ref.read(transactionHistoryControllerProvider.notifier).applyFilter(
                  TransactionHistoryFilter(
                    service: service != null && service.isNotEmpty
                        ? service
                        : 'Credit Card',
                    paymentType: paymentType != null && paymentType.isNotEmpty
                        ? paymentType
                        : 'Credit Card',
                  ),
                ),
      );
      return;
    }
    final filterService = widget.initialServiceFilter?.trim();
    final filterConsumerId = widget.initialConsumerIdFilter?.trim();
    final hasService = filterService != null && filterService.isNotEmpty;
    final hasConsumerId =
        filterConsumerId != null && filterConsumerId.isNotEmpty;
    if (hasService || hasConsumerId) {
      final filter = TransactionHistoryFilter(
        service: hasService ? filterService : null,
        consumerId: hasConsumerId ? filterConsumerId : null,
      );
      // The controller owns the active filter (single source of truth); it
      // survives refresh/pagination/retry for the lifetime of this scope.
      Future.microtask(
        () => ref
            .read(transactionHistoryControllerProvider.notifier)
            .applyFilter(filter),
      );
    } else {
      Future.microtask(
        () => ref
            .read(transactionHistoryControllerProvider.notifier)
            .fetchHistory(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use select() to avoid full rebuilds when unrelated state changes
    final isLoading = ref.watch(
      transactionHistoryControllerProvider.select((s) => s.isLoading),
    );
    final items = ref.watch(
      transactionHistoryControllerProvider.select((s) => s.items),
    );
    final isFetchingMore = ref.watch(
      transactionHistoryControllerProvider.select((s) => s.isFetchingMore),
    );
    final hasMore = ref.watch(
      transactionHistoryControllerProvider.select((s) => s.hasMore),
    );
    final totalRecords = ref.watch(
      transactionHistoryControllerProvider.select((s) => s.totalRecords),
    );
    final selectedRange = ref.watch(
      transactionHistoryControllerProvider.select((s) => s.selectedRange),
    );
    final errorMessage = ref.watch(
      transactionHistoryControllerProvider.select((s) => s.errorMessage),
    );

    final controller = ref.read(transactionHistoryControllerProvider.notifier);
    final query = _searchController.text.trim().toLowerCase();
    final filteredItems = _filterItems(items, query, controller.activeFilter);
    final sections = _sectionsFor(items, query, filteredItems);
    final apiMonthTotal = _apiMonthTotal(
      items: items,
      filteredItems: filteredItems,
      query: query,
      filter: controller.activeFilter,
      range: selectedRange,
      totalRecords: totalRecords,
    );
    // Pages arrive newest first, so only the oldest loaded month can still
    // have rows on later pages. Electricity and generic history hide that
    // month until a later page proves it complete. Credit-card history is
    // already scoped by service=Credit Card, so its loaded rows stay visible.
    final incompleteMonth = widget.initialCreditCardScoped
        ? null
        : (hasMore && apiMonthTotal == null ? _trailingMonthKey(items) : null);
    final visibleSections = incompleteMonth == null
        ? sections
        : sections
            .where((section) => section.title != incompleteMonth)
            .toList(growable: false);
    final isCompletingMonth = visibleSections.length != sections.length;
    if (isCompletingMonth && errorMessage == null) {
      _scheduleMonthCompletion();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        body: Column(
          children: [
            MyAppBar(
              title: 'Transactions',
              showHelp: true,
              onBack: _handleBack,
              // No custom titleStyle on purpose: this falls through to
              // MyAppBar's default title style
              // (Theme.titleMedium.copyWith(color: black, fontWeight: w700)),
              // which is byte-for-byte identical to the Mobile Prepaid AppBar
              // title (font family, size, weight, letter spacing, line height,
              // alignment and color all match). The visible text is unchanged.
              bharatConnectWidth: 52,
              bharatConnectHeight: 25,
              helpIconSize: 20,
            ),
            Padding(
              // Pinned search row (Column above Expanded list). Same 16px
              // (440→360) above and below as AppSearchBar.pinnedPadding so
              // scrolled cards stop that far under the field.
              padding: AppSearchBar.pinnedPadding,
              // Reference: the field, then the filter icon outside it on the
              // right with no background. Icon and gap scale with the screen
              // width from the 440 frame.
              child: Builder(
                builder: (context) {
                  final scale = MediaQuery.sizeOf(context).width / 440;
                  final iconSize = (24 * scale).clamp(20.0, 28.0);
                  final tapWidth = (44 * scale).clamp(40.0, 52.0);
                  return Row(
                    children: [
                      Expanded(
                        child: AppSearchBar(
                          hintText: 'Search by Transactions',
                          controller: _searchController,
                          textStyle: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w500,
                            fontSize: 14.sp,
                            color: Colors.black,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      SizedBox(width: 6 * scale),
                      Semantics(
                        button: true,
                        label: 'Filter transactions',
                        child: GestureDetector(
                          key: const ValueKey('transaction-filter-button'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _openFilterScreen(controller),
                          child: SizedBox(
                            width: tapWidth,
                            height: AppSearchBar.height,
                            child: Center(
                              child: SvgPicture.string(
                                _transactionFilterSvg,
                                width: iconSize,
                                height: iconSize,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: isLoading
                  ? const _TransactionHistoryShimmer()
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => _handleRefresh(controller),
                      child: InfiniteScrollListener(
                        isLoading: isFetchingMore,
                        hasMore: hasMore,
                        onEndReached: () => controller.fetchNextPage(),
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            if (visibleSections.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: errorMessage != null
                                    ? ScreenWrapper(
                                        isFetching: false,
                                        isEmpty: false,
                                        emptyMessage: '',
                                        errorMessage: errorMessage,
                                        actions: [
                                          TextButton(
                                            onPressed: () => items.isEmpty
                                                ? _handleRefresh(controller)
                                                : controller.fetchNextPage(),
                                            child: const Text('Retry'),
                                          ),
                                        ],
                                        child: const SizedBox.shrink(),
                                      )
                                    : isCompletingMonth
                                        ? const Center(
                                            child: SpinKitCircle(
                                              color: AppColors.primary,
                                              size: 48,
                                            ),
                                          )
                                        : const _TransactionEmptyState(),
                              )
                            else ...[
                              for (final section in visibleSections) ...[
                                SliverToBoxAdapter(
                                  child: _MonthHeader(
                                    title: section.title,
                                    count:
                                        apiMonthTotal ?? section.items.length,
                                    isFirst: identical(
                                        section, visibleSections.first),
                                  ),
                                ),
                                SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final item = section.items[index];
                                      return _TransactionTile(
                                        item: item,
                                        onTap: () {
                                          context.push(
                                            RouteConstants
                                                .transactionDetailForStatus(
                                              item.paymentStatus,
                                            ),
                                            extra: item,
                                          );
                                        },
                                      );
                                    },
                                    childCount: section.items.length,
                                  ),
                                ),
                              ],
                              SliverToBoxAdapter(
                                child: SizedBox(height: 12.h),
                              ),
                              SliverToBoxAdapter(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: isFetchingMore
                                      ? Padding(
                                          padding:
                                              EdgeInsets.only(bottom: 24.h),
                                          child: const Center(
                                            child: SpinKitCircle(
                                              color: AppColors.primary,
                                              size: 48,
                                            ),
                                          ))
                                      : errorMessage != null && hasMore
                                          ? _LoadMoreError(
                                              message: errorMessage,
                                              onRetry: controller.fetchNextPage,
                                            )
                                          : SizedBox(height: 24.h),
                                ),
                              ),
                            ],
                            // Bottom system/gesture inset so the last
                            // transaction (or the empty state) stays clear of
                            // the navigation area. Applied once; this screen
                            // has no SafeArea, so there is no double-counting.
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height:
                                    MediaQuery.viewPaddingOf(context).bottom,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<TransactionHistoryEntry> _filterItems(
    List<TransactionHistoryEntry> items,
    String query,
    TransactionHistoryFilter? filter,
  ) {
    // Electricity card-scoped View History ONLY. The API request is already
    // scoped by service_no_full; this preserves every valid row for the
    // selected card (including rows missing service_no_full) and drops just
    // rows that explicitly belong to another card or another service.
    // Generic/main history uses the untouched path below.
    if (filter?.electricityCardScoped == true ||
        widget.initialElectricityCardScoped) {
      final target = (filter?.consumerId?.trim() ??
              widget.initialConsumerIdFilter?.trim() ??
              '')
          .replaceAll(RegExp(r'\s+'), '');
      // Same strict rule the controller already applied per page; kept here
      // so the visible list can never drift from the selected card's scope.
      final scoped = target.isEmpty
          ? items
              .where((item) => !item.isDefinitelyOtherService)
              .toList(growable: false)
          : items
              .where(
                ElectricityCardHistoryScope(serviceNoFull: target)
                    .includesEntry,
              )
              .toList(growable: false);
      if (query.isEmpty) return scoped;
      return scoped.where((item) {
        final haystack = '${item.billerName} ${item.paymentType}';
        return haystack.toLowerCase().contains(query);
      }).toList(growable: false);
    }
    if (widget.initialCreditCardScoped) {
      final scoped =
          items.where(_isCreditCardHistoryRow).toList(growable: false);
      if (query.isEmpty) return scoped;
      return scoped.where((item) {
        final haystack =
            '${item.billerName} ${item.paymentType} ${item.maskedIdentifier}';
        return haystack.toLowerCase().contains(query);
      }).toList(growable: false);
    }
    var filtered = items;
    final consumerFilter = filter?.consumerId?.trim();
    if (consumerFilter != null && consumerFilter.isNotEmpty) {
      // Safety net only: the API already scopes by service_no_full. Exact
      // candidate matching (see TransactionHistoryEntry.matchesConsumerId)
      // keeps unrelated short-substring rows out of the list.
      final normalizedTarget = consumerFilter.replaceAll(RegExp(r'\s+'), '');
      filtered = filtered
          .where((item) => item.matchesConsumerId(normalizedTarget))
          .toList(growable: false);
    }
    final serviceFilter = filter?.service?.trim().toLowerCase();
    if (serviceFilter != null && serviceFilter.isNotEmpty) {
      filtered = filtered.where((item) {
        final pt = item.paymentType.trim().toLowerCase();
        final bn = item.billerName.trim().toLowerCase();
        final sf = serviceFilter.toLowerCase();
        if (sf.contains('electric')) {
          return pt.contains('electric') || bn.contains('electric');
        }
        return pt.contains(sf) || bn.contains(sf) || sf.contains(pt);
      }).toList(growable: false);
    }
    if (query.isEmpty) return filtered;
    return filtered.where((item) {
      final haystack = '${item.billerName} ${item.paymentType}';
      return haystack.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  List<_TxnSection> _sectionsFor(
    List<TransactionHistoryEntry> items,
    String query,
    List<TransactionHistoryEntry> filteredItems,
  ) {
    if (identical(items, _cachedItems) && query == _cachedQuery) {
      return _cachedSections;
    }
    _cachedItems = items;
    _cachedQuery = query;
    final sections = _buildSections(filteredItems);
    _cachedSections = sections;
    return sections;
  }

  /// `total_records` is a month's count only when the request itself covered
  /// that calendar month and nothing narrows the rows on the device (search,
  /// consumer/service safety filters, card scope); otherwise counts come
  /// from the loaded records.
  int? _apiMonthTotal({
    required List<TransactionHistoryEntry> items,
    required List<TransactionHistoryEntry> filteredItems,
    required String query,
    required TransactionHistoryFilter? filter,
    required DateTimeRange? range,
    required int totalRecords,
  }) {
    if (widget.initialElectricityCardScoped ||
        filter?.electricityCardScoped == true) {
      return null;
    }
    // Consumer/service filters also run on the device and could drop rows
    // on pages not loaded yet, which the API total would still include.
    final narrowsOnDevice = (filter?.consumerId?.trim().isNotEmpty ?? false) ||
        (filter?.service?.trim().isNotEmpty ?? false);
    if (query.isNotEmpty ||
        narrowsOnDevice ||
        items.isEmpty ||
        filteredItems.length != items.length) {
      return null;
    }
    final month = _requestedMonth(filter, range);
    if (month == null) return null;
    for (final item in items) {
      final date = _parseTxnDate(item.transactionTime);
      if (date == null ||
          date.year != month.year ||
          date.month != month.month) {
        return null;
      }
    }
    return totalRecords >= items.length ? totalRecords : null;
  }

  /// Loads the next page through the existing pagination while the oldest
  /// month is still incomplete and the end of the list is in view (the same
  /// threshold [InfiniteScrollListener] uses).
  void _scheduleMonthCompletion() {
    if (_monthCompletionScheduled) return;
    _monthCompletionScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _monthCompletionScheduled = false;
      if (!mounted) return;
      final state = ref.read(transactionHistoryControllerProvider);
      if (state.isLoading ||
          state.isFetchingMore ||
          !state.hasMore ||
          state.errorMessage != null) {
        return;
      }
      final position =
          _scrollController.hasClients ? _scrollController.position : null;
      final endInView = position == null ||
          !position.hasContentDimensions ||
          position.maxScrollExtent - position.pixels <= _loadMoreEndOffset;
      if (endInView) {
        ref.read(transactionHistoryControllerProvider.notifier).fetchNextPage();
      }
    });
  }

  Future<void> _handleRefresh(TransactionHistoryController controller) async {
    // Reuse the controller's persistent filter so pull-to-refresh re-requests
    // page 1 for the SAME biller/consumer instead of falling back to the
    // generic history scope.
    final filter = controller.activeFilter;
    // Electricity card-scoped mode re-fetches ALL pages for the same card.
    if (filter != null && filter.electricityCardScoped) {
      final serviceNoFull = filter.consumerId?.trim() ?? '';
      if (serviceNoFull.isNotEmpty) {
        await controller.fetchElectricityCardHistory(
          serviceNoFull: serviceNoFull,
          status: filter.status,
          month: filter.month,
          fromDate: filter.fromDate,
          toDate: filter.toDate,
        );
        return;
      }
    }
    if (filter == null || filter.isEmpty) {
      await controller.fetchHistory();
      return;
    }
    await controller.applyFilter(filter);
  }

  Future<void> _openFilterScreen(
    TransactionHistoryController controller,
  ) async {
    final result = await PersistentNavBarNavigator.pushDynamicScreen<
        TransactionHistoryFilter>(
      context,
      withNavBar: false,
      screen: PageRouteBuilder<TransactionHistoryFilter>(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => TransactionFilterScreen(
          initialFilter: controller.activeFilter,
        ),
      ),
    );
    if (!mounted) return;
    if (result == null) return;
    // Electricity card-scoped mode keeps its card scope even when the user
    // refines status/date filters; only generic history may go fully generic.
    final scoped = controller.activeFilter?.electricityCardScoped == true ||
        widget.initialElectricityCardScoped;
    if (scoped) {
      final scopeId =
          controller.activeFilter?.consumerId?.trim().isNotEmpty == true
              ? controller.activeFilter!.consumerId!.trim()
              : widget.initialConsumerIdFilter?.trim() ?? '';
      if (scopeId.isEmpty) {
        if (result.isEmpty) {
          await controller.fetchHistory();
        } else {
          await controller.applyFilter(result);
        }
        return;
      }
      if (result.isEmpty) {
        await controller.fetchElectricityCardHistory(serviceNoFull: scopeId);
        return;
      }
      await controller.fetchElectricityCardHistory(
        serviceNoFull: scopeId,
        status: result.status,
        month: result.month,
        fromDate: result.fromDate,
        toDate: result.toDate,
      );
      return;
    }
    if (result.isEmpty) {
      await controller.fetchHistory();
    } else {
      await controller.applyFilter(result);
    }
  }
}

/// Card typography shared by every payment type (taken from the School Fee
/// card), so House Rent, Shop Rent, Education Fee and the rest stay identical.
abstract final class _TxnCardText {
  static TextStyle paymentType() => GoogleFonts.plusJakartaSans(
        fontSize: 10.sp,
        fontWeight: FontWeight.w400,
        height: 1,
        letterSpacing: 0,
        color: const Color(0xFF000000),
      );

  /// Also used for the consumer/mobile number line so Electricity, Mobile and
  /// other cards match the School Fee recipient line.
  static TextStyle recipientName() => GoogleFonts.plusJakartaSans(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: const Color(0xFF000000),
      );

  static TextStyle dateTime() => GoogleFonts.plusJakartaSans(
        fontSize: 10.sp,
        fontWeight: FontWeight.w400,
        height: 1.1,
        color: const Color(0xFF7C7C7C),
      );

  /// Colour follows the payment status, not the service.
  static TextStyle amount(Color color) => GoogleFonts.plusJakartaSans(
        fontSize: 15.sp,
        fontWeight: FontWeight.w700,
        height: 1.4,
        letterSpacing: 0,
        color: color,
      );
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.item, required this.onTap});

  final TransactionHistoryEntry item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final amount = item.amount.trim();
    final displayAmount =
        amount.isEmpty ? '' : (amount.startsWith('₹') ? amount : '₹ $amount');

    final status = _resolveStatus(item.paymentStatus);
    final amountColor = _amountColor(status);

    final creditCardRow = _isCreditCardHistoryRow(item);
    final bankName = item.billerName.trim();
    final displayPaymentType = creditCardRow && bankName.isNotEmpty
        ? bankName
        : _getDisplayPaymentType(item);
    final recipientDisplay = _getRecipientDisplay(item);
    final consumerNumber = _getConsumerDisplay(item);
    final consumerDisplay =
        consumerNumber == recipientDisplay ? '' : consumerNumber;

    return InkWell(
      onTap: onTap,
      customBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_figmaR(12)),
      ),
      child: Container(
        // Figma (measured on the 440 frame): 24px side margins, 12px
        // card-to-card gap (6 x 2), 76px card = 13px vertical padding +
        // 50px icon circle (tallest element), 16px left padding to the
        // circle. Pitch works out to exactly 88px, matching the reference.
        margin: EdgeInsets.symmetric(
          horizontal: _figmaW(24),
          vertical: _figmaW(6),
        ),
        padding: EdgeInsets.fromLTRB(
          _figmaW(16),
          _figmaW(13),
          _figmaW(16),
          _figmaW(13),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_figmaR(12)),
          boxShadow: _figmaCardShadow(),
        ),
        child: Row(
          children: [
            Container(
              width: _figmaR(50),
              height: _figmaR(50),
              padding: EdgeInsets.all(_figmaR(10)),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0x66FF835C),
                  width: 1,
                ),
              ),
              child: Center(
                child: SizedBox(
                  // Identical inner icon box on every row regardless of
                  // status/service type (outer circle is already fixed).
                  width: _figmaR(30),
                  height: _figmaR(30),
                  child: AppNetworkImage(
                    url: item.iconUrl,
                    fit: BoxFit.contain,
                    showShimmer: false,
                  ),
                ),
              ),
            ),
            SizedBox(width: _figmaW(12)),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _capitalizeWords(displayPaymentType),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _TxnCardText.paymentType(),
                  ),
                  if (creditCardRow &&
                      item.paymentType.trim().isNotEmpty &&
                      item.paymentType.trim().toLowerCase() !=
                          displayPaymentType.trim().toLowerCase()) ...[
                    SizedBox(height: _figmaW(6)),
                    Text(
                      _capitalizeWords(item.paymentType),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _TxnCardText.recipientName(),
                    ),
                  ],
                  if (recipientDisplay.isNotEmpty) ...[
                    SizedBox(height: _figmaW(6)),
                    Text(
                      recipientDisplay,
                      key: const ValueKey('transaction-recipient-name'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _TxnCardText.recipientName(),
                    ),
                  ],
                  if (consumerDisplay.isNotEmpty) ...[
                    SizedBox(height: _figmaW(6)),
                    Text(
                      consumerDisplay,
                      key: const ValueKey('transaction-consumer-number'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _TxnCardText.recipientName(),
                    ),
                  ],
                  // Show fee_type above date/time for House Rent and Shop Rent
                  if (_shouldShowFeeType(item)) ...[
                    SizedBox(height: _figmaW(6)),
                    Text(
                      _getFeeTypeDisplay(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                        color: const Color(0xFF7C7C7C),
                      ),
                    ),
                  ],
                  SizedBox(height: _figmaW(6)),
                  Text(
                    _formatTxnTime(item.transactionTime),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _TxnCardText.dateTime(),
                  ),
                ],
              ),
            ),
            SizedBox(width: _figmaW(8)),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ConstrainedBox(
                  // Defensive cap: an unusually large amount ellipsizes
                  // instead of overflowing the card at 320px. Normal amounts
                  // are far narrower and render exactly as before.
                  constraints: BoxConstraints(maxWidth: 150.w),
                  child: Text(
                    displayAmount,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _TxnCardText.amount(amountColor),
                  ),
                ),
                SizedBox(height: _figmaW(4)),
                _StatusChip(
                  status: status,
                  methodIcon: item.methodIcon,
                  method: item.method,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
    required this.methodIcon,
    required this.method,
  });

  final _TxnStatus status;
  final String methodIcon;
  final String method;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case _TxnStatus.success:
        return _PaidFromBadge(methodIcon: methodIcon);
      case _TxnStatus.failed:
        // "Failed" red pill badge
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: _figmaW(8),
            vertical: _figmaW(3),
          ),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(_figmaR(10)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Failed',
                // Same text style/size as the Paid From / Processing SVG
                // badges, whose baked glyph size is ~10.3px on the 440
                // frame (= 8.4.sp). 8.5.sp matches them visually.
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 8.5.sp,
                  fontWeight: FontWeight.w600,
                  height: 1,
                  letterSpacing: 0,
                  color: Colors.red,
                ),
              ),
              SizedBox(width: _figmaW(4)),
              Icon(
                Icons.info_outline,
                size: _figmaR(13),
                color: Colors.red,
              ),
            ],
          ),
        );
      case _TxnStatus.processing:
        // "Processing" orange pill badge — exact SVG from design
        return SvgPicture.asset(
          'assets/images/badge_processing.svg',
          height: _figmaR(20),
          fit: BoxFit.contain,
        );
    }
  }
}

/// "Paid From" pill. The payment-source icon is [methodIcon] (`method_icon`
/// from the history API). A missing or non-network value leaves the text
/// only — it does not fall back to a bundled icon.
class _PaidFromBadge extends StatelessWidget {
  const _PaidFromBadge({required this.methodIcon});

  final String methodIcon;

  static bool _isNetworkIcon(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  @override
  Widget build(BuildContext context) {
    final iconUrl = methodIcon.trim();
    final showIcon = _isNetworkIcon(iconUrl);
    final iconSize = _figmaR(11);
    return Container(
      height: _figmaR(21),
      padding: EdgeInsets.only(
        left: _figmaW(7),
        right: showIcon ? _figmaW(4) : _figmaW(8),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF058337).withOpacity(0.1),
        borderRadius: BorderRadius.circular(_figmaR(10.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Paid From',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8.5.sp,
              fontWeight: FontWeight.w600,
              height: 1,
              letterSpacing: 0,
              color: const Color(0xFF058337),
            ),
          ),
          if (showIcon) ...[
            SizedBox(width: _figmaW(4)),
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: iconUrl.toLowerCase().endsWith('.svg')
                  ? SvgPicture.network(
                      iconUrl,
                      width: iconSize,
                      height: iconSize,
                      fit: BoxFit.contain,
                      placeholderBuilder: (_) =>
                          SizedBox(width: iconSize, height: iconSize),
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    )
                  : AppNetworkImage(
                      url: iconUrl,
                      width: iconSize,
                      height: iconSize,
                      fit: BoxFit.contain,
                      showShimmer: false,
                      placeholder: SizedBox(width: iconSize, height: iconSize),
                      errorWidget: const SizedBox.shrink(),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.title,
    required this.count,
    this.isFirst = false,
  });

  final String title;
  final int count;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final countLabel = '$count Transaction${count == 1 ? '' : 's'}';
    return Padding(
      // Figma (440 frame): 24px side margins. Header ink sits ~25px below
      // the previous card bottom (incl. the 6px card margin) and ~22px above
      // the next card top. The first header already has the search row's
      // 16px bottom gap above it, so it only adds a little more.
      padding: EdgeInsets.fromLTRB(
        _figmaW(24),
        isFirst ? _figmaW(4) : _figmaW(15),
        _figmaW(24),
        _figmaW(12),
      ),
      child: Row(
        children: [
          // Long month names ellipsize instead of pushing the count out.
          Expanded(
            child: Text(
              // Capitalize per spec (month names already are).
              _capitalizeWords(title),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                height: 1,
                letterSpacing: 0,
                color: const Color(0xFF000000),
              ),
            ),
          ),
          SizedBox(width: _figmaW(8)),
          Text(
            countLabel,
            maxLines: 1,
            // Same size as the month/year title (12.sp); Plus Jakarta Sans
            // w600, 100% line-height, 0% letter-spacing, capitalize (the
            // label is built as "3 Transactions", already capitalized).
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              height: 1,
              letterSpacing: 0,
              color: const Color(0xFF7C7C7C),
            ),
          ),
        ],
      ),
    );
  }
}

enum _TxnStatus { success, failed, processing }

_TxnStatus _resolveStatus(String raw) {
  final value = raw.trim().toLowerCase().replaceAll('-', '_');
  if (value.contains('fail') || value.contains('refund')) {
    return _TxnStatus.failed;
  }
  if (value.contains('process') || value.contains('pending')) {
    return _TxnStatus.processing;
  }
  return _TxnStatus.success;
}

Color _amountColor(_TxnStatus status) {
  switch (status) {
    case _TxnStatus.failed:
      return Colors.red;
    case _TxnStatus.processing:
      return Colors.orange;
    case _TxnStatus.success:
      return const Color(0xFF000000);
  }
}

const int _txnCacheMaxEntries = 1000;
final Map<String, DateTime?> _txnDateCache = <String, DateTime?>{};
final Map<String, String> _txnTimeLabelCache = <String, String>{};
final Map<String, String> _txnMonthKeyCache = <String, String>{};

void _putBounded<K, V>(Map<K, V> map, K key, V value) {
  if (map.length >= _txnCacheMaxEntries && !map.containsKey(key)) {
    map.remove(map.keys.first);
  }
  map[key] = value;
}

String _formatTxnTime(String raw) {
  final key = raw.trim();
  final cached = _txnTimeLabelCache[key];
  if (cached != null) return cached;

  if (key.isEmpty) {
    _putBounded(_txnTimeLabelCache, key, '');
    return '';
  }
  final parsed = _parseTxnDate(key);
  if (parsed == null) {
    _putBounded(_txnTimeLabelCache, key, key);
    return key;
  }
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
  final day = parsed.day.toString().padLeft(2, '0');
  final month = months[parsed.month - 1];
  final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
  final minute = parsed.minute.toString().padLeft(2, '0');
  final ampm = parsed.hour >= 12 ? 'PM' : 'AM';
  final label = '$day $month, $hour:$minute$ampm';
  _putBounded(_txnTimeLabelCache, key, label);
  return label;
}

const double _loadMoreEndOffset = 240;

DateTime? _requestedMonth(
  TransactionHistoryFilter? filter,
  DateTimeRange? range,
) {
  final from = filter?.fromDate ?? range?.start;
  final to = filter?.toDate ?? range?.end;
  if (from != null && to != null) {
    return from.year == to.year && from.month == to.month
        ? DateTime(from.year, from.month)
        : null;
  }
  final match =
      RegExp(r'^(\d{4})-(\d{1,2})$').firstMatch(filter?.month?.trim() ?? '');
  if (match == null) return null;
  return DateTime(int.parse(match[1]!), int.parse(match[2]!));
}

bool _isCreditCardHistoryRow(TransactionHistoryEntry item) {
  // Identity uses fields the history model already parses. Customer-param
  // labels are included only for a positive credit-card signal, because a
  // credit-card row's "Registered Mobile Number" param would otherwise look
  // like a mobile recharge.
  final identity =
      '${item.paymentType} ${item.billerName} ${item.feeType ?? ''}'
          .toLowerCase();
  final paramLabels =
      item.customerParams.map((param) => param.label).join(' ').toLowerCase();
  if (_containsCreditCard('$identity $paramLabels')) return true;
  if (_isDefinitelyNonCreditCardService(identity)) return false;
  // The request is already `service=Credit Card`. A bank row whose
  // payment_type/biller_name is only the bank ("HDFC Bank") is still a
  // credit-card transaction and must stay visible.
  return true;
}

bool _containsCreditCard(String value) {
  return value.contains('credit card') || value.contains('creditcard');
}

bool _isDefinitelyNonCreditCardService(String haystack) {
  final value = haystack.trim();
  if (value.isEmpty) return false;
  const markers = <String>[
    'fastag',
    'mobile',
    'recharge',
    'postpaid',
    'prepaid',
    'tuition',
    'tution',
    'school',
    'college',
    'education',
    'dth',
    'gas',
    'water',
    'broadband',
    'landline',
    'insurance',
    'loan',
    'electric',
    'rent',
  ];
  return markers.any(value.contains);
}

/// Month of the oldest dated row loaded so far.
String? _trailingMonthKey(List<TransactionHistoryEntry> items) {
  for (final item in items.reversed) {
    if (_parseTxnDate(item.transactionTime) != null) {
      return _monthKey(item.transactionTime);
    }
  }
  return null;
}

class _LoadMoreError extends StatelessWidget {
  const _LoadMoreError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(_figmaW(24), 0, _figmaW(24), 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF7C7C7C),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _TxnSection {
  const _TxnSection({required this.title, required this.items});
  final String title;
  final List<TransactionHistoryEntry> items;
}

List<_TxnSection> _buildSections(List<TransactionHistoryEntry> items) {
  if (items.isEmpty) return const [];
  final sections = <String, List<TransactionHistoryEntry>>{};
  for (final item in items) {
    final key = _monthKey(item.transactionTime);
    sections.putIfAbsent(key, () => []).add(item);
  }
  return sections.entries
      .map((e) => _TxnSection(title: e.key, items: e.value))
      .toList();
}

String _monthKey(String raw) {
  final key = raw.trim();
  final cached = _txnMonthKeyCache[key];
  if (cached != null) return cached;

  final parsed = _parseTxnDate(key);
  if (parsed == null) {
    _putBounded(_txnMonthKeyCache, key, 'Transactions');
    return 'Transactions';
  }
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
  final label = '${months[parsed.month - 1]},${parsed.year}';
  _putBounded(_txnMonthKeyCache, key, label);
  return label;
}

DateTime? _parseTxnDate(String raw) {
  final key = raw.trim();
  if (_txnDateCache.containsKey(key)) return _txnDateCache[key];

  if (key.isEmpty) {
    _putBounded(_txnDateCache, key, null);
    return null;
  }
  final direct = DateTime.tryParse(
    key.contains(' ') ? key.replaceFirst(' ', 'T') : key,
  );
  if (direct != null) {
    _putBounded(_txnDateCache, key, direct);
    return direct;
  }

  final match = RegExp(
    r'(\d{1,2})\s+([A-Za-z]{3,})(?:\s+(\d{4}))?,\s*(\d{1,2}):(\d{2})(am|pm|AM|PM)',
  ).firstMatch(key);
  if (match == null) {
    _putBounded(_txnDateCache, key, null);
    return null;
  }

  final day = int.parse(match.group(1)!);
  final monthRaw = match.group(2)!.toLowerCase();
  final year =
      match.group(3) != null ? int.parse(match.group(3)!) : DateTime.now().year;
  var hour = int.parse(match.group(4)!);
  final minute = int.parse(match.group(5)!);
  final ampm = match.group(6)!.toLowerCase();

  if (ampm == 'pm' && hour < 12) hour += 12;
  if (ampm == 'am' && hour == 12) hour = 0;

  const months = [
    'january',
    'february',
    'march',
    'april',
    'may',
    'june',
    'july',
    'august',
    'september',
    'october',
    'november',
    'december',
  ];
  var monthIndex = months.indexWhere(
    (name) => name.startsWith(monthRaw),
  );
  if (monthIndex == -1) {
    monthIndex = months.indexWhere(
      (name) => monthRaw.startsWith(name.substring(0, 3)),
    );
  }
  if (monthIndex == -1) {
    _putBounded(_txnDateCache, key, null);
    return null;
  }

  final dt = DateTime(year, monthIndex + 1, day, hour, minute);
  _putBounded(_txnDateCache, key, dt);
  return dt;
}

String _getDisplayPaymentType(TransactionHistoryEntry item) {
  // Primary label is the API payment_type. The specific fee_type (when present)
  // is rendered separately below via _shouldShowFeeType / _getFeeTypeDisplay, so
  // returning it here as well would duplicate the same value in the tile.
  return item.paymentType;
}

/// API `recipient_name` (see [TransactionHistoryEntry.recipientName]); empty
/// when the API sent none, so nothing is shown rather than a guess.
String _getRecipientDisplay(TransactionHistoryEntry item) {
  final name = item.recipientName?.trim() ?? '';
  if (name.isEmpty ||
      name.toLowerCase() == 'null' ||
      name.toLowerCase() == item.paymentType.trim().toLowerCase()) {
    return '';
  }
  return name;
}

String _getConsumerDisplay(TransactionHistoryEntry item) {
  final consumer = item.primaryConsumerNumber;
  if (consumer.isNotEmpty &&
      consumer.toLowerCase() != 'null' &&
      consumer != item.paymentType) {
    return consumer;
  }
  return '';
}

String _formatFeeType(String feeType) {
  switch (feeType.toLowerCase()) {
    case 'school fee':
    case 'school fees':
      return 'School Fee';
    case 'college fee':
    case 'college fees':
      return 'College Fee';
    case 'tuition fee':
    case 'tuition fees':
    case 'tution fee':
    case 'tution fees':
      return 'Tuition Fee';
    default:
      return feeType;
  }
}

bool _shouldShowFeeType(TransactionHistoryEntry item) {
  final feeType = item.feeType?.trim().toLowerCase();
  final paymentType = item.paymentType.trim().toLowerCase();
  // Only show fee_type for House Rent and Shop Rent
  return (feeType?.contains('rent') == true) ||
      (paymentType.contains('rent') && feeType != null && feeType.isNotEmpty);
}

String _getFeeTypeDisplay(TransactionHistoryEntry item) {
  final feeType = item.feeType?.trim();
  if (feeType != null && feeType.isNotEmpty) {
    return _formatFeeType(feeType);
  }
  return '';
}

class _TransactionEmptyState extends StatelessWidget {
  const _TransactionEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 100.r,
              height: 100.r,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Image.asset(
                    FileConstants.history,
                    width: 40.w,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              'No Transactions Found.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Once You Make A Payment Or Receive Funds,\n'
              'Your History Will Appear Here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.6),
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionHistoryShimmer extends StatelessWidget {
  const _TransactionHistoryShimmer();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: IgnorePointer(
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(0, _figmaW(16), 0, 80.h),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: 6,
          itemBuilder: (_, __) => const _TransactionTileSkeleton(),
        ),
      ),
    );
  }
}

class _TransactionTileSkeleton extends StatelessWidget {
  const _TransactionTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: _figmaW(24),
        vertical: _figmaW(6),
      ),
      padding: EdgeInsets.fromLTRB(
        _figmaW(16),
        _figmaW(13),
        _figmaW(16),
        _figmaW(13),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_figmaR(12)),
        boxShadow: _figmaCardShadow(),
      ),
      child: Row(
        children: [
          Container(
            width: _figmaR(50),
            height: _figmaR(50),
            padding: EdgeInsets.all(_figmaR(10)),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0x66FF835C),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: _figmaR(30),
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(width: _figmaW(12)),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loading transaction',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    letterSpacing: 0,
                    color: const Color(0xFF000000),
                  ),
                ),
                SizedBox(height: _figmaW(6)),
                Text(
                  '1234567890',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: const Color(0xFF000000),
                  ),
                ),
                SizedBox(height: _figmaW(6)),
                Text(
                  '01 January, 12:00AM',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w400,
                    height: 1.1,
                    color: const Color(0xFF7C7C7C),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: _figmaW(8)),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹ 0.00',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  letterSpacing: 0,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: _figmaW(4)),
              Text(
                'Paid From',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 8.5.sp,
                  fontWeight: FontWeight.w600,
                  height: 1,
                  letterSpacing: 0,
                  color: const Color(0xFF7C7C7C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const String _transactionFilterSvg = '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M9 5.00001C8.73478 5.00001 8.48043 5.10537 8.29289 5.2929C8.10536 5.48044 8 5.73479 8 6.00001C8 6.26523 8.10536 6.51958 8.29289 6.70712C8.48043 6.89465 8.73478 7.00001 9 7.00001C9.26522 7.00001 9.51957 6.89465 9.70711 6.70712C9.89464 6.51958 10 6.26523 10 6.00001C10 5.73479 9.89464 5.48044 9.70711 5.2929C9.51957 5.10537 9.26522 5.00001 9 5.00001ZM6.17 5.00001C6.3766 4.41448 6.75974 3.90744 7.2666 3.5488C7.77346 3.19015 8.37909 2.99756 9 2.99756C9.62091 2.99756 10.2265 3.19015 10.7334 3.5488C11.2403 3.90744 11.6234 4.41448 11.83 5.00001H19C19.2652 5.00001 19.5196 5.10537 19.7071 5.2929C19.8946 5.48044 20 5.73479 20 6.00001C20 6.26523 19.8946 6.51958 19.7071 6.70712C19.5196 6.89465 19.2652 7.00001 19 7.00001H11.83C11.6234 7.58554 11.2403 8.09258 10.7334 8.45122C10.2265 8.80986 9.62091 9.00246 9 9.00246C8.37909 9.00246 7.77346 8.80986 7.2666 8.45122C6.75974 8.09258 6.3766 7.58554 6.17 7.00001H5C4.73478 7.00001 4.48043 6.89465 4.29289 6.70712C4.10536 6.51958 4 6.26523 4 6.00001C4 5.73479 4.10536 5.48044 4.29289 5.2929C4.48043 5.10537 4.73478 5.00001 5 5.00001H6.17ZM15 11C14.7348 11 14.4804 11.1054 14.2929 11.2929C14.1054 11.4804 14 11.7348 14 12C14 12.2652 14.1054 12.5196 14.2929 12.7071C14.4804 12.8947 14.7348 13 15 13C15.2652 13 15.5196 12.8947 15.7071 12.7071C15.8946 12.5196 16 12.2652 16 12C16 11.7348 15.8946 11.4804 15.7071 11.2929C15.5196 11.1054 15.2652 11 15 11ZM12.17 11C12.3766 10.4145 12.7597 9.90744 13.2666 9.5488C13.7735 9.19015 14.3791 8.99756 15 8.99756C15.6209 8.99756 16.2265 9.19015 16.7334 9.5488C17.2403 9.90744 17.6234 10.4145 17.83 11H19C19.2652 11 19.5196 11.1054 19.7071 11.2929C19.8946 11.4804 20 11.7348 20 12C20 12.2652 19.8946 12.5196 19.7071 12.7071C19.5196 12.8947 19.2652 13 19 13H17.83C17.6234 13.5855 17.2403 14.0926 16.7334 14.4512C16.2265 14.8099 15.6209 15.0025 15 15.0025C14.3791 15.0025 13.7735 14.8099 13.2666 14.4512C12.7597 14.0926 12.3766 13.5855 12.17 13H5C4.73478 13 4.48043 12.8947 4.29289 12.7071C4.10536 12.5196 4 12.2652 4 12C4 11.7348 4.10536 11.4804 4.29289 11.2929C4.48043 11.1054 4.73478 11 5 11H12.17ZM9 17C8.73478 17 8.48043 17.1054 8.29289 17.2929C8.10536 17.4804 8 17.7348 8 18C8 18.2652 8.10536 18.5196 8.29289 18.7071C8.48043 18.8947 8.73478 19 9 19C9.26522 19 9.51957 18.8947 9.70711 18.7071C9.89464 18.5196 10 18.2652 10 18C10 17.7348 9.89464 17.4804 9.70711 17.2929C9.51957 17.1054 9.26522 17 9 17ZM6.17 17C6.3766 16.4145 6.75974 15.9074 7.2666 15.5488C7.77346 15.1902 8.37909 14.9976 9 14.9976C9.62091 14.9976 10.2265 15.1902 10.7334 15.5488C11.2403 15.9074 11.6234 16.4145 11.83 17H19C19.2652 17 19.5196 17.1054 19.7071 17.2929C19.8946 17.4804 20 17.7348 20 18C20 18.2652 19.8946 18.5196 19.7071 18.7071C19.5196 18.8947 19.2652 19 19 19H11.83C11.6234 19.5855 11.2403 20.0926 10.7334 20.4512C10.2265 20.8099 9.62091 21.0025 9 21.0025C8.37909 21.0025 7.77346 20.8099 7.2666 20.4512C6.75974 20.0926 6.3766 19.5855 6.17 19H5C4.73478 19 4.48043 18.8947 4.29289 18.7071C4.10536 18.5196 4 18.2652 4 18C4 17.7348 4.10536 17.4804 4.29289 17.2929C4.48043 17.1054 4.73478 17 5 17H6.17Z" fill="black"/>
</svg>
''';
