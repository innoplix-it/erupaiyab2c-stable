part of '../digital_gold_home_v2_view.dart';

class _GoldHomeTab extends ConsumerWidget {
  const _GoldHomeTab({required this.greetingName});

  final String greetingName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(digitalGoldDashboardProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(8.w, 8.h, 12.w, 8.h),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  Expanded(
                    child: Text(
                      'Invest In Gold',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                    ),
                  ),
                  Image.asset(
                    FileConstants.bharatConnectColor,
                    height: 22.h,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(width: 6.w),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.help_outline_rounded),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1.h, color: AppColors.lightBorder.withOpacity(0.6)),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(digitalGoldDashboardProvider);
                // ignore: discarded_futures
                await ref.read(digitalGoldDashboardProvider.future);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h + MediaQuery.of(context).viewPadding.bottom,
                ),
                children: [
                Text(
                  'Hello, $greetingName',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                ),
                SizedBox(height: 12.h),
                if (dashboardAsync.isLoading)
                  const _GoldPriceCardSkeleton()
                else
                  _GoldPriceCard(rate: dashboardAsync.asData?.value.gold),
                SizedBox(height: 14.h),
                if (dashboardAsync.isLoading)
                  const _MiniPriceRowSkeleton()
                else
                  _MiniPriceRow(rate: dashboardAsync.asData?.value.silver),
                SizedBox(height: 18.h),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                ),
                SizedBox(height: 12.h),
                dashboardAsync.when(
                  loading: () => const _QuickActionsLoadingRow(),
                  error: (_, __) => _QuickActionsRow(
                    onBuyGold: () => context.push(
                      '${RouteConstants.digitalGold}?mode=buy&metal=gold',
                    ),
                    onGoldSip: () =>
                        context.push(RouteConstants.digitalGoldSipSetup),
                    onSellGold: () => context.push(
                      '${RouteConstants.digitalGold}?mode=sell&metal=gold',
                    ),
                    onAlert: () {},
                  ),
                  data: (dashboard) {
                    final actions = dashboard.quickActions;
                    if (actions.isEmpty) {
                      return _QuickActionsRow(
                        onBuyGold: () => context.push(
                          '${RouteConstants.digitalGold}?mode=buy&metal=gold',
                        ),
                        onGoldSip: () =>
                            context.push(RouteConstants.digitalGoldSipSetup),
                        onSellGold: () => context.push(
                          '${RouteConstants.digitalGold}?mode=sell&metal=gold',
                        ),
                        onAlert: () {},
                      );
                    }
                    return _QuickActionsApiRow(
                      actions: actions,
                      onBuyGold: () => context.push(
                        '${RouteConstants.digitalGold}?mode=buy&metal=gold',
                      ),
                      onGoldSip: () =>
                          context.push(RouteConstants.digitalGoldSipSetup),
                      onSellGold: () => context.push(
                        '${RouteConstants.digitalGold}?mode=sell&metal=gold',
                      ),
                      onAlert: () {},
                    );
                  },
                ),
                SizedBox(height: 14.h),
                _SipPromoCard(
                  onTap: () => context.push(RouteConstants.digitalGoldSipSetup),
                ),
                SizedBox(height: 14.h),
                const _WhyInvestCard(),
                SizedBox(height: 24.h),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }
}
