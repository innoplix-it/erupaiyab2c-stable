// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/my_app_bar.dart';
import '../../home/controllers/home_controller.dart';
import '../../home/models/quick_actions_model.dart';
import '../controllers/mobile_prepaid_controller.dart';
import '../models/recharge_quick_action_payload.dart';

class MobileRecentRechargesView extends HookConsumerWidget {
  const MobileRecentRechargesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeControllerProvider);
    final isFetching = homeState.isFetchingRecharge;
    final recharges = homeState.rechargeActions;

    useEffect(() {
      Future.microtask(() {
        ref.read(homeControllerProvider.notifier).fetchRechargeActions();
      });
      return null;
    }, const []);

    // Once loaded and empty, skip this screen and go to new recharge
    final isLoaded = !isFetching && recharges != null;
    useEffect(() {
      if (isLoaded && recharges.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.pushReplacement(RouteConstants.mobilePrepaid);
          }
        });
      }
      return null;
    }, [isLoaded]);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          MyAppBar(
            title: 'Mobile Recharge',
            onBack: () => context.pop(),
          ),
          Expanded(
            child: isFetching || recharges == null || recharges.isEmpty
                ? const Center(
                    child: SpinKitCircle(
                      color: AppColors.primary,
                      size: 48,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recent recharges list
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
                          itemCount: recharges.length,
                          separatorBuilder: (_, __) => SizedBox(height: 12.h),
                          itemBuilder: (context, index) {
                            final item = recharges[index];
                            return _RechargeCard(
                              item: item,
                              onRepeat: () {
                                final amountValue =
                                    (double.tryParse(item.amount ?? '') ?? 0)
                                        .round();
                                context.push(
                                  RouteConstants.mobilePrepaid,
                                  extra: RechargeQuickActionPayload(
                                    phone: item.billerId ?? '',
                                    amount: amountValue,
                                    desc: item.desc,
                                    operatorName: item.billerName,
                                    iconUrl: item.icon,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      // New recharge button
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 0.h, 16.w, 24.h),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ref
                                  .read(
                                      mobilePrepaidControllerProvider.notifier)
                                  .reset();
                              context.push(RouteConstants.mobilePrepaid);
                            },
                            icon: Icon(Icons.add,
                                color: AppColors.primary, size: 20.r),
                            label: const Text(
                              'Recharge a New Number',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _RechargeCard extends StatelessWidget {
  const _RechargeCard({required this.item, required this.onRepeat});

  final Data item;
  final VoidCallback onRepeat;

  @override
  Widget build(BuildContext context) {
    final operatorName = item.billerName?.trim().isNotEmpty == true
        ? item.billerName!.trim()
        : 'Unknown';
    final phone = item.billerId ?? '';
    final amount = item.amount ?? '0';
    final dueDate = item.nextDue ?? '';
    final daysLeft = item.daysLeft ?? 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onRepeat,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.lightBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 14.r,
                offset: Offset(0.w, 6.h),
              ),
            ],
          ),
          child: Row(
            children: [
              // Operator icon
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: item.icon?.isNotEmpty == true
                      ? AppNetworkImage(
                          url: item.icon,
                          width: 44.w,
                          height: 44.w,
                          fit: BoxFit.cover,
                          showShimmer: false,
                        )
                      : Icon(Icons.phone_android,
                          color: AppColors.primary, size: 22.sp),
                ),
              ),
              SizedBox(width: 12.w),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          operatorName,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const Spacer(),
                        Text(
                          '₹$amount',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      phone,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary.withOpacity(0.6),
                          ),
                    ),
                    if (dueDate.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 11.sp,
                            color: daysLeft == 0
                                ? Colors.red
                                : AppColors.textPrimary.withOpacity(0.5),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            daysLeft == 0
                                ? 'Due today'
                                : 'Due in $daysLeft day${daysLeft == 1 ? '' : 's'}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: daysLeft == 0
                                      ? Colors.red
                                      : AppColors.textPrimary.withOpacity(0.5),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              // Repeat button
              GestureDetector(
                onTap: onRepeat,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'Repeat',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
