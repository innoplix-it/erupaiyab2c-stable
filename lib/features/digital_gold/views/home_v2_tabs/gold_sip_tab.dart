part of '../digital_gold_home_v2_view.dart';

class _GoldSipTab extends StatelessWidget {
  const _GoldSipTab({required this.onOpenSetup});

  final VoidCallback onOpenSetup;

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFFFFAF2);
    const accent = Color(0xFFE85A2C);
    return Scaffold(
      backgroundColor: bg,
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
                  const Spacer(),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDD8),
                      borderRadius: BorderRadius.circular(999.r),
                      border: Border.all(color: const Color(0xFFE8C9A4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6.r,
                          height: 6.r,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '₹ 16,144.25/gm',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F7EE),
                      borderRadius: BorderRadius.circular(999.r),
                      border: Border.all(color: const Color(0xFFCDEEDB)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Active',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF0B8A3B),
                                  ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          width: 18.r,
                          height: 18.r,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF22C55E),
                          ),
                          child: Icon(
                            Icons.check,
                            size: 12.r,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 120.h),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18.r),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          FileConstants.sipBg,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 16.h),
                        child: Column(
                          children: [
                            Image.asset(
                              FileConstants.coinsDeck,
                              width: 90.w,
                              height: 54.h,
                              fit: BoxFit.contain,
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              'Total Invested In Digital Gold',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.black.withOpacity(0.55),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              '₹200',
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              'Projected Returns In 5 Years : ₹1,80,000.00',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.black.withOpacity(0.55),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            SizedBox(height: 14.h),
                            Row(
                              children: [
                                const Expanded(
                                  child: _SipQuickStatCard(
                                    title: '₹50',
                                    subtitle: 'Daily Saving',
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                const Expanded(
                                  child: _SipQuickStatCard(
                                    title: 'Track Savings',
                                    subtitle: '',
                                    showIcon: true,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 14.h),
                            _IncreaseSipCard(
                              currentAmount: '₹50',
                              recommendedAmount: '₹100',
                              onTap: onOpenSetup,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  height: 80.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  'Manage Savings',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                ),
                SizedBox(height: 10.h),
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: Column(
                    children: [
                      _ManageRow(
                        left: 'Daily Savings Amount',
                        right: '₹50',
                        rightWidget: Icon(
                          Icons.edit,
                          size: 16.r,
                          color: Colors.black.withOpacity(0.55),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      const _ManageRow(
                        left: 'Saving Through',
                        right: 'PhonePe',
                      ),
                      SizedBox(height: 12.h),
                      const _ManageRow(
                        left: 'Pause Daily Saving',
                        rightWidget: _SmallActionPill(
                          label: 'Pause',
                          bg: Color(0xFFFFEDD8),
                          fg: accent,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      const _ManageRow(
                        left: 'Stop Daily Saving',
                        rightWidget: _SmallActionPill(
                          label: 'Stop',
                          bg: Color(0xFFFFE8E8),
                          fg: Color(0xFFB42318),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.black.withOpacity(0.12),
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      child: Text(
                        '1 Cr+ Users Trust Us',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.black.withOpacity(0.55),
                            ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.black.withOpacity(0.12),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '“',
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black.withOpacity(0.35),
                                  height: 0.8,
                                ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'eRupaiya Gold SIP Made Investing In Gold Simple\n'
                        'And Affordable. I Started With A Small Amount\n'
                        'And Now I Feel More Confident About My Savings\n'
                        'Journey.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black.withOpacity(0.65),
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Container(
                            width: 34.r,
                            height: 34.r,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE5E7EB),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ivanshu',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                              ),
                              Text(
                                'Daily Saver',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: accent,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_user,
                        color: Color(0xFF16A34A), size: 16),
                    SizedBox(width: 6.w),
                    Text(
                      '100% \nSecured Savings',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.black.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: bg,
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 14.h),
          child: SizedBox(height: 44.h,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28.r),
                ),
              ),
              child: Text(
                'Instant Withdraw',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SipQuickStatCard extends StatelessWidget {
  const _SipQuickStatCard({
    required this.title,
    required this.subtitle,
    this.showIcon = false,
  });

  final String title;
  final String subtitle;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE8C9A4)),
      ),
      child: Row(
        children: [
          if (showIcon) ...[
            const Icon(Icons.track_changes, color: Color(0xFFB3722A)),
            SizedBox(width: 8.w),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                ),
                if (subtitle.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.black.withOpacity(0.6),
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IncreaseSipCard extends StatelessWidget {
  const _IncreaseSipCard({
    required this.currentAmount,
    required this.recommendedAmount,
    required this.onTap,
  });

  final String currentAmount;
  final String recommendedAmount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE85A2C);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.fromLTRB(14.w, 18.h, 14.w, 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: accent.withOpacity(0.7)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -28.h,
              left: -2.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(999.r),
                ),
                child: Text(
                  'Increase SIP Amount',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                ),
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentAmount,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Current',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black.withOpacity(0.55),
                                    ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.play_arrow_rounded,
                            color: Colors.black.withOpacity(0.25)),
                        Icon(Icons.play_arrow_rounded,
                            color: Colors.black.withOpacity(0.25)),
                        Icon(Icons.play_arrow_rounded,
                            color: Colors.black.withOpacity(0.25)),
                      ],
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            recommendedAmount,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0B8A3B),
                                ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Recommended',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black.withOpacity(0.55),
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Text(
                  'Projected Returns In 5 Years : ₹1,80,000.00',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black.withOpacity(0.55),
                        fontWeight: FontWeight.w700,
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

class _ManageRow extends StatelessWidget {
  const _ManageRow({
    required this.left,
    this.right,
    this.rightWidget,
  });

  final String left;
  final String? right;
  final Widget? rightWidget;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            left,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.black.withOpacity(0.65),
                ),
          ),
        ),
        if (rightWidget != null) rightWidget!,
        if (rightWidget == null && right != null)
          Text(
            right!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
          ),
      ],
    );
  }
}

class _SmallActionPill extends StatelessWidget {
  const _SmallActionPill({
    required this.label,
    required this.bg,
    required this.fg,
  });

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: fg,
            ),
      ),
    );
  }
}
