import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/my_app_bar.dart';
import '../components/gold_buy_card.dart';
import '../components/gold_provider_section.dart';
import '../controllers/digital_gold_trade_controller.dart';
import '../models/digital_metal.dart';
import '../models/quick_amount_option.dart';

class DigitalGoldTradeView extends HookConsumerWidget {
  const DigitalGoldTradeView({
    super.key,
    required this.mode,
    required this.metal,
    required this.validateRegistration,
  });

  final GoldTradeMode mode;
  final DigitalMetal metal;
  final bool validateRegistration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSell = mode == GoldTradeMode.sell;
    final theme = DigitalMetalTheme.of(metal);
    final args = DigitalGoldTradeArgs(
      mode: mode,
      metal: metal,
      validateRegistration: validateRegistration,
    );

    final state = ref.watch(
      digitalGoldTradeControllerProvider(args),
    );
    final controller = ref.read(
      digitalGoldTradeControllerProvider(args).notifier,
    );

    final amountController = useTextEditingController(text: state.amountText);
    useEffect(() {
      if (amountController.text != state.amountText) {
        amountController.text = state.amountText;
      }
      return null;
    }, [state.amountText]);

    useEffect(() {
      if (!state.shouldRedirectToDetails) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.markRedirectHandled();
        context.push(
          '${RouteConstants.digitalGoldDetails}?metal=${theme.queryValue}&postRegToGold=1',
        );
      });
      return null;
    }, [state.shouldRedirectToDetails]);

    final quickAmounts = isSell
        ? const [
            QuickAmountOption(label: '10%', value: 10),
            QuickAmountOption(label: '25%', value: 25),
            QuickAmountOption(label: '50%', value: 50),
            QuickAmountOption(label: '100%', value: 100),
          ]
        : state.isBuyingInRupees
            ? const [
                QuickAmountOption(label: '₹500', value: 500),
                QuickAmountOption(label: '₹1000', value: 1000),
                QuickAmountOption(label: '₹5000', value: 5000),
                QuickAmountOption(label: '₹10000', value: 10000),
              ]
            : const [
                QuickAmountOption(label: '0.5g', value: 1),
                QuickAmountOption(label: '1.0g', value: 2),
                QuickAmountOption(label: '1.5g', value: 3),
                QuickAmountOption(label: '2.0g', value: 4),
              ];

    final priceValue = state.preview?.totalAmount ?? 0.0;
    final trailingText = state.isBuyingInRupees
        ? '=${(state.preview?.myGoldBalance ?? 0).toStringAsFixed(4)}g'
        : '=₹${priceValue.toStringAsFixed(2)}';

    final prefixText = state.isBuyingInRupees ? '₹' : '';

    Future<void> proceed() async {
      final preview = state.preview;
      if (preview == null) return;
      final amount = double.tryParse(state.amountText.trim()) ?? 0;
      if (isSell) {
        context.push(
          '${RouteConstants.digitalGoldSellConfirm}?metal=${theme.queryValue}',
          extra: <String, dynamic>{
            'amount': amount,
            'preview': preview,
            'isBuyingInRupees': state.isBuyingInRupees,
          },
        );
        return;
      }
      context.push(
        '${RouteConstants.digitalGoldSummary}?metal=${theme.queryValue}',
        extra: <String, dynamic>{
          'amount': amount,
          'preview': preview,
          'isBuyingInRupees': state.isBuyingInRupees,
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          MyAppBar(
            title: isSell ? 'Sell ${theme.label}' : 'Buy ${theme.label}',
            onBack: () => context.pop(),
            showHelp: true,
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: controller.refresh,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 110.h),
                children: [
                  GoldProviderSection(
                    title: isSell
                        ? 'Selling To MMTC-PAMP'
                        : 'Buying From MMTC-PAMP',
                    subtitle: theme.providerSubtitle,
                    showChevron: false,
                  ),
                  SizedBox(height: 12.h),
                  GoldBuyCard(
                    isBuyingInRupees: state.isBuyingInRupees,
                    onUnitChanged: (value) =>
                        controller.setUnit(buyInRupees: value),
                    amountController: amountController,
                    quickAmounts: quickAmounts,
                    onAmountSelected: (value) {
                      if (isSell) {
                        controller.setAmountText(value.toString());
                        return;
                      }
                      if (state.isBuyingInRupees) {
                        controller.setAmountText(value.toString());
                      } else {
                        final grams = value * 0.5;
                        controller.setAmountText(grams.toStringAsFixed(1));
                      }
                    },
                    leftToggleLabel:
                        isSell ? 'Sell In Rupees' : 'Buy In Rupees',
                    rightToggleLabel: isSell ? 'Sell In Grams' : 'Buy In Grams',
                    priceText: isSell
                        ? 'Selling Price: ₹${priceValue.toStringAsFixed(2)}/G + 3% GST'
                        : 'Buy Price: ₹${priceValue.toStringAsFixed(2)}/G + 3% GST',
                    trailingText: trailingText,
                    prefixText: prefixText,
                    cardColor: Colors.white,
                    chipGradient: null,
                    toggleActiveColor: const Color(0xFFE85A2C),
                  ),
                  if ((state.errorMessage ?? '').trim().isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Text(
                      state.errorMessage!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                  if (!isSell) ...[
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You Will Receive',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textPrimary
                                          .withOpacity(0.55),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                state.preview == null
                                    ? '--'
                                    : (state.preview!.preTaxAmount / 1000)
                                        .toStringAsFixed(4),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Of ${theme.providerSubtitle}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: const Color(0xFF0B8A3B),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Image.asset(
                          FileConstants.coinsDeck,
                          width: 90.w,
                          height: 70.h,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1FBF3),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: const Color(0xFFBEEFC6)),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            FileConstants.resetPinIcon,
                            height: 32.r,
                            width: 32.r,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${theme.label} (99.9%) Pure Gold',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF0B8A3B),
                                      ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'Will be securely stored in your portfolio',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
          child: SizedBox(height: 40.h,
            child: ElevatedButton(
              onPressed: state.isFetching ? null : proceed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE85A2C),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26.r),
                ),
              ),
              child: Text(
                isSell ? 'Confirm & Withdraw' : 'Proceed',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
