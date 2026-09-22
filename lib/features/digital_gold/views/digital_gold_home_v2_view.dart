// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../profile/controllers/profile_controller.dart';
import '../components/digital_gold_title_live_bar.dart';
import '../models/digital_gold_dashboard.dart';
import '../repo/digital_gold_repo.dart';

part 'home_v2_tabs/gold_alerts_tab.dart';
part 'home_v2_tabs/gold_history_tab.dart';
part 'home_v2_tabs/gold_home_tab.dart';
part 'home_v2_tabs/gold_portfolio_tab.dart';
part 'home_v2_tabs/gold_sip_tab.dart';

enum _GoldDashTab { home, gold, sip, portfolio, alerts, history }

class DigitalGoldHomeV2View extends ConsumerStatefulWidget {
  const DigitalGoldHomeV2View({super.key});

  @override
  ConsumerState<DigitalGoldHomeV2View> createState() =>
      _DigitalGoldHomeV2ViewState();
}

class _DigitalGoldHomeV2ViewState extends ConsumerState<DigitalGoldHomeV2View> {
  _GoldDashTab _tab = _GoldDashTab.home;
  late final PersistentTabController _tabController;
  int _lastNonSipTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = PersistentTabController(initialIndex: _tab.index);
    _lastNonSipTabIndex = _tab.index;
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final name = (profileState.profile?.name ?? '').trim();
    final greetingName = name.isEmpty ? 'there' : name.split(' ').first;

    final tabs = <Widget>[
      _GoldHomeTab(greetingName: greetingName),
      const _GoldPortfolioTab(),
      _GoldSipTab(onOpenSetup: () {
        context.push(RouteConstants.digitalGoldSipSetup);
      }),
      const _GoldPortfolioTab(),
      const SizedBox.shrink(),
      const _GoldHistoryTab(),
    ];

    final navTextStyle = TextStyle(
      fontSize: 11.sp,
      fontWeight: FontWeight.w600,
      color: Colors.black,
      height: 0.75,
    );

    PersistentBottomNavBarItem item({
      required IconData icon,
      required String title,
      IconData? activeIcon,
    }) {
      return PersistentBottomNavBarItem(
        contentPadding: 0,
        icon: Icon(activeIcon ?? icon),
        inactiveIcon: Icon(icon),
        title: title,
        textStyle: navTextStyle,
        iconSize: 26.r,
        activeColorPrimary: AppColors.primary,
        inactiveColorPrimary: Colors.black.withOpacity(0.45),
      );
    }

    final navItems = <PersistentBottomNavBarItem>[
      item(icon: Icons.home_outlined, activeIcon: Icons.home, title: 'Home'),
      item(
        icon: Icons.account_balance_wallet_outlined,
        activeIcon: Icons.account_balance_wallet,
        title: 'Gold',
      ),
      item(icon: Icons.autorenew_rounded, title: 'SIP'),
      item(
          icon: Icons.pie_chart_outline,
          activeIcon: Icons.pie_chart,
          title: 'Portfolio'),
      item(
        icon: Icons.notifications_none_rounded,
        activeIcon: Icons.notifications_rounded,
        title: 'Alerts',
      ),
      item(icon: Icons.history, title: 'History'),
    ];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_tabController.index != 0) {
          _tabController.jumpToTab(0);
          return;
        }
        context.pop();
      },
      child: PersistentTabView(
        context,
        controller: _tabController,
        screens: tabs,
        items: navItems,
        navBarStyle: NavBarStyle.simple,
        decoration: NavBarDecoration(
          borderRadius: BorderRadius.circular(0.r),
          colorBehindNavBar: Colors.white,
        ),
        navBarHeight: 62,
        padding: EdgeInsets.only(top: 2.h, bottom: 8.h),
        backgroundColor: Colors.white,
        hideNavigationBarWhenKeyboardAppears: true,
        confineToSafeArea: true,
        onItemSelected: (index) {
          // SIP should open as a separate screen (no bottom bar), like the
          // old flow. Keep the previously selected tab highlighted.
          if (index == _GoldDashTab.sip.index) {
            final restoreIndex = _lastNonSipTabIndex;
            _tabController.jumpToTab(restoreIndex);
            context.push(RouteConstants.digitalGoldSipSetup);
            return;
          }
          if (index == _GoldDashTab.alerts.index) {
            final restoreIndex = _lastNonSipTabIndex;
            _tabController.jumpToTab(restoreIndex);
            PersistentNavBarNavigator.pushDynamicScreen(
              context,
              withNavBar: false,
              screen: MaterialPageRoute(
                builder: (_) => const _GoldAlertsTab(),
              ),
            );
            return;
          }
          if (index == _GoldDashTab.portfolio.index) {
            final restoreIndex = _lastNonSipTabIndex;
            _tabController.jumpToTab(restoreIndex);
            PersistentNavBarNavigator.pushDynamicScreen(
              context,
              withNavBar: false,
              screen: MaterialPageRoute(
                builder: (_) => const _GoldPortfolioTab(),
              ),
            );
            return;
          }
          if (index != _GoldDashTab.sip.index) {
            _lastNonSipTabIndex = index;
          }
          setState(() => _tab = _GoldDashTab.values[index]);
        },
      ),
    );
  }
}

class _PortfolioHeaderCard extends StatelessWidget {
  const _PortfolioHeaderCard({
    required this.onBack,
    required this.onHelp,
    required this.rateText,
  });

  final VoidCallback onBack;
  final VoidCallback onHelp;
  final String rateText;

  @override
  Widget build(BuildContext context) {
    const headerBg = Color.fromARGB(255, 255, 255, 255);
    return Container(
      color: Colors.white,
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    heightFactor: 0.48,
                    child: Opacity(
                      opacity: 0.35,
                      child: Image.asset(
                        FileConstants.sipBg,
                        fit: BoxFit.cover,
                        alignment: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16.w,
                MediaQuery.of(context).viewPadding.top + 8.h,
                16.w,
                20.h,
              ),
              child: Column(
                children: [
                  DigitalGoldTitleLiveBar(
                    title: 'Portfolio',
                    rateText: rateText,
                    onBack: onBack,
                    onHelp: onHelp,
                    padding: EdgeInsets.zero,
                    chipLeading: Image.asset(
                      FileConstants.liveSignal,
                      width: 12.r,
                      height: 12.r,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: _HeaderMetric(
                          title: 'Current Value',
                          value: '₹545.00',
                          valueColor: Color(0xFF0B8A3B),
                          subtitle: '24k | 99% | Pure Gold',
                        ),
                      ),
                      SizedBox(width: 12.w),
                      const Expanded(
                        child: _HeaderMetric(
                          title: 'Total Digital Gold',
                          value: '0.89g',
                          valueColor: Colors.black,
                          subtitle: 'Overall Returns\n11.18%',
                          subtitleColor: Color(0xFF0B8A3B),
                          subtitleAlign: TextAlign.right,
                          alignEnd: true,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      const Expanded(
                        child: _MiniMetric(
                          title: 'Total Invested',
                          value: '+545.60',
                        ),
                      ),
                      SizedBox(width: 12.w),
                      const Expanded(
                        child: _MiniMetric(
                          title: 'Overall Returns',
                          value: '11.18%',
                          valueColor: Color(0xFF0B8A3B),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    height: 1,
                    color: const Color(0xFFE8C9A4).withOpacity(0.6),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: _PillButton(
                          label: 'Save More',
                          filled: true,
                          onTap: () {},
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _PillButton(
                          label: 'Withdraw',
                          filled: false,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.title,
    required this.value,
    this.valueColor,
  });

  final String title;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.black.withOpacity(0.55),
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: 6.h),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: valueColor ?? Colors.black,
              ),
        ),
      ],
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({
    required this.title,
    required this.value,
    required this.valueColor,
    required this.subtitle,
    this.subtitleColor,
    this.subtitleAlign,
    this.alignEnd = false,
  });

  final String title;
  final String value;
  final Color valueColor;
  final String subtitle;
  final Color? subtitleColor;
  final TextAlign? subtitleAlign;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.black.withOpacity(0.55),
                fontWeight: FontWeight.w700,
              ),
        ),
        SizedBox(height: 6.h),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: valueColor,
              ),
        ),
        SizedBox(height: 4.h),
        Text(
          subtitle,
          textAlign: subtitleAlign,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: subtitleColor ?? Colors.black.withOpacity(0.55),
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
        ),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE85A2C);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        height: 36.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? accent : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: accent),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: filled ? Colors.white : accent,
              ),
        ),
      ),
    );
  }
}

class _PortfolioTabChip extends StatelessWidget {
  const _PortfolioTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE85A2C);
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: selected ? accent : Colors.black54,
                ),
          ),
          SizedBox(height: 6.h),
          Container(
            height: 2.h,
            width: selected ? 60.w : 0,
            color: accent,
          ),
        ],
      ),
    );
  }
}

class _HoldingCardV2 extends StatelessWidget {
  const _HoldingCardV2({
    required this.title,
    required this.amount,
    required this.value,
    required this.avgBuy,
  });

  final String title;
  final String amount;
  final String value;
  final String avgBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.lightBorder.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 34.r,
            height: 34.r,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDD8),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: const Icon(Icons.star, color: Color(0xFFE85A2C), size: 18),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Avg. Buy Price\n$avgBuy',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black.withOpacity(0.55),
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
              ),
              SizedBox(height: 6.h),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.black.withOpacity(0.65),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SipSummaryTile extends StatelessWidget {
  const _SipSummaryTile({
    required this.label,
    required this.amount,
    required this.status,
    required this.onTap,
  });

  final String label;
  final String amount;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.lightBorder.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                ),
                SizedBox(height: 2.h),
                Text(
                  status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0B8A3B),
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

class _GoldPriceCard extends StatelessWidget {
  const _GoldPriceCard({required this.rate});

  final DigitalGoldMetalRate? rate;

  @override
  Widget build(BuildContext context) {
    final data = rate;
    if (data == null) return const SizedBox.shrink();

    final changePercent = data.percentChange;
    final isUp = data.isUp || (!data.isDown && changePercent >= 0);
    final chipBg = isUp ? const Color(0xFFE8F7EE) : const Color(0xFFFFE8E8);
    final chipFg = isUp ? const Color(0xFF0B8A3B) : const Color(0xFFB42318);
    final price = data.rateTodayValue > 0
        ? '₹${data.rateTodayValue.toStringAsFixed(2)}/gm'
        : data.rateToday;

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
                        color: Colors.black.withOpacity(0.55),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: 6.h),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 10.w,
                  runSpacing: 6.h,
                  children: [
                    Text(
                      price,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: const Color(0xFFB3722A),
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: chipBg,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        '${isUp ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: chipFg,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  '24k | 99% | Pure Gold',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF058337),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          SizedBox(width: 150.w,
            height: 60.h,
            child: data.graphImageUrl.trim().isEmpty
                ? const SizedBox.shrink()
                : Image.network(
                    data.graphImageUrl,
                    fit: BoxFit.contain,
                    alignment: Alignment.centerRight,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MiniPriceRow extends StatelessWidget {
  const _MiniPriceRow({required this.rate});

  final DigitalGoldMetalRate? rate;

  @override
  Widget build(BuildContext context) {
    final data = rate;
    if (data == null) return const SizedBox.shrink();

    Widget item(String label, String price, String percent) {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8.w,
        runSpacing: 6.h,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
          ),
          Text(
            price,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7EE),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              percent,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF0B8A3B),
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      );
    }

    final changePercent = data.percentChange;
    final isUp = data.isUp || (!data.isDown && changePercent >= 0);
    final price = data.rateTodayValue > 0
        ? data.rateTodayValue.toStringAsFixed(2)
        : data.rateToday;
    final percent = '${isUp ? '+' : ''}${changePercent.toStringAsFixed(2)}%';

    return Row(
      children: [
        Expanded(child: item('Silver', price, percent)),
        // Expanded(child: item('Platinum', '1,80,000.15', '+0.73%')),
      ],
    );
  }
}

class _GoldPriceCardSkeleton extends StatelessWidget {
  const _GoldPriceCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: IgnorePointer(
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
                      'Gold Price Today',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black.withOpacity(0.55),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      '₹0.00/gm',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: const Color(0xFFB3722A),
                                fontWeight: FontWeight.w900,
                              ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '24k | 99% | Pure Gold',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF0B8A3B),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              Container(
                width: 150.w,
                height: 60.h,
                color: AppColors.lightBorder.withOpacity(0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPriceRowSkeleton extends StatelessWidget {
  const _MiniPriceRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: IgnorePointer(
        child: Row(
          children: [
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8.w,
                runSpacing: 6.h,
                children: [
                  Text(
                    'Silver',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                  ),
                  Text(
                    '0.00',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F7EE),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      '+0.00%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF0B8A3B),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.onBuyGold,
    required this.onGoldSip,
    required this.onSellGold,
    required this.onAlert,
  });

  final VoidCallback onBuyGold;
  final VoidCallback onGoldSip;
  final VoidCallback onSellGold;
  final VoidCallback onAlert;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionTile(
            label: 'Buy Gold',
            icon: FileConstants.digitalGold,
            onTap: onBuyGold,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _QuickActionTile(
            label: 'Gold SIP',
            icon: FileConstants.goldSip,
            onTap: onGoldSip,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _QuickActionTile(
            label: 'Sell Gold',
            icon: FileConstants.digitalGold,
            onTap: onSellGold,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _QuickActionTile(
            label: 'Alert',
            icon: FileConstants.digitalGold,
            onTap: onAlert,
          ),
        ),
      ],
    );
  }
}

class _QuickActionsLoadingRow extends StatelessWidget {
  const _QuickActionsLoadingRow();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: IgnorePointer(
        child: Row(
          children: [
            for (var i = 0; i < 4; i++) ...[
              if (i != 0) SizedBox(width: 12.w),
              Expanded(
                child: _QuickActionTile(
                  label: 'Loading',
                  icon: FileConstants.digitalGold,
                  onTap: () {},
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickActionsApiRow extends StatelessWidget {
  const _QuickActionsApiRow({
    required this.actions,
    required this.onBuyGold,
    required this.onGoldSip,
    required this.onSellGold,
    required this.onAlert,
  });

  final List<DigitalGoldQuickAction> actions;
  final VoidCallback onBuyGold;
  final VoidCallback onGoldSip;
  final VoidCallback onSellGold;
  final VoidCallback onAlert;

  VoidCallback? _tapFor(String rawName) {
    final name = rawName.trim().toLowerCase();
    if (name == 'buy gold') return onBuyGold;
    if (name == 'gold sip' || name == 'sip') return onGoldSip;
    if (name == 'sell gold') return onSellGold;
    if (name == 'alert') return onAlert;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final firstFour = actions.take(4).toList(growable: false);
    if (firstFour.isEmpty) return const SizedBox.shrink();

    return Row(
      children: List.generate(firstFour.length, (index) {
        final action = firstFour[index];
        final name = action.name;
        final imageUrl = action.imageUrl;
        final onTap = _tapFor(name);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 12.w),
            child: _QuickActionNetworkTile(
              label: name,
              imageUrl: imageUrl,
              onTap: onTap,
            ),
          ),
        );
      }),
    );
  }
}

class _QuickActionNetworkTile extends StatelessWidget {
  const _QuickActionNetworkTile({
    required this.label,
    required this.imageUrl,
    required this.onTap,
  });

  final String label;
  final String imageUrl;
  final VoidCallback? onTap;

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
            SizedBox(width: 30.w,
              height: 30.w,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.image_not_supported_outlined,
                  size: 20.r,
                  color: AppColors.textPrimary.withOpacity(0.45),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.lightBorder.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String icon;
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
              icon,
              width: 30.w,
              height: 30.w,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 6.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
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
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color.fromRGBO(183, 112, 35, 0),
              Colors.white,
              Colors.white,
            ],
            // stops: [0.0, 0.2436, 1.0],
          ),
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
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Image.asset(
              FileConstants.goldSip,
              width: 54.w,
              height: 54.w,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}

class _WhyInvestCard extends StatelessWidget {
  const _WhyInvestCard();

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
                  'Why Invest In Gold?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Gold Is Hedge Against Inflation',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
