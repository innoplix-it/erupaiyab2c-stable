// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:e_rupaiya/features/mobile_prepaid/components/recharge_quick_action_card.dart';
import 'package:e_rupaiya/features/paymentgateway/razorpay_guard.dart';
import 'package:e_rupaiya/features/paymentgateway/razorpay_service.dart';
import 'package:e_rupaiya/features/services/models/biller_detail_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../config/app_env.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../services/permission_service.dart';
import '../../../utils/date_format_helper.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/bill_sample_terms_card.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/date_picker_field.dart';
import '../../../widgets/k_dialog.dart';
import '../../../widgets/my_app_bar.dart';
import '../../../widgets/param_dropdown_field.dart';
import '../../../widgets/payment_success_flow.dart';
import '../../../widgets/processing_overlay.dart';
import '../../../widgets/search_textfield.dart';
import '../../mobile_prepaid/components/payment_bottom_sheet.dart';
import '../../mobile_prepaid/controllers/contacts_cache_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/views/transaction_detail_screen.dart';
import '../components/credit_card_pay_now/credit_card_pay_now_section.dart';
import '../components/piped_gas/piped_gas_bill_section.dart';
import '../components/service_error_banner.dart';
import '../controllers/biller_detail_controller.dart';
import '../models/bill_response_model.dart';
import '../models/biller_detail_args.dart';
import '../models/biller_detail_model.dart';

part 'biller_detail_view_parts.dart';

void _debugLog(String message) {
  if (!AppEnv.enableLogs || !kDebugMode) return;
  debugPrint(message);
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  const _UpperCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final upperText = newValue.text.toUpperCase();
    return newValue.copyWith(
      text: upperText,
      selection: TextSelection.collapsed(offset: upperText.length),
      composing: TextRange.empty,
    );
  }
}

class BillerDetailView extends HookConsumerWidget {
  const BillerDetailView({super.key, this.args});

  final BillerDetailArgs? args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(billerDetailControllerProvider);
    final controller = ref.read(billerDetailControllerProvider.notifier);
    final biller = detailState.selectedBiller ?? args?.biller;
    final detail = detailState.billerDetail;
    final bill = detailState.billResponse;
    final profileState = ref.watch(profileControllerProvider);
    final customerParamsInput = detailState.customerParamsInput ?? {};
    final inputControllers =
        useMemoized(() => <String, TextEditingController>{});
    final billAmountController = useTextEditingController();
    final selectedAmountType = useState(_PaymentAmountType.totalOutstanding);
    final permissionService = useMemoized(() => const PermissionService());
    final contactsController =
        ref.read(contactsCacheControllerProvider.notifier);
    final isCreditCardFlow = args?.isCreditCard ?? false;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final mobilePrefill = args?.mobileNumber?.trim();
    final last4Prefill = args?.cardLast4?.trim();
    final autoFetchBill = args?.autoFetchBill ?? false;
    final autoOpenPaymentSheet = args?.autoOpenPaymentSheet ?? false;
    final loggedInMobile = profileState.profile?.mobile.trim();
    final isGasCylinder = useMemoized(
      () => _isGasCylinderCategory(args?.paymentType),
      [args?.paymentType],
    );
    final isPipedGas = useMemoized(
      () => _isPipedGasCategory(args?.paymentType),
      [args?.paymentType],
    );
    final isElectricity = useMemoized(
      () => (args?.paymentType ?? '').toLowerCase().contains('electric'),
      [args?.paymentType],
    );
    final showBillSample = useState(false);
    final isHandlingPayAction = useState(false);
    final fieldErrors = useState<Map<String, String?>>({});
    final gasPolicyMessage = useState<String?>(null);
    final pipedGasErrorMessage = useState<String?>(null);
    final creditCardErrorMessage = useState<String?>(null);
    final didAutoFetchBill = useRef(false);
    useEffect(() {
      Future.microtask(
        () =>
            ref.read(profileControllerProvider.notifier).fetchProfileIfNeeded(),
      );
      return null;
    }, const []);
    final isSubscription = _isSubscriptionFlow(
      paymentType: args?.paymentType,
      detailCategory: detail?.billerCategoryName,
      billerName: biller?.billerName,
    );
    final showSubscriptionSummary = isSubscription && bill != null;

    Map<String, String?> gasCylinderInlineErrors(BillerDetail detail) {
      final errors = <String, String?>{};
      final visible = detail.customerParams.where((p) => p.visibility).toList();
      if (visible.isEmpty) return errors;

      for (final p in visible) {
        final key = p.paramName.toLowerCase();
        final isLpg =
            key.contains('lpg') || key.contains('gas') || key.contains('id');
        final isContact = key.contains('contact') ||
            key.contains('mobile') ||
            key.contains('registered');
        if (isLpg || isContact) {
          errors[p.paramName] =
              'Please enter either Registered Contact Number or LPG ID.';
        }
      }

      // If we failed to match, fall back to marking all visible fields.
      if (errors.isEmpty) {
        for (final p in visible) {
          errors[p.paramName] =
              'Please enter either Registered Contact Number or LPG ID.';
        }
      }
      return errors;
    }

    Map<String, String?> mapFetchBillValidationToFields({
      required String message,
      required BillerDetail? detail,
      required bool isGasCylinder,
    }) {
      final trimmed = message.trim();
      if (trimmed.isEmpty || detail == null) return const {};

      String normalize(String input) =>
          input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

      final normalizedMessage = normalize(trimmed);
      if (normalizedMessage.isEmpty) return const {};

      if (isGasCylinder &&
          (normalizedMessage.contains('lpg') ||
              normalizedMessage.contains('registeredcontact') ||
              normalizedMessage.contains('registeredmobil'))) {
        return gasCylinderInlineErrors(detail);
      }

      final errors = <String, String?>{};
      for (final param in detail.customerParams.where((p) => p.visibility)) {
        final name = param.paramName.trim();
        if (name.isEmpty) continue;
        final normalizedName = normalize(name);
        if (normalizedName.isEmpty) continue;
        if (normalizedMessage.contains(normalizedName)) {
          errors[param.paramName] = trimmed;
        }
      }
      return errors;
    }

    useEffect(() {
      final argBiller = args?.biller;
      if (argBiller != null &&
          detailState.selectedBiller?.billerId != argBiller.billerId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          controller.selectBiller(
            argBiller,
            categoryName: args?.paymentType,
          );
        });
      }
      return null;
    }, [args?.biller.billerId]);

    // Fetch profile for gas cylinder flow mobile prefill (if needed).
    useEffect(() {
      if (!isGasCylinder) return null;
      Future.microtask(() async {
        if (loggedInMobile != null && loggedInMobile.isNotEmpty) return;
        if (profileState.isFetching) return;
        await ref.read(profileControllerProvider.notifier).fetchProfile();
      });
      return null;
    }, [isGasCylinder, loggedInMobile, profileState.isFetching]);

    // Prefetch contacts early so opening the picker is instant.
    useEffect(() {
      Future.microtask(() async {
        final granted = await permissionService.hasContactsPermission();
        if (!granted) return;
        await contactsController.fetchIfNeeded();
      });
      return null;
    }, const []);

    ref.listen<BillerDetailState>(billerDetailControllerProvider,
        (previous, next) {
      final message = next.errorMessage;
      if (message != null && message.isNotEmpty) {
        if (previous?.errorMessage != message) {
          // Inline validation errors for fetch-bill form (instead of snackbars).
          final isOnInputForm =
              next.billResponse == null && next.billerDetail != null;
          if (isOnInputForm) {
            if (isGasCylinder && _isGasBookingPolicyMessage(message)) {
              gasPolicyMessage.value = message;
              fieldErrors.value = {};
              return;
            }
            if (isPipedGas) {
              pipedGasErrorMessage.value = message;
              return;
            }
            if (isCreditCardFlow) {
              creditCardErrorMessage.value = message;
              return;
            }
            if (gasPolicyMessage.value != null) {
              gasPolicyMessage.value = null;
            }
            final inline = mapFetchBillValidationToFields(
              message: message,
              detail: next.billerDetail,
              isGasCylinder: isGasCylinder,
            );
            if (inline.isNotEmpty) {
              fieldErrors.value = {
                ...fieldErrors.value,
                ...inline,
              };

              return;
            }

            // Gas fetch-bill failures should be rendered inline (red cards)
            // beneath the form; never show a popup for gas.
            if (isGasCylinder) {
              return;
            }
          }
          // For gas/piped-gas/credit-card, avoid popups in any state.
          if (isGasCylinder) {
            AppSnackbar.show(
              message,
              behavior: SnackBarBehavior.fixed,
            );
            return;
          }
          if (isCreditCardFlow) {
            creditCardErrorMessage.value = message;
            return;
          }
          if (isOnInputForm) {
            // Gas bill fetch failures should be shown inline (red cards)
            // instead of a dialog.
            if (isGasCylinder) {
              return;
            }
            if (isPipedGas) {
              // Show inline banner for piped gas instead of popup.
              pipedGasErrorMessage.value = message;
              return;
            }
            // Fetch-bill failures should be shown as a friendly popup instead
            // of a snackbar since we support many billers/services.
            KDialog.instance.openDialog(
              barrierDismissible: true,
              dialog: _BillFetchFailedDialog(
                message: message,
                onContinue: () {
                  Navigator.of(context).pop();
                  controller.clearBill();
                },
              ),
            );
          } else {
            AppSnackbar.show(
              message,
              behavior: SnackBarBehavior.fixed,
            );
          }
        }
      }
    });

    final totalOutstanding =
        bill == null ? null : _resolveTotalOutstanding(bill);
    final minimumDue = bill == null ? null : _resolveMinimumDue(bill);
    final isFastTag = (() {
      bool hasFastTag(String? v) =>
          (v ?? '').toLowerCase().replaceAll('-', '').contains('fastag') ||
          (v ?? '').toLowerCase().replaceAll('-', '').contains('fasttag');
      return hasFastTag(detail?.billerCategoryName) ||
          hasFastTag(biller?.billerName);
    })();
    final fastTagMinAmount =
        isFastTag && bill != null ? _resolveFastTagMinAmount(bill) : null;
    final fastTagMaxAmount =
        isFastTag && bill != null ? _resolveFastTagMaxAmount(bill) : null;

    // Set bill amount when fetched
    useEffect(() {
      if (bill != null) {
        selectedAmountType.value = _PaymentAmountType.totalOutstanding;
        final amount = _resolveDateBasedAmount(bill);
        billAmountController.text = isFastTag
            ? _formatAmountForInput(amount)
            : amount.toStringAsFixed(2);
      }
      return null;
    }, [bill]);

    useEffect(() {
      if (bill != null || detailState.errorMessage == null) {
        if (gasPolicyMessage.value != null) {
          gasPolicyMessage.value = null;
        }
        if (pipedGasErrorMessage.value != null) {
          pipedGasErrorMessage.value = null;
        }
        if (creditCardErrorMessage.value != null) {
          creditCardErrorMessage.value = null;
        }
      }
      return null;
    }, [bill, detailState.errorMessage]);

    // Create controllers for each customer param
    if (detail != null) {
      for (final param in detail.customerParams) {
        if (param.visibility) {
          _debugLog(
            'Biller param: name=${param.paramName} '
            'type=${param.dataType} '
            'min=${param.minLength} '
            'max=${param.maxLength}',
          );
          inputControllers.putIfAbsent(
            param.paramName,
            () => TextEditingController(),
          );
          final tc = inputControllers[param.paramName];
          if (tc != null && tc.text.isEmpty) {
            final isMobileField = _isMobileParam(param.paramName) ||
                (isCreditCardFlow &&
                    param.dataType.toUpperCase() == 'NUMERIC' &&
                    param.maxLength == 10 &&
                    !_isLastFourParam(param.paramName));
            final isLastFourField = _isLastFourParam(param.paramName) ||
                (isCreditCardFlow &&
                    param.dataType.toUpperCase() == 'NUMERIC' &&
                    param.maxLength == 4);
            final isGasLockedMobile = isGasCylinder && isMobileField;
            _debugLog(
              'Prefill check: name=${param.paramName} '
              'mobile=$mobilePrefill last4=$last4Prefill '
              'isMobile=$isMobileField isLast4=$isLastFourField',
            );
            if (isGasLockedMobile &&
                loggedInMobile != null &&
                loggedInMobile.isNotEmpty) {
              tc.text = _sanitizePhone(loggedInMobile);
              _debugLog(
                  'Prefilled gas mobile for ${param.paramName}: ${tc.text}');
            } else if (mobilePrefill != null &&
                mobilePrefill.isNotEmpty &&
                !isLastFourField &&
                (isMobileField ||
                    _isIdentifierParam(param.paramName, param.dataType))) {
              tc.text =
                  isMobileField ? _sanitizePhone(mobilePrefill) : mobilePrefill;
              _debugLog(
                  'Prefilled identifier for ${param.paramName}: ${tc.text}');
            } else if (last4Prefill != null &&
                last4Prefill.isNotEmpty &&
                isLastFourField) {
              final digits = last4Prefill.replaceAll(RegExp(r'[^0-9]'), '');
              tc.text = digits.length > 4
                  ? digits.substring(digits.length - 4)
                  : digits;
              _debugLog('Prefilled last4 for ${param.paramName}: ${tc.text}');
            }
          }
        }
      }
    }

    useEffect(() {
      return () {
        for (final controller in inputControllers.values) {
          controller.dispose();
        }
      };
    }, const []);

    useEffect(() {
      if (detail == null) return null;
      for (final param in detail.customerParams) {
        if (!param.visibility) continue;
        final tc = inputControllers[param.paramName];
        if (tc == null || tc.text.isNotEmpty) continue;
        final isMobileField = _isMobileParam(param.paramName) ||
            (isCreditCardFlow &&
                param.dataType.toUpperCase() == 'NUMERIC' &&
                param.maxLength == 10 &&
                !_isLastFourParam(param.paramName));
        final isLastFourField = _isLastFourParam(param.paramName) ||
            (isCreditCardFlow &&
                param.dataType.toUpperCase() == 'NUMERIC' &&
                param.maxLength == 4);
        final isGasLockedMobile = isGasCylinder && isMobileField;
        if (isGasLockedMobile &&
            loggedInMobile != null &&
            loggedInMobile.isNotEmpty) {
          tc.text = _sanitizePhone(loggedInMobile);
        } else if (mobilePrefill != null &&
            mobilePrefill.isNotEmpty &&
            !isLastFourField &&
            isMobileField) {
          tc.text = _sanitizePhone(mobilePrefill);
        } else if (last4Prefill != null &&
            last4Prefill.isNotEmpty &&
            isLastFourField) {
          final digits = last4Prefill.replaceAll(RegExp(r'[^0-9]'), '');
          tc.text =
              digits.length > 4 ? digits.substring(digits.length - 4) : digits;
        }
      }
      return null;
    }, [detail, mobilePrefill, last4Prefill, loggedInMobile, isGasCylinder]);

    // Auto-fetch bill & open payment sheet for "Pay Now" from recent cards.
    useEffect(() {
      // Reset per biller/flag so navigating to another provider can auto-fetch once.
      didAutoFetchBill.value = false;
      return null;
    }, [autoFetchBill, biller?.billerId]);

    useEffect(() {
      if (!autoFetchBill) return null;
      if (detail == null || biller == null) return null;
      if (bill != null) return null;
      if (didAutoFetchBill.value) return null;
      if (detailState.isFetchingBill || detailState.isFetchingDetail) {
        return null;
      }

      didAutoFetchBill.value = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!context.mounted) return;
        final params = <String, String>{};
        for (final p in detail.customerParams.where((p) => p.visibility)) {
          final tc = inputControllers[p.paramName];
          final value = tc?.text.trim() ?? '';
          if (value.isNotEmpty) {
            params[p.paramName] = value;
          }
        }
        if (params.isEmpty) return;
        await controller.fetchBill(customerParams: params);
      });
      return null;
    }, [
      autoFetchBill,
      biller?.billerId,
      detail,
      bill,
      detailState.isFetchingBill,
      detailState.isFetchingDetail,
    ]);

    useEffect(() {
      if (!autoOpenPaymentSheet) return null;
      if (bill == null) return null;
      if (detailState.isFetchingBill) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final amountToPay = _resolveDateBasedAmount(bill);
        _showPaymentSheet(
          context,
          amountToPay,
          isCreditCardFlow: isCreditCardFlow,
          paymentTypeOverride: args?.paymentType,
          ecoinsRestrictionsPercent: bill.ecoinsRestrictionsPercent,
        );
      });
      return null;
    }, [autoOpenPaymentSheet, bill, detailState.isFetchingBill]);

    return PopScope(
      canPop: detailState.billResponse == null,
      onPopInvoked: (didPop) {
        if (didPop) return;
        controller.clearBill();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(140),
          child: MyAppBar(
            title: (isCreditCardFlow && detailState.billResponse != null)
                ? 'Pay Now'
                : 'Fetch Your Provider',
            showHelp: true,
            onBack: () {
              if (detailState.billResponse != null) {
                controller.clearBill();
              } else {
                controller.reset();
                context.pop();
              }
            },
            onHelp: () {},
          ),
        ),
        body: biller == null
            ? const Center(child: Text('No provider selected'))
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SimpleQuickActionCard(
                            title: biller.billerName,
                            subtitle: '',
                            leadingImageUrl: biller.iconUrl,
                            actionLabel: 'Change',
                            onAction: () {
                              controller.reset();
                              context.pop();
                            },
                          ),
                          // // Provider card
                          // QuickActionCard(
                          //   title: biller.billerName,
                          //   subtitle: '',
                          //   amount: 'Change',
                          //   buttonLabel: '',
                          //   imageUrl: biller.iconUrl,
                          //   showTail: true,
                          //   showLeadingImage: true,
                          //   onTap: () {
                          //     controller.reset();
                          //     context.pop();
                          //   },
                          // ),
                          const SizedBox(height: 24),

                          // --- Loading detail ---
                          if (detailState.isFetchingDetail)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: SpinKitCircle(
                                  color: AppColors.primary,
                                  size: 48,
                                ),
                              ),
                            )

                          // --- Input form (no bill yet) ---
                          else if (detail != null && bill == null) ...[
                            if (isGasCylinder || isElectricity) ...[
                              BillSampleTermsCard(
                                isExpanded: showBillSample.value,
                                onToggle: () => showBillSample.value =
                                    !showBillSample.value,
                                billImageUrl: detail.billImage,
                                termsText: detail.billTermsCond,
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (isPipedGas &&
                                pipedGasErrorMessage.value != null &&
                                pipedGasErrorMessage.value!.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: ServiceErrorBanner(
                                  message: pipedGasErrorMessage.value!,
                                ),
                              ),
                            if (isSubscription) ...[
                              const _InfoNoteCard(
                                text:
                                    'Subscription starts immediately upon payment. Please check the phone number before proceeding.',
                                showLogo: false,
                              ),
                              const SizedBox(height: 16),
                            ],
                            ...detail.customerParams
                                .where((p) => p.visibility)
                                .map((param) {
                              final tc = inputControllers[param.paramName];
                              final isLastFour =
                                  _isLastFourParam(param.paramName);
                              final isMobile = _isMobileParam(param.paramName);
                              final isGasLockedMobile =
                                  isGasCylinder && isMobile;
                              final isDate =
                                  DateFormatHelper.isDateParam(param.paramName);
                              final isAlphaNumeric =
                                  param.dataType.toUpperCase() ==
                                      'ALPHANUMERIC';
                              final dateFormat = isDate
                                  ? DateFormatHelper.extractFormat(
                                      param.paramName)
                                  : null;
                              final errorText =
                                  fieldErrors.value[param.paramName];
                              final label = isGasLockedMobile
                                  ? 'Registered Mobile Number'
                                  : param.paramName;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            label,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                        if (param.optional)
                                          Text(
                                            ' (Optional)',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: AppColors.textPrimary
                                                      .withOpacity(0.5),
                                                ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (isDate)
                                      DatePickerField(
                                        controller: tc!,
                                        dateFormat: dateFormat!,
                                        errorText: errorText,
                                        onDatePicked: () {
                                          if (fieldErrors.value
                                              .containsKey(param.paramName)) {
                                            fieldErrors.value =
                                                Map.from(fieldErrors.value)
                                                  ..remove(param.paramName);
                                          }
                                          if (gasPolicyMessage.value != null) {
                                            gasPolicyMessage.value = null;
                                          }
                                        },
                                      )
                                    else if (param.hasDropdown)
                                      ParamDropdownField(
                                        controller: tc!,
                                        items: param.values,
                                        hintText: 'Select ${param.paramName}',
                                        errorText: errorText,
                                        onChanged: (_) {
                                          if (fieldErrors.value
                                              .containsKey(param.paramName)) {
                                            fieldErrors.value =
                                                Map.from(fieldErrors.value)
                                                  ..remove(param.paramName);
                                          }
                                          if (gasPolicyMessage.value != null) {
                                            gasPolicyMessage.value = null;
                                          }
                                        },
                                      )
                                    else
                                      TextField(
                                        controller: tc,
                                        readOnly: isGasLockedMobile,
                                        enableInteractiveSelection:
                                            !isGasLockedMobile,
                                        showCursor:
                                            isGasLockedMobile ? false : null,
                                        onTap: isGasLockedMobile
                                            ? () =>
                                                FocusScope.of(context).unfocus()
                                            : null,
                                        keyboardType:
                                            param.dataType == 'NUMERIC'
                                                ? TextInputType.number
                                                : TextInputType.text,
                                        inputFormatters: isAlphaNumeric
                                            ? const [_UpperCaseTextFormatter()]
                                            : null,
                                        maxLength:
                                            isLastFour ? 4 : param.maxLength,
                                        onChanged: (_) {
                                          if (fieldErrors.value
                                              .containsKey(param.paramName)) {
                                            fieldErrors.value =
                                                Map.from(fieldErrors.value)
                                                  ..remove(param.paramName);
                                          }
                                          if (gasPolicyMessage.value != null) {
                                            gasPolicyMessage.value = null;
                                          }
                                        },
                                        decoration: InputDecoration(
                                          hintText: _buildParamHint(param),
                                          errorText: errorText,
                                          counterText: '',
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                          prefixIcon: isLastFour
                                              ? _MaskedPrefix()
                                              : null,
                                          suffixIcon: (isMobile &&
                                                  !isGasLockedMobile)
                                              ? IconButton(
                                                  icon: const Icon(
                                                    Icons.contact_phone,
                                                    color: AppColors.primary,
                                                  ),
                                                  onPressed: () async {
                                                    final picked =
                                                        await _pickContactNumber(
                                                      context,
                                                      permissionService,
                                                      contactsController:
                                                          contactsController,
                                                    );
                                                    if (picked != null &&
                                                        picked.isNotEmpty) {
                                                      tc?.text = picked;
                                                    }
                                                    if (gasPolicyMessage
                                                            .value !=
                                                        null) {
                                                      gasPolicyMessage.value =
                                                          null;
                                                    }
                                                  },
                                                )
                                              : null,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                                color: AppColors.lightBorder),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                                color: AppColors.lightBorder),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                                color: AppColors.primary),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                                color: Colors.red),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                                color: Colors.red),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 16),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                            if (isCreditCardFlow &&
                                creditCardErrorMessage.value != null &&
                                creditCardErrorMessage.value!
                                    .trim()
                                    .isNotEmpty) ...[
                              ServiceErrorBanner(
                                message: creditCardErrorMessage.value!,
                                onClose: () =>
                                    creditCardErrorMessage.value = null,
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (gasPolicyMessage.value != null) ...[
                              _GasPolicyBanner(
                                message: gasPolicyMessage.value!,
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (isGasCylinder &&
                                (detailState.errorMessage ?? '')
                                    .trim()
                                    .isNotEmpty) ...[
                              _GasErrorBanner(
                                message: detailState.errorMessage!.trim(),
                              ),
                              const SizedBox(height: 12),
                              if ((detailState.billFetchNote ?? '')
                                  .trim()
                                  .isNotEmpty) ...[
                                _GasErrorBanner(
                                  message: detailState.billFetchNote!.trim(),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ],
                          ]

                          // --- Subscription summary ---
                          else if (detail != null &&
                              showSubscriptionSummary) ...[
                            _SubscriptionSummaryCard(
                              mobileNumber: _resolveSubscriptionMobile(
                                  customerParamsInput),
                              plan:
                                  _resolveSubscriptionPlan(customerParamsInput),
                              amount: _resolveSubscriptionAmount(
                                customerParamsInput,
                                billAmountController.text,
                                bill,
                              ),
                              onChange: () {
                                controller.clearBill();
                              },
                            ),
                            const SizedBox(height: 12),
                          ]

                          // --- Compact bill view ---
                          else if (bill != null &&
                              !detailState.showFullDetails) ...[
                            _CompactBillSection(
                              bill: bill,
                              customerParams: customerParamsInput,
                              billAmountController: billAmountController,
                              onToggle: controller.toggleFullDetails,
                              selectedAmountType: selectedAmountType.value,
                              onAmountTypeChanged: (next) {
                                selectedAmountType.value = next;
                                if (next ==
                                    _PaymentAmountType.totalOutstanding) {
                                  final amount = _resolveDateBasedAmount(bill);
                                  billAmountController.text = isFastTag
                                      ? _formatAmountForInput(amount)
                                      : amount.toStringAsFixed(2);
                                } else if (next ==
                                    _PaymentAmountType.minimumDue) {
                                  final amount = minimumDue ??
                                      totalOutstanding ??
                                      bill.amountInRupees;
                                  billAmountController.text = isFastTag
                                      ? _formatAmountForInput(amount)
                                      : amount.toStringAsFixed(2);
                                }
                              },
                              totalOutstanding: totalOutstanding,
                              minimumDue: minimumDue,
                              isCreditCardFlow: isCreditCardFlow,
                              isPipedGas: isPipedGas,
                              allowCustomAmount: isFastTag,
                              minimumCustomAmount: fastTagMinAmount,
                              maximumCustomAmount: fastTagMaxAmount,
                              isElectricity: isElectricity,
                              showFullDetailsInline: isFastTag,
                              hideAmountDisplayCard: isFastTag,
                            ),
                          ]

                          // --- Full details view ---
                          else if (bill != null &&
                              detailState.showFullDetails) ...[
                            _FullDetailsSection(
                              bill: bill,
                              customerParams: customerParamsInput,
                              onToggle: controller.toggleFullDetails,
                            ),
                          ],

                          if (detail != null &&
                              (bill == null || showSubscriptionSummary)) ...[
                            const SizedBox(height: 12),
                            const _InfoNoteCard(
                              text:
                                  'By proceeding further, you allow E-Rupaiya to store your bill details, fetch current and future bills, and send you reminders.',
                            ),
                            const SizedBox(height: 8),
                          ],

                          // Loading bill spinner
                          if (detailState.isFetchingBill)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: SpinKitCircle(
                                  color: AppColors.primary,
                                  size: 48,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom button
                  if (detail != null &&
                      !detailState.isFetchingDetail &&
                      !detailState.isFetchingBill)
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: billAmountController,
                            builder: (context, value, _) {
                              final payLabel = showSubscriptionSummary
                                  ? 'Pay Now'
                                  : (bill != null
                                      ? (isCreditCardFlow
                                          ? 'Proceed'
                                          : 'Proceed to Pay')
                                      : 'CONFIRM');
                              final enteredAmount =
                                  _parseEnteredAmount(value.text);
                              final subscriptionAmount = showSubscriptionSummary
                                  ? _resolveSubscriptionAmount(
                                      customerParamsInput,
                                      value.text,
                                      bill,
                                    )
                                  : null;
                              final shouldDisablePay = showSubscriptionSummary
                                  ? (subscriptionAmount ?? 0) <= 0
                                  : (bill != null &&
                                      ((enteredAmount ?? 0) <= 0 ||
                                          (isFastTag &&
                                              ((fastTagMinAmount != null &&
                                                      (enteredAmount ?? 0) <
                                                          fastTagMinAmount) ||
                                                  (fastTagMaxAmount != null &&
                                                      (enteredAmount ?? 0) >
                                                          fastTagMaxAmount))) ||
                                          (isPipedGas &&
                                              ((enteredAmount ?? 0) <
                                                      PipedGasBillSection
                                                          .minAmount ||
                                                  (enteredAmount ?? 0) >
                                                      PipedGasBillSection
                                                          .maxAmount))));
                              return CustomElevatedButton(
                                onPressed: shouldDisablePay ||
                                        detailState.isPayingBill ||
                                        isHandlingPayAction.value
                                    ? null
                                    : () async {
                                        if (isHandlingPayAction.value ||
                                            detailState.isPayingBill) {
                                          return;
                                        }
                                        isHandlingPayAction.value = true;
                                        try {
                                          if (showSubscriptionSummary) {
                                            final amountToPay =
                                                subscriptionAmount ?? 0;
                                            final mobile =
                                                _resolveSubscriptionMobile(
                                              customerParamsInput,
                                            );
                                            final name = biller.billerName
                                                    .trim()
                                                    .isNotEmpty
                                                ? biller.billerName.trim()
                                                : 'Subscription';
                                            if (!await RazorpayGuard
                                                .ensureProfileReadyAndNotPaused(
                                              ref,
                                            )) {
                                              return;
                                            }
                                            final paymentType =
                                                (args?.paymentType ?? '')
                                                        .trim()
                                                        .isNotEmpty
                                                    ? args!.paymentType!.trim()
                                                    : 'Subscription';
                                            final order = await controller
                                                .createPayAllServicesOrder(
                                              amount: amountToPay,
                                              paymentType: paymentType,
                                              useWallet: false,
                                              isCreditCardFlow:
                                                  isCreditCardFlow,
                                            );
                                            if (!context.mounted) return;
                                            if (order == null ||
                                                order.orderId.isEmpty ||
                                                order.key.isEmpty ||
                                                order.transactionRef.isEmpty) {
                                              AppSnackbar.show(
                                                ref
                                                        .read(
                                                          billerDetailControllerProvider,
                                                        )
                                                        .payErrorMessage ??
                                                    'Unable to start payment. Please try again.',
                                                type: AppSnackbarType.error,
                                              );
                                              return;
                                            }

                                            Future<void> verifyAndShowResult({
                                              required String fallbackMessage,
                                            }) async {
                                              if (!context.mounted) return;
                                              final wait =
                                                  await showPaymentProcessingWhile(
                                                work: controller
                                                    .verifyPayAllServicesStatus(
                                                  transactionRef:
                                                      order.transactionRef,
                                                ),
                                              );
                                              if (!context.mounted) return;
                                              final status = wait.value;
                                              final normalized = (status?.status
                                                      .trim()
                                                      .toUpperCase() ??
                                                  '');
                                              final fallbackStatus =
                                                  wait.timedOut
                                                      ? 'PENDING'
                                                      : (normalized.isNotEmpty
                                                          ? normalized
                                                          : 'FAILED');
                                              final entry =
                                                  buildPaymentFlowTransactionEntryFromRechargeStatus(
                                                status: status,
                                                fallbackStatus: fallbackStatus,
                                                fallbackPaymentType: args
                                                        ?.paymentType ??
                                                    detail.billerCategoryName,
                                                fallbackBillerName: name,
                                                fallbackAmount: amountToPay,
                                                fallbackTransactionId:
                                                    order.transactionRef,
                                              );

                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      TransactionDetailScreen(
                                                    entry: entry,
                                                    doneLabel: 'Continue',
                                                    navigateHomeOnExit: true,
                                                  ),
                                                ),
                                              );
                                            }

                                            await RazorpayService.instance
                                                .openCheckout(
                                              amount: amountToPay,
                                              name: name,
                                              description:
                                                  'Subscription bill payment',
                                              orderId: order.orderId,
                                              keyOverride: order.key,
                                              prefill: {
                                                if (mobile.isNotEmpty)
                                                  'contact': mobile,
                                              },
                                              onSuccess: (_) async {
                                                await verifyAndShowResult(
                                                  fallbackMessage:
                                                      'Your payment was completed successfully.',
                                                );
                                              },
                                              onFailure: (message) async {
                                                await verifyAndShowResult(
                                                  fallbackMessage: message
                                                          .isEmpty
                                                      ? 'Payment failed. Please try again.'
                                                      : message,
                                                );
                                              },
                                              onExternalWallet: (_) async {
                                                await verifyAndShowResult(
                                                  fallbackMessage:
                                                      'We are verifying your payment. Please wait a moment.',
                                                );
                                              },
                                            );
                                            return;
                                          }
                                          if (bill == null) {
                                            // Validate all visible params
                                            final visibleParams = detail
                                                .customerParams
                                                .where((p) => p.visibility)
                                                .toList();
                                            if (visibleParams.isEmpty) return;

                                            final errors = <String, String?>{};
                                            final values = <String, String>{};
                                            for (final param in visibleParams) {
                                              final value = inputControllers[
                                                          param.paramName]
                                                      ?.text
                                                      .trim() ??
                                                  '';
                                              final error =
                                                  _validateParam(param, value);
                                              if (error != null) {
                                                errors[param.paramName] = error;
                                              } else if (value.isNotEmpty) {
                                                values[param.paramName] = value;
                                              }
                                            }

                                            if (errors.isNotEmpty) {
                                              fieldErrors.value = errors;
                                              return;
                                            }
                                            fieldErrors.value = {};

                                            if (isGasCylinder &&
                                                visibleParams.isNotEmpty &&
                                                values.isEmpty) {
                                              fieldErrors.value =
                                                  gasCylinderInlineErrors(
                                                      detail);
                                              return;
                                            }

                                            if (values.isNotEmpty) {
                                              if (gasPolicyMessage.value !=
                                                  null) {
                                                gasPolicyMessage.value = null;
                                              }
                                              controller.fetchBill(
                                                customerParams: values,
                                              );
                                            }
                                          } else if (!detailState
                                              .showFullDetails) {
                                            // Open payment bottom sheet (details expansion is via the
                                            // down-arrow in the bill card, not the pay CTA).
                                            final amountToPay = enteredAmount ??
                                                bill.amountInRupees;
                                            _showPaymentSheet(
                                              context,
                                              amountToPay,
                                              isCreditCardFlow:
                                                  isCreditCardFlow,
                                              paymentTypeOverride:
                                                  args?.paymentType,
                                              ecoinsRestrictionsPercent: bill
                                                  .ecoinsRestrictionsPercent,
                                            );
                                          } else {
                                            // Open payment bottom sheet
                                            final amountToPay = enteredAmount ??
                                                bill.amountInRupees;
                                            _showPaymentSheet(
                                              context,
                                              amountToPay,
                                              isCreditCardFlow:
                                                  isCreditCardFlow,
                                              paymentTypeOverride:
                                                  args?.paymentType,
                                              ecoinsRestrictionsPercent: bill
                                                  .ecoinsRestrictionsPercent,
                                            );
                                          }
                                        } finally {
                                          isHandlingPayAction.value = false;
                                        }
                                      },
                                label: detailState.isPayingBill ||
                                        isHandlingPayAction.value
                                    ? 'Processing...'
                                    : payLabel,
                                showArrow: false,
                                uppercaseLabel: false,
                                height: 38.h,
                              );
                            },
                          ),
                          // if (bill == null) ...[
                          //   const SizedBox(height: 10),
                          //   Row(
                          //     mainAxisAlignment: MainAxisAlignment.center,
                          //     children: [
                          //       Text(
                          //         'Powered by',
                          //         style: Theme.of(context)
                          //             .textTheme
                          //             .bodySmall
                          //             ?.copyWith(
                          //               color: AppColors.textPrimary
                          //                   .withOpacity(0.6),
                          //               fontWeight: FontWeight.w600,
                          //             ),
                          //       ),
                          //       const SizedBox(width: 8),
                          //       Image.asset(
                          //         FileConstants.bharatConnectColor,
                          //         height: 20,
                          //         fit: BoxFit.contain,
                          //       ),
                          //     ],
                          //   ),
                          // ],
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  void _showPaymentSheet(
    BuildContext context,
    double amount, {
    required bool isCreditCardFlow,
    String? paymentTypeOverride,
    double? ecoinsRestrictionsPercent,
  }) {
    KDialog.instance.openSheet(
      dialog: PaymentBottomSheet(
        amount: amount,
        isCreditCardFlow: isCreditCardFlow,
        paymentTypeOverride: paymentTypeOverride,
        ecoinsRestrictionsPercent: ecoinsRestrictionsPercent,
      ),
    );
  }

  String _buildParamHint(BillerCustomerParam param) {
    return '';
  }

  String? _validateParam(BillerCustomerParam param, String value) {
    if (value.isEmpty) {
      return param.optional ? null : 'Please enter ${param.paramName}';
    }
    final min = param.minLength;
    final max = param.maxLength;
    if (min != null && value.length < min) {
      return max != null && min == max
          ? '${param.paramName} must be $min characters'
          : '${param.paramName} must be at least $min characters';
    }
    final regexStr = param.regex?.trim();
    if (regexStr != null && regexStr.isNotEmpty) {
      try {
        if (!RegExp(regexStr).hasMatch(value)) {
          if (min != null && max != null) {
            return 'Enter a valid ${param.paramName.toLowerCase()} ($min–$max characters)';
          }
          return 'Invalid ${param.paramName.toLowerCase()}';
        }
      } catch (_) {
        // Skip malformed regex
      }
    }
    return null;
  }
}
