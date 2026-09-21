// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:e_rupaiya/features/mobile_prepaid/components/recharge_quick_action_card.dart';
import 'package:e_rupaiya/features/mobile_prepaid/models/mobile_prepaid_state.dart';
import 'package:e_rupaiya/widgets/search_textfield.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../services/permission_service.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/contacts_permission_card.dart';
import '../../../widgets/k_dialog.dart';
import '../../../widgets/my_app_bar.dart';
import '../../../widgets/screen_wrapper.dart';
import '../../home/models/banner_model.dart';
import '../../profile/controllers/profile_controller.dart';
import '../components/contacts_list.dart';
import '../components/filter_plans_sheet.dart';
import '../components/mobile_prepaid_shimmer.dart';
import '../components/payment_bottom_sheet.dart';
import '../components/plan_card.dart';
import '../components/plan_details_sheet.dart';
import '../controllers/contacts_cache_controller.dart';
import '../controllers/mobile_prepaid_controller.dart';
import '../controllers/prepaid_meta_controller.dart';
import '../models/latest_transaction.dart';
import '../models/operator_option.dart';
import '../models/plan_item.dart';
import '../models/recharge_quick_action_payload.dart';
import '../models/region_option.dart';

part 'mobile_prepaid_view_parts.dart';

List<int> _filterContactIndices(Map<String, dynamic> payload) {
  final rawEntries = payload['entries'] as List<dynamic>? ?? const [];
  final query = (payload['query'] as String? ?? '').toLowerCase();
  final queryDigits = query.replaceAll(RegExp(r'\D'), '');
  final normalizedQueryDigits = _normalizeMobile(queryDigits);
  if (rawEntries.isEmpty) return const [];
  if (query.isEmpty) {
    return List<int>.generate(rawEntries.length, (index) => index);
  }
  final matches = <int>[];
  for (var i = 0; i < rawEntries.length; i++) {
    final entry = rawEntries[i] as Map;
    final name = (entry['name'] as String? ?? '');
    final phone = (entry['phone'] as String? ?? '').replaceAll(
      RegExp(r'\D'),
      '',
    );
    final normalizedPhone = _normalizeMobile(phone);
    final matchesName = name.contains(query);
    final matchesPhone = queryDigits.isNotEmpty &&
        (phone.contains(queryDigits) ||
            (normalizedQueryDigits.isNotEmpty &&
                normalizedPhone.contains(normalizedQueryDigits)));
    if (matchesName || matchesPhone) {
      matches.add(i);
    }
  }
  return matches;
}

String _normalizeMobile(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.length > 10 && digits.startsWith('91')) {
    return digits.substring(digits.length - 10);
  }
  return digits;
}

class MobilePrepaidView extends HookConsumerWidget {
  const MobilePrepaidView({super.key, this.quickAction});

  final RechargeQuickActionPayload? quickAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mobilePrepaidControllerProvider);
    final controller = ref.read(mobilePrepaidControllerProvider.notifier);
    final quickActionPayload = quickAction;
    final recentPayments = ref.watch(latestRechargeTransactionsProvider);
    final banners = ref.watch(mobilePrepaidBannersProvider);
    final profileState = ref.watch(profileControllerProvider);
    final myNumberForApi =
        _normalizeMobile((profileState.profile?.mobile ?? '').trim());

    final permissionService = useMemoized(() => const PermissionService());
    final hasPermission = useState(false);
    final contactsState = ref.watch(contactsCacheControllerProvider);
    final contactsController =
        ref.read(contactsCacheControllerProvider.notifier);
    final filteredContacts = useState<List<Contact>>([]);
    final visibleContactCount = useState(100);
    final contactQuery = useState('');
    final contactSearchController = useTextEditingController();
    final isMounted = useIsMounted();
    final filterToken = useRef(0);
    final contactsSectionKey = useMemoized(GlobalKey.new);

    final manualMobileController = useTextEditingController();
    final manualNumberController = useTextEditingController();
    final numericFocusNode = useFocusNode();
    final alphaFocusNode = useFocusNode();
    final searchMode = useState<_MobilePrepaidSearchMode>(
      _MobilePrepaidSearchMode.abc,
    );
    final planSearchController =
        useTextEditingController(text: state.planSearchQuery);
    final planSearchDebounceRef = useRef<Timer?>(null);

    final showPlans = state.mobile.isNotEmpty || state.operatorInfo != null;
    final quickActionHandled = useRef(false);
    final repeatTarget = useState<LatestTransaction?>(null);
    final repeatHandledForId = useRef<String?>(null);

    void handleRepeatRecharge(LatestTransaction payment) {
      repeatTarget.value = payment;
      final phone = _normalizeMobile(payment.serviceNo);
      manualMobileController.text = phone;
      Future.microtask(() async {
        await controller.fetchOperatorAndPlans(phone);
        final amountInt = payment.amount.toInt();
        if (amountInt > 0) {
          controller.updatePlanSearch('$amountInt');
        }
      });
    }

    void handleMyNumberRecharge(String mobile) {
      final normalized = _normalizeMobile(mobile);
      final items = recentPayments.asData?.value ?? const <LatestTransaction>[];
      final match = items.cast<LatestTransaction?>().firstWhere(
            (e) => e != null && _normalizeMobile(e.serviceNo) == normalized,
            orElse: () => null,
          );
      if (match != null && match.amount.toInt() > 0) {
        handleRepeatRecharge(match);
        return;
      }
      controller.fetchOperatorAndPlans(normalized);
    }

    useEffect(() {
      return () {
        planSearchDebounceRef.value?.cancel();
        controller.reset();
      };
    }, const []);

    useEffect(() {
      if (searchMode.value == _MobilePrepaidSearchMode.numeric) {
        // When switching from ABC -> 123, carry any typed number over so the
        // numeric search can continue seamlessly.
        final fromAlpha = _normalizeMobile(contactSearchController.text);
        if (fromAlpha.isNotEmpty && manualNumberController.text != fromAlpha) {
          manualNumberController.text = fromAlpha;
          manualNumberController.selection = TextSelection.collapsed(
            offset: manualNumberController.text.length,
          );
        }
        Future.microtask(() => numericFocusNode.requestFocus());
      } else {
        // When switching from 123 -> ABC, carry the digits back so the user
        // can continue searching in the same field.
        final fromNumeric = _normalizeMobile(manualNumberController.text);
        if (fromNumeric.isNotEmpty &&
            contactSearchController.text != fromNumeric) {
          contactSearchController.text = fromNumeric;
          contactSearchController.selection = TextSelection.collapsed(
            offset: contactSearchController.text.length,
          );
        }
        Future.microtask(() => alphaFocusNode.requestFocus());
      }
      return null;
    }, [searchMode.value, numericFocusNode, alphaFocusNode]);

    useEffect(() {
      void listener() {
        if (searchMode.value != _MobilePrepaidSearchMode.numeric) return;
        contactQuery.value = manualNumberController.text;
      }

      manualNumberController.addListener(listener);
      return () => manualNumberController.removeListener(listener);
    }, [manualNumberController, searchMode.value]);

    Future<void> loadContacts() async {
      await contactsController.fetchIfNeeded();
    }

    useEffect(() {
      Future.microtask(() async {
        final granted = await permissionService.hasContactsPermission();
        if (!isMounted()) return;
        hasPermission.value = granted;
        if (granted) {
          await loadContacts();
        }
      });
      return null;
    }, const []);

    useEffect(() {
      if (quickActionPayload == null) return null;
      Future.microtask(() async {
        final phone = _normalizeMobile(quickActionPayload.phone.trim());
        if (phone.isEmpty) return;
        manualMobileController.text = phone;
        await controller.fetchOperatorAndPlans(phone);
        if (quickActionPayload.amount > 0) {
          controller.updatePlanSearch(
            quickActionPayload.amount.toString(),
          );
        }
      });
      return null;
    }, [quickActionPayload]);

    useEffect(() {
      if (quickActionPayload == null) return null;
      if (!quickActionPayload.autoOpenPaymentSheet) return null;
      if (quickActionHandled.value) return null;
      if (state.isFetching) return null;
      if (state.plansByCategory.isEmpty) return null;

      final targetAmount = quickActionPayload.amount;
      if (targetAmount <= 0) return null;

      String? matchedCategory;
      PlanItem? matchedPlan;
      for (final entry in state.plansByCategory.entries) {
        for (final plan in entry.value) {
          if (plan.amount != targetAmount) continue;
          matchedCategory = entry.key;
          matchedPlan = plan;
          break;
        }
        if (matchedPlan != null) break;
      }

      if (matchedPlan == null) return null;
      quickActionHandled.value = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        if (matchedCategory != null && matchedCategory.isNotEmpty) {
          controller.selectCategory(matchedCategory);
        }
        controller.selectPlan(matchedPlan!);
        KDialog.instance.openSheet(
          dialog: PrepaidPaymentBottomSheet(
            plan: matchedPlan,
            billerName: state.operatorInfo?.operatorName ?? 'Mobile Prepaid',
            ecoinsRestrictionsPercent: state.ecoinsRestrictionsPercent,
          ),
        );
      });
      return null;
    }, [
      quickActionPayload,
      state.isFetching,
      state.plansByCategory,
    ]);

    useEffect(() {
      final payment = repeatTarget.value;
      if (payment == null) return null;
      if (repeatHandledForId.value == payment.id) return null;
      if (state.isFetching) return null;
      if (state.plansByCategory.isEmpty) return null;

      final amountInt = payment.amount.toInt();
      if (amountInt <= 0) return null;

      String? matchedCategory;
      PlanItem? matchedPlan;
      for (final entry in state.plansByCategory.entries) {
        for (final plan in entry.value) {
          if (plan.amount != amountInt) continue;
          matchedCategory = entry.key;
          matchedPlan = plan;
          break;
        }
        if (matchedPlan != null) break;
      }

      repeatHandledForId.value = payment.id;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        if (matchedPlan == null) return;
        if (matchedCategory != null && matchedCategory.isNotEmpty) {
          controller.selectCategory(matchedCategory);
        }
        controller.selectPlan(matchedPlan);
        KDialog.instance.openSheet(
          dialog: PrepaidPaymentBottomSheet(
            plan: matchedPlan,
            billerName: state.operatorInfo?.operatorName ?? 'Mobile Prepaid',
            ecoinsRestrictionsPercent: state.ecoinsRestrictionsPercent,
          ),
        );
      });

      return null;
    }, [
      repeatTarget.value,
      state.isFetching,
      state.plansByCategory,
    ]);

    Future<void> handleRequestPermission() async {
      final granted = await permissionService.requestContacts();
      if (!isMounted()) return;
      hasPermission.value = granted;
      if (granted) {
        await contactsController.reload();
      }
    }

    useEffect(() {
      if (planSearchController.text != state.planSearchQuery) {
        planSearchController.text = state.planSearchQuery;
        planSearchController.selection = TextSelection.collapsed(
          offset: planSearchController.text.length,
        );
      }
      return null;
    }, [state.planSearchQuery]);

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

      // If user typed a phone number in ABC search and no contacts matched,
      // automatically switch to the numeric (123) mode.
      if (searchMode.value == _MobilePrepaidSearchMode.abc) {
        final queryDigits = query.replaceAll(RegExp(r'\D'), '');
        final looksNumericOnly = queryDigits.isNotEmpty && queryDigits == query;
        if (looksNumericOnly && queryDigits.length >= 4 && indices.isEmpty) {
          searchMode.value = _MobilePrepaidSearchMode.numeric;
        }
      }
    }

    useEffect(() {
      Future.microtask(rebuildFilteredContacts);
      return null;
    }, [contactQuery.value, contactsState.searchIndex]);

    final lastError = useRef<String?>(null);
    final lastMessage = useRef<String?>(null);

    useEffect(() {
      if (state.errorMessage != null && state.errorMessage != lastError.value) {
        lastError.value = state.errorMessage;
        final message = state.errorMessage?.trim().toLowerCase() ?? '';
        if (message == 'unable to process recharge') {
          return null;
        }
        // WidgetsBinding.instance.addPostFrameCallback((_) {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     SnackBar(
        //       content: Text(state.errorMessage!),
        //       backgroundColor: Colors.red.shade400,
        //     ),
        //   );
        // });
      }
      return null;
    }, [state.errorMessage]);

    useEffect(() {
      if (state.rechargeMessage != null &&
          state.rechargeMessage != lastMessage.value) {
        lastMessage.value = state.rechargeMessage;
        // WidgetsBinding.instance.addPostFrameCallback((_) {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     SnackBar(
        //       content: Text(state.rechargeMessage!),
        //       backgroundColor: AppColors.primary,
        //     ),
        //   );
        // });
      }
      return null;
    }, [state.rechargeMessage]);

    final hasPlanSelected = showPlans && state.selectedPlan != null;
    final showOperatorCard = showPlans || hasPlanSelected;
    final isOpeningOperatorSheet = useState(false);
    final isSelectionScreen = !showPlans && !hasPlanSelected;

    Future<void> handleChange() async {
      if (isOpeningOperatorSheet.value) return;
      isOpeningOperatorSheet.value = true;
      try {
        await _openOperatorSheet(
          ref,
          mobile: state.mobile,
          onSelected: (operator, region) async {
            await controller.fetchPlansForSelection(
              mobileInput: state.mobile,
              operatorName: operator.name,
              circleName: region.name,
              circleCode: region.code,
              iconUrl: operator.iconUrl,
            );
          },
        );
      } finally {
        isOpeningOperatorSheet.value = false;
      }
    }

    Future<void> handleManualProceed(String mobile) async {
      final normalized = _normalizeMobile(mobile);
      manualMobileController.text = normalized;
      await controller.fetchOperatorAndPlans(normalized);
      final latest = ref.read(mobilePrepaidControllerProvider);
      if (latest.operatorInfo != null && latest.plansByCategory.isNotEmpty) {
        return;
      }
      if (!context.mounted) return;
      // If auto-detect fails we fallback to manual selection, so suppress the
      // generic error snackbar/message for this path.
      controller.clearError();
      await _openOperatorSheet(
        ref,
        mobile: normalized,
        onSelected: (operator, region) async {
          await controller.fetchPlansForSelection(
            mobileInput: normalized,
            operatorName: operator.name,
            circleName: region.name,
            circleCode: region.code,
            iconUrl: operator.iconUrl,
          );
        },
      );
    }

    void handleBack() {
      if (hasPlanSelected) {
        controller.deselectPlan();
        return;
      }
      if (showPlans) {
        controller.reset();
        manualMobileController.clear();
        planSearchController.clear();
        contactQuery.value = '';
        return;
      }
      if (context.canPop()) {
        context.pop();
        return;
      }
      context.go(RouteConstants.home);
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: MyAppBar(
          title: isSelectionScreen
              ? 'Mobile Prepaid'
              : (hasPlanSelected ? 'Pay Now' : 'Select A Recharge Plan'),
          onBack: handleBack,
        ),
        body: Column(
          children: [
            if (showOperatorCard) ...[
              SizedBox(height: 12.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Center(
                  child: SimpleQuickActionCard(
                    title: '+91 ${state.mobile}',
                    subtitle:
                        '${state.operatorInfo?.operatorName ?? 'Operator'} • ${state.operatorInfo?.circle ?? 'Circle'}',
                    leadingImageUrl: state.operatorInfo?.iconUrl,
                    actionLabel: 'Change',
                    onAction: handleChange,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
            ] else
              SizedBox(height: 12.h),
            Expanded(
              child: state.isFetching
                  ? const MobilePrepaidContentShimmer() 
                  : hasPlanSelected
                      ? _PayNowSection(
                          state: state,
                          controller: controller,
                        )
                      : showPlans
                          ? _PlanSection(
                              state: state,
                              controller: controller,
                              planSearchController: planSearchController,
                              onPlanSearchChanged: (value) {
                                controller.updatePlanSearch(value);
                                planSearchDebounceRef.value?.cancel();
                                final info = state.operatorInfo;
                                if (info == null || state.mobile.isEmpty)
                                  return;
                                planSearchDebounceRef.value = Timer(
                                  const Duration(milliseconds: 350),
                                  () async {
                                    await controller.fetchPlansForSelection(
                                      mobileInput: state.mobile,
                                      operatorName: info.operatorName,
                                      circleName: info.circle,
                                      circleCode: info.circleCode,
                                      iconUrl: info.iconUrl,
                                      search: value,
                                      filters: state.appliedFilters
                                          .where(
                                            (e) =>
                                                e.trim().isNotEmpty &&
                                                e.trim() != 'All',
                                          )
                                          .toList(),
                                    );
                                  },
                                );
                              },
                            )
                          : _ContactsSection(
                              hasContactsPermission: hasPermission.value,
                              onRequestPermission: handleRequestPermission,
                              recentPayments: recentPayments,
                              banners: banners,
                              myNumberForApi: myNumberForApi,
                              contactsSectionKey: contactsSectionKey,
                              isLoading: contactsState.isLoading,
                              contacts: filteredContacts.value,
                              allContacts: contactsState.contacts,
                              visibleCount: visibleContactCount.value,
                              contactSearchController: contactSearchController,
                              manualNumberController: manualNumberController,
                              numericFocusNode: numericFocusNode,
                              alphaFocusNode: alphaFocusNode,
                              searchMode: searchMode.value,
                              onSearchModeChange: (mode) =>
                                  searchMode.value = mode,
                              onQueryChange: (value) =>
                                  contactQuery.value = value,
                              onReload: loadContacts,
                              onLoadMore: () {
                                if (visibleContactCount.value >=
                                    filteredContacts.value.length) {
                                  return;
                                }
                                visibleContactCount.value =
                                    (visibleContactCount.value + 100).clamp(
                                  0,
                                  filteredContacts.value.length,
                                );
                              },
                              onSelect: (mobile) {
                                controller.fetchOperatorAndPlans(
                                  _normalizeMobile(mobile),
                                );
                              },
                              onManualProceed: handleManualProceed,
                              onRepeatRecent: (payment) {
                                handleRepeatRecharge(payment);
                              },
                              onMyNumberRecharge: handleMyNumberRecharge,
                              onViewAllRecent: () => context.push(
                                RouteConstants.mobileRecentRecharges,
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
