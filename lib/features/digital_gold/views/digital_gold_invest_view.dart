import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/my_app_bar.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/digital_gold_market_controller.dart';
import '../models/digital_metal.dart';

class DigitalGoldInvestView extends ConsumerWidget {
  const DigitalGoldInvestView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final name = (profileState.profile?.name ?? '').trim();
    final greetingName = name.isEmpty ? 'there' : name.split(' ').first;

    final market = ref.watch(digitalGoldMarketProvider(DigitalMetal.gold));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          MyAppBar(
            title: 'Invest In Gold',
            onBack: () => context.pop(),
            onHelp: () {},
            showHelp: true,
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h + MediaQuery.of(context).viewPadding.bottom,
              ),
              children: [
                Text(
                  'Hello, $greetingName',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ),
                SizedBox(height: 12.h),
                market.when(
                  loading: () => const _PriceCardShimmer(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (info) => _GoldPriceCard(info: info),
                ),
                SizedBox(height: 12.h),
                const _MiniMarketRow(),
                SizedBox(height: 18.h),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ),
                SizedBox(height: 12.h),
                _QuickActionsRow(
                  onBuyGold: () => context.push(
                      '${RouteConstants.digitalGold}?mode=buy&metal=gold'),
                  onSip: () {},
                  onSell: () => context.push(
                      '${RouteConstants.digitalGold}?mode=sell&metal=gold'),
                  onAlert: () {},
                ),
                SizedBox(height: 14.h),
                _SipPromoCard(
                  onTap: () {},
                ),
                SizedBox(height: 14.h),
                _WhyInvestCard(
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldPriceCard extends StatelessWidget {
  const _GoldPriceCard({required this.info});

  final DigitalGoldMarketInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.lightBorder.withOpacity(0.7)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gold Price Today',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.55),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: 6.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${info.pricePerGram.toStringAsFixed(0)}/g',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: const Color(0xFFB3722A),
                                fontWeight: FontWeight.w900,
                              ),
                    ),
                    SizedBox(width: 10.w),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F7EE),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        '+${info.changePercent.toStringAsFixed(3)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF0B8A3B),
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  info.qualityLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF0B8A3B),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: Image.asset(
              FileConstants.viewGold,
              width: 110.w,
              height: 56.h,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMarketRow extends StatelessWidget {
  const _MiniMarketRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniMarketCard(
            title: 'Silver',
            price: '2,75,808.00',
            change: '-15,196.00 (-5.22%)',
            up: false,
            asset: FileConstants.digitalSilverGif,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _MiniMarketCard(
            title: 'Platinum',
            price: '2,75,808.00',
            change: '+15,196.00 (+5.22%)',
            up: true,
            asset: FileConstants.digitalGoldGif,
          ),
        ),
      ],
    );
  }
}

class _MiniMarketCard extends StatelessWidget {
  const _MiniMarketCard({
    required this.title,
    required this.price,
    required this.change,
    required this.up,
    required this.asset,
  });

  final String title;
  final String price;
  final String change;
  final bool up;
  final String asset;

  @override
  Widget build(BuildContext context) {
    final changeColor = up ? const Color(0xFF0B8A3B) : Colors.red.shade700;
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.lightBorder.withOpacity(0.7)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ),
                SizedBox(height: 6.h),
                Text(
                  price,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                ),
                SizedBox(height: 4.h),
                Text(
                  change,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: changeColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          SizedBox(width: 44.w,
            height: 36.h,
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.onBuyGold,
    required this.onSip,
    required this.onSell,
    required this.onAlert,
  });

  final VoidCallback onBuyGold;
  final VoidCallback onSip;
  final VoidCallback onSell;
  final VoidCallback onAlert;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionTile(
            label: 'Buy Gold',
            onTap: onBuyGold,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _QuickActionTile(
            label: 'Gold SIP',
            onTap: onSip,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _QuickActionTile(
            label: 'Sell Gold',
            onTap: onSell,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _QuickActionTile(
            label: 'Alert',
            onTap: onAlert,
          ),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.lightBorder.withOpacity(0.7)),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 12.r,
              offset: Offset(0.w, 6.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              FileConstants.digitalGold,
              width: 28.w,
              height: 28.w,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 6.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SipPromoCard extends StatelessWidget {
  const _SipPromoCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: const Color(0xFFFBF1E6),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.lightBorder.withOpacity(0.7)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SIP In Gold',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFFB3722A),
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Build Wealth Automatically\nStart With Just ₹100',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Image.asset(
              FileConstants.buyMore,
              width: 48.w,
              height: 48.w,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}

class _WhyInvestCard extends StatelessWidget {
  const _WhyInvestCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.lightBorder.withOpacity(0.7)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why Invest In Gold?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Gold Is Hedge Against Inflation',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _PriceCardShimmer extends StatelessWidget {
  const _PriceCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.lightBorder.withOpacity(0.7)),
      ),
    );
  }
}
