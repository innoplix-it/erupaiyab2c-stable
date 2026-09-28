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
import '../../../widgets/common_search_bar.dart';
import '../../../widgets/infinite_scroll_listener.dart';
import '../../../widgets/k_dialog.dart';
import '../../../widgets/my_app_bar.dart';
import '../controllers/transaction_history_controller.dart';
import '../models/transaction_history_entry.dart';
import '../models/transaction_history_filter.dart';
import 'transaction_filter_screen.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  TransactionHistoryFilter? _activeFilter;
  List<TransactionHistoryEntry>? _cachedItems;
  String _cachedQuery = '';
  List<_TxnSection> _cachedSections = const [];

  void _handleBack() {
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
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(transactionHistoryControllerProvider.notifier)
          .fetchHistory(),
    );
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

    final controller = ref.read(transactionHistoryControllerProvider.notifier);
    final query = _searchController.text.trim().toLowerCase();
    final filteredItems = _filterItems(items, query);
    final sections = _sectionsFor(items, query, filteredItems);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            MyAppBar(
              title: 'Transactions',
              showHelp: true,
              onBack: _handleBack,
              titleStyle: GoogleFonts.bricolageGrotesque(
                fontSize: 18.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF000000),
              ),
              bharatConnectWidth: 52,
              bharatConnectHeight: 25,
              helpIconSize: 20,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
              child: SizedBox(
                height: 48.h,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: CommonSearchBar(
                        hintText: 'Search Transactions',
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        height: 48.h,
                        radius: 12.r,
                        fillColor: const Color(0xFFFFFFFF),
                        borderColor: const Color(0xFFE6E6E6),
                        borderWidth: 1,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x14000000),
                            offset: Offset(0, 2.h),
                            blurRadius: 10.r,
                          ),
                        ],
                        searchIconOnRight: true,
                        searchIconWidth: 22.w,
                        searchIconHeight: 22.h,
                        searchIconInset: 14.w,
                        contentPadding: EdgeInsets.only(left: 4.w),
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w500,
                          fontSize: 14.sp,
                          height: 18.h / 14.sp,
                          color: const Color(0xFF000000),
                        ),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w500,
                          fontSize: 14.sp,
                          height: 18.h / 14.sp,
                          color: const Color(0xFF000000),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    GestureDetector(
                      onTap: () => _openFilterScreen(controller),
                      child: SizedBox(
                        width: 24.w,
                        height: 24.h,
                        child: SvgPicture.string(
                          _transactionFilterSvg,
                          width: 24.w,
                          height: 24.h,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
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
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          if (filteredItems.isEmpty)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: _TransactionEmptyState(),
                            )
                          else ...[
                            for (final section in sections) ...[
                              SliverToBoxAdapter(
                                child: _MonthHeader(title: section.title),
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
                                        padding: EdgeInsets.only(bottom: 24.h),
                                        child: const Center(
                                          child: SpinKitCircle(
                                            color: AppColors.primary,
                                            size: 48,
                                          ),
                                        ))
                                    : SizedBox(height: 24.h),
                              ),
                            ),
                          ],
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
  ) {
    if (query.isEmpty) return items;
    return items.where((item) {
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

  Future<void> _handleRefresh(TransactionHistoryController controller) async {
    final filter = _activeFilter;
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
          initialFilter: _activeFilter,
        ),
      ),
    );
    if (!mounted) return;
    if (result == null) return;
    _activeFilter = result;
    if (result.isEmpty) {
      await controller.fetchHistory();
    } else {
      await controller.applyFilter(result);
    }
  }
}

class _TransactionFilterRow extends StatelessWidget {
  const _TransactionFilterRow({
    required this.selectedDays,
    required this.selectedRange,
    this.selectedLastYears,
    required this.onTap,
  });

  final int selectedDays;
  final DateTimeRange? selectedRange;
  final int? selectedLastYears;
  final VoidCallback onTap;

  String _formatLabel() {
    if (selectedLastYears != null) {
      return 'Last ${selectedLastYears!} years';
    }
    if (selectedRange == null) {
      return 'Last $selectedDays days';
    }
    final start = selectedRange!.start;
    final end = selectedRange!.end;
    return '${_formatDate(start)} - ${_formatDate(end)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Pre-compute styles outside child tree
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        );
    final filterLabelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textPrimary.withOpacity(0.8),
          fontWeight: FontWeight.w600,
        );

    return Row(
      children: [
        Text('All Transactions', style: labelStyle),
        const Spacer(),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            child: Row(
              children: [
                Text(_formatLabel(), style: filterLabelStyle),
                SizedBox(width: 6.w),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 18.sp,
                  color: AppColors.textPrimary.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
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

    final titleStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        );
    final subStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textPrimary.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        );
    final status = _resolveStatus(item.paymentStatus);
    final amountColor = _amountColor(status);
    final amountStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          color: amountColor,
          fontWeight: FontWeight.w700,
        );

    final displayPaymentType = _getDisplayPaymentType(item);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: AppColors.lightBorder.withOpacity(0.8),
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0x66FF835C),
                  width: 1,
                ),
              ),
              child: Center(
                child: AppNetworkImage(
                  url: item.iconUrl,
                  width: 30.w,
                  height: 30.w,
                  fit: BoxFit.contain,
                  cacheWidth:
                      (30 * MediaQuery.devicePixelRatioOf(context)).toInt(),
                  cacheHeight:
                      (30 * MediaQuery.devicePixelRatioOf(context)).toInt(),
                  showShimmer: false,
                  fitToDeviceWidth: true,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayPaymentType, style: titleStyle),
                  SizedBox(height: 1.h),
                  Text(_formatTxnTime(item.transactionTime), style: subStyle),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(displayAmount, style: amountStyle),
                SizedBox(height: 1.h),
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
        final iconUrl = methodIcon.trim();
        final mode = method.trim();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Paid From',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (iconUrl.isNotEmpty) ...[
              SizedBox(width: 6.w),
              AppNetworkImage(
                url: iconUrl,
                width: 16.w,
                height: 16.w,
                fit: BoxFit.contain,
                showShimmer: false,
              ),
            ] else if (mode.isNotEmpty) ...[
              SizedBox(width: 6.w),
              Text(
                mode,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ],
        );
      case _TxnStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Failed',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(width: 4.w),
            Icon(
              Icons.info_outline,
              size: 14.sp,
              color: Colors.red,
            ),
          ],
        );
      case _TxnStatus.processing:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Processing',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(width: 4.w),
            Icon(
              Icons.refresh,
              size: 14.sp,
              color: Colors.orange,
            ),
          ],
        );
    }
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 44.h,
      color: const Color(0xFFEFEFEF),
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 12.h),
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 20.h,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              height: 1,
              letterSpacing: 0,
              color: const Color(0xFF000000),
            ),
          ),
        ),
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
  final feeType = item.feeType?.trim();
  if (feeType != null && feeType.isNotEmpty) {
    return _formatFeeType(feeType);
  }
  return item.paymentType;
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

class _FilterFab extends StatelessWidget {
  const _FilterFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.filter_list, color: Colors.white),
      label: Text(
        'Filters',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

Future<void> _openFilterSheet(
  BuildContext context, {
  required TransactionHistoryController controller,
  required int selectedDays,
  required int? selectedLastYears,
  required DateTimeRange? selectedRange,
}) async {
  KDialog.instance.openSheet(
    dialog: _TransactionFilterSheet(
      selectedDays: selectedDays,
      selectedLastYears: selectedLastYears,
      selectedRange: selectedRange,
      onSelectDays: (days) {
        Navigator.of(context).pop();
        controller.applyDaysFilter(days);
      },
      onSelectLastYears: (years) {
        Navigator.of(context).pop();
        controller.applyLastYears(years);
      },
      onSelectRange: (range) {
        Navigator.of(context).pop();
        controller.applyDateRange(range);
      },
    ),
  );
}

class _TransactionFilterSheet extends StatefulWidget {
  const _TransactionFilterSheet({
    required this.selectedDays,
    this.selectedLastYears,
    required this.selectedRange,
    required this.onSelectDays,
    required this.onSelectLastYears,
    required this.onSelectRange,
  });

  final int selectedDays;
  final int? selectedLastYears;
  final DateTimeRange? selectedRange;
  final ValueChanged<int> onSelectDays;
  final ValueChanged<int> onSelectLastYears;
  final ValueChanged<DateTimeRange> onSelectRange;

  @override
  State<_TransactionFilterSheet> createState() =>
      _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<_TransactionFilterSheet> {
  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: widget.selectedRange,
    );
    if (picked != null) {
      widget.onSelectRange(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filters',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Divider(color: AppColors.lightBorder.withOpacity(0.7)),
          _FilterOption(
            label: 'Last 30 days',
            selected: widget.selectedRange == null && widget.selectedDays == 30,
            onTap: () => widget.onSelectDays(30),
          ),
          _FilterOption(
            label: 'Last 60 days',
            selected: widget.selectedRange == null && widget.selectedDays == 60,
            onTap: () => widget.onSelectDays(60),
          ),
          _FilterOption(
            label: 'Last 90 days',
            selected: widget.selectedRange == null && widget.selectedDays == 90,
            onTap: () => widget.onSelectDays(90),
          ),
          _FilterOption(
            label: 'Last 180 days',
            selected:
                widget.selectedRange == null && widget.selectedDays == 180,
            onTap: () => widget.onSelectDays(180),
          ),
          _FilterOption(
            label: 'Last 4 years',
            selected: widget.selectedLastYears == 4,
            onTap: () => widget.onSelectLastYears(4),
          ),
          _FilterOption(
            label: 'Custom date range',
            selected: widget.selectedRange != null,
            onTap: _pickRange,
          ),
        ],
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  const _FilterOption({
    required this.label,
    required this.onTap,
    required this.selected,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      trailing: Icon(
        selected ? Icons.check_circle : Icons.arrow_forward,
        color: selected ? AppColors.primary : AppColors.textPrimary,
      ),
      onTap: onTap,
    );
  }
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
            SizedBox(width: 100.w,
              height: 100.w,
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
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 80.h),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: 6,
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
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
    final titleStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        );
    final subStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textPrimary.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        );
    final amountStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Colors.green,
          fontWeight: FontWeight.w700,
        );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.lightBorder.withOpacity(0.8),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 50.w,
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: const Color(0x66FF835C),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 20.sp,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Loading transaction', style: titleStyle),
                SizedBox(height: 1.h),
                Text('Loading date & time', style: subStyle),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹ 0.00', style: amountStyle),
              SizedBox(height: 1.h),
              Text('Paid From', style: subStyle),
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
