// ignore_for_file: deprecated_member_use

part of '../digital_gold_home_v2_view.dart';

class _GoldPortfolioTab extends StatefulWidget {
  const _GoldPortfolioTab();

  @override
  State<_GoldPortfolioTab> createState() => _GoldPortfolioTabState();
}

class _GoldPortfolioTabState extends State<_GoldPortfolioTab> {
  bool _sipActive = true;

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF9F9F9);
    const accent = Color(0xFFE85A2C);

    return Scaffold(
      backgroundColor: background,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(height: 420.h,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(22.r),
                    ),
                    child: Image.asset(
                      FileConstants.portfolioBg,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16.w,
                    MediaQuery.of(context).viewPadding.top + 4.h,
                    16.w,
                    18.h,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          ),
                          Expanded(
                            child: Center(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7D5),
                                  borderRadius: BorderRadius.circular(999.r),
                                  border: Border.all(
                                    color: const Color(0xFFC59B17),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      FileConstants.liveSignal,
                                      width: 12.r,
                                      height: 12.r,
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      '16,144.25/gm',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Text(
                            'Active',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF0B8A3B),
                                    ),
                          ),
                          SizedBox(width: 8.w),
                          Transform.scale(
                            scale: 0.85,
                            child: Switch(
                              value: _sipActive,
                              activeThumbColor: Colors.white,
                              activeTrackColor: const Color(0xFF0B8A3B),
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor:
                                  Colors.black.withOpacity(0.15),
                              onChanged: (v) => setState(() => _sipActive = v),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Image.asset(
                        FileConstants.coinsDeck,
                        height: 78.h,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        'Total Invested In Digital Gold',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black.withOpacity(0.55),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        '₹200',
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                      ),
                      SizedBox(height: 6.h),
                      RichText(
                        text: TextSpan(
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.black.withOpacity(0.55),
                                    fontWeight: FontWeight.w700,
                                  ),
                          children: [
                            const TextSpan(
                                text: 'Projected Returns In 5 Years : '),
                            TextSpan(
                              text: '₹1,80,000.00',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14.h),
                      Row(
                        children: [
                          Expanded(
                            child: _InfoTile(
                              title: 'Daily Saving',
                              value: '₹50',
                              icon: null,
                              onTap: () {},
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _InfoTile(
                              title: 'Track Savings',
                              value: null,
                              icon: FileConstants.trackSavings,
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                Positioned(
                  left: 16.w,
                  right: 16.w,
                  bottom: -44.h,
                  child: _IncreaseSipAmountCard(
                    currentAmount: '₹50',
                    recommendedAmount: '₹100',
                    projectedReturns: '₹1,80,000.00',
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 56.h),
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 18.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage Savings',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                ),
                SizedBox(height: 10.h),
                _ManageSavingsCard(
                  onPause: () => _openPausedSuccess(context),
                  onStop: () => _openStopSipSheet(context),
                ),
                SizedBox(height: 16.h),
                _TrustHeader(),
                SizedBox(height: 12.h),
                _TestimonialCard(),
                SizedBox(height: 14.h),
                _SecuredSavingsRow(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 14.h),
        child: SafeArea(
          top: false,
          child: SizedBox(height: 40.h,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999.r),
                ),
              ),
              child: Text(
                'Instant Withdraw',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  void _openPausedSuccess(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _SipPausedSuccessView()),
    );
  }

  Future<void> _openStopSipSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      builder: (context) => const _StopSipBottomSheet(),
    );
    if (selected == null) return;
    // After confirmation, show paused/success screen (UI only).
    if (context.mounted) _openPausedSuccess(context);
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String? value;
  final String? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFEFEFE),
              Color(0xFFF3F3F3),
            ],
          ),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFDFDFDF)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (value != null)
                    Text(
                      value!,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    )
                  else
                    Image.asset(icon ?? '', height: 24.h, fit: BoxFit.contain),
                  SizedBox(height: 6.h),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.black.withOpacity(0.7),
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

class _IncreaseSipAmountCard extends StatelessWidget {
  const _IncreaseSipAmountCard({
    required this.currentAmount,
    required this.recommendedAmount,
    required this.projectedReturns,
    required this.onTap,
  });

  final String currentAmount;
  final String recommendedAmount;
  final String projectedReturns;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE85A2C);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: accent),
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(14.w, 32.h, 14.w, 14.w),
              child: Column(
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
                            SizedBox(height: 4.h),
                            Text(
                              'Current',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black.withOpacity(0.6),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Image.asset(
                        FileConstants.righTrack,
                        width: 55.r,
                        height: 55.r,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(width: 12.w),
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
                            SizedBox(height: 4.h),
                            Text(
                              'Recommended',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black.withOpacity(0.6),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black.withOpacity(0.55),
                            fontWeight: FontWeight.w700,
                          ),
                      children: [
                        const TextSpan(text: 'Projected Returns In 5 Years : '),
                        TextSpan(
                          text: projectedReturns,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 10.h,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12.r),
                      bottomRight: Radius.circular(12.r)),
                ),
                child: Text(
                  'Increase SIP Amount',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManageSavingsCard extends StatelessWidget {
  const _ManageSavingsCard({required this.onPause, required this.onStop});

  final VoidCallback onPause;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE85A2C);
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.1, -0.2),
          end: Alignment(1.0, 1.0),
          colors: [
            Color(0xFFFEFEFE),
            Color(0xFFF3F3F3),
          ],
          stops: [0.0, 1.0],
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: const Color(0x80DD5428),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          _RowItem(
            label: 'Daily Savings Amount',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹50',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                ),
                SizedBox(width: 6.w),
                Icon(Icons.edit, size: 16.r, color: Colors.black54),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          _RowItem(
            label: 'Saving Through',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PhonePe',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                ),
                SizedBox(width: 6.w),
                Icon(Icons.edit, size: 16.r, color: Colors.black54),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          _RowItem(
            label: 'Pause Daily Saving',
            trailing: SizedBox(height: 28.h,
              child: OutlinedButton(
                onPressed: onPause,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: accent.withOpacity(0.25)),
                  backgroundColor: const Color(0xFFFFF1EA),
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: Text(
                  'Pause',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: accent,
                      ),
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          _RowItem(
            label: 'Stop Daily Saving',
            trailing: SizedBox(height: 28.h,
              child: OutlinedButton(
                onPressed: onStop,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: accent.withOpacity(0.25)),
                  backgroundColor: const Color(0xFFFFF1EA),
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: Text(
                  'Stop',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: accent,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  const _RowItem({required this.label, required this.trailing});

  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.black.withOpacity(0.7),
                ),
          ),
        ),
        trailing,
      ],
    );
  }
}

class _TrustHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(FileConstants.leftGradientLine, width: 50.w, height: 50.h),
        SizedBox(width: 10.w),
        Text(
          '1 Cr+ Users Trust Us',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
        ),
        SizedBox(width: 10.w),
        Image.asset(FileConstants.rightGradientLine, width: 50.w, height: 50.h),
      ],
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.18, -0.05),
          end: Alignment(1.0, 1.0),
          colors: [
            Color(0xFFFEFEFE),
            Color(0xFFF3F3F3),
          ],
          stops: [0.0, 1.0],
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.lightBorder.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '“',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  height: 0.9,
                ),
          ),
          SizedBox(height: 8.h),
          Text(
            'ERupaiya Gold SIP Made Investing In Gold Simple\n'
            'And Affordable. I Started With A Small Amount\n'
            'And Now I Feel More Confident About My Savings\n'
            'Journey.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withOpacity(0.7),
                  height: 1.35,
                ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Container(
                width: 34.r,
                height: 34.r,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 10.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ivanshu',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                  ),
                  Text(
                    'Daily Saver',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFE85A2C),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SecuredSavingsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          FileConstants.resetPinIcon,
          width: 30.w,
          height: 2.h,
          fit: BoxFit.contain,
        ),
        SizedBox(width: 8.w),
        Text(
          '100%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
        ),
        SizedBox(width: 6.w),
        Text(
          'Secured Savings',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.black.withOpacity(0.6),
              ),
        ),
      ],
    );
  }
}

class _StopSipBottomSheet extends StatefulWidget {
  const _StopSipBottomSheet();

  @override
  State<_StopSipBottomSheet> createState() => _StopSipBottomSheetState();
}

class _StopSipBottomSheetState extends State<_StopSipBottomSheet> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE85A2C);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Stop Gold SIP?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7D5),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFE8C9A4)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Stopping Your SIP Now May Reduce Your\n'
                      'Projected Returns And Future Savings\n'
                      'Growth.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.black.withOpacity(0.75),
                            height: 1.35,
                          ),
                    ),
                  ),
                  Image.asset(
                    FileConstants.goldCoin,
                    width: 46.w,
                    height: 46.w,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            _StopOption(
              label: 'Till Tomorrow',
              selected: _selected == 0,
              onTap: () => setState(() => _selected = 0),
            ),
            _StopOption(
              label: 'For 1st Week',
              selected: _selected == 1,
              onTap: () => setState(() => _selected = 1),
            ),
            _StopOption(
              label: 'For 2 Weeks',
              selected: _selected == 2,
              onTap: () => setState(() => _selected = 2),
            ),
            _StopOption(
              label: 'Permanently',
              selected: _selected == 3,
              onTap: () => setState(() => _selected = 3),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(_selected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  minimumSize: Size.fromHeight(44.h),
                ),
                child: Text(
                  'Confirm',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StopOption extends StatelessWidget {
  const _StopOption({
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
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
              ),
            ),
            Container(
              width: 18.r,
              height: 18.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? accent : Colors.black.withOpacity(0.35),
                  width: 1.5,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10.r,
                        height: 10.r,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SipPausedSuccessView extends StatelessWidget {
  const _SipPausedSuccessView();

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE85A2C);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Container(
                width: 76.r,
                height: 76.r,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF0B8A3B),
                ),
                child: Icon(Icons.check, color: Colors.white, size: 36.r),
              ),
              SizedBox(height: 16.h),
              Text(
                'Gold SIP Paused Successfully',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
              ),
              SizedBox(height: 10.h),
              Text(
                'Your Daily Gold Savings Have Been Paused Temporarily.\n'
                'You Can Resume Your SIP Anytime From Manage\n'
                'Savings.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withOpacity(0.65),
                      height: 1.35,
                    ),
              ),
              SizedBox(height: 18.h),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: accent),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                  ),
                  child: Text(
                    'Return To Dashboard',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: accent,
                        ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                    minimumSize: Size.fromHeight(48.h),
                  ),
                  child: Text(
                    'Resume SIP',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
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
