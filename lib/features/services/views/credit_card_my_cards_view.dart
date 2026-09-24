// ignore_for_file: deprecated_member_use

import 'package:e_rupaiya/constants/file_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/routes_constant.dart';
import '../../../utils/date_format_helper.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/k_dialog.dart';
import '../../../widgets/my_app_bar.dart';
import '../../home/controllers/home_controller.dart';
import '../../home/models/credit_card_item.dart';
import '../components/credit_card_my_cards_banner.dart';
import '../components/credit_card_my_cards_shimmer.dart';
import '../controllers/biller_detail_controller.dart';
import '../controllers/service_extras_controller.dart';
import '../models/biller_detail_args.dart';
import '../models/biller_model.dart';

class CreditCardMyCardsView extends HookConsumerWidget {
  const CreditCardMyCardsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeControllerProvider);
    final isFetching = homeState.isFetchingCreditCards;
    final cards = homeState.creditCardActions;
    final banners = ref.watch(servicePageBannersProvider('credit-card'));

    useEffect(() {
      Future.microtask(() {
        ref.read(homeControllerProvider.notifier).fetchCreditCardActions();
      });
      return null;
    }, const []);

    // Once data is loaded and empty, replace this screen with biller listing
    final isLoaded = !isFetching && cards != null;
    useEffect(() {
      if (isLoaded && cards.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.pushReplacement(RouteConstants.creditCardListing);
          }
        });
      }
      return null;
    }, [isLoaded]);

    void handleBack() {
      if (context.canPop()) {
        context.pop();
        return;
      }
      if (context.mounted) {
        context.go(RouteConstants.home);
      }
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: MyAppBar(
          title: 'Credit Card Payment',
          showHelp: true,
          onBack: handleBack,
        ),
        body: Column(
          children: [
            Expanded(
              child: isFetching || cards == null || cards.isEmpty
                  ? (isFetching || cards == null
                      ? const CreditCardMyCardsShimmer()
                      : const SizedBox.shrink())
                  : SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CreditCardMyCardsBanner(banners: banners),
                          SizedBox(height: 14.h),
                          ...cards.asMap().entries.map(
                                (entry) => Padding(
                                  padding: EdgeInsets.only(bottom: 14.h),
                                  child: CreditCardMyCardTile(
                                    item: entry.value,
                                    isHighlighted: entry.key == 0,
                                    onOpen: () async {
                                      final item = entry.value;
                                      final billerName =
                                          item.billerName?.trim().isNotEmpty ==
                                                  true
                                              ? item.billerName!.trim()
                                              : 'Card';
                                      final biller = Biller(
                                        billerId: item.billerId ?? '',
                                        billerName: billerName,
                                        icon: item.icon,
                                      );
                                      ref
                                          .read(billerDetailControllerProvider
                                              .notifier)
                                          .selectBiller(
                                            biller,
                                            categoryName: 'Credit card',
                                          );
                                      await context.push(
                                        RouteConstants.billerDetail,
                                        extra: BillerDetailArgs(
                                          biller: biller,
                                          isCreditCard: true,
                                          paymentType: 'Credit card',
                                          mobileNumber: item.registerMobNo,
                                          cardLast4: item.last4Digit,
                                        ),
                                      );
                                    },
                                    onPayNow: () async {
                                      final item = entry.value;
                                      final billerName =
                                          item.billerName?.trim().isNotEmpty ==
                                                  true
                                              ? item.billerName!.trim()
                                              : 'Card';
                                      final biller = Biller(
                                        billerId: item.billerId ?? '',
                                        billerName: billerName,
                                        icon: item.icon,
                                      );
                                      ref
                                          .read(billerDetailControllerProvider
                                              .notifier)
                                          .selectBiller(
                                            biller,
                                            categoryName: 'Credit card',
                                          );
                                      await context.push(
                                        RouteConstants.billerDetail,
                                        extra: BillerDetailArgs(
                                          biller: biller,
                                          isCreditCard: true,
                                          paymentType: 'Credit card',
                                          mobileNumber: item.registerMobNo,
                                          cardLast4: item.last4Digit,
                                        ),
                                      );
                                    },
                                    onMenuTap: () =>
                                        _openCardActions(entry.value),
                                  ),
                                ),
                              ),
                          SizedBox(height: 8.h),
                        ],
                      ),
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                child: CustomElevatedButton(
                  onPressed: () =>
                      context.push(RouteConstants.creditCardListing),
                  label: 'Add New Card',
                  uppercaseLabel: false,
                  height: 42.h,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCardActions(CreditCardItem item) {
    KDialog.instance.openSheet(
      dialog: _CardActionSheet(item: item),
    );
  }
}

class CreditCardMyCardTile extends HookWidget {
  const CreditCardMyCardTile({
    super.key,
    required this.item,
    required this.onOpen,
    required this.onPayNow,
    required this.onMenuTap,
    this.isHighlighted = false,
  });

  final CreditCardItem item;
  final Future<void> Function() onOpen;
  final Future<void> Function() onPayNow;
  final VoidCallback onMenuTap;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final isPayNowLoading = useState(false);
    final bankName = item.billerName?.trim().isNotEmpty == true
        ? item.billerName!.trim()
        : 'Card';
    final masked = _maskedId(
      item.maskedIdentifier,
      item.last4Digit,
      item.billerId,
    );
    final amount = item.lastAmount ?? 0.0;
    final isDue = item.isDue == true;
    final dueText = isDue
        ? ((item.dueDate ?? '').trim().isNotEmpty
            ? 'Bill Due ${DateFormatHelper.formatDisplayDateWithYear(item.dueDate!)}'
            : 'Bill Due Soon')
        : ((item.lastPaidDate ?? '').trim().isNotEmpty
            ? 'Last Paid on ${DateFormatHelper.formatDisplayDateWithYear(item.lastPaidDate!)}'
            : 'Last Paid');

    return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async => onOpen(),
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isHighlighted
                    ? AppColors.primary.withOpacity(0.45)
                    : AppColors.lightBorder,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 10.r,
                  offset: Offset(0.w, 6.h),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 12.h, 8.w, 10.h),
                  child: Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.lightBorder),
                        ),
                        child: Center(
                          child: item.icon?.trim().isNotEmpty == true
                              ? AppNetworkImage(
                                  url: item.icon,
                                  width: 20.w,
                                  height: 20.w,
                                  fit: BoxFit.contain,
                                  borderRadius: BorderRadius.circular(10.r),
                                  errorWidget: Image.asset(
                                    FileConstants.credit,
                                    width: 20.w,
                                    height: 20.w,
                                    fit: BoxFit.contain,
                                  ),
                                  placeholder: Image.asset(
                                    FileConstants.credit,
                                    width: 20.w,
                                    height: 20.w,
                                    fit: BoxFit.contain,
                                  ),
                                )
                              : Image.asset(
                                  FileConstants.credit,
                                  width: 20.w,
                                  height: 20.w,
                                  fit: BoxFit.contain,
                                ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bankName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              masked,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color:
                                        AppColors.textPrimary.withOpacity(0.6),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: onMenuTap,
                        borderRadius: BorderRadius.circular(16.r),
                        child: Padding(
                          padding: EdgeInsets.all(6.w),
                          child: Icon(
                            Icons.more_vert,
                            size: 20.sp,
                            color: AppColors.textPrimary.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                    height: 1, color: AppColors.lightBorder.withOpacity(0.8)),
                Padding(
                  padding: EdgeInsets.fromLTRB(14.w, 10.h, 12.w, 12.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatAmount(amount),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              dueText,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (isDue)
                        InkWell(
                          onTap: isPayNowLoading.value
                              ? null
                              : () async {
                                  isPayNowLoading.value = true;
                                  try {
                                    await onPayNow();
                                  } finally {
                                    if (context.mounted) {
                                      isPayNowLoading.value = false;
                                    }
                                  }
                                },
                          borderRadius: BorderRadius.circular(22.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 18.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(22.r),
                            ),
                            child: isPayNowLoading.value
                                ? SizedBox(width: 16.sp,
                                    height: 16.sp,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Pay Now',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  String _maskedId(String? masked, String? last4, String? billerId) {
    final maskedValue = (masked ?? '').trim();
    if (maskedValue.isNotEmpty) return maskedValue;
    final fallback = (last4 ?? '').trim().isNotEmpty ? last4! : billerId ?? '';
    final value = fallback.trim();
    if (value.isEmpty) return 'XXXX1234';
    final suffix =
        value.length >= 4 ? value.substring(value.length - 4) : value;
    return 'XXXX$suffix';
  }

  String _formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }
}

class _CardActionSheet extends ConsumerWidget {
  const _CardActionSheet({required this.item});

  final CreditCardItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bankName = item.billerName?.trim().isNotEmpty == true
        ? item.billerName!.trim()
        : 'Card';
    final masked = _maskedId(
      item.maskedIdentifier,
      item.last4Digit,
      item.billerId,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bankName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      masked,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Divider(color: AppColors.lightBorder),
          _SheetActionRow(
            icon: Icons.history,
            label: 'History',
            onTap: () {
              final maskedId = item.maskedIdentifier?.trim() ?? '';
              Navigator.of(context).pop();
              if (maskedId.isNotEmpty) {
                context.push(
                  RouteConstants.creditCardTransactions,
                  extra: maskedId,
                );
              } else {
                AppSnackbar.show('Masked identifier missing.');
              }
            },
          ),
          const Divider(color: AppColors.lightBorder),
          _SheetActionRow(
            icon: Icons.delete_outline,
            label: 'Remove Card',
            onTap: () async {
              Navigator.of(context).pop();
              final maskedId = item.maskedIdentifier?.trim() ?? '';
              if (maskedId.isEmpty) {
                AppSnackbar.show('Masked identifier missing.');
                return;
              }

              final shouldRemove = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (_) => const _RemoveCardConfirmDialog(),
              );
              if (shouldRemove != true) return;

              final ok = await ref
                  .read(homeControllerProvider.notifier)
                  .removeCreditCard(maskedId);
              if (!context.mounted) return;
              if (ok) {
                AppSnackbar.show('Card removed successfully.');
              } else {
                AppSnackbar.show('Failed to remove card. Please try again.');
              }
            },
          ),
        ],
      ),
    );
  }

  String _maskedId(String? masked, String? last4, String? billerId) {
    final maskedValue = (masked ?? '').trim();
    if (maskedValue.isNotEmpty) return maskedValue;
    final fallback = (last4 ?? '').trim().isNotEmpty ? last4! : billerId ?? '';
    final value = fallback.trim();
    if (value.isEmpty) return 'XXXX1234';
    final suffix =
        value.length >= 4 ? value.substring(value.length - 4) : value;
    return 'XXXX$suffix';
  }
}

class _RemoveCardConfirmDialog extends StatelessWidget {
  const _RemoveCardConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(22.w, 22.h, 22.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64.r,
              height: 64.r,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF2B9A6)),
              ),
              child: Icon(
                Icons.delete_outline,
                color: AppColors.primary,
                size: 34.sp,
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              'Remove Card?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Are you sure you want to remove this card from recent?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.75),
                    height: 1.35,
                  ),
            ),
            SizedBox(height: 18.h),
            Row(
              children: [
                Expanded(
                  child: SizedBox(height: 40.h,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.textPrimary.withOpacity(0.18),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary.withOpacity(0.8),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: SizedBox(height: 40.h,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Remove',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
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

class _SheetActionRow extends StatelessWidget {
  const _SheetActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: AppColors.lightBorder.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.textPrimary, size: 18.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14.sp, color: AppColors.textPrimary.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
