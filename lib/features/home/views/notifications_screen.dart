// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:e_rupaiya/features/refer_and_earn/views/refer_and_earn_wallet_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/routes_constant.dart';
import '../../../services/notification_badge_service.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/infinite_scroll_listener.dart';
import '../../../widgets/my_app_bar.dart';
import '../../profile/controllers/transaction_history_controller.dart';
import '../../services/controllers/credit_card_transactions_controller.dart';
import '../controllers/notifications_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/home_tab_controller.dart';
import '../helpers/bill_reminder_payment.dart';
import '../helpers/notification_transaction_resolver.dart';
import '../models/notification_item.dart';

final notificationReadIdsProvider =
    StateProvider.autoDispose<Set<String>>((ref) => <String>{});

final notificationTransactionResolverProvider =
    Provider<NotificationTransactionResolver>(
  (ref) => NotificationTransactionResolver(
    ref.watch(transactionHistoryRepositoryProvider),
    creditCards: ref.watch(creditCardTransactionsRepositoryProvider),
  ),
);

final notificationBillPaymentResolverProvider =
    Provider<NotificationBillPaymentResolver>(
  (ref) => NotificationBillPaymentResolver(ref.watch(homeRepositoryProvider)),
);

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final Set<String> _dismissedIds = <String>{};

  // Guards against double-tap while the clear operation runs.
  bool _isClearing = false;

  // Held from the lookup until the opened screen is popped, so a second tap
  // cannot call the API again or push the screen twice.
  bool _isOpening = false;

  // True only while an API lookup runs; shows the loading overlay.
  bool _isLookingUp = false;

  Future<void> _onNotificationTap(NotificationItem item) async {
    if (_isOpening) return;
    _markNotificationRead(ref, item);
    final isPayNow = _primaryLabelFor(item) == 'Pay Now';
    final isTransaction = item.isTransactionNotification;
    if (!isPayNow && !isTransaction && !item.mayReferToTransaction) {
      _handleNotificationRedirect(context, item);
      return;
    }

    _isOpening = true;
    try {
      if (isPayNow) {
        await _openBillPayment(item);
      } else {
        await _openTransaction(item, isTransaction: isTransaction);
      }
    } finally {
      _isOpening = false;
      if (mounted && _isLookingUp) setState(() => _isLookingUp = false);
    }
  }

  Future<T> _lookUp<T>(Future<T> Function() lookup) async {
    setState(() => _isLookingUp = true);
    try {
      return await lookup();
    } finally {
      if (mounted) setState(() => _isLookingUp = false);
    }
  }

  Future<void> _openBillPayment(NotificationItem item) async {
    final lookup = await _lookUp(
      () => ref.read(notificationBillPaymentResolverProvider).resolve(item),
    );
    if (!mounted) return;
    final reminder = lookup.value;
    if (lookup.status == NotificationLookupStatus.failed) {
      AppSnackbar.show(
        'Could not load bill details. Please try again.',
        type: AppSnackbarType.error,
      );
      return;
    }
    if (reminder == null) {
      if (!_handleNotificationRedirect(context, item)) {
        AppSnackbar.show(
          'Bill details are not available for this notification.',
          type: AppSnackbarType.error,
        );
      }
      return;
    }
    if (!reminder.canPayNow) {
      AppSnackbar.show(
        'This bill cannot be paid right now.',
        type: AppSnackbarType.error,
      );
      return;
    }
    await openBillReminderPayment(context, ref, reminder);
  }

  Future<void> _openTransaction(
    NotificationItem item, {
    required bool isTransaction,
  }) async {
    final lookup = await _lookUp(
      () =>
          ref.read(notificationTransactionResolverProvider).lookupTarget(item),
    );
    if (!mounted) return;
    final target = lookup.value;
    if (target != null) {
      await context.push(target.route, extra: target.extra);
      return;
    }
    if (!isTransaction) {
      _handleNotificationRedirect(context, item);
      return;
    }
    if (lookup.status == NotificationLookupStatus.failed) {
      AppSnackbar.show(
        'Could not load transaction details. Please try again.',
        type: AppSnackbarType.error,
      );
      return;
    }
    AppSnackbar.show(
      'Transaction details are not available for this notification.',
      type: AppSnackbarType.error,
    );
    await context.push(RouteConstants.transactions);
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(notificationsControllerProvider.notifier)
          .fetchNotifications(),
    );
  }

  /// Confirmation before clearing: "Yes" calls the verified
  /// `POST /api/notification/clear-read` endpoint through the controller and
  /// refreshes from the server response; "No" closes without any API call.
  void _showClearAllDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _ConfirmClearAllDialog(
        onCancel: () => Navigator.of(dialogContext).pop(),
        onConfirm: () {
          Navigator.of(dialogContext).pop();
          _clearReadNotifications();
        },
      ),
    );
  }

  Future<void> _clearReadNotifications() async {
    // Prevent duplicate requests while the clear + refresh is in flight.
    if (_isClearing) return;
    setState(() => _isClearing = true);
    try {
      final ok = await ref
          .read(notificationsControllerProvider.notifier)
          .clearReadNotifications();
      if (ok) {
        // The controller already refreshed the feed; the server response
        // drives the list, so nothing is deleted locally before success.
        AppSnackbar.show(
          'All read notifications cleared',
          type: AppSnackbarType.success,
        );
      } else {
        // API failed: current notification data stays untouched.
        AppSnackbar.show(
          'Failed to clear notifications. Please try again.',
          type: AppSnackbarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }

  /// Empty/error state pinned to the exact center of the available area, so
  /// the top and bottom padding stay equal. Still scrollable (and
  /// pull-to-refresh friendly) via AlwaysScrollableScrollPhysics.
  Widget _buildCenteredEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: const Center(
              child: _NotificationsEmptyState(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificationsState = ref.watch(notificationsControllerProvider);
    final localReadIds = ref.watch(notificationReadIdsProvider);
    final items = notificationsState.notifications
        .where((n) => !_dismissedIds.contains(n.id))
        .toList(growable: false);
    final unreadCountToSync = notificationsState.unreadCount > 0
        ? notificationsState.unreadCount
        : items.where((n) => !n.isRead && !localReadIds.contains(n.id)).length;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationBadgeService.syncFromList(unreadCountToSync);
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: _LookupOverlay(
        isLoading: _isLookingUp,
        child: Column(
        children: [
          MyAppBar(
            title: 'Notifications',
            showHelp: true,
            // trailing: unreadCount > 0 ? _CountBadge(count: unreadCount) : null,
            onBack: () {
              final navigator = Navigator.of(context);
              if (navigator.canPop()) {
                navigator.pop();
                return;
              }
              ref.read(homeTabControllerProvider).jumpToTab(0);
            },
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref
                  .read(notificationsControllerProvider.notifier)
                  .fetchNotifications(force: true),
              child: notificationsState.isLoading
                  ? const _NotificationsLoadingSkeleton()
                  : notificationsState.errorMessage != null
                      ? _buildCenteredEmptyState()
                      : items.isEmpty
                          ? _buildCenteredEmptyState()
                          : InfiniteScrollListener(
                              isLoading: notificationsState.isFetchingMore,
                              hasMore: notificationsState.hasMore,
                              onEndReached: () => ref
                                  .read(
                                      notificationsControllerProvider.notifier)
                                  .fetchNextPage(),
                              child: Builder(
                                builder: (context) {
                                  final unreadNotifications = items
                                      .where((n) =>
                                          !n.isRead &&
                                          !localReadIds.contains(n.id))
                                      .toList(growable: false);
                                  final updates = items
                                      .where((n) =>
                                          n.isRead ||
                                          localReadIds.contains(n.id))
                                      .toList(growable: false);

                                  final entries = <_NotificationsListEntry>[
                                    if (unreadNotifications.isNotEmpty) ...[
                                      const _NotificationsListEntry.header(
                                          'Unread'),
                                      ...unreadNotifications
                                          .map(_NotificationsListEntry.unread),
                                    ],
                                    if (updates.isNotEmpty) ...[
                                      const _NotificationsListEntry.header(
                                          'Updates'),
                                      ...updates
                                          .map(_NotificationsListEntry.update),
                                    ],
                                    const _NotificationsListEntry
                                        .bottomSpacer(),
                                  ];

                                  return CustomScrollView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    slivers: [
                                      SliverPadding(
                                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0.h),
                                        sliver: SliverList(
                                          delegate: SliverChildBuilderDelegate(
                                            (context, index) {
                                              final entry = entries[index];
                                              if (entry.kind ==
                                                  _NotificationsListEntryKind
                                                      .header) {
                                                // "Clear All" sits in the same
                                                // row as the section heading,
                                                // right corner. It shows on the
                                                // first heading whenever there
                                                // are read notifications.
                                                final showClearAll =
                                                    updates.isNotEmpty &&
                                                        (entry.headerText ==
                                                                'Unread' ||
                                                            unreadNotifications
                                                                .isEmpty);
                                                return Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        _SectionTitle(
                                                            entry
                                                                .headerText ??
                                                                ''),
                                                        const Spacer(),
                                                        if (showClearAll)
                                                          InkWell(
                                                            onTap:
                                                                _showClearAllDialog,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              8.r,
                                                            ),
                                                            child: Padding(
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                horizontal: 4.w,
                                                                vertical: 4.h,
                                                              ),
                                                              child: Text(
                                                                'Clear All',
                                                                style: Theme.of(context)
                                                                    .textTheme
                                                                    .bodyMedium
                                                                    ?.copyWith(
                                                                      color: AppColors
                                                                          .primary,
                                                                      fontWeight:
                                                                          FontWeight.w700,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    SizedBox(height: 10.h),
                                                  ],
                                                );
                                              }
                                              if (entry.kind ==
                                                  _NotificationsListEntryKind
                                                      .bottomSpacer) {
                                                return SizedBox(height: 24.h);
                                              }

                                              final item = entry.item!;
                                              return Padding(
                                                padding: EdgeInsets.only(
                                                    bottom: 12.h),
                                                child: RepaintBoundary(
                                                  child: _NotificationCard(
                                                    item: item,
                                                    onClose: () {
                                                      _handleNotificationClose(
                                                          ref, item);
                                                      setState(() =>
                                                          _dismissedIds
                                                              .add(item.id));
                                                    },
                                                    onPrimary: () => unawaited(
                                                      _onNotificationTap(item),
                                                    ),
                                                    primaryLabel:
                                                        _primaryLabelFor(item),
                                                  ),
                                                ),
                                              );
                                            },
                                            childCount: entries.length,
                                          ),
                                        ),
                                      ),
                                      SliverToBoxAdapter(
                                        child: AnimatedSwitcher(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          child: notificationsState
                                                  .isFetchingMore
                                              ? Padding(
                                                  padding: EdgeInsets.only(
                                                      bottom: 24.h),
                                                  child: const Center(
                                                    child: SpinKitCircle(
                                                      color: AppColors.primary,
                                                      size: 48,
                                                    ),
                                                  ),
                                                )
                                              : SizedBox(height: 24.h),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/// Blocks the list with a loader while a notification's target is looked up.
class _LookupOverlay extends StatelessWidget {
  const _LookupOverlay({required this.isLoading, required this.child});

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          const Positioned.fill(
            child: AbsorbPointer(
              child: ColoredBox(
                color: Color(0x33000000),
                child: Center(
                  child: SpinKitCircle(color: AppColors.primary, size: 48),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

enum _NotificationsListEntryKind { header, unread, update, bottomSpacer }

class _NotificationsListEntry {
  const _NotificationsListEntry._(
    this.kind, {
    this.headerText,
    this.item,
  });

  const _NotificationsListEntry.header(String text)
      : this._(_NotificationsListEntryKind.header, headerText: text);

  const _NotificationsListEntry.unread(NotificationItem item)
      : this._(_NotificationsListEntryKind.unread, item: item);

  const _NotificationsListEntry.update(NotificationItem item)
      : this._(_NotificationsListEntryKind.update, item: item);

  const _NotificationsListEntry.bottomSpacer()
      : this._(_NotificationsListEntryKind.bottomSpacer);

  final _NotificationsListEntryKind kind;
  final String? headerText;
  final NotificationItem? item;
}

void _handleNotificationClose(WidgetRef ref, NotificationItem item) {
  final readIds = ref.read(notificationReadIdsProvider);
  final isAlreadyRead = item.isRead || readIds.contains(item.id);
  if (!isAlreadyRead) {
    NotificationBadgeService.decrement();
    ref.read(notificationReadIdsProvider.notifier).state = {
      ...readIds,
      item.id,
    };
    unawaited(
      ref.read(notificationsRepositoryProvider).markNotificationRead(item.id),
    );
  }
}

void _markNotificationRead(WidgetRef ref, NotificationItem item) {
  final readIds = ref.read(notificationReadIdsProvider);
  final isAlreadyRead = item.isRead || readIds.contains(item.id);
  if (!isAlreadyRead) {
    NotificationBadgeService.decrement();
    ref.read(notificationReadIdsProvider.notifier).state = {
      ...readIds,
      item.id,
    };
    unawaited(
      ref.read(notificationsRepositoryProvider).markNotificationRead(item.id),
    );
  }
}

/// Returns false when [item] has no destination of its own.
bool _handleNotificationRedirect(BuildContext context, NotificationItem item) {
  final redirect = (item.redirectScreen ?? '').trim().toLowerCase();
  if (redirect == 'app_update_screen') {
    unawaited(_openPlayStore());
    return true;
  }
  if (redirect == 'spin_screen') {
    context.push(RouteConstants.spinAndWin);
    return true;
  }
  if (redirect == 'wallet_history') {
    PersistentNavBarNavigator.pushNewScreen(
      context,
      screen: const ReferAndEarnWalletView(),
      withNavBar: false,
    );
    return true;
  }
  if (redirect == 'bill_history') {
    context.push(RouteConstants.transactions);
    return true;
  }

  final combined = '${item.title} ${item.subtitle}'.toLowerCase();
  if (combined.contains('spin')) {
    context.push(RouteConstants.spinAndWin);
    return true;
  }
  if (combined.contains('wallet')) {
    PersistentNavBarNavigator.pushNewScreen(
      context,
      screen: const ReferAndEarnWalletView(),
      withNavBar: false,
    );
    return true;
  }
  return false;
}

Future<void> _openPlayStore() async {
  try {
    final info = await PackageInfo.fromPlatform();
    final packageName = info.packageName.trim();
    if (packageName.isEmpty) return;
    final uri =
        Uri.parse('https://play.google.com/store/apps/details?id=$packageName');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
}

String _primaryLabelFor(NotificationItem item) {
  if (item.isBillPaymentSuccessNotification) return 'View';
  final redirect = (item.redirectScreen ?? '').trim().toLowerCase();
  if (redirect == 'spin_screen') return 'Play Now';
  if (redirect == 'app_update_screen') return 'Tap To Update';
  if (item.isBillReminderNotification) return 'Pay Now';
  return 'View';
}

String _relativeAge(DateTime? dateTime) {
  if (dateTime == null) return '';
  final diff = DateTime.now().difference(dateTime);
  if (diff.inDays >= 1) return '${diff.inDays}d';
  if (diff.inHours >= 1) return '${diff.inHours}h';
  if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
  return 'now';
}

/// Dismiss ("X") icon supplied for the Alerts screen.
const String _notificationCloseSvg = '''
<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M5.18748 4.00907C5.03031 3.85727 4.81981 3.77328 4.60131 3.77518C4.38281 3.77708 4.1738 3.86472 4.0193 4.01922C3.86479 4.17373 3.77715 4.38274 3.77525 4.60124C3.77335 4.81974 3.85735 5.03024 4.00915 5.18741L8.82165 9.99991L4.00831 14.8124C3.92872 14.8893 3.86524 14.9812 3.82156 15.0829C3.77789 15.1846 3.7549 15.2939 3.75394 15.4046C3.75298 15.5152 3.77406 15.625 3.81596 15.7274C3.85786 15.8298 3.91974 15.9228 3.99798 16.0011C4.07623 16.0793 4.16927 16.1412 4.27168 16.1831C4.3741 16.225 4.48383 16.2461 4.59448 16.2451C4.70513 16.2442 4.81448 16.2212 4.91615 16.1775C5.01782 16.1338 5.10977 16.0703 5.18665 15.9907L9.99998 11.1782L14.8125 15.9907C14.9696 16.1425 15.1802 16.2265 15.3986 16.2246C15.6171 16.2227 15.8262 16.1351 15.9807 15.9806C16.1352 15.8261 16.2228 15.6171 16.2247 15.3986C16.2266 15.1801 16.1426 14.9696 15.9908 14.8124L11.1783 9.99991L15.9908 5.18741C16.1426 5.03024 16.2266 4.81974 16.2247 4.60124C16.2228 4.38274 16.1352 4.17373 15.9807 4.01922C15.8262 3.86472 15.6171 3.77708 15.3986 3.77518C15.1802 3.77328 14.9696 3.85727 14.8125 4.00907L9.99998 8.82157L5.18748 4.00907Z" fill="black"/>
</svg>
''';

/// Relative-time clock icon supplied for the Alerts screen.
const String _notificationTimerSvg = '''
<svg width="14" height="14" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M7.00033 1.16675C6.23428 1.16675 5.47574 1.31763 4.76801 1.61078C4.06027 1.90394 3.41721 2.33362 2.87554 2.87529C1.78157 3.96925 1.16699 5.45298 1.16699 7.00008C1.16699 8.54718 1.78157 10.0309 2.87554 11.1249C3.41721 11.6665 4.06027 12.0962 4.76801 12.3894C5.47574 12.6825 6.23428 12.8334 7.00033 12.8334C8.54742 12.8334 10.0312 12.2188 11.1251 11.1249C12.2191 10.0309 12.8337 8.54718 12.8337 7.00008C12.8337 6.23404 12.6828 5.47549 12.3896 4.76776C12.0965 4.06003 11.6668 3.41697 11.1251 2.87529C10.5834 2.33362 9.94038 1.90394 9.23265 1.61078C8.52491 1.31763 7.76637 1.16675 7.00033 1.16675ZM9.45033 9.45008L6.41699 7.58341V4.08341H7.29199V7.11675L9.91699 8.69175L9.45033 9.45008Z" fill="#A4A4A4"/>
</svg>
''';

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.onPrimary,
    required this.primaryLabel,
    this.onClose,
  });

  final NotificationItem item;
  final VoidCallback onPrimary;
  final String primaryLabel;
  final VoidCallback? onClose;

  static final RegExp _amountRegExp =
      RegExp(r'(\u20B9\s?[\d][\d,]*(?:\.\d+)?)');

  List<TextSpan> _titleSpans(String text, TextStyle base) {
    if (text.isEmpty) return <TextSpan>[TextSpan(text: text, style: base)];
    final spans = <TextSpan>[];
    var last = 0;
    for (final match in _amountRegExp.allMatches(text)) {
      if (match.start > last) {
        spans.add(
          TextSpan(text: text.substring(last, match.start), style: base),
        );
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: base.copyWith(color: AppColors.primary),
      ));
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last), style: base));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final ageText = _relativeAge(item.createdAt);
    final iconUrl = (item.iconUrl ?? '').trim();
    final titleStyle =
        (Theme.of(context).textTheme.bodyMedium ?? const TextStyle()).copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
      height: 1.25,
    );

    final radius = BorderRadius.circular(16.r);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        border: Border.all(color: AppColors.textPrimary.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16.r,
            offset: Offset(0.w, 8.h),
          ),
        ],
      ),
      // The whole card opens the notification; the close button keeps its
      // own tap.
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        child: InkWell(
          key: ValueKey('notification-card-${item.id}'),
          onTap: onPrimary,
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: _buildContent(context, ageText, iconUrl, titleStyle),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    String ageText,
    String iconUrl,
    TextStyle titleStyle,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48.r,
          height: 48.r,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.lightBorder2),
          ),
          child: Center(
            child: AppNetworkImage(
              url: iconUrl,
              width: 28.r,
              height: 28.r,
              fit: BoxFit.contain,
              showShimmer: true,
              errorWidget: Image.asset(
                item.iconAsset,
                width: 28.r,
                height: 28.r,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                  TextSpan(children: _titleSpans(item.title, titleStyle))),
              SizedBox(height: 4.h),
              Text(
                item.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary.withOpacity(0.72),
                      height: 1.25,
                    ),
              ),
              SizedBox(height: 8.h),
              InkWell(
                onTap: onPrimary,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  child: Text(
                    primaryLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(999.r),
              child: Padding(
                padding: EdgeInsets.all(4.r),
                child: SvgPicture.string(
                  _notificationCloseSvg,
                  width: 18.r,
                  height: 18.r,
                ),
              ),
            ),
            if (ageText.isNotEmpty) ...[
              SizedBox(height: 10.h),
              SvgPicture.string(
                _notificationTimerSvg,
                width: 12.r,
                height: 12.r,
              ),
              SizedBox(height: 4.h),
              Text(
                ageText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary.withOpacity(0.45),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Confirmation popup reusing the project's standard Dialog pattern
/// (same shape/typography as the bank-account delete confirmation):
/// white No = OutlinedButton, orange (#DD5428) Yes = ElevatedButton.
class _ConfirmClearAllDialog extends StatelessWidget {
  const _ConfirmClearAllDialog({
    required this.onCancel,
    required this.onConfirm,
  });

  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Are you sure you want to clear all notifications?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.75),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            SizedBox(height: 18.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    child: const Text(
                      'No',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text(
                      'Yes',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _NotificationsLoadingSkeleton extends StatelessWidget {
  const _NotificationsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: IgnorePointer(
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
          itemCount: 6,
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
          itemBuilder: (_, __) => const _NotificationCardSkeleton(),
        ),
      ),
    );
  }
}

class _NotificationCardSkeleton extends StatelessWidget {
  const _NotificationCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.textPrimary.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16.r,
            offset: Offset(0.w, 8.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38.r,
                height: 38.r,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loading notification title',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Loading notification subtitle goes here',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              Container(
                width: 26.r,
                height: 26.r,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(999.r),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 30.h,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: SizedBox(
                  height: 30.h,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationsEmptyState extends StatelessWidget {
  const _NotificationsEmptyState();

  /// Exact Figma mailbox icon (70x66) shown inside the soft circle.
  static const String _emptyIconSvg = '''
<svg width="70" height="66" viewBox="0 0 70 66" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M68.9769 39.9265H63.7158C63.7675 39.7183 63.7979 39.5021 63.7979 39.278V22.217C63.7979 20.7313 62.589 19.5224 61.1033 19.5224H60.2841C57.6817 15.6557 54.1054 13.6951 49.6449 13.6951H39.5887V1.02312C39.5887 0.458186 39.1307 0 38.5656 0H22.2279C21.663 0 21.2048 0.458186 21.2048 1.02312V7.12465C21.2048 7.68975 21.663 8.14777 22.2279 8.14777H34.3242V13.6951H15.3251C11.7321 13.6951 8.68779 14.9837 6.27681 17.525C-0.726428 24.9071 0.00254364 40.3499 0.0371591 41.0037C0.0658064 41.5469 0.514614 41.9729 1.05874 41.9729H27.0031V64.1901C27.0031 64.755 27.4613 65.2132 28.0263 65.2132H34.699C35.264 65.2132 35.7221 64.755 35.7221 64.1901V41.9727H68.9769C69.5418 41.9727 70 41.5147 70 40.9496C70 40.3847 69.5418 39.9265 68.9769 39.9265ZM61.1035 21.5687C61.3964 21.5687 61.6416 21.7653 61.7218 22.0325C59.8935 23.6799 51.8187 30.9445 50.3215 32.0858C49.2998 32.8644 48.0918 32.8796 48.056 32.8798C48.0529 32.8796 48.0497 32.8796 48.0463 32.8796C48.0434 32.8796 48.0406 32.8799 48.0378 32.8801C48.0354 32.8801 48.0335 32.8798 48.0311 32.8798H48.0303C47.9931 32.8798 46.7967 32.8673 45.7712 32.0858C45.03 31.5209 42.4029 29.226 38.3517 25.6049C38.8265 24.1862 39.4113 22.8145 40.1364 21.5687H61.1035ZM42.3879 31.9092L36.4392 36.791C36.5606 34.3164 36.889 31.0255 37.7145 27.7794C39.6744 29.5282 41.2352 30.9075 42.3879 31.9092ZM57.7245 19.5224H41.5578C41.7268 19.3199 41.9009 19.1231 42.081 18.9333C44.0902 16.8153 46.6352 15.7413 49.6447 15.7413C52.9122 15.7413 55.6211 17.0143 57.7245 19.5224ZM23.2512 6.10153V2.04624H37.5426V6.10153H23.2512ZM37.5426 8.14777V13.6951H36.3706V8.14777H37.5426ZM7.76119 18.9333C9.77076 16.8153 12.3154 15.7413 15.3251 15.7413H42.6926C41.9492 16.2449 41.2489 16.8374 40.5966 17.5252C34.5713 23.8765 34.27 36.1942 34.3251 39.9267H2.05577C2.01638 36.4736 2.30371 24.6863 7.76119 18.9333ZM29.0494 63.1668V41.9727H33.6759V63.1668H29.0494ZM36.3759 39.9265C36.3744 39.795 36.3735 39.6468 36.3734 39.4918L43.968 33.2595C44.2053 33.4566 44.3937 33.6087 44.5308 33.7131C46.0486 34.8701 47.7704 34.9241 48.0284 34.9255C48.0292 34.9255 48.0301 34.9257 48.0311 34.9257C48.0331 34.9257 48.0386 34.9257 48.043 34.9257C48.0458 34.9257 48.0466 34.9257 48.05 34.9257H48.062C48.063 34.9257 48.0638 34.9255 48.0647 34.9255C48.3227 34.924 50.0437 34.8701 51.5617 33.7131C51.7012 33.6067 51.8922 33.4525 52.1246 33.2593L60.2492 39.9265H36.3759ZM61.7516 38.5127L53.7043 31.909C56.0796 29.845 59.6486 26.6488 61.7516 24.7586V38.5127Z" fill="#DD5428"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    // The screen wraps this widget in a Center inside the exact remaining
    // body height (LayoutBuilder), so top and bottom padding stay equal —
    // no manual MediaQuery height math (and no AppBar-height drift) here.
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 140.w,
            height: 140.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Center(
              // Exact Figma SVG (70x66) rendered verbatim; .r scales both
              // axes from the design width, preserving the native ratio.
              child: SvgPicture.string(
                _emptyIconSvg,
                width: 70.r,
                height: 66.r,
              ),
            ),
          ),
          SizedBox(height: 18.h),
          Text(
            "You're All Caught Up!",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Any Alerts, Updates, Or Activity Related To\n'
            'Your Account Will Appear Here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.black,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
