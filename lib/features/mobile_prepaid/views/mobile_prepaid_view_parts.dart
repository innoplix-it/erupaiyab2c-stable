// ignore_for_file: deprecated_member_use, use_build_context_synchronously

part of 'mobile_prepaid_view.dart';

class _ContactsSection extends StatelessWidget {
  const _ContactsSection({
    required this.hasContactsPermission,
    required this.onRequestPermission,
    required this.recentPayments,
    required this.banners,
    required this.myNumberForApi,
    required this.contactsSectionKey,
    required this.isLoading,
    required this.contacts,
    required this.allContacts,
    required this.visibleCount,
    required this.contactSearchController,
    required this.manualNumberController,
    required this.numericFocusNode,
    required this.alphaFocusNode,
    required this.searchMode,
    required this.onSearchModeChange,
    required this.onQueryChange,
    required this.onReload,
    required this.onLoadMore,
    required this.onSelect,
    required this.onManualProceed,
    required this.onRepeatRecent,
    required this.onMyNumberRecharge,
    required this.onViewAllRecent,
  });

  final bool hasContactsPermission;
  final VoidCallback onRequestPermission;
  final AsyncValue<List<LatestTransaction>> recentPayments;
  // Kept so the parent can continue fetching banners without layout use.
  // ignore: unused_field
  final AsyncValue<List<BannerModel>> banners;
  final String myNumberForApi;
  final GlobalKey contactsSectionKey;
  final bool isLoading;
  final List<Contact> contacts;
  final List<Contact> allContacts;
  final int visibleCount;
  final TextEditingController contactSearchController;
  final TextEditingController manualNumberController;
  final FocusNode numericFocusNode;
  final FocusNode alphaFocusNode;
  final _MobilePrepaidSearchMode searchMode;
  final ValueChanged<_MobilePrepaidSearchMode> onSearchModeChange;
  final ValueChanged<String> onQueryChange;
  final VoidCallback onReload;
  final VoidCallback onLoadMore;
  final ValueChanged<String> onSelect;
  final Future<void> Function(String mobile) onManualProceed;
  final ValueChanged<LatestTransaction> onRepeatRecent;
  final ValueChanged<String> onMyNumberRecharge;
  final VoidCallback onViewAllRecent;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
          onLoadMore();
        }
        return false;
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          24.w,
          8.h,
          24.w,
          16.h + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          if (searchMode == _MobilePrepaidSearchMode.abc) ...[
            const _MobilePrepaidBanner(),
            SizedBox(height: 12.h),
          ],
          _MobilePrepaidSearchSwitcher(
            searchMode: searchMode,
            onSearchModeChange: onSearchModeChange,
            alphaController: contactSearchController,
            numericController: manualNumberController,
            numericFocusNode: numericFocusNode,
            alphaFocusNode: alphaFocusNode,
            onAlphaChanged: onQueryChange,
            contacts: allContacts,
            onProceed: onManualProceed,
          ),
          if (searchMode == _MobilePrepaidSearchMode.numeric) ...[
            SizedBox(height: 12.h),
            const _SectionHeader(
              title: 'My Contacts',
              specHeading: true,
            ),
            SizedBox(height: 10.h),
            if (!hasContactsPermission)
              ContactsPermissionCard(
                onAllow: onRequestPermission,
                outerPadding: EdgeInsets.zero,
              )
            else if (isLoading)
              Center(
                child: SpinKitCircle(
                  color: AppColors.primary,
                  size: 48.r,
                ),
              )
            else if (contacts.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Center(
                  child: Text(
                    'No contacts found',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary.withOpacity(0.6),
                        ),
                  ),
                ),
              )
            else ...[
              ContactsList(
                contacts: contacts,
                visibleCount: visibleCount,
                onSelect: onSelect,
                prepaidStyle: true,
              ),
              if (contacts.length > visibleCount) ...[
                SizedBox(height: 10.h),
                Center(
                  child: Text(
                    'Scroll to load more',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary.withOpacity(0.6),
                        ),
                  ),
                ),
              ],
            ],
          ] else ...[
            SizedBox(height: 16.h),
            _MyNumberSection(
              numberForApi: myNumberForApi,
              recentPayments: recentPayments,
              onSelect: onSelect,
              onRecharge: onMyNumberRecharge,
            ),
            SizedBox(height: 16.h),
            _RecentRechargesSection(
              recentPayments: recentPayments,
              onRepeatRecent: onRepeatRecent,
              onViewAllRecent: onViewAllRecent,
            ),
            SizedBox(height: 18.h),
            SizedBox(key: contactsSectionKey),
            const _SectionHeader(
              title: 'My Contacts',
              specHeading: true,
            ),
            SizedBox(height: 8.h),
            if (!hasContactsPermission)
              ContactsPermissionCard(
                onAllow: onRequestPermission,
                outerPadding: EdgeInsets.zero,
              )
            else if (isLoading)
              Center(
                child: SpinKitCircle(
                  color: AppColors.primary,
                  size: 48.r,
                ),
              )
            else if (contacts.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Center(
                  child: Text(
                    'No contacts found',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary.withOpacity(0.6),
                        ),
                  ),
                ),
              )
            else ...[
              ContactsList(
                contacts: contacts,
                visibleCount: visibleCount,
                onSelect: onSelect,
                prepaidStyle: true,
              ),
              if (contacts.length > visibleCount) ...[
                SizedBox(height: 10.h),
                Center(
                  child: Text(
                    'Scroll to load more',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary.withOpacity(0.6),
                        ),
                  ),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

class _MobilePrepaidBanner extends StatelessWidget {
  const _MobilePrepaidBanner();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 392.w),
        child: Container(
          width: double.infinity,
          height: 70.h,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFC7C7C7), width: 0.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Image.asset(
              FileConstants.mobileRecharge,
              width: double.infinity,
              height: 70.h,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
        ),
      ),
    );
  }
}

enum _MobilePrepaidSearchMode { abc, numeric }

class _MobilePrepaidSearchSwitcher extends StatelessWidget {
  const _MobilePrepaidSearchSwitcher({
    required this.searchMode,
    required this.onSearchModeChange,
    required this.alphaController,
    required this.numericController,
    required this.numericFocusNode,
    required this.alphaFocusNode,
    required this.onAlphaChanged,
    required this.contacts,
    required this.onProceed,
  });

  final _MobilePrepaidSearchMode searchMode;
  final ValueChanged<_MobilePrepaidSearchMode> onSearchModeChange;
  final TextEditingController alphaController;
  final TextEditingController numericController;
  final FocusNode numericFocusNode;
  final FocusNode alphaFocusNode;
  final ValueChanged<String> onAlphaChanged;
  final List<Contact> contacts;
  final Future<void> Function(String mobile) onProceed;

  @override
  Widget build(BuildContext context) {
    final isNumeric = searchMode == _MobilePrepaidSearchMode.numeric;

    return Column(
      children: [
        AppSearchBar(
          hintText:
              isNumeric ? 'Enter mobile number' : 'Search by number or name',
          controller: isNumeric ? numericController : alphaController,
          focusNode: isNumeric ? numericFocusNode : alphaFocusNode,
          autofocus: true,
          keyboardType: isNumeric ? TextInputType.phone : TextInputType.text,
          textInputAction:
              isNumeric ? TextInputAction.done : TextInputAction.search,
          inputFormatters: isNumeric
              ? [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ]
              : const [],
          onChanged: isNumeric ? null : onAlphaChanged,
          prefixText: isNumeric ? '+91 ' : null,
          prefixStyle: GoogleFonts.plusJakartaSans(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 14.sp,
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w400,
            fontSize: 14.sp,
          ),
          trailing: _SearchModeToggle(
            mode: searchMode,
            onChanged: onSearchModeChange,
          ),
        ),
        if (isNumeric)
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: numericController,
            builder: (context, value, _) {
              final numericDigits = _normalizeMobile(value.text);
              final isEnabled = numericDigits.length == 10;
              return Column(
                children: [
                  SizedBox(height: 14.h),
                  SizedBox(
                    width: double.infinity,
                    height: 46.h,
                    child: ElevatedButton(
                      onPressed:
                          isEnabled ? () => onProceed(numericDigits) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withOpacity(0.35),
                        disabledForegroundColor: Colors.white.withOpacity(0.9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Proceed',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _SearchModeToggle extends StatelessWidget {
  const _SearchModeToggle({
    required this.mode,
    required this.onChanged,
  });

  final _MobilePrepaidSearchMode mode;
  final ValueChanged<_MobilePrepaidSearchMode> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip({
      required String label,
      required _MobilePrepaidSearchMode value,
    }) {
      final active = mode == value;
      return InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(90.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 36.w,
          height: 16.h,
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? const Color(0xFFDD5428) : Colors.transparent,
            borderRadius: BorderRadius.circular(90.r),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color:
                    active ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
                fontWeight: FontWeight.w500,
                fontSize: 10.sp,
                height: 1.0,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0x21DD5428),
          borderRadius: BorderRadius.circular(90.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            chip(label: 'ABC', value: _MobilePrepaidSearchMode.abc),
            chip(label: '123', value: _MobilePrepaidSearchMode.numeric),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionText,
    this.onAction,
    this.specHeading = false,
  });

  final String title;
  final String? actionText;
  final VoidCallback? onAction;
  final bool specHeading;

  @override
  Widget build(BuildContext context) {
    final titleText = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
        fontSize: 14.sp,
        height: 1.0,
        letterSpacing: -0.02 * 14.sp,
        color: const Color(0xFF292D32),
      ),
    );
    return Row(
      children: [
        Expanded(child: titleText),
        if (actionText != null && onAction != null)
          InkWell(
            onTap: onAction,
            child: Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: Text(
                actionText!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFFDD5428),
                  fontWeight: FontWeight.w500,
                  fontSize: 14.sp,
                  height: 1.0,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LastOnLabel extends StatelessWidget {
  const _LastOnLabel(
    this.lastOn, {
    this.fontSize,
    this.color,
  });

  final String lastOn;
  final double? fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final trimmed = lastOn.trim();
    final text = trimmed.toLowerCase().startsWith('last on')
        ? trimmed
        : 'Last on - $trimmed';
    final resolvedSize = fontSize ?? 12.sp;
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.plusJakartaSans(
        fontSize: resolvedSize,
        fontWeight: FontWeight.w400,
        height: 1.0,
        letterSpacing: -0.02 * resolvedSize,
        color: color ?? const Color(0xFF7C7C7C),
      ),
    );
  }
}

class _ExpiryPill extends StatelessWidget {
  const _ExpiryPill(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return _MyNumberDueBadge(label);
  }
}

class _MyNumberDueBadge extends StatelessWidget {
  const _MyNumberDueBadge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final words = label.trim().split(RegExp(r'\s+'));
    final display = words
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
    return Container(
      height: 14.h,
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF801900),
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(8.r),
        ),
      ),
      child: Text(
        display,
        maxLines: 1,
        softWrap: false,
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 8.sp,
          height: 1,
          letterSpacing: -0.02 * 8.sp,
        ),
      ),
    );
  }
}

class _RechargePillButton extends StatelessWidget {
  const _RechargePillButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78.5.w,
      height: 22.r,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDD5428),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(23.r),
          ),
          visualDensity: VisualDensity.compact,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Recharge',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              height: 1.0,
              letterSpacing: 0,
              color: const Color(0xFFFFFFFF),
            ),
          ),
        ),
      ),
    );
  }
}

class _RepeatPillButton extends StatelessWidget {
  const _RepeatPillButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 65.5.w,
      height: 22.r,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDD5428),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(23.r),
          ),
          visualDensity: VisualDensity.compact,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Repeat',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              height: 1.0,
              letterSpacing: 0,
              color: const Color(0xFFFFFFFF),
            ),
          ),
        ),
      ),
    );
  }
}

class _MyNumberCard extends StatelessWidget {
  const _MyNumberCard({
    required this.dueLabel,
    required this.operatorLabel,
    this.operatorIconUrl,
    required this.mobile,
    required this.lastOn,
    required this.onRecharge,
  });

  final String? dueLabel;
  final String operatorLabel;
  final String? operatorIconUrl;
  final String mobile;
  final String lastOn;
  final VoidCallback onRecharge;

  @override
  Widget build(BuildContext context) {
    final hasDue = (dueLabel ?? '').trim().isNotEmpty;
    final radius = 16.r;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                12.w,
                hasDue ? 20.h : 12.h,
                12.w,
                10.h,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _OperatorBrandLogo(
                    operatorLabel: operatorLabel,
                    operatorIconUrl: operatorIconUrl,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          mobile,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                            height: 1.1,
                            letterSpacing: -0.02 * 14.sp,
                            color: const Color(0xFF000000),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        _LastOnLabel(
                          lastOn,
                          fontSize: 10.sp,
                          color: const Color(0xFF7C7C7C),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  _RechargePillButton(
                    onPressed: onRecharge,
                  ),
                ],
              ),
            ),
            if (hasDue)
              Positioned(
                top: 0,
                left: 0,
                child: _MyNumberDueBadge(dueLabel!.trim()),
              ),
          ],
        ),
      ),
    );
  }
}

class _OperatorBrandLogo extends StatelessWidget {
  const _OperatorBrandLogo({
    required this.operatorLabel,
    required this.operatorIconUrl,
  });

  final String operatorLabel;
  final String? operatorIconUrl;

  @override
  Widget build(BuildContext context) {
    return _OperatorIconBadge(
      label: operatorLabel,
      iconUrl: operatorIconUrl,
    );
  }
}

class _RecentRechargeRow extends StatelessWidget {
  const _RecentRechargeRow({
    required this.recentPayments,
    required this.onRepeat,
  });

  final AsyncValue<List<LatestTransaction>> recentPayments;
  final ValueChanged<LatestTransaction> onRepeat;

  @override
  Widget build(BuildContext context) {
    Widget buildScroller(Widget child) {
      return SizedBox(
        height: 76.h,
        child: child,
      );
    }

    return recentPayments.when(
      loading: () => buildScroller(
        ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: EdgeInsets.symmetric(vertical: 2.h),
          itemBuilder: (_, __) =>
              const MobilePrepaidRecentRechargeCardShimmer(),
          separatorBuilder: (_, __) => SizedBox(width: 12.w),
          itemCount: 2,
        ),
      ),
      error: (_, __) => Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Center(
          child: Text(
            'Unable to load recents',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary.withOpacity(0.5),
            ),
          ),
        ),
      ),
      data: (items) {
        final display = items.take(10).toList();
        if (display.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Center(
              child: Text(
                'No recent recharges',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary.withOpacity(0.5),
                ),
              ),
            ),
          );
        }
        return buildScroller(
          ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: EdgeInsets.symmetric(vertical: 2.h),
            itemBuilder: (context, index) => _RecentRechargeCard(
              title: display[index].billerName.trim().isNotEmpty
                  ? display[index].billerName
                  : display[index].serviceNo,
              iconUrl: display[index].icon,
              mobile: display[index].serviceNo,
              amount: display[index].amount,
              lastOn:
                  (display[index].transactionTime?.trim().isNotEmpty ?? false)
                      ? _recentRechargeDateOnly(
                          display[index].transactionTime,
                        )
                      : '--',
              badgeLabel: _expiresInDaysLabel(
                days:
                    _kPrepaidDaysPlaceholder, // later: display[index].daysLeft
              ),
              onRepeat: () => onRepeat(display[index]),
            ),
            separatorBuilder: (_, __) => SizedBox(width: 10.w),
            itemCount: display.length,
          ),
        );
      },
    );
  }
}

String? _resolveDueOrExpiryLabel({
  required String? dueDate,
  required String? expiresAt,
  int? daysLeft,
}) {
  DateTime? parse(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty || value.toLowerCase() == 'null') return null;
    return DateTime.tryParse(value);
  }

  final due = parse(dueDate);
  final exp = parse(expiresAt);
  final hasDueText = (dueDate ?? '').trim().isNotEmpty &&
      (dueDate ?? '').trim().toLowerCase() != 'null';
  final useDue = due != null || (hasDueText && exp == null);

  if (daysLeft != null) {
    if (daysLeft <= 0) return useDue ? 'Due Today' : 'Expires Today';
    if (daysLeft == 1) return useDue ? 'Due In 1 Day' : 'Expires In 1 Day';
    return useDue ? 'Due In $daysLeft Days' : 'Expires In $daysLeft Days';
  }

  final target = due ?? exp;
  if (target == null) return null;

  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final days = target.difference(startOfToday).inDays;
  if (days <= 0) return (due != null) ? 'Due Today' : 'Expires Today';
  if (days == 1) return (due != null) ? 'Due In 1 Day' : 'Expires In 1 Day';
  return (due != null) ? 'Due In $days Days' : 'Expires In $days Days';
}

/// Temporary static days-left. Pass [days] from API (`days_left`) later.
const int _kPrepaidDaysPlaceholder = 0;

String _duesInDaysLabel({int? days}) =>
    'Dues in ${days ?? _kPrepaidDaysPlaceholder} days';

String _expiresInDaysLabel({int? days}) =>
    'Expires in ${days ?? _kPrepaidDaysPlaceholder} days';

String _recentRechargeDateOnly(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return '--';
  final commaIndex = value.indexOf(',');
  if (commaIndex <= 0) return value;
  return value.substring(0, commaIndex).trim();
}

class _RecentRechargeCard extends StatelessWidget {
  const _RecentRechargeCard({
    required this.title,
    required this.iconUrl,
    required this.mobile,
    required this.amount,
    required this.lastOn,
    required this.badgeLabel,
    required this.onRepeat,
  });

  final String title;
  final String iconUrl;
  final String mobile;
  final num amount;
  final String lastOn;
  final String? badgeLabel;
  final VoidCallback onRepeat;

  @override
  Widget build(BuildContext context) {
    final showBadge = (badgeLabel ?? '').trim().isNotEmpty;
    final radius = 16.r;
    final availableWidth = MediaQuery.sizeOf(context).width - 48.w;
    final cardWidth = 323.w > availableWidth ? availableWidth : 323.w;
    final name = title.trim();
    final number = mobile.trim();
    final showNumber = number.isNotEmpty && number != name;
    return SizedBox(
      width: cardWidth,
      child: Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: cardWidth,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x1AC7C7C7),
                  offset: Offset(0, 9.h),
                  blurRadius: 20.r,
                ),
                BoxShadow(
                  color: const Color(0x17C7C7C7),
                  offset: Offset(0, 36.h),
                  blurRadius: 36.r,
                ),
                BoxShadow(
                  color: const Color(0x0DC7C7C7),
                  offset: Offset(0, 80.h),
                  blurRadius: 48.r,
                ),
                BoxShadow(
                  color: const Color(0x03C7C7C7),
                  offset: Offset(0, 143.h),
                  blurRadius: 57.r,
                ),
                BoxShadow(
                  color: const Color(0x00C7C7C7),
                  offset: Offset(0, 223.h),
                  blurRadius: 62.r,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16.w,
                      showBadge ? 20.h : 13.h,
                      16.w,
                      8.h,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _OperatorIconBadge(
                          label: title,
                          iconUrl: iconUrl,
                        ),
                        SizedBox(width: 13.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                name.isEmpty ? number : name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF000000),
                                  height: 1.1,
                                  letterSpacing: -0.02 * 13.sp,
                                ),
                              ),
                              if (showNumber) ...[
                                SizedBox(height: 4.h),
                                Text(
                                  number,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF000000),
                                    height: 1.1,
                                    letterSpacing: -0.02 * 11.sp,
                                  ),
                                ),
                              ],
                              SizedBox(height: 4.h),
                              _LastOnLabel(
                                lastOn,
                                fontSize: 10.sp,
                                color: const Color(0xFF7C7C7C),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        _RepeatPillButton(
                          onPressed: onRepeat,
                        ),
                      ],
                    ),
                  ),
                  if (showBadge)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: _ExpiryPill(badgeLabel!.trim()),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OperatorIconBadge extends StatelessWidget {
  const _OperatorIconBadge({
    required this.label,
    required this.iconUrl,
  });

  final String label;
  final String? iconUrl;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        width: 40.w,
        height: 40.w,
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: const Color(0xFFE2E2E2),
            width: 0.5,
          ),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: LeadingIcon(
              asset: null,
              url: iconUrl,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanSection extends HookWidget {
  const _PlanSection({
    required this.state,
    required this.controller,
    required this.planSearchController,
    required this.onPlanSearchChanged,
  });

  final MobilePrepaidState state;
  final MobilePrepaidController controller;
  final TextEditingController planSearchController;
  final ValueChanged<String> onPlanSearchChanged;

  @override
  Widget build(BuildContext context) {
    const suggestedGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFFDBCF),
        Colors.white,
        Color(0xFFFFDBCF),
      ],
      stops: [0.0, 0.5, 1.0],
    );

    const allFilterLabel = 'All';
    final quickFilters = state.filterTags
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e != allFilterLabel)
        .toList();
    final applied = state.appliedFilters.map((e) => e.trim()).toSet();
    final isAllSelected = applied.isEmpty || applied.contains(allFilterLabel);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
          controller.loadNextPlansPage();
        }
        return false;
      },
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          0.w,
          0.h,
          0.w,
          24.h + MediaQuery.of(context).viewPadding.bottom,
        ),
        children: [
          // Suggested plans block should be at the top (edge-to-edge gradient).
          if (!state.isFetching && state.currentPlans.isNotEmpty)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(gradient: suggestedGradient),
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suggested Plans',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 18.sp,
                      color: Colors.black,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  _SuggestedPlanCards(
                    plans: state.currentPlans,
                    onSelect: controller.selectPlan,
                  ),
                ],
              ),
            ),

          // Search field — unified AppSearchBar (same as Transaction History)
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0.h),
            child: AppSearchBar(
              hintText: 'Search a plan, eg 299, 5g,etc.',
              controller: planSearchController,
              onChanged: onPlanSearchChanged,
              textStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
                color: Colors.black,
              ),
            ),
          ),

          // Filters row
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0.h),
            child: SizedBox(
              height: 34.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 1 + quickFilters.length,
                separatorBuilder: (_, __) => SizedBox(width: 8.w),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _PlanFilterChip(
                      label: 'Filter',
                      selected: false,
                      icon: Icons.tune_rounded,
                      onTap: () => KDialog.instance.openSheet(
                        dialog: FilterPlansSheet(
                          validityOptions: state.validityFilters,
                          dataOptions: state.dataFilters,
                          initialValiditySelected: applied
                              .where((t) => t != allFilterLabel)
                              .where((t) => state.validityFilters.contains(t))
                              .toSet(),
                          initialDataSelected: applied
                              .where((t) => t != allFilterLabel)
                              .where((t) => state.dataFilters.contains(t))
                              .toSet(),
                          onApply: (validity, data) async {
                            final selected = <String>[
                              ...validity,
                              ...data,
                            ];
                            final info = state.operatorInfo;
                            if (info == null) return;
                            await controller.fetchPlansForSelection(
                              mobileInput: state.mobile,
                              operatorName: info.operatorName,
                              circleName: info.circle,
                              circleCode: info.circleCode,
                              iconUrl: info.iconUrl,
                              search: state.planSearchQuery,
                              filters: selected,
                            );
                          },
                        ),
                      ),
                    );
                  }
                  final label = quickFilters[index - 1];
                  final isSelected = applied.contains(label) && !isAllSelected;
                  return _PlanFilterChip(
                    label: label,
                    selected: isSelected,
                    onTap: () async {
                      final info = state.operatorInfo;
                      if (info == null) return;
                      await controller.fetchPlansForSelection(
                        mobileInput: state.mobile,
                        operatorName: info.operatorName,
                        circleName: info.circle,
                        circleCode: info.circleCode,
                        iconUrl: info.iconUrl,
                        search: state.planSearchQuery,
                        filters: isSelected ? const [] : [label],
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // Categories + plan list content
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0.h),
            child: _CategoryTabs(
              categories: state.categories,
              selected: state.selectedCategory,
              onSelected: controller.selectCategory,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0.h),
            child: Builder(
              builder: (context) {
                if (state.isFetching && state.currentPlans.isEmpty) {
                  return Center(
                    child: SpinKitCircle(
                      color: AppColors.primary,
                      size: 48.r,
                    ),
                  );
                }
                if (state.visiblePlans.isEmpty) {
                  return _EmptyPlansState(query: state.planSearchQuery);
                }
                return _PlanList(
                  plans: state.visiblePlans,
                  selectedPlan: state.selectedPlan,
                  onSelect: controller.selectPlan,
                  onPayNow: (plan) => KDialog.instance.openSheet(
                    dialog: PrepaidPaymentBottomSheet(
                      plan: plan,
                      billerName:
                          state.operatorInfo?.operatorName ?? 'Mobile Prepaid',
                      ecoinsRestrictionsPercent:
                          state.ecoinsRestrictionsPercent,
                    ),
                  ),
                );
              },
            ),
          ),
          if (state.isFetchingMorePlans)
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0.h),
              child: Center(
                child: SpinKitCircle(
                  color: AppColors.primary,
                  size: 28.r,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PayNowSection extends StatelessWidget {
  const _PayNowSection({
    required this.state,
    required this.controller,
  });

  final MobilePrepaidState state;
  final MobilePrepaidController controller;

  @override
  Widget build(BuildContext context) {
    final plan = state.selectedPlan;
    if (plan == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 8.h),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.lightBorder,
                  width: 1.w,
                ),
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 10.h, left: 16.w),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 81.w,
                          height: 40.h,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '₹ ${plan.amount}',
                                maxLines: 1,
                                overflow: TextOverflow.visible,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 40.sp,
                                  height: 40.h / 40,
                                  color: const Color(0xFF000000),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        GetAssuredCoinsBadge(
                          label: plan.assuredBadgeLabel,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 2.h, 14.w, 12.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PlanInfoRow(
                          plan: plan,
                          onBenefitsTap: () => KDialog.instance.openSheet(
                            dialog: PlanDetailsSheet(
                              plan: plan,
                              onProceedToPay: () => KDialog.instance.openSheet(
                                dialog: PrepaidPaymentBottomSheet(
                                  plan: plan,
                                  billerName:
                                      state.operatorInfo?.operatorName ??
                                          'Mobile Prepaid',
                                  ecoinsRestrictionsPercent:
                                      state.ecoinsRestrictionsPercent,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        const PlanValidityDivider(),
                        SizedBox(height: 8.h),
                        Text(
                          plan.description.isEmpty
                              ? 'No description available.'
                              : plan.description,
                          maxLines: 10,
                          overflow: TextOverflow.visible,
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF222222),
                            height: 1.4,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: GestureDetector(
                                  onTap: () => KDialog.instance.openSheet(
                                    dialog: PlanDetailsSheet(
                                      plan: plan,
                                      onProceedToPay: () =>
                                          KDialog.instance.openSheet(
                                        dialog: PrepaidPaymentBottomSheet(
                                          plan: plan,
                                          billerName: state
                                                  .operatorInfo?.operatorName ??
                                              'Mobile Prepaid',
                                          ecoinsRestrictionsPercent:
                                              state.ecoinsRestrictionsPercent,
                                        ),
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    plan.planName.trim().isNotEmpty
                                        ? plan.planName
                                        : 'Entertainment',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.sp,
                                      height: 17.h / 14,
                                      color: const Color(0xFFDD5428),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            GestureDetector(
                              onTap: () => controller.deselectPlan(),
                              child: Container(
                                width: 124.w,
                                height: 32.h,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 0,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF084591),
                                  borderRadius: BorderRadius.circular(23.r),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Change Plan',
                                          maxLines: 1,
                                          style: GoogleFonts.plusJakartaSans(
                                            color: const Color(0xFFFFFFFF),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12.sp,
                                            height: 1,
                                            letterSpacing: 0,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 6.w),
                                    SvgPicture.string(
                                      '<svg width="14" height="14" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M1.65381 13.2699L1.59698 13.2077L1.44639 14.3515C1.43521 14.4399 1.40535 14.5253 1.35852 14.6029C1.3117 14.6805 1.24885 14.7486 1.17361 14.8034C1.06022 14.8883 0.92211 14.9395 0.777168 14.9504C0.632226 14.9612 0.487134 14.9312 0.360688 14.8642C0.234242 14.7972 0.132269 14.6964 0.0679792 14.5747C0.00368921 14.453 -0.019955 14.3162 0.000109539 14.1818L0.396487 11.2196V11.2103C0.399034 11.192 0.40283 11.1738 0.407852 11.156C0.429734 11.0697 0.469624 10.9883 0.525244 10.9164C0.580864 10.8446 0.651122 10.7836 0.732003 10.7371C0.812883 10.6906 0.902801 10.6594 0.996614 10.6453C1.09043 10.6312 1.1863 10.6345 1.27875 10.655C2.34143 10.8785 3.40318 11.106 4.46397 11.3375C4.55658 11.3567 4.64414 11.3929 4.72149 11.4441C4.79884 11.4954 4.86441 11.5605 4.91434 11.6358C5.015 11.7877 5.04765 11.9705 5.00526 12.1447C4.98457 12.2309 4.94564 12.3123 4.89074 12.3842C4.83585 12.4561 4.7661 12.5171 4.6856 12.5635C4.52362 12.6584 4.32792 12.6893 4.14147 12.6497C3.67122 12.5503 3.20096 12.4482 2.73213 12.3475C2.85932 12.4863 2.99399 12.619 3.13561 12.7451C4.15727 13.6765 5.45575 14.2995 6.86212 14.533C7.55227 14.6468 8.25694 14.662 8.95198 14.5781C9.63975 14.4984 10.3102 14.32 10.9396 14.0493C11.1782 13.9441 11.407 13.8319 11.6258 13.7126C11.8474 13.5894 12.0619 13.4582 12.2665 13.315C12.7134 13.0115 13.1215 12.661 13.4826 12.2706C13.8366 11.8876 14.1412 11.4672 14.3905 11.0181L14.47 10.8723L15.8907 11.2289L15.7771 11.4489C15.4767 12.031 15.0996 12.576 14.6547 13.0711C14.2026 13.5736 13.6869 14.0231 13.1189 14.4098C12.8802 14.5728 12.6274 14.7279 12.3631 14.8737C12.0988 15.0195 11.8332 15.148 11.5476 15.2713C10.7837 15.6063 9.96911 15.8298 9.13241 15.934C8.29203 16.0369 7.43971 16.0195 6.60498 15.8823C4.91117 15.6012 3.34759 14.8501 2.11838 13.7272C1.9479 13.5735 1.7973 13.421 1.65807 13.2699H1.65381ZM14.3492 2.73052L14.4061 2.79281L14.5481 1.64901C14.5581 1.55942 14.5872 1.47259 14.6336 1.39361C14.68 1.31462 14.7429 1.24507 14.8184 1.18901C14.894 1.13296 14.9808 1.09153 15.0738 1.06716C15.1667 1.04278 15.2639 1.03595 15.3597 1.04705C15.4556 1.05816 15.548 1.08699 15.6318 1.13184C15.7155 1.1767 15.7888 1.23668 15.8474 1.30829C15.9059 1.37989 15.9486 1.46168 15.9729 1.54886C15.9972 1.63604 16.0026 1.72686 15.9887 1.816L15.5995 4.78088V4.79016C15.5995 4.80739 15.5995 4.82594 15.5895 4.8445C15.5453 5.01729 15.4297 5.16681 15.268 5.26061C15.1063 5.35441 14.9114 5.38491 14.7257 5.34549C13.6645 5.1215 12.5947 4.89486 11.5405 4.66292C11.4482 4.64362 11.3609 4.6073 11.2838 4.55609C11.2067 4.50488 11.1413 4.43981 11.0916 4.36471C10.9898 4.21314 10.9566 4.03013 10.9992 3.85576C11.0199 3.76961 11.0588 3.68818 11.1137 3.61626C11.1686 3.54433 11.2384 3.48337 11.3189 3.43694C11.4814 3.34203 11.6775 3.31105 11.8644 3.35079C12.3347 3.4502 12.8035 3.55225 13.2738 3.65298C13.1544 3.52044 13.0223 3.38791 12.8703 3.24874C12.3611 2.78483 11.7802 2.3948 11.147 2.09168C10.5178 1.7876 9.84287 1.57401 9.1452 1.45815C8.45553 1.3444 7.75133 1.32921 7.05676 1.41309C6.36761 1.4971 5.69662 1.68041 5.06777 1.95649C4.82815 2.06076 4.59941 2.17297 4.38157 2.29314C4.15852 2.4164 3.94541 2.54761 3.73941 2.69075C3.29263 2.99395 2.88501 3.34442 2.52471 3.73516C2.1698 4.1175 1.86504 4.53796 1.61687 4.98764L1.53589 5.13343L0.108083 4.7716L0.22174 4.55159C0.522458 3.96959 0.89946 3.42467 1.3441 2.92932C1.79655 2.4272 2.3122 1.97775 2.87988 1.59069C3.12046 1.42722 3.37239 1.2726 3.6357 1.1268C3.89285 0.986315 4.16562 0.852451 4.45118 0.729191C5.21512 0.394191 6.02969 0.170686 6.86639 0.0665001C7.70864 -0.037023 8.56291 -0.0195909 9.39951 0.11819C10.241 0.256961 11.0553 0.513439 11.8147 0.878959C12.5764 1.2446 13.2751 1.71458 13.8875 2.27326C14.0566 2.427 14.2086 2.57942 14.3478 2.73052H14.3492Z" fill="white"/></svg>',
                                      width: 14.w,
                                      height: 14.w,
                                      fit: BoxFit.contain,
                                    ),
                                  ],
                                ),
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
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            16.w,
            8.h,
            16.w,
            14.h + MediaQuery.of(context).viewPadding.bottom,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 44.h,
            child: ElevatedButton(
              onPressed: state.isRecharging
                  ? null
                  : () => KDialog.instance.openSheet(
                        dialog: PrepaidPaymentBottomSheet(
                          plan: plan,
                          billerName: state.operatorInfo?.operatorName ??
                              'Mobile Prepaid',
                          ecoinsRestrictionsPercent:
                              state.ecoinsRestrictionsPercent,
                        ),
                      ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDD5428),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: 12.h,
                  horizontal: 8.w,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(86.r),
                ),
                elevation: 0,
              ),
              child: state.isRecharging
                  ? SizedBox(
                      height: 20.r,
                      width: 20.r,
                      child: SpinKitCircle(
                        color: Colors.white,
                        size: 20.r,
                      ),
                    )
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Proceed to Pay',
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.sp,
                          height: 1,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _openOperatorSheet(
  WidgetRef ref, {
  required String mobile,
  required Future<void> Function(OperatorOption operator, RegionOption region)
      onSelected,
}) async {
  final metaController = ref.read(prepaidMetaControllerProvider.notifier);
  KDialog.instance.openDialog(
    dialog: const ScreenWrapper(
      isFetching: true,
      isEmpty: false,
      emptyMessage: '',
      child: SizedBox.shrink(),
    ),
    barrierDismissible: false,
  );
  await metaController.loadOperatorsIfNeeded();
  final currentContext = navigatorKey.currentContext;
  if (currentContext == null) return;
  Navigator.of(currentContext).pop();
  KDialog.instance.openConstraintsSheet(
    dialog: _OperatorSelectSheet(
      onSelected: (operator) async {
        KDialog.instance.openDialog(
          dialog: const ScreenWrapper(
            isFetching: true,
            isEmpty: false,
            emptyMessage: '',
            child: SizedBox.shrink(),
          ),
          barrierDismissible: false,
        );
        await metaController.loadRegionsIfNeeded();
        final regionContext = navigatorKey.currentContext;
        if (regionContext == null) return;
        Navigator.of(regionContext).pop();
        KDialog.instance.openConstraintsSheet(
          dialog: _RegionSelectSheet(
            onSelected: (region) async {
              if (mobile.trim().isEmpty) return;
              await onSelected(operator, region);
            },
          ),
          maxHeight: 0.65.sh,
        );
      },
    ),
    maxHeight: 0.6.sh,
  );
}

class _OperatorSelectSheet extends ConsumerWidget {
  const _OperatorSelectSheet({required this.onSelected});

  final ValueChanged<OperatorOption> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = ref.watch(prepaidMetaControllerProvider);
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Select Operator',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Divider(color: AppColors.lightBorder.withOpacity(0.7)),
          if (meta.isLoadingOperators)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: SpinKitCircle(
                color: AppColors.primary,
                size: 48.r,
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: meta.operators.length,
                itemBuilder: (_, index) {
                  final item = meta.operators[index];
                  return InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelected(item);
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 6.h),
                      child: Row(
                        children: [
                          _OperatorLogo(iconUrl: item.iconUrl),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              item.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          Transform.rotate(
                            angle: -0.65,
                            child: Icon(
                              Icons.arrow_forward,
                              size: 20.r,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _RegionSelectSheet extends ConsumerStatefulWidget {
  const _RegionSelectSheet({required this.onSelected});

  final ValueChanged<RegionOption> onSelected;

  @override
  ConsumerState<_RegionSelectSheet> createState() => _RegionSelectSheetState();
}

class _RegionSelectSheetState extends ConsumerState<_RegionSelectSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meta = ref.watch(prepaidMetaControllerProvider);
    final query = _searchController.text.trim().toLowerCase();
    final regions = query.isEmpty
        ? meta.regions
        : meta.regions
            .where((r) => r.name.toLowerCase().contains(query))
            .toList();

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Select Your Circle',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Divider(color: AppColors.lightBorder.withOpacity(0.7)),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search region',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            ),
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: 8.h),
          if (meta.isLoadingRegions)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: SpinKitCircle(
                color: AppColors.primary,
                size: 48.r,
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: regions.length,
                separatorBuilder: (_, __) => Divider(
                  color: AppColors.lightBorder.withOpacity(0.7),
                  height: 1,
                ),
                itemBuilder: (_, index) {
                  final item = regions[index];
                  return ListTile(
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onSelected(item);
                    },
                    title: Text(
                      item.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    trailing: const Icon(Icons.arrow_forward),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _OperatorLogo extends StatelessWidget {
  const _OperatorLogo({required this.iconUrl});

  final String iconUrl;

  @override
  Widget build(BuildContext context) {
    if (iconUrl.isEmpty) {
      return Container(
        padding: EdgeInsets.all(4.r),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: CircleAvatar(
          radius: 20.r,
          backgroundColor: AppColors.primary.withOpacity(0.08),
          child: Icon(
            Icons.sim_card,
            color: AppColors.primary,
            size: 20.r,
          ),
        ),
      );
    }
    final isSvg = iconUrl.toLowerCase().endsWith('.svg');
    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: CircleAvatar(
        radius: 20.r,
        backgroundColor: Colors.white,
        child: isSvg
            ? SvgPicture.network(
                iconUrl,
                width: 24.r,
                height: 24.r,
                fit: BoxFit.contain,
                placeholderBuilder: (_) => _logoPlaceholder(),
              )
            : Image.network(
                iconUrl,
                width: 24.r,
                height: 24.r,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _logoPlaceholder(),
              ),
      ),
    );
  }

  Widget _logoPlaceholder() {
    return Icon(
      Icons.sim_card,
      size: 20.r,
      color: AppColors.primary,
    );
  }
}

class _PlanFilterChip extends StatelessWidget {
  const _PlanFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isFilter = icon != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        height: isFilter ? 32.h : 34.h,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isFilter
              ? const Color(0xFFE5E5E5)
              : selected
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: selected && !isFilter
                ? AppColors.primary.withOpacity(0.35)
                : const Color(0xFFD8D8D8),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 11.sp,
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            if (icon != null) ...[
              SizedBox(width: 4.w),
              Icon(icon, size: 14.r, color: AppColors.textPrimary),
            ],
          ],
        ),
      ),
    );
  }
}

class _SuggestedPlanCards extends StatelessWidget {
  const _SuggestedPlanCards({
    required this.plans,
    required this.onSelect,
  });

  final List<PlanItem> plans;
  final ValueChanged<PlanItem> onSelect;

  @override
  Widget build(BuildContext context) {
    final displayPlans = plans.take(5).toList();
    return SizedBox(
      height: 95.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: displayPlans.length,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (context, index) {
          final plan = displayPlans[index];
          return _SuggestedPlanCard(
            plan: plan,
            onTap: () => onSelect(plan),
          );
        },
      ),
    );
  }
}

class _SuggestedPlanCard extends StatelessWidget {
  const _SuggestedPlanCard({
    required this.plan,
    required this.onTap,
  });

  final PlanItem plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final validity = plan.validity.trim();
    final description = plan.description.trim();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 256.w,
        height: 95.h,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(26, 130, 128, 128),
              blurRadius: 3.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 6.h, 40.w, 6.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 71.w,
                    height: 29.h,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '₹ ${plan.amount}'.toUpperCase(),
                          maxLines: 1,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 24.sp,
                            color: Colors.black,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (validity.isNotEmpty) ...[
                    SizedBox(height: 1.h),
                    SizedBox(
                      width: 180.w,
                      height: 14.h,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Validity: $validity',
                          textAlign: TextAlign.left,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.sp,
                            color: const Color(0xFF222222),
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (description.isNotEmpty)
                    ConstrainedBox(
                      constraints: BoxConstraints(minHeight: 15.h),
                      child: Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w400,
                          fontSize: 12.sp,
                          height: 15 / 12,
                          color: const Color(0xFF222222),
                        ),
                      ),
                    ),
                  SizedBox(height: 4.h),
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: 15.h),
                    child: GestureDetector(
                      onTap: onTap,
                      child: Text(
                        'Details',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFFDD5428),
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                          height: 15 / 12,
                          decoration: TextDecoration.underline,
                          decorationColor: const Color(0xFFDD5428),
                          decorationStyle: TextDecorationStyle.solid,
                          decorationThickness: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 12.w,
              top: 12.h,
              child: IgnorePointer(
                child: Container(
                  width: 24.r,
                  height: 24.r,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFF835C),
                        Color(0xFFDD5428),
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 16.sp,
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

class _MyNumberSection extends ConsumerWidget {
  const _MyNumberSection({
    required this.numberForApi,
    required this.recentPayments,
    required this.onSelect,
    required this.onRecharge,
  });

  final String numberForApi;
  final AsyncValue<List<LatestTransaction>> recentPayments;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onRecharge;

  // Kept for mapping recents `days_left` into `_duesInDaysLabel(days: ...)` later.
  // ignore: unused_element
  String? _dueFromRecents(String mobile) {
    final items = recentPayments.asData?.value ?? const <LatestTransaction>[];
    final digits = mobile.replaceAll(RegExp(r'\D'), '');
    final mobileTail =
        digits.length > 10 ? digits.substring(digits.length - 10) : digits;
    for (final item in items) {
      final service =
          (item.serviceNoFull ?? item.serviceNo).replaceAll(RegExp(r'\D'), '');
      if (service.isEmpty) continue;
      final serviceTail = service.length > 10
          ? service.substring(service.length - 10)
          : service;
      if (service != digits &&
          serviceTail != mobileTail &&
          !service.endsWith(digits) &&
          !digits.endsWith(service)) {
        continue;
      }
      final label = _resolveDueOrExpiryLabel(
        dueDate: item.dueDate,
        expiresAt: item.expiresAt,
        daysLeft: item.daysLeft,
      );
      if (label != null && label.trim().isNotEmpty) {
        return label.replaceFirst('Expires', 'Due');
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolved = numberForApi.trim();
    if (resolved.isEmpty) return const SizedBox.shrink();
    final myNumberInfo = ref.watch(mobilePrepaidMyNumberProvider(resolved));
    return myNumberInfo.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'My Number',
            specHeading: true,
          ),
          SizedBox(height: 12.h),
          const MobilePrepaidMyNumberCardShimmer(),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (info) {
        final mobile = info.number.trim();
        if (mobile.isEmpty) return const SizedBox.shrink();
        final dueLabel = _duesInDaysLabel(
          days: _kPrepaidDaysPlaceholder, // later: API days_left
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              title: 'My Number',
              specHeading: true,
            ),
            SizedBox(height: 12.h),
            _MyNumberCard(
              dueLabel: dueLabel,
              operatorLabel: (info.operatorName?.trim().isNotEmpty ?? false)
                  ? info.operatorName!.trim()
                  : '',
              operatorIconUrl: info.operatorIcon,
              mobile: mobile,
              lastOn: (info.lastOn?.trim().isNotEmpty ?? false)
                  ? info.lastOn!.trim()
                  : '--',
              onRecharge: () => onRecharge(mobile),
            ),
          ],
        );
      },
    );
  }
}

class _RecentRechargesSection extends StatelessWidget {
  const _RecentRechargesSection({
    required this.recentPayments,
    required this.onRepeatRecent,
    required this.onViewAllRecent,
  });

  final AsyncValue<List<LatestTransaction>> recentPayments;
  final ValueChanged<LatestTransaction> onRepeatRecent;
  final VoidCallback onViewAllRecent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Recents',
          specHeading: true,
          actionText: 'View All',
          onAction: onViewAllRecent,
        ),
        SizedBox(height: 8.h),
        _RecentRechargeRow(
          recentPayments: recentPayments,
          onRepeat: onRepeatRecent,
        ),
      ],
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 28.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => SizedBox(width: 18.w),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isActive = category == selected;
          return GestureDetector(
            onTap: () => onSelected(category),
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? Colors.black
                          : AppColors.textPrimary.withOpacity(0.45),
                      fontSize: 14.sp,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    height: 2.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.black : Colors.transparent,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlanList extends StatelessWidget {
  const _PlanList({
    required this.plans,
    required this.selectedPlan,
    required this.onSelect,
    required this.onPayNow,
  });

  final List<PlanItem> plans;
  final PlanItem? selectedPlan;
  final ValueChanged<PlanItem> onSelect;
  final ValueChanged<PlanItem> onPayNow;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: plans.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final plan = plans[index];
        return PlanCard(
          plan: plan,
          isSelected: selectedPlan == plan,
          onTap: () => onSelect(plan),
          onPayNow: () => onPayNow(plan),
        );
      },
    );
  }
}

class _EmptyPlansState extends StatelessWidget {
  const _EmptyPlansState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Center(
        child: Text(
          query.isEmpty
              ? 'No plans available for this category.'
              : 'No plans match "$query".',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary.withOpacity(0.6),
              ),
        ),
      ),
    );
  }
}
