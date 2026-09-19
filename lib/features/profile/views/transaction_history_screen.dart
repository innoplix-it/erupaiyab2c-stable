// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../home/controllers/home_tab_controller.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/infinite_scroll_listener.dart';
import '../../../widgets/k_dialog.dart';
import '../../../widgets/my_app_bar.dart';
import '../../../widgets/search_textfield.dart';
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
              title: 'Transaction History',
              showHelp: true,
              onBack: _handleBack,
              onHelp: () {},
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
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                            sliver: SliverToBoxAdapter(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: SearchTextfield(
                                      hintText: 'Search Transactions',
                                      controller: _searchController,
                                      onChange: (_) => setState(() {}),
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  SizedBox(
                                    height: 46.h,
                                    width: 46.h,
                                    child: IconButton(
                                      onPressed: () {
                                        _openFilterScreen(controller);
                                      },
                                      icon: const Icon(
                                        Icons.tune,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
      screen: MaterialPageRoute<TransactionHistoryFilter>(
        builder: (_) => TransactionFilterScreen(
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
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.4),
                ),
              ),
              child: Center(
                child: AppNetworkImage(
                  url: item.iconUrl,
                  width: 22.w,
                  height: 22.w,
                  fit: BoxFit.contain,
                  cacheWidth:
                      (22 * MediaQuery.devicePixelRatioOf(context)).toInt(),
                  cacheHeight:
                      (22 * MediaQuery.devicePixelRatioOf(context)).toInt(),
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
              'Pending',
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
      color: const Color(0xFFF4F4F4),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
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
      return Colors.green;
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
  final label = '$day $month ${parsed.year}, $hour:$minute$ampm';
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
            SizedBox(
              width: 100.w,
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
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.4),
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
