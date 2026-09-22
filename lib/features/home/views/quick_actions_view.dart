// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/my_app_bar.dart';
import '../../mobile_prepaid/models/recharge_quick_action_payload.dart';
import '../../services/controllers/biller_detail_controller.dart';
import '../../services/models/biller_detail_args.dart';
import '../../services/models/biller_model.dart';
import '../components/quick_action_card.dart';
import '../controllers/home_controller.dart';

class QuickActionsView extends HookConsumerWidget {
  const QuickActionsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeControllerProvider);
    final allQuickActions = homeState.allQuickActions ?? [];
    final selectedTab = useState(0);
    final showActionNeededCard = useState(true);

    useEffect(() {
      Future.microtask(() {
        ref.read(homeControllerProvider.notifier).fetchAllQuickActions();
      });
      return null;
    }, const []);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          MyAppBar(
            title: 'Quick Actions',
            onBack: () => context.pop(),
            trailing: IconButton(
              icon:
                  const Icon(Icons.help_outline, color: AppColors.textPrimary),
              onPressed: () {},
            ),
          ),
          // Custom tab bar
          Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => selectedTab.value = 0,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          child: Text(
                            'Quick Actions',
                            style: AppTextStyles.tabLabel(context,
                                isActive: selectedTab.value == 0),
                          ),
                        ),
                        Container(
                          height: 2,
                          color: selectedTab.value == 0
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => selectedTab.value = 1,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          child: Text(
                            'Actions Needed',
                            style: AppTextStyles.tabLabel(context,
                                isActive: selectedTab.value == 1),
                          ),
                        ),
                        Container(
                          height: 2,
                          color: selectedTab.value == 1
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.lightBorder),
          // Tab content
          Expanded(
            child: selectedTab.value == 0
                ? (allQuickActions.isEmpty
                    ? const Center(
                        child: Text('No quick actions available'),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 16.h),
                        itemCount: allQuickActions.length,
                        separatorBuilder: (_, __) => SizedBox(height: 12.h),
                        itemBuilder: (context, index) {
                          final item = allQuickActions[index];
                          final title =
                              item.billerName?.trim().isNotEmpty == true
                                  ? item.billerName!.trim()
                                  : item.paymentType?.trim().isNotEmpty == true
                                      ? item.paymentType!.trim()
                                      : 'Quick Action';
                          final due = (item.nextDue ?? '').trim();
                          final subtitle = due.isEmpty
                              ? (item.paymentType ?? '')
                              : '${item.paymentType ?? ''} Due : $due'.trim();
                          final amount = item.amount?.trim().isNotEmpty == true
                              ? '\u20B9 ${item.amount}'
                              : '';
                          final rawAmount = item.amount ?? '';
                          final amountValue =
                              (double.tryParse(rawAmount) ?? 0).round();
                          final billerId = item.billerId ?? '';
                          final billerName =
                              item.billerName?.trim().isNotEmpty == true
                                  ? item.billerName!.trim()
                                  : 'Biller';
                          final type = item.paymentType?.toLowerCase() ?? '';
                          final isRecharge = type.contains('recharge');
                          final isCreditCard = type.contains('credit');
                          final buttonLabel = isRecharge
                              ? 'Repeat'
                              : (amount.isEmpty ? '' : 'PAY NOW');

                          return QuickActionCard(
                            title: title,
                            subtitle: subtitle,
                            amount: amount,
                            buttonLabel: buttonLabel,
                            onTap: () {
                              if (isRecharge) {
                                if (billerId.isEmpty) return;
                                context.push(
                                  RouteConstants.mobilePrepaid,
                                  extra: RechargeQuickActionPayload(
                                    phone: billerId,
                                    amount: amountValue,
                                    desc: item.desc,
                                    operatorName: billerName,
                                    iconUrl: item.icon,
                                  ),
                                );
                              } else {
                                if (billerId.isEmpty) return;
                                ref
                                    .read(
                                        billerDetailControllerProvider.notifier)
                                    .selectBiller(
                                      Biller(
                                        billerId: billerId,
                                        billerName: billerName,
                                        icon: item.icon,
                                      ),
                                      categoryName: item.paymentType,
                                    );
                                context.push(
                                  RouteConstants.billerDetail,
                                  extra: BillerDetailArgs(
                                    biller: Biller(
                                      billerId: billerId,
                                      billerName: billerName,
                                      icon: item.icon,
                                    ),
                                    isCreditCard: isCreditCard,
                                    paymentType: item.paymentType,
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ))
                : (showActionNeededCard.value
                    ? Padding(
                        padding: EdgeInsets.all(16.w),
                        child: ClipRect(
                          child: OverflowBox(
                            alignment: Alignment.topCenter,
                            maxHeight: double.infinity,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.cardShadow,
                                        blurRadius: 18.r,
                                        offset: Offset(0, 8.h),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      // Ellipse8 top-left oval
                                      Positioned(
                                        top: 0,
                                        left: 0,
                                        child: Image.asset(
                                          FileConstants.ellipse8,
                                          height: 58.r,
                                          width: 58.r,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      // X close button
                                      Positioned(
                                        top: 12.h,
                                        right: 12.w,
                                        child: GestureDetector(
                                          onTap: () => showActionNeededCard
                                              .value = false,
                                          child: Icon(
                                            Icons.close,
                                            size: 20.sp,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      // Card content
                                      Padding(
                                        padding: EdgeInsets.fromLTRB(16.w, 20.h, 80.w, 48.h),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              height: 40.r,
                                              width: 40.r,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFF0E8),
                                                borderRadius:
                                                    BorderRadius.circular(12.r),
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  Icons.credit_card,
                                                  color: AppColors.primary,
                                                  size: 28.sp,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 14.w),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Add Credit Card',
                                                    style: AppTextStyles
                                                        .titleMediumBold(
                                                            context),
                                                  ),
                                                  SizedBox(height: 6.h),
                                                  Text(
                                                    'Link A Card To Easily Pay\nStatements And Track Spending.',
                                                    style: AppTextStyles
                                                        .bodySmallMuted(
                                                            context),
                                                  ),
                                                  SizedBox(height: 10.h),
                                                  Text(
                                                    '+ Add Now',
                                                    style: AppTextStyles
                                                        .bodyMediumBold(context,
                                                            color: AppColors
                                                                .primary),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Frame213 - orange circle with arrow at bottom-right
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Image.asset(
                                          FileConstants.frame213,
                                          height: 60.r,
                                          width: 60.r,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink()),
          ),
        ],
      ),
    );
  }
}
