// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../services/permission_service.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/contacts_permission_card.dart';
import '../../../widgets/infinite_scroll_listener.dart';
import '../../../widgets/my_app_bar.dart';
import '../../../widgets/screen_wrapper.dart';
import '../../../widgets/search_textfield.dart';
import '../../home/models/banner_model.dart';
import '../../mobile_prepaid/components/contacts_list.dart';
import '../../mobile_prepaid/controllers/contacts_cache_controller.dart';
import '../../mobile_prepaid/models/latest_transaction.dart';
import '../components/service_recent_section.dart';
import '../controllers/biller_detail_controller.dart';
import '../controllers/biller_listing_controller.dart';
import '../controllers/service_extras_controller.dart';
import '../models/biller_detail_args.dart';
import '../models/biller_model.dart';

enum _BillerListingVariant {
  standard,
  figmaBannerRecents,
  postpaidFlow,
  electricityFlow,
}

class _BillerListingUiConfig {
  const _BillerListingUiConfig({
    required this.variant,
    required this.appBarTitle,
    this.bannerAsset,
    this.showSearch = true,
  });

  final _BillerListingVariant variant;
  final String appBarTitle;
  final String? bannerAsset;
  final bool showSearch;
}

_BillerListingUiConfig _resolveUiConfig(String categoryName) {
  final normalized = categoryName.trim().toLowerCase();
  final titleCategory = categoryName.trim().isEmpty ? 'Your' : categoryName;

  if (normalized.contains('postpaid')) {
    return _BillerListingUiConfig(
      variant: _BillerListingVariant.postpaidFlow,
      appBarTitle: 'Postpaid Bill',
      bannerAsset: FileConstants.homeBanner8,
      showSearch: false,
    );
  }

  // Figma v1 layout: banner + recents + all billers list (no search).
  // Currently enabled for DTH (can be extended per category).
  if (normalized == 'dth') {
    return _BillerListingUiConfig(
      variant: _BillerListingVariant.figmaBannerRecents,
      appBarTitle: 'Fetch Your $titleCategory Provider',
      bannerAsset: FileConstants.homeBanner8,
      showSearch: false,
    );
  }

  if (normalized.contains('electric')) {
    return const _BillerListingUiConfig(
      variant: _BillerListingVariant.electricityFlow,
      appBarTitle: 'Fetch Your Provider',
      showSearch: true,
    );
  }

  return const _BillerListingUiConfig(
    variant: _BillerListingVariant.standard,
    appBarTitle: 'Fetch Your Provider',
    showSearch: true,
  );
}

List<int> _filterContactIndices(Map<String, dynamic> payload) {
  final rawEntries = payload['entries'] as List<dynamic>? ?? const [];
  final query = (payload['query'] as String? ?? '').toLowerCase();
  if (rawEntries.isEmpty) return const [];
  if (query.isEmpty) {
    return List<int>.generate(rawEntries.length, (index) => index);
  }
  final matches = <int>[];
  for (var i = 0; i < rawEntries.length; i++) {
    final entry = rawEntries[i] as Map;
    final name = (entry['name'] as String? ?? '');
    final phone = (entry['phone'] as String? ?? '');
    if (name.contains(query) || phone.contains(query)) {
      matches.add(i);
    }
  }
  return matches;
}

Biller? _findRecentBillerMatch({
  required LatestTransaction txn,
  required List<Biller> billers,
}) {
  final recentBillerId = txn.billerId.trim();
  if (recentBillerId.isNotEmpty) {
    for (final biller in billers) {
      if (biller.billerId.trim() == recentBillerId) {
        return biller;
      }
    }

    return Biller(
      billerId: recentBillerId,
      billerName: txn.billerName.trim(),
      icon: txn.icon.trim().isNotEmpty ? txn.icon.trim() : null,
    );
  }

  final recentBillerName = txn.billerName.trim().toLowerCase();
  if (recentBillerName.isEmpty) return null;
  for (final biller in billers) {
    if (biller.billerName.trim().toLowerCase() == recentBillerName) {
      return biller;
    }
  }
  return null;
}

class BillerListingView extends HookConsumerWidget {
  const BillerListingView({super.key, required this.categoryName});

  final String categoryName;

  static String _latestTransactionService(String categoryName) =>
      categoryName.trim();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingState = ref.watch(billerListingControllerProvider);
    final searchController = useTextEditingController();
    final uiConfig = _resolveUiConfig(categoryName);

    useEffect(() {
      if (uiConfig.variant == _BillerListingVariant.postpaidFlow) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        searchController.clear();
        ref
            .read(billerListingControllerProvider.notifier)
            .fetchBillers(categoryName: categoryName, searchQuery: '');
      });
      return null;
    }, [categoryName]);

    final billers = listingState.billers;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MyAppBar(
        title: uiConfig.appBarTitle,
        showHelp: true,
        onBack: () => context.pop(),
        onHelp: () {
          context.pop();
        },
      ),
      body: switch (uiConfig.variant) {
        _BillerListingVariant.standard => _StandardBillerListingBody(
            categoryName: categoryName,
            showSearch: uiConfig.showSearch,
            searchController: searchController,
          ),
        _BillerListingVariant.figmaBannerRecents => _BillerListingFigmaLayout(
            bannerAsset: uiConfig.bannerAsset,
            recentTransactions: categoryName.trim().isNotEmpty
                ? ref.watch(
                    serviceLatestTransactionsProvider(
                      _latestTransactionService(categoryName),
                    ),
                  )
                : null,
            isFetching: listingState.isFetching,
            errorMessage: listingState.errorMessage,
            isEmpty: billers.isEmpty,
            billers: billers,
            isFetchingMore: listingState.isFetchingMore,
            hasMore: listingState.hasMore,
            onRetry: () => ref
                .read(billerListingControllerProvider.notifier)
                .fetchBillers(categoryName: categoryName),
            onEndReached: () => ref
                .read(billerListingControllerProvider.notifier)
                .fetchNextPage(),
            onTapBiller: (biller) {
              ref.read(billerDetailControllerProvider.notifier).selectBiller(
                    biller,
                    categoryName: categoryName,
                  );
              context.push(
                RouteConstants.billerDetail,
                extra: BillerDetailArgs(
                  biller: biller,
                  paymentType: categoryName,
                ),
              );
            },
            onPayNowRecent: (txn) {
              final biller = _findRecentBillerMatch(
                txn: txn,
                billers: billers,
              );
              if (biller == null) return;
              ref.read(billerDetailControllerProvider.notifier).selectBiller(
                    biller,
                    categoryName: categoryName,
                  );
              context.push(
                RouteConstants.billerDetail,
                extra: BillerDetailArgs(
                  biller: biller,
                  paymentType: categoryName,
                  mobileNumber: txn.serviceNo,
                  autoFetchBill: true,
                  autoOpenPaymentSheet: true,
                ),
              );
            },
          ),
        _BillerListingVariant.postpaidFlow => _MobilePostpaidFlow(
            categoryName: categoryName,
          ),
        _BillerListingVariant.electricityFlow => _ElectricityFlow(
            categoryName: categoryName,
            searchController: searchController,
          ),
      },
    );
  }
}

class _StandardBillerListingBody extends HookConsumerWidget {
  const _StandardBillerListingBody({
    required this.categoryName,
    required this.showSearch,
    required this.searchController,
  });

  final String categoryName;
  final bool showSearch;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingState = ref.watch(billerListingControllerProvider);
    final billers = listingState.billers;

    void openBiller(Biller biller) {
      ref.read(billerDetailControllerProvider.notifier).selectBiller(
            biller,
            categoryName: categoryName,
          );
      context.push(
        RouteConstants.billerDetail,
        extra: BillerDetailArgs(
          biller: biller,
          paymentType: categoryName,
        ),
      );
    }

    return Column(
      children: [
        if (showSearch)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final barWidth = constraints.maxWidth < 392.w
                    ? constraints.maxWidth
                    : 392.w;
                return Align(
                  alignment: Alignment.center,
                  child: SearchTextfield(
                    hintText: 'Search Provider',
                    controller: searchController,
                    onChange: (value) => ref
                        .read(billerListingControllerProvider.notifier)
                        .updateSearch(value),
                    width: barWidth,
                    height: 60.h,
                    radius: 12.r,
                    fillColor: const Color(0xFFFFFFFF),
                    borderColor: const Color(0xFFE2E2E2),
                    borderWidth: 1,
                    contentPadding:
                        EdgeInsets.fromLTRB(0, 18.h, 20.w, 18.h),
                    hintStyle: GoogleFonts.bricolageGrotesque(
                      fontWeight: FontWeight.w500,
                      fontSize: 14.sp,
                      color: AppColors.textPrimary.withOpacity(0.45),
                    ),
                    style: GoogleFonts.bricolageGrotesque(
                      fontWeight: FontWeight.w500,
                      fontSize: 14.sp,
                      color: Colors.black,
                    ),
                    prefixIconConstraints: BoxConstraints(
                      minWidth: 52.w,
                      minHeight: 24.h,
                    ),
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(left: 20.w, right: 8.w),
                      child: SizedBox(
                        width: 24.w,
                        height: 24.h,
                        child: TwotoneSearchIcon(size: 24.w),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        Expanded(
          child: _BillerListPane(
            isFetching: listingState.isFetching,
            errorMessage: listingState.errorMessage,
            billers: billers,
            isFetchingMore: listingState.isFetchingMore,
            hasMore: listingState.hasMore,
            onRetry: () => ref
                .read(billerListingControllerProvider.notifier)
                .fetchBillers(categoryName: categoryName),
            onEndReached: () => ref
                .read(billerListingControllerProvider.notifier)
                .fetchNextPage(),
            onTapBiller: openBiller,
          ),
        ),
      ],
    );
  }
}

class _ElectricityFlow extends HookConsumerWidget {
  const _ElectricityFlow({
    required this.categoryName,
    required this.searchController,
  });

  final String categoryName;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingState = ref.watch(billerListingControllerProvider);
    final recentTransactions =
        ref.watch(serviceLatestTransactionsProvider(categoryName.trim()));

    final billers = listingState.billers;
    final showRecentSection = recentTransactions.maybeWhen(
      data: (items) => items.isNotEmpty,
      orElse: () => false,
    );

    void openBiller(Biller biller) {
      ref.read(billerDetailControllerProvider.notifier).selectBiller(
            biller,
            categoryName: categoryName,
          );
      context.push(
        RouteConstants.billerDetail,
        extra: BillerDetailArgs(
          biller: biller,
          paymentType: categoryName,
        ),
      );
    }

    return Column(
      children: [
        ServiceRecentSection(
          recentTransactions: recentTransactions,
          onPayNow: (txn) {
            final biller = _findRecentBillerMatch(
              txn: txn,
              billers: billers,
            );
            if (biller == null) {
              AppSnackbar.show(
                  'Provider not found. Please select from the list.');
              return;
            }
            final identifier = (txn.serviceNoFull ?? '').trim().isNotEmpty
                ? txn.serviceNoFull!.trim()
                : txn.serviceNo.trim();
            final isMaskedIdentifier = identifier.contains('*') ||
                identifier.toLowerCase().contains('x');

            ref.read(billerDetailControllerProvider.notifier).selectBiller(
                  biller,
                  categoryName: categoryName,
                );
            context.push(
              RouteConstants.billerDetail,
              extra: BillerDetailArgs(
                biller: biller,
                paymentType: categoryName,
                mobileNumber: identifier,
                autoFetchBill: !isMaskedIdentifier,
                autoOpenPaymentSheet: !isMaskedIdentifier,
              ),
            );

            if (isMaskedIdentifier) {
              AppSnackbar.show(
                  'Enter full consumer number to fetch bill again.');
            }
          },
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            16.w,
            showRecentSection ? 0 : 12.h,
            16.w,
            12.h,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth < 392.w
                  ? constraints.maxWidth
                  : 392.w;
              return Align(
                alignment: Alignment.center,
                child: SearchTextfield(
                  hintText: 'Search Provider',
                  controller: searchController,
                  onChange: (value) => ref
                      .read(billerListingControllerProvider.notifier)
                      .updateSearch(value),
                  width: barWidth,
                  height: 60.h,
                  radius: 12.r,
                  fillColor: const Color(0xFFFFFFFF),
                  borderColor: const Color(0xFFE2E2E2),
                  borderWidth: 1,
                  contentPadding:
                      EdgeInsets.fromLTRB(0, 18.h, 20.w, 18.h),
                  hintStyle: GoogleFonts.bricolageGrotesque(
                    fontWeight: FontWeight.w500,
                    fontSize: 14.sp,
                    color: AppColors.textPrimary.withOpacity(0.45),
                  ),
                  style: GoogleFonts.bricolageGrotesque(
                    fontWeight: FontWeight.w500,
                    fontSize: 14.sp,
                    color: Colors.black,
                  ),
                  prefixIconConstraints: BoxConstraints(
                    minWidth: 52.w,
                    minHeight: 24.h,
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: 20.w, right: 8.w),
                    child: SizedBox(
                      width: 24.w,
                      height: 24.h,
                      child: TwotoneSearchIcon(size: 24.w),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: _BillerListPane(
            isFetching: listingState.isFetching,
            errorMessage: listingState.errorMessage,
            billers: billers,
            isFetchingMore: listingState.isFetchingMore,
            hasMore: listingState.hasMore,
            onRetry: () => ref
                .read(billerListingControllerProvider.notifier)
                .fetchBillers(categoryName: categoryName),
            onEndReached: () => ref
                .read(billerListingControllerProvider.notifier)
                .fetchNextPage(),
            onTapBiller: openBiller,
          ),
        ),
      ],
    );
  }
}

class _BillerListPane extends StatelessWidget {
  const _BillerListPane({
    required this.isFetching,
    required this.errorMessage,
    required this.billers,
    required this.isFetchingMore,
    required this.hasMore,
    required this.onRetry,
    required this.onEndReached,
    required this.onTapBiller,
  });

  final bool isFetching;
  final String? errorMessage;
  final List<Biller> billers;
  final bool isFetchingMore;
  final bool hasMore;
  final VoidCallback onRetry;
  final VoidCallback onEndReached;
  final ValueChanged<Biller> onTapBiller;

  @override
  Widget build(BuildContext context) {
    if (isFetching && billers.isEmpty && errorMessage == null) {
      return const _BillerListingSkeleton();
    }

    return ScreenWrapper(
      isFetching: false,
      isEmpty: billers.isEmpty,
      emptyMessage: 'No providers found',
      errorMessage: errorMessage,
      actions: errorMessage != null
          ? [
              TextButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ]
          : null,
      child: InfiniteScrollListener(
        isLoading: isFetchingMore,
        hasMore: hasMore,
        onEndReached: onEndReached,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: billers.length + (isFetchingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= billers.length) {
              return const _BillerListingFooterSkeleton();
            }
            final biller = billers[index];
            return _BillerTile(
              biller: biller,
              onTap: () => onTapBiller(biller),
            );
          },
        ),
      ),
    );
  }
}

class _MobilePostpaidFlow extends HookConsumerWidget {
  const _MobilePostpaidFlow({required this.categoryName});

  final String categoryName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingState = ref.watch(billerListingControllerProvider);
    final contactsState = ref.watch(contactsCacheControllerProvider);
    final contactsController =
        ref.read(contactsCacheControllerProvider.notifier);
    final banners = ref.watch(servicePageBannersProvider('mobile-postpaid'));
    final recentTransactions = ref.watch(
      serviceLatestTransactionsProvider(categoryName.trim()),
    );
    final permissionService = useMemoized(() => const PermissionService());
    final hasPermission = useState(false);
    final isMounted = useIsMounted();

    final filteredContacts = useState<List<Contact>>([]);
    final visibleContactCount = useState(100);
    final contactQuery = useState('');
    final contactSearchController = useTextEditingController();
    final filterToken = useRef(0);

    final selectedMobile = useState<String?>(null);
    final selectedName = useState<String?>(null);
    final selectedBiller = useState<Biller?>(null);

    useEffect(() {
      Future.microtask(() async {
        final granted = await permissionService.hasContactsPermission();
        if (!isMounted()) return;
        hasPermission.value = granted;
        if (granted) {
          await contactsController.fetchIfNeeded();
        }
      });
      return null;
    }, const []);

    Future<void> handleRequestPermission() async {
      final granted = await permissionService.requestContacts();
      if (!isMounted()) return;
      hasPermission.value = granted;
      if (granted) {
        await contactsController.reload();
      }
    }

    useEffect(() {
      if (contactSearchController.text != contactQuery.value) {
        contactSearchController.text = contactQuery.value;
      }
      return null;
    }, [contactQuery.value]);

    Future<void> rebuildFilteredContacts() async {
      final entries = contactsState.searchIndex;
      if (entries.isEmpty) {
        filteredContacts.value = [];
        return;
      }
      final token = ++filterToken.value;
      final query = contactQuery.value.trim().toLowerCase();
      final indices = await compute(
        _filterContactIndices,
        <String, dynamic>{
          'entries': entries,
          'query': query,
        },
      );
      if (!isMounted() || token != filterToken.value) return;
      filteredContacts.value = [
        for (final i in indices)
          if (i >= 0 && i < contactsState.contacts.length)
            contactsState.contacts[i],
      ];
      visibleContactCount.value = 100;
    }

    useEffect(() {
      Future.microtask(rebuildFilteredContacts);
      return null;
    }, [contactQuery.value, contactsState.searchIndex]);

    Future<void> ensureBillersLoaded() async {
      await ref
          .read(billerListingControllerProvider.notifier)
          .fetchBillers(categoryName: categoryName, searchQuery: '');
    }

    useEffect(() {
      if (selectedMobile.value == null) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ensureBillersLoaded();
      });
      return null;
    }, [selectedMobile.value]);

    final isSelectingContact = selectedMobile.value == null;
    final billers = listingState.billers;

    return isSelectingContact
        ? NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 200) {
                if (visibleContactCount.value >=
                    filteredContacts.value.length) {
                  return false;
                }
                visibleContactCount.value =
                    (visibleContactCount.value + 100).clamp(
                  0,
                  filteredContacts.value.length,
                );
              }
              return false;
            },
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
              children: [
                _PostpaidBanner(banners: banners),
                SizedBox(height: 14.h),
                _PostpaidSearchRow(
                  controller: contactSearchController,
                  onQueryChange: (value) => contactQuery.value = value,
                  onContactsTap: () async {
                    await contactsController.reload();
                  },
                ),
                SizedBox(height: 18.h),
                const _FigmaSectionHeader(title: 'Recent'),
                SizedBox(height: 10.h),
                _PostpaidRecentSection(
                  recentTransactions: recentTransactions,
                  contacts: filteredContacts.value,
                  onPayNow: (txn) {
                    final rawServiceNo = txn.serviceNo.trim();
                    final normalizedMobile = rawServiceNo.isEmpty
                        ? ''
                        : normalizeMobile(rawServiceNo); // handles +91 etc.
                    final resolvedMobile = normalizedMobile.isNotEmpty
                        ? normalizedMobile
                        : rawServiceNo;
                    if (resolvedMobile.isEmpty) return;

                    final contactName = normalizedMobile.isEmpty
                        ? ''
                        : _nameForMobile(
                            contacts: filteredContacts.value,
                            mobile: normalizedMobile,
                          ).trim();
                    selectedName.value = contactName.isNotEmpty
                        ? contactName
                        : (txn.billerName.trim().isNotEmpty
                            ? txn.billerName.trim()
                            : 'Recent');
                    selectedMobile.value = resolvedMobile;

                    Future.microtask(() async {
                      await ensureBillersLoaded();
                      if (!context.mounted) return;

                      final billersNow =
                          ref.read(billerListingControllerProvider).billers;
                      if (billersNow.isEmpty) return;

                      Biller? selected = _findRecentBillerMatch(
                        txn: txn,
                        billers: billersNow,
                      );
                      selected ??= billersNow.first;

                      ref
                          .read(billerDetailControllerProvider.notifier)
                          .selectBiller(
                            selected,
                            categoryName: categoryName,
                          );
                      context.push(
                        RouteConstants.billerDetail,
                        extra: BillerDetailArgs(
                          biller: selected,
                          paymentType: categoryName,
                          mobileNumber: resolvedMobile,
                          autoFetchBill: true,
                          autoOpenPaymentSheet: true,
                        ),
                      );
                    });
                  },
                ),
                SizedBox(height: 18.h),
                const _FigmaSectionHeader(title: 'My Contacts'),
                SizedBox(height: 10.h),
                if (!hasPermission.value)
                  ContactsPermissionCard(
                    onAllow: handleRequestPermission,
                    outerPadding: EdgeInsets.zero,
                  )
                else if (contactsState.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else if (filteredContacts.value.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: Center(
                      child: Text(
                        'No contacts found',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary.withOpacity(0.6),
                            ),
                      ),
                    ),
                  )
                else
                  ContactsList(
                    contacts: filteredContacts.value,
                    visibleCount: visibleContactCount.value,
                    onSelect: (mobile) {
                      selectedMobile.value = mobile;
                      selectedName.value = _nameForMobile(
                        contacts: filteredContacts.value,
                        mobile: mobile,
                      );
                    },
                  ),
              ],
            ),
          )
        : _PostpaidProviderSelection(
            isFetching: listingState.isFetching,
            isEmpty: billers.isEmpty,
            errorMessage: listingState.errorMessage,
            selectedName: selectedName.value ?? '',
            selectedMobile: selectedMobile.value ?? '',
            billers: billers,
            selectedBillerId: selectedBiller.value?.billerId,
            onChangeContact: () {
              selectedBiller.value = null;
              selectedMobile.value = null;
              selectedName.value = null;
              contactQuery.value = '';
            },
            onRetry: ensureBillersLoaded,
            onSelectBiller: (biller) => selectedBiller.value = biller,
            onConfirm: selectedBiller.value == null
                ? null
                : () {
                    final biller = selectedBiller.value!;
                    ref
                        .read(billerDetailControllerProvider.notifier)
                        .selectBiller(
                          biller,
                          categoryName: categoryName,
                        );
                    context.push(
                      RouteConstants.billerDetail,
                      extra: BillerDetailArgs(
                        biller: biller,
                        paymentType: categoryName,
                        mobileNumber: selectedMobile.value,
                      ),
                    );
                  },
          );
  }
}

String _nameForMobile({
  required List<Contact> contacts,
  required String mobile,
}) {
  for (final c in contacts) {
    if (c.phones.isEmpty) continue;
    final raw = c.phones.first.number;
    if (normalizeMobile(raw) == mobile) return c.displayName;
  }
  return '';
}

class _PostpaidSearchRow extends StatelessWidget {
  const _PostpaidSearchRow({
    required this.controller,
    required this.onQueryChange,
    required this.onContactsTap,
  });

  final TextEditingController controller;
  final ValueChanged<String> onQueryChange;
  final VoidCallback onContactsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SearchTextfield(
            hintText: 'Search by number or name',
            controller: controller,
            onChange: onQueryChange,
          ),
        ),
        SizedBox(width: 12.w),
        InkWell(
          onTap: onContactsTap,
          borderRadius: BorderRadius.circular(14.r),
          child: Center(
            child: Image.asset(
              FileConstants.contactLogo,
              width: 30.w,
              height: 30.w,
            ),
          ),
        ),
      ],
    );
  }
}

class _PostpaidBanner extends StatelessWidget {
  const _PostpaidBanner({required this.banners});

  final AsyncValue<List<BannerModel>> banners;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: banners.when(
        loading: () => Image.asset(
          FileConstants.homeBanner8,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        error: (_, __) => Image.asset(
          FileConstants.homeBanner8,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        data: (items) {
          final image = items.isNotEmpty ? items.first.image.trim() : '';
          if (image.isEmpty) {
            return Image.asset(
              FileConstants.homeBanner8,
              width: double.infinity,
              fit: BoxFit.cover,
            );
          }
          return AppNetworkImage(
            url: image,
            width: double.infinity,
            height: 92.h,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(16.r),
          );
        },
      ),
    );
  }
}

class _PostpaidRecentSection extends StatelessWidget {
  const _PostpaidRecentSection({
    required this.recentTransactions,
    required this.contacts,
    required this.onPayNow,
  });

  final AsyncValue<List<LatestTransaction>> recentTransactions;
  final List<Contact> contacts;
  final ValueChanged<LatestTransaction> onPayNow;

  @override
  Widget build(BuildContext context) {
    return recentTransactions.when(
      loading: () => SizedBox(
        height: 74.h,
        child: ListView.separated(
          padding: EdgeInsets.zero,
          scrollDirection: Axis.horizontal,
          itemCount: 2,
          separatorBuilder: (_, __) => SizedBox(width: 12.w),
          itemBuilder: (_, __) => const _PostpaidRecentCardShimmer(),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final display = items.take(10).toList();
        return SizedBox(
          height: 74.h,
          child: ListView.separated(
            padding: EdgeInsets.zero,
            scrollDirection: Axis.horizontal,
            itemCount: display.length,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (context, index) {
              final txn = display[index];
              final rawServiceNo = txn.serviceNo.trim();
              final normalized = rawServiceNo.isEmpty
                  ? ''
                  : normalizeMobile(rawServiceNo); // handles +91 etc.
              final contactName = normalized.isEmpty
                  ? ''
                  : _nameForMobile(contacts: contacts, mobile: normalized)
                      .trim();
              final name = contactName.isNotEmpty
                  ? contactName
                  : (txn.billerName.trim().isNotEmpty
                      ? txn.billerName.trim()
                      : 'Recent');
              final mobile = normalized.isNotEmpty ? normalized : rawServiceNo;
              return _PostpaidRecentCard(
                name: name,
                mobile: mobile,
                onPayNow: () => onPayNow(txn),
              );
            },
          ),
        );
      },
    );
  }
}

class _PostpaidRecentCardShimmer extends StatelessWidget {
  const _PostpaidRecentCardShimmer();

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: 320.w,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFE2E2E2)),
        ),
        child: Row(
          children: [
            Container(
              height: 44.w,
              width: 44.w,
              decoration: BoxDecoration(
                color: AppColors.lightBorder.withOpacity(0.25),
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12.h,
                    width: 140.w,
                    decoration: BoxDecoration(
                      color: AppColors.lightBorder.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    height: 10.h,
                    width: 110.w,
                    decoration: BoxDecoration(
                      color: AppColors.lightBorder.withOpacity(0.25),
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
                color: AppColors.lightBorder.withOpacity(0.25),
                borderRadius: BorderRadius.circular(22.r),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
                AppColors.lightBorder.withOpacity(0.2),
                AppColors.lightBorder.withOpacity(0.6),
                AppColors.lightBorder.withOpacity(0.2),
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
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

class _PostpaidRecentCard extends StatelessWidget {
  const _PostpaidRecentCard({
    required this.name,
    required this.mobile,
    required this.onPayNow,
  });

  final String name;
  final String mobile;
  final VoidCallback onPayNow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320.w,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E2E2)),
      ),
      child: Row(
        children: [
          Container(
            height: 44.w,
            width: 44.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: const Color(0xFFE2E2E2)),
            ),
            child: Center(
              child: Text(
                name.trim().isEmpty ? '' : name.trim()[0].toUpperCase(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFFE85A2C),
                      fontWeight: FontWeight.w900,
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
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ),
                SizedBox(height: 2.h),
                Text(
                  mobile,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.55),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          ElevatedButton(
            onPressed: onPayNow,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE85A2C),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22.r),
              ),
            ),
            child: Text(
              'Pay Now',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostpaidProviderSelection extends StatelessWidget {
  const _PostpaidProviderSelection({
    required this.isFetching,
    required this.isEmpty,
    required this.errorMessage,
    required this.selectedName,
    required this.selectedMobile,
    required this.billers,
    required this.selectedBillerId,
    required this.onChangeContact,
    required this.onRetry,
    required this.onSelectBiller,
    required this.onConfirm,
  });

  final bool isFetching;
  final bool isEmpty;
  final String? errorMessage;
  final String selectedName;
  final String selectedMobile;
  final List<Biller> billers;
  final String? selectedBillerId;
  final VoidCallback onChangeContact;
  final VoidCallback onRetry;
  final ValueChanged<Biller> onSelectBiller;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
          child: _SelectedContactCard(
            name: selectedName,
            mobile: selectedMobile,
            onChange: onChangeContact,
          ),
        ),
        SizedBox(height: 12.h),
        Expanded(
          child: ScreenWrapper(
            isFetching: isFetching,
            isEmpty: isEmpty,
            emptyMessage: 'No providers found',
            errorMessage: errorMessage,
            actions: errorMessage != null
                ? [
                    TextButton(
                      onPressed: onRetry,
                      child: const Text('Retry'),
                    ),
                  ]
                : null,
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              itemCount: billers.length,
              itemBuilder: (context, index) {
                final biller = billers[index];
                final isSelected = biller.billerId == selectedBillerId;
                return _PostpaidBillerTile(
                  biller: biller,
                  selected: isSelected,
                  onTap: () => onSelectBiller(biller),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
          child: SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE85A2C),
                disabledBackgroundColor:
                    const Color(0xFFE85A2C).withOpacity(0.4),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28.r),
                ),
              ),
              child: Text(
                'Confirm',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectedContactCard extends StatelessWidget {
  const _SelectedContactCard({
    required this.name,
    required this.mobile,
    required this.onChange,
  });

  final String name;
  final String mobile;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? 'U'
        : name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((p) => p.isEmpty ? '' : p[0].toUpperCase())
            .join();
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            height: 42.w,
            width: 42.w,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
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
                  name.trim().isEmpty ? 'User' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ),
                SizedBox(height: 2.h),
                Text(
                  mobile,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.55),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          ElevatedButton(
            onPressed: onChange,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE85A2C),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22.r),
              ),
            ),
            child: Text(
              'Change',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostpaidBillerTile extends StatelessWidget {
  const _PostpaidBillerTile({
    required this.biller,
    required this.selected,
    required this.onTap,
  });

  final Biller biller;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = biller.billerName.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '';

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: selected ? const Color(0xFFFFF0EB) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              children: [
                Container(
                  height: 44.w,
                  width: 44.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black.withOpacity(0.08)),
                  ),
                  child: ClipOval(
                    child: (biller.iconUrl ?? '').trim().isEmpty
                        ? Center(
                            child: Text(
                              initial,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                  ),
                            ),
                          )
                        : AppNetworkImage(
                            url: biller.iconUrl,
                            fit: BoxFit.contain,
                            showShimmer: false,
                          ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Image.asset(
                  FileConstants.tiltArrow,
                  height: 25,
                  width: 25,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BillerListingFigmaLayout extends StatelessWidget {
  const _BillerListingFigmaLayout({
    required this.bannerAsset,
    required this.recentTransactions,
    required this.isFetching,
    required this.isEmpty,
    required this.errorMessage,
    required this.billers,
    required this.isFetchingMore,
    required this.hasMore,
    required this.onRetry,
    required this.onEndReached,
    required this.onTapBiller,
    required this.onPayNowRecent,
  });

  final String? bannerAsset;
  final AsyncValue<List<LatestTransaction>>? recentTransactions;
  final bool isFetching;
  final bool isEmpty;
  final String? errorMessage;
  final List<Biller> billers;
  final bool isFetchingMore;
  final bool hasMore;
  final VoidCallback onRetry;
  final VoidCallback onEndReached;
  final ValueChanged<Biller> onTapBiller;
  final ValueChanged<LatestTransaction> onPayNowRecent;

  @override
  Widget build(BuildContext context) {
    return InfiniteScrollListener(
      isLoading: isFetchingMore,
      hasMore: hasMore,
      onEndReached: onEndReached,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((bannerAsset ?? '').trim().isNotEmpty) ...[
                    _StaticBanner(asset: bannerAsset!),
                    SizedBox(height: 14.h),
                  ],
                  if (recentTransactions == null) ...[
                    const _FigmaSectionHeader(
                      title: 'Recents',
                      actionText: 'View all',
                    ),
                    SizedBox(height: 10.h),
                    const _StaticRecentRow(),
                    SizedBox(height: 18.h),
                  ] else ...[
                    _ServiceRecentRow(
                      recentTransactions: recentTransactions!,
                      onPayNow: onPayNowRecent,
                    ),
                  ],
                  const _FigmaSectionHeader(title: 'All Billers'),
                  SizedBox(height: 6.h),
                ],
              ),
            ),
          ),
          if (isFetching || errorMessage != null || isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
                child: ScreenWrapper(
                  isFetching: isFetching,
                  isEmpty: isEmpty && (errorMessage == null),
                  emptyMessage: 'No providers found',
                  errorMessage: errorMessage,
                  actions: errorMessage != null
                      ? [
                          TextButton(
                            onPressed: onRetry,
                            child: const Text('Retry'),
                          ),
                        ]
                      : null,
                  child: const SizedBox.shrink(),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 16.h),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= billers.length) {
                      return const _BillerListingFooterSkeleton();
                    }
                    final item = billers[index];
                    return Column(
                      children: [
                        _BillerTile(
                          biller: item,
                          onTap: () => onTapBiller(item),
                        ),
                      ],
                    );
                  },
                  childCount: billers.length + (isFetchingMore ? 1 : 0),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BillerListingSkeleton extends StatelessWidget {
  const _BillerListingSkeleton();

  static const _mockBillers = [
    Biller(billerId: '1', billerName: 'Electricity Board Service'),
    Biller(billerId: '2', billerName: 'Regional Power Provider'),
    Biller(billerId: '3', billerName: 'National Utility Payment'),
    Biller(billerId: '4', billerName: 'Consumer Energy Services'),
    Biller(billerId: '5', billerName: 'State Electricity Network'),
    Biller(billerId: '6', billerName: 'Metro Bill Payments'),
  ];

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: IgnorePointer(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                height: 52.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: AppColors.lightBorder),
                ),
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: AppColors.textPrimary,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'Search Service',
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
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _mockBillers.length,
                separatorBuilder: (_, __) => SizedBox(height: 10.h),
                itemBuilder: (_, index) => _BillerTile(
                  biller: _mockBillers[index],
                  onTap: () {},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillerListingFooterSkeleton extends StatelessWidget {
  const _BillerListingFooterSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: IgnorePointer(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: _BillerTile(
            biller: _BillerListingSkeleton._mockBillers.first,
            onTap: null,
          ),
        ),
      ),
    );
  }
}

class _ServiceRecentRow extends StatelessWidget {
  const _ServiceRecentRow({
    required this.recentTransactions,
    required this.onPayNow,
  });

  final AsyncValue<List<LatestTransaction>> recentTransactions;
  final ValueChanged<LatestTransaction> onPayNow;

  @override
  Widget build(BuildContext context) {
    return ServiceRecentSection(
      recentTransactions: recentTransactions,
      onPayNow: onPayNow,
      title: 'Recents',
      actionText: 'View all',
    );
  }
}

class _StaticBanner extends StatelessWidget {
  const _StaticBanner({required this.asset});
  final String asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        asset,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _FigmaSectionHeader extends StatelessWidget {
  const _FigmaSectionHeader({
    required this.title,
    this.actionText,
  });

  final String title;
  final String? actionText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
        ),
        const Spacer(),
        if ((actionText ?? '').trim().isNotEmpty)
          Text(
            actionText!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFE85A2C),
                  fontWeight: FontWeight.w700,
                ),
          ),
      ],
    );
  }
}

class _StaticRecentRow extends StatelessWidget {
  const _StaticRecentRow();

  @override
  Widget build(BuildContext context) {
    const items = [
      _RecentStaticItem(
        title: 'Sun Direct',
        subtitleLine1: '1234567890',
        subtitleLine2: 'Last Paid - ₹ 289 On 12-04-2020',
      ),
      _RecentStaticItem(
        title: 'Airtel Digital TV',
        subtitleLine1: '+911234567890',
        subtitleLine2: 'Last Paid - ₹ 449 On 02-03-2020',
      ),
    ];

    return SizedBox(
      height: 86.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (context, index) => _RecentStaticCard(item: items[index]),
      ),
    );
  }
}

class _RecentStaticItem {
  const _RecentStaticItem({
    required this.title,
    required this.subtitleLine1,
    required this.subtitleLine2,
  });

  final String title;
  final String subtitleLine1;
  final String subtitleLine2;
}

class _RecentStaticCard extends StatelessWidget {
  const _RecentStaticCard({required this.item});
  final _RecentStaticItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300.w,
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 12.w, 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E2E2)),
      ),
      child: Row(
        children: [
          Container(
            height: 44.w,
            width: 44.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: const Color(0xFFE2E2E2)),
            ),
            child: Center(
              child: Text(
                item.title.trim().isEmpty ? '' : item.title.trim()[0],
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFFE85A2C),
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ),
                SizedBox(height: 2.h),
                Text(
                  item.subtitleLine1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: 2.h),
                Text(
                  item.subtitleLine2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Image.asset(
            FileConstants.tiltArrow,
            height: 25,
            width: 25,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

class _BillerTile extends StatelessWidget {
  const _BillerTile({
    required this.biller,
    this.onTap,
  });

  final Biller biller;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            // Provider logo placeholder
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.lightBorder2,
                  width: 1,
                ),
              ),
              child: _BillerIcon(
                name: biller.billerName,
                iconUrl: biller.iconUrl,
                size: 38,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                biller.billerName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            Image.asset(
              FileConstants.tiltArrow,
              height: 25,
              width: 25,
              fit: BoxFit.contain,
            ),
          ],
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
    required this.borderRadius,
  });

  final String name;
  final String? iconUrl;
  final double size;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '';
    final fallback = Center(
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
      fit: BoxFit.cover,
      borderRadius: borderRadius,
      placeholder: fallback,
      errorWidget: fallback,
    );
  }
}
