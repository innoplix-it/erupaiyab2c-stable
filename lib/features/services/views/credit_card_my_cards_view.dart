// ignore_for_file: deprecated_member_use

import 'package:e_rupaiya/constants/file_constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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
import '../../profile/controllers/profile_controller.dart';
import '../components/credit_card/credit_card_figma_metrics.dart';
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

    final scrollPad = CreditCardFigmaMetrics.screenPadding(context).copyWith(
      top: CreditCardFigmaMetrics.sy(context, 12),
      bottom: CreditCardFigmaMetrics.sy(context, 12),
    );
    final bottomPad = CreditCardFigmaMetrics.bottomBarPadding(
      context,
      MediaQuery.paddingOf(context).bottom,
    );

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
          title: 'My Cards',
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
                      padding: scrollPad,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CreditCardMyCardsBanner(banners: banners),
                          SizedBox(
                            height: CreditCardFigmaMetrics.myCardAfterBannerGap(
                              context,
                            ),
                          ),
                          ...cards.asMap().entries.map(
                                (entry) => Padding(
                                  padding: EdgeInsets.only(
                                    bottom:
                                        CreditCardFigmaMetrics.myCardListGap(
                                      context,
                                    ),
                                  ),
                                  child: CreditCardMyCardTile(
                                    item: entry.value,
                                    onOpenBills: () => _openCreditCardPayNow(
                                      context,
                                      ref,
                                      entry.value,
                                    ),
                                    onMenuTap: () =>
                                        _openCardActions(entry.value),
                                  ),
                                ),
                              ),
                          SizedBox(
                              height: CreditCardFigmaMetrics.sy(context, 8)),
                        ],
                      ),
                    ),
            ),
            Padding(
              padding: bottomPad.copyWith(
                top: CreditCardFigmaMetrics.sy(context, 12),
              ),
              child: CustomElevatedButton(
                onPressed: () =>
                    context.push(RouteConstants.creditCardListing),
                label: 'Add New Card',
                uppercaseLabel: false,
                height: CreditCardFigmaMetrics.primaryButtonHeight(context),
                labelStyle: CreditCardFigmaMetrics.primaryButtonLabelStyle(
                  context,
                ),
                borderRadius: CreditCardFigmaMetrics.s(context, 28),
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

  /// Card tap and bill row → [RouteConstants.creditCardPayNow]; bill fetch on that screen.
  static Future<void> _openCreditCardPayNow(
    BuildContext context,
    WidgetRef ref,
    CreditCardItem item,
  ) async {
    await ref.read(profileControllerProvider.notifier).fetchProfileIfNeeded();
    await _pushCreditCardBiller(
      context,
      ref,
      item,
      route: RouteConstants.creditCardPayNow,
      autoFetchBill: true,
      creditCardPayNowEntry: true,
    );
  }

  static Future<void> _pushCreditCardBiller(
    BuildContext context,
    WidgetRef ref,
    CreditCardItem item, {
    required String route,
    required bool autoFetchBill,
    bool creditCardPayNowEntry = false,
  }) async {
    final profileMobile =
        ref.read(profileControllerProvider).profile?.mobile.trim() ?? '';
    final mobile = _resolveCreditCardMobile(item, profileMobile);
    final last4 = _resolveCreditCardLast4(item);

    final billerName = item.billerName?.trim().isNotEmpty == true
        ? item.billerName!.trim()
        : 'Card';
    final biller = Biller(
      billerId: item.billerId ?? '',
      billerName: billerName,
      icon: item.icon,
    );
    ref.read(billerDetailControllerProvider.notifier).reset();
    ref.read(billerDetailControllerProvider.notifier).selectBiller(
          biller,
          categoryName: billerName,
        );
    await context.push(
      route,
      extra: BillerDetailArgs(
        biller: biller,
        isCreditCard: true,
        paymentType: billerName,
        mobileNumber: mobile,
        cardLast4: last4,
        autoFetchBill: autoFetchBill,
        autoOpenPaymentSheet: false,
        creditCardPayNowEntry: creditCardPayNowEntry,
      ),
    );
  }

  static String? _resolveCreditCardMobile(
    CreditCardItem item,
    String profileMobile,
  ) {
    final registered = (item.registerMobNo ?? '').replaceAll(RegExp(r'\D'), '');
    if (registered.length >= 10) {
      return registered.substring(registered.length - 10);
    }
    final profileDigits = profileMobile.replaceAll(RegExp(r'\D'), '');
    if (profileDigits.length >= 10) {
      return profileDigits.substring(profileDigits.length - 10);
    }
    return null;
  }

  static String? _resolveCreditCardLast4(CreditCardItem item) {
    final fromField = (item.last4Digit ?? '').replaceAll(RegExp(r'\D'), '');
    if (fromField.length >= 4) {
      return fromField.substring(fromField.length - 4);
    }
    final masked = (item.maskedIdentifier ?? '').replaceAll(RegExp(r'\D'), '');
    if (masked.length >= 4) {
      return masked.substring(masked.length - 4);
    }
    return null;
  }
}

class CreditCardMyCardTile extends HookWidget {
  const CreditCardMyCardTile({
    super.key,
    required this.item,
    required this.onOpenBills,
    required this.onMenuTap,
  });

  final CreditCardItem item;
  final Future<void> Function() onOpenBills;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    final isPayNowLoading = useState(false);
    final bankName = item.billerName?.trim().isNotEmpty == true
        ? item.billerName!.trim()
        : 'Card';
    final logoUrl = Biller(
      billerId: item.billerId ?? '',
      billerName: bankName,
      icon: item.icon,
    ).iconUrl;
    final masked = _maskedId(
      item.maskedIdentifier,
      item.last4Digit,
      item.billerId,
    );
    final amount = item.lastAmount ?? 0.0;
    final isDue = item.isDue == true;
    // Figma: "Due On 6 May 2026" (title case On).
    final dueText = isDue
        ? ((item.dueDate ?? '').trim().isNotEmpty
            ? 'Due On ${DateFormatHelper.formatDisplayDateWithYear(item.dueDate!)}'
            : 'Due Soon')
        : ((item.lastPaidDate ?? '').trim().isNotEmpty
            ? 'Last Paid On ${DateFormatHelper.formatDisplayDateWithYear(item.lastPaidDate!)}'
            : 'Last Paid');

    Future<void> openBillsScreen() async {
      if (isPayNowLoading.value) return;
      isPayNowLoading.value = true;
      try {
        await onOpenBills();
      } finally {
        if (context.mounted) {
          isPayNowLoading.value = false;
        }
      }
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
              CreditCardFigmaMetrics.myCardRadius(context)),
          border: Border.all(color: AppColors.lightBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: CreditCardFigmaMetrics.myCardShadowBlur(context),
              offset: Offset(
                  0, CreditCardFigmaMetrics.myCardShadowOffsetY(context)),
            ),
          ],
        ),
        child: Column(
          children: [
            InkWell(
              onTap: openBillsScreen,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(
                    CreditCardFigmaMetrics.myCardRadius(context)),
              ),
              child: Padding(
                padding: CreditCardFigmaMetrics.myCardHeaderPadding(context),
                child: Row(
                  children: [
                    Container(
                      width: CreditCardFigmaMetrics.myCardLogoSize(context),
                      height: CreditCardFigmaMetrics.myCardLogoSize(context),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          CreditCardFigmaMetrics.myCardLogoRadius(context),
                        ),
                        border: Border.all(
                          color: CreditCardFigmaMetrics.providerLogoBorderColor,
                          width: CreditCardFigmaMetrics.providerLogoBorderWidth(
                              context),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          CreditCardFigmaMetrics.myCardLogoRadius(context),
                        ),
                        child: logoUrl != null
                            ? AppNetworkImage(
                                url: logoUrl,
                                width:
                                    CreditCardFigmaMetrics.myCardLogoIconSize(
                                        context),
                                height:
                                    CreditCardFigmaMetrics.myCardLogoIconSize(
                                        context),
                                fit: BoxFit.contain,
                                showShimmer: false,
                                errorWidget: Image.asset(
                                  FileConstants.credit,
                                  width:
                                      CreditCardFigmaMetrics.myCardLogoIconSize(
                                          context),
                                  height:
                                      CreditCardFigmaMetrics.myCardLogoIconSize(
                                          context),
                                  fit: BoxFit.contain,
                                ),
                                placeholder: Image.asset(
                                  FileConstants.credit,
                                  width:
                                      CreditCardFigmaMetrics.myCardLogoIconSize(
                                          context),
                                  height:
                                      CreditCardFigmaMetrics.myCardLogoIconSize(
                                          context),
                                  fit: BoxFit.contain,
                                ),
                              )
                            : Image.asset(
                                FileConstants.credit,
                                width:
                                    CreditCardFigmaMetrics.myCardLogoIconSize(
                                        context),
                                height:
                                    CreditCardFigmaMetrics.myCardLogoIconSize(
                                        context),
                                fit: BoxFit.contain,
                              ),
                      ),
                    ),
                    SizedBox(width: CreditCardFigmaMetrics.s(context, 12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bankName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CreditCardFigmaMetrics.myCardTitleStyle(
                                context),
                          ),
                          SizedBox(
                              height: CreditCardFigmaMetrics.sy(context, 2)),
                          Text(
                            masked,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CreditCardFigmaMetrics.myCardMaskedStyle(
                                context),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onMenuTap,
                      padding:
                          EdgeInsets.all(CreditCardFigmaMetrics.s(context, 6)),
                      constraints: BoxConstraints(
                        minWidth:
                            CreditCardFigmaMetrics.myCardMenuTapTarget(context),
                        minHeight:
                            CreditCardFigmaMetrics.myCardMenuTapTarget(context),
                      ),
                      icon: Icon(
                        Icons.more_vert,
                        size:
                            CreditCardFigmaMetrics.myCardMenuIconSize(context),
                        color: AppColors.textPrimary.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, thickness: 1, color: AppColors.lightBorder),
            InkWell(
              onTap: openBillsScreen,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(
                    CreditCardFigmaMetrics.myCardRadius(context)),
              ),
              child: Padding(
                padding: CreditCardFigmaMetrics.myCardBillPadding(context),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatAmount(amount),
                            style: CreditCardFigmaMetrics.myCardAmountStyle(
                                context),
                          ),
                          SizedBox(
                              height: CreditCardFigmaMetrics.sy(context, 2)),
                          Text(
                            dueText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CreditCardFigmaMetrics.myCardDueStyle(
                                context,
                                isDue: isDue),
                          ),
                        ],
                      ),
                    ),
                    if (isDue)
                      SizedBox(
                        width:
                            CreditCardFigmaMetrics.payNowButtonWidth(context),
                        height:
                            CreditCardFigmaMetrics.payNowButtonHeight(context),
                        child: ElevatedButton(
                          onPressed:
                              isPayNowLoading.value ? null : openBillsScreen,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            minimumSize: Size.zero,
                            fixedSize: CreditCardFigmaMetrics.payNowButtonSize(
                              context,
                            ),
                            padding: EdgeInsets.zero,
                            backgroundColor:
                                CreditCardFigmaMetrics.payNowButtonColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: CreditCardFigmaMetrics
                                .payNowButtonColor
                                .withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                CreditCardFigmaMetrics.payNowButtonRadius(
                                  context,
                                ),
                              ),
                            ),
                          ),
                          child: isPayNowLoading.value
                              ? SizedBox(
                                  width: CreditCardFigmaMetrics.s(context, 14),
                                  height: CreditCardFigmaMetrics.s(context, 14),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Pay Now',
                                  style: CreditCardFigmaMetrics
                                      .payNowButtonLabelStyle(context),
                                ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
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

  String _formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }
}

class _CardActionSheet extends ConsumerWidget {
  const _CardActionSheet({required this.item});

  final CreditCardItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double sx(double v) => CreditCardFigmaMetrics.s(context, v);
    final bankName = item.billerName?.trim().isNotEmpty == true
        ? item.billerName!.trim()
        : 'Card';
    final masked = _maskedId(
      item.maskedIdentifier,
      item.last4Digit,
      item.billerId,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(sx(16), sx(18), sx(16), sx(24)),
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
                            fontSize: sx(16),
                          ),
                    ),
                    SizedBox(height: sx(2)),
                    Text(
                      masked,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary.withOpacity(0.6),
                            fontSize: sx(12),
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
    double sx(double v) => CreditCardFigmaMetrics.s(context, v);
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(sx(16)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(sx(22), sx(22), sx(22), sx(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: sx(64),
              height: sx(64),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF2B9A6)),
              ),
              child: Icon(
                Icons.delete_outline,
                color: AppColors.primary,
                size: sx(34),
              ),
            ),
            SizedBox(height: sx(14)),
            Text(
              'Remove Card?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontSize: sx(18),
                  ),
            ),
            SizedBox(height: sx(8)),
            Text(
              'Are you sure you want to remove this card from recent?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.75),
                    height: 1.35,
                    fontSize: sx(14),
                  ),
            ),
            SizedBox(height: sx(18)),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: sx(40),
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.textPrimary.withOpacity(0.18),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(sx(12)),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textPrimary.withOpacity(0.8),
                          fontWeight: FontWeight.w700,
                          fontSize: sx(14),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: sx(10)),
                Expanded(
                  child: SizedBox(
                    height: sx(40),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(sx(12)),
                        ),
                      ),
                      child: Text(
                        'Remove',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: sx(14),
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
    double sx(double v) => CreditCardFigmaMetrics.s(context, v);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: sx(12)),
        child: Row(
          children: [
            Container(
              width: sx(36),
              height: sx(36),
              decoration: BoxDecoration(
                color: AppColors.lightBorder.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.textPrimary, size: sx(18)),
            ),
            SizedBox(width: sx(12)),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: sx(14),
                    ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: sx(14),
              color: AppColors.textPrimary.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}
