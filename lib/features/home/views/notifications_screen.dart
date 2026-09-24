// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:e_rupaiya/features/refer_and_earn/views/refer_and_earn_wallet_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
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
import '../controllers/notifications_controller.dart';
import '../controllers/home_tab_controller.dart';
import '../models/notification_item.dart';

final notificationReadIdsProvider =
    StateProvider.autoDispose<Set<String>>((ref) => <String>{});

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final Set<String> _dismissedIds = <String>{};
  final Set<String> _remindingIds = <String>{};

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(notificationsControllerProvider.notifier)
          .fetchNotifications(),
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
      body: Column(
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
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: 40.h),
                            _NotificationsEmptyState(),
                          ],
                        )
                      : items.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(height: 40.h),
                                _NotificationsEmptyState(),
                              ],
                            )
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
                                        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0.h),
                                        sliver: SliverList(
                                          delegate: SliverChildBuilderDelegate(
                                            (context, index) {
                                              final entry = entries[index];
                                              if (entry.kind ==
                                                  _NotificationsListEntryKind
                                                      .header) {
                                                return Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    _SectionTitle(
                                                        entry.headerText ?? ''),
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
                                                    onPrimary: () =>
                                                        _handleNotificationTap(
                                                      context,
                                                      ref,
                                                      item,
                                                    ),
                                                    onSecondary: entry.kind ==
                                                            _NotificationsListEntryKind
                                                                .unread
                                                        ? item.isBillReminderNotification
                                                            ? () async {
                                                                if (_remindingIds
                                                                    .contains(item
                                                                        .id)) {
                                                                  return;
                                                                }
                                                                setState(() =>
                                                                    _remindingIds
                                                                        .add(item
                                                                            .id));
                                                                final ok = await ref
                                                                    .read(
                                                                        notificationsRepositoryProvider)
                                                                    .remindMeLater(
                                                                        item.id);
                                                                if (mounted) {
                                                                  setState(() =>
                                                                      _remindingIds
                                                                          .remove(
                                                                              item.id));
                                                                }
                                                                if (ok) {
                                                                  AppSnackbar
                                                                      .show(
                                                                    'We will remind you later',
                                                                  );
                                                                  ref
                                                                      .read(notificationsControllerProvider
                                                                          .notifier)
                                                                      .fetchNotifications(
                                                                          force:
                                                                              true);
                                                                } else {
                                                                  AppSnackbar
                                                                      .show(
                                                                    'Failed to set reminder. Please try again.',
                                                                  );
                                                                }
                                                              }
                                                            : null
                                                        : null,
                                                    secondaryLoading:
                                                        _remindingIds
                                                            .contains(item.id),
                                                    primaryLabel:
                                                        _primaryLabelFor(item),
                                                    secondaryLabel: entry
                                                                    .kind ==
                                                                _NotificationsListEntryKind
                                                                    .unread &&
                                                            item.isBillReminderNotification
                                                        ? 'Remind me Later'
                                                        : null,
                                                    isPrimaryFullWidth: entry
                                                                .kind ==
                                                            _NotificationsListEntryKind
                                                                .update
                                                        ? true
                                                        : !item
                                                            .isBillReminderNotification,
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

void _handleNotificationTap(
  BuildContext context,
  WidgetRef ref,
  NotificationItem item,
) {
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

  final redirect = (item.redirectScreen ?? '').trim().toLowerCase();
  if (redirect == 'app_update_screen') {
    unawaited(_openPlayStore());
    return;
  }
  if (redirect == 'spin_screen') {
    context.push(RouteConstants.spinAndWin);
    return;
  }
  if (redirect == 'wallet_history') {
    PersistentNavBarNavigator.pushNewScreen(
      context,
      screen: const ReferAndEarnWalletView(),
      withNavBar: false,
    );
    return;
  }
  if (redirect == 'bill_history') {
    context.push(RouteConstants.transactions);
    return;
  }

  final combined = '${item.title} ${item.subtitle}'.toLowerCase();
  if (combined.contains('spin')) {
    context.push(RouteConstants.spinAndWin);
    return;
  }
  if (combined.contains('wallet')) {
    PersistentNavBarNavigator.pushNewScreen(
      context,
      screen: const ReferAndEarnWalletView(),
      withNavBar: false,
    );
    return;
  }
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

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.onPrimary,
    required this.primaryLabel,
    this.onSecondary,
    this.secondaryLabel,
    this.secondaryLoading = false,
    this.onClose,
    this.isPrimaryFullWidth = false,
  });

  final NotificationItem item;
  final VoidCallback onPrimary;
  final String primaryLabel;
  final VoidCallback? onSecondary;
  final String? secondaryLabel;
  final bool secondaryLoading;
  final VoidCallback? onClose;
  final bool isPrimaryFullWidth;

  @override
  Widget build(BuildContext context) {
    final ageText = _relativeAge(item.createdAt);
    final iconUrl = (item.iconUrl ?? '').trim();
    final hasSecondary =
        onSecondary != null && (secondaryLabel ?? '').isNotEmpty;

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
                child: Center(
                  child: AppNetworkImage(
                    url: iconUrl,
                    width: 22.r,
                    height: 22.r,
                    fit: BoxFit.contain,
                    showShimmer: true,
                    errorWidget: Image.asset(
                      item.iconAsset,
                      width: 22.r,
                      height: 22.r,
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
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
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
                  ],
                ),
              ),
              Column(
                children: [
                  InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(999.r),
                    child: Padding(
                      padding: EdgeInsets.all(6.r),
                      child: Icon(
                        Icons.close,
                        size: 18.r,
                        color: AppColors.textPrimary.withOpacity(0.55),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  if (ageText.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14.r,
                          color: AppColors.textPrimary.withOpacity(0.4),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          ageText,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.textPrimary.withOpacity(0.45),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: 14.h),
          if (isPrimaryFullWidth)
            SizedBox(
              width: double.infinity,
              height: 30.h,
              child: ElevatedButton(
                onPressed: onPrimary,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  primaryLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: SizedBox(height: 30.h,
                    child: OutlinedButton(
                      onPressed: (hasSecondary && !secondaryLoading)
                          ? onSecondary
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                          color: AppColors.primary.withOpacity(
                            hasSecondary ? 1 : 0.35,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999.r),
                        ),
                      ),
                      child: secondaryLoading
                          ? SizedBox(height: 18.h,
                              width: 18.h,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary.withOpacity(0.9),
                                ),
                              ),
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                secondaryLabel ?? '',
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary.withOpacity(
                                        hasSecondary ? 1 : 0.5,
                                      ),
                                    ),
                              ),
                            ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: SizedBox(height: 30.h,
                    child: ElevatedButton(
                      onPressed: onPrimary,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        primaryLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
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
                child: SizedBox(height: 30.h,
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
                child: SizedBox(height: 30.h,
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

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
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
                child: Icon(
                  Icons.mark_email_unread_outlined,
                  size: 56.r,
                  color: AppColors.primary,
                ),
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              "You're All Caught Up!",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Any Alerts, Updates, Or Activity Related To\n'
              'Your Account Will Appear Here.',
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
