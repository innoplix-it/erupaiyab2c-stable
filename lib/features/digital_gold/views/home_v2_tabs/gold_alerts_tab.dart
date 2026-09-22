// ignore_for_file: deprecated_member_use

part of '../digital_gold_home_v2_view.dart';

class _GoldAlertsTab extends ConsumerStatefulWidget {
  const _GoldAlertsTab();

  @override
  ConsumerState<_GoldAlertsTab> createState() => _GoldAlertsTabState();
}

class _GoldAlertsTabState extends ConsumerState<_GoldAlertsTab> {
  bool _dropsBelow = true;
  bool _oneTime = true;
  final TextEditingController _targetController =
      TextEditingController(text: '');

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  void _openEditSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      builder: (context) {
        return _EditAlertSheet(
          dropsBelow: _dropsBelow,
          oneTime: _oneTime,
          targetController: TextEditingController(text: _targetController.text),
        );
      },
    );
  }

  void _openDeleteSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      builder: (context) => const _DeleteAlertSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      'Gold Price Alert',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                    ),
                  ),
                  Image.asset(
                    FileConstants.bharatConnectColor,
                    height: 20.h,
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
                if (dashboardAsync.isLoading)
                  const _GoldPriceCardSkeleton()
                else
                  _GoldPriceCard(rate: dashboardAsync.asData?.value.gold),
                SizedBox(height: 14.h),
                _AlertFormCard(
                  title: 'Create Price Alert',
                  primaryLabel: 'Create Alert',
                  dropsBelow: _dropsBelow,
                  oneTime: _oneTime,
                  targetController: _targetController,
                  onDropsBelowTap: () => setState(() => _dropsBelow = true),
                  onRiseAboveTap: () => setState(() => _dropsBelow = false),
                  onOneTimeTap: () => setState(() => _oneTime = true),
                  onRecurringTap: () => setState(() => _oneTime = false),
                  onPrimaryTap: () {},
                ),
                SizedBox(height: 14.h),
                const _SmartInsightsCard(),
                SizedBox(height: 16.h),
                Text(
                  'Your Active Alerts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                ),
                SizedBox(height: 10.h),
                _ActiveAlertCard(
                  onEdit: _openEditSheet,
                  onDelete: _openDeleteSheet,
                ),
              ],
            ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
        child: SafeArea(
          top: false,
          child: SizedBox(height: 40.h,
            child: ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE85A2C),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999.r),
                ),
              ),
              icon: Icon(Icons.add_circle_outline_rounded, size: 18.r),
              label: Text(
                'Create Alert',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertFormCard extends StatelessWidget {
  const _AlertFormCard({
    required this.title,
    required this.primaryLabel,
    required this.dropsBelow,
    required this.oneTime,
    required this.targetController,
    required this.onDropsBelowTap,
    required this.onRiseAboveTap,
    required this.onOneTimeTap,
    required this.onRecurringTap,
    required this.onPrimaryTap,
    this.showPrimaryButton = false,
  });

  final String title;
  final String primaryLabel;
  final bool dropsBelow;
  final bool oneTime;
  final TextEditingController targetController;
  final VoidCallback onDropsBelowTap;
  final VoidCallback onRiseAboveTap;
  final VoidCallback onOneTimeTap;
  final VoidCallback onRecurringTap;
  final VoidCallback onPrimaryTap;
  final bool showPrimaryButton;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE85A2C);
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.lightBorder.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.trim().isNotEmpty) ...[
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
            ),
            SizedBox(height: 12.h),
          ],
          Row(
            children: [
              Expanded(
                child: SizedBox(height: 44.h,
                  child: _AlertToggleButton(
                    selected: dropsBelow,
                    label: 'Price Drops Below',
                    icon: Icons.south_east_rounded,
                    onTap: onDropsBelowTap,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: SizedBox(height: 44.h,
                  child: _AlertToggleButton(
                    selected: !dropsBelow,
                    label: 'Price Rise Above',
                    icon: Icons.north_east_rounded,
                    onTap: onRiseAboveTap,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.lightBorder),
            ),
            child: Row(
              children: [
                Text(
                  '₹',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: TextField(
                    controller: targetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter target price',
                      border: InputBorder.none,
                      hintStyle:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.black.withOpacity(0.35),
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                  ),
                ),
                Text(
                  '/gm',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black.withOpacity(0.55),
                      ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "You'll receive a notification when the gold price reaches your selected target.",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black.withOpacity(0.55),
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 14.h),
          Text(
            'Alert Type',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _RadioOption(
                  selected: oneTime,
                  title: 'One Time Alert',
                  subtitle: 'Notify once when price\nreaches target',
                  onTap: onOneTimeTap,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: _RadioOption(
                  selected: !oneTime,
                  title: 'Recurring Alert',
                  subtitle: 'Notify each time price\nreaches target',
                  onTap: onRecurringTap,
                ),
              ),
            ],
          ),
          if (showPrimaryButton) ...[
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              height: 40.h,
              child: ElevatedButton(
                onPressed: onPrimaryTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                ),
                child: Text(
                  primaryLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AlertToggleButton extends StatelessWidget {
  const _AlertToggleButton({
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE85A2C);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF1EA) : Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: selected ? accent : AppColors.lightBorder.withOpacity(0.8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16.r,
              color: selected ? accent : Colors.black.withOpacity(0.7),
            ),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: selected ? accent : Colors.black.withOpacity(0.7),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioOption extends StatelessWidget {
  const _RadioOption({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE85A2C);
    return InkWell(
      onTap: onTap,
      child: SizedBox(height: 52.h,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black.withOpacity(0.55),
                          fontWeight: FontWeight.w600,
                          height: 1.25,
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

class _SmartInsightsCard extends StatelessWidget {
  const _SmartInsightsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF2),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE8C9A4)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline_rounded,
              color: const Color(0xFFC59B17), size: 22.r),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Insights',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFC59B17),
                      ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Gold prices dropped by 2.6% this week\nthis could be the good opportunity to invest',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withOpacity(0.7),
                        height: 1.3,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Image.asset(
            FileConstants.coinsDeck,
            width: 44.w,
            height: 44.w,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

class _ActiveAlertCard extends StatelessWidget {
  const _ActiveAlertCard({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE85A2C);
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.lightBorder.withOpacity(0.6)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.notifications_none_rounded, size: 20.r, color: accent),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notify when gold drops below 14,900/gm',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Created: today, 9:30AM',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.black.withOpacity(0.55),
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7EE),
                  borderRadius: BorderRadius.circular(999.r),
                ),
                child: Text(
                  'Active',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0B8A3B),
                      ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: accent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    minimumSize: Size.fromHeight(34.h),
                  ),
                  child: Text(
                    'Edit',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: accent,
                        ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: OutlinedButton(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: accent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    minimumSize: Size.fromHeight(34.h),
                  ),
                  child: Text(
                    'Delete',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: accent,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditAlertSheet extends StatefulWidget {
  const _EditAlertSheet({
    required this.dropsBelow,
    required this.oneTime,
    required this.targetController,
  });

  final bool dropsBelow;
  final bool oneTime;
  final TextEditingController targetController;

  @override
  State<_EditAlertSheet> createState() => _EditAlertSheetState();
}

class _EditAlertSheetState extends State<_EditAlertSheet> {
  late bool _dropsBelow = widget.dropsBelow;
  late bool _oneTime = widget.oneTime;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Edit Price Alert',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
            _AlertFormCard(
              title: '',
              primaryLabel: 'Update Alert',
              dropsBelow: _dropsBelow,
              oneTime: _oneTime,
              targetController: widget.targetController,
              onDropsBelowTap: () => setState(() => _dropsBelow = true),
              onRiseAboveTap: () => setState(() => _dropsBelow = false),
              onOneTimeTap: () => setState(() => _oneTime = true),
              onRecurringTap: () => setState(() => _oneTime = false),
              onPrimaryTap: () => Navigator.of(context).pop(),
              showPrimaryButton: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteAlertSheet extends StatelessWidget {
  const _DeleteAlertSheet();

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE85A2C);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Image.asset(
              FileConstants.goldDustbin,
              width: 64.w,
              height: 64.w,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 12.h),
            Text(
              'Delete this Alert',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Are you sure you want to delete this gold price alert ? you will\nno longer receive notifications for this alert.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withOpacity(0.55),
                    height: 1.35,
                  ),
            ),
            SizedBox(height: 14.h),
            const _ActiveAlertPreview(),
            SizedBox(height: 12.h),
            const _SmartInsightsCard(),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              height: 40.h,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB42318),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                ),
                child: Text(
                  'Delete Alert',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              height: 40.h,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: accent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: accent,
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

class _ActiveAlertPreview extends StatelessWidget {
  const _ActiveAlertPreview();

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE85A2C);
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.lightBorder.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_none_rounded, size: 20.r, color: accent),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notify when gold drops below 14,900/gm',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Created: today, 9:30AM',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withOpacity(0.55),
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7EE),
              borderRadius: BorderRadius.circular(999.r),
            ),
            child: Text(
              'Active',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0B8A3B),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
