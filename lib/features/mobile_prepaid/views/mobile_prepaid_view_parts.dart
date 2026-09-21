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
        padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 16.h),
        children: [
          if (searchMode == _MobilePrepaidSearchMode.abc) ...[
            _MobilePrepaidBanner(banners: banners),
            SizedBox(height: 14.h),
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
            const _SectionHeader(title: 'My Contacts'),
            SizedBox(height: 10.h),
            if (!hasContactsPermission)
              ContactsPermissionCard(
                onAllow: onRequestPermission,
                outerPadding: EdgeInsets.zero,
              )
            else if (isLoading)
              const Center(
                child: SpinKitCircle(
                  color: AppColors.primary,
                  size: 48,
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
            SizedBox(height: 18.h),
            _MyNumberSection(
              numberForApi: myNumberForApi,
              onSelect: onSelect,
              onRecharge: onMyNumberRecharge,
            ),
            SizedBox(height: 18.h),
            _RecentRechargesSection(
              recentPayments: recentPayments,
              onRepeatRecent: onRepeatRecent,
              onViewAllRecent: onViewAllRecent,
            ),
            SizedBox(height: 18.h),
            SizedBox(key: contactsSectionKey),
            const _SectionHeader(title: 'My Contacts'),
            SizedBox(height: 10.h),
            if (!hasContactsPermission)
              ContactsPermissionCard(
                onAllow: onRequestPermission,
                outerPadding: EdgeInsets.zero,
              )
            else if (isLoading)
              const Center(
                child: SpinKitCircle(
                  color: AppColors.primary,
                  size: 48,
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
  const _MobilePrepaidBanner({required this.banners});

  final AsyncValue<List<BannerModel>> banners;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 86.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFC7C7C7), width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: banners.when(
          loading: () => const _BannerShimmer(),
          error: (_, __) => Image.asset(
            FileConstants.homeBanner2,
            width: double.infinity,
            height: 86.h,
            fit: BoxFit.cover,
            alignment: Alignment.centerLeft,
          ),
          data: (items) {
            final image = items.isNotEmpty ? items.first.image.trim() : '';
            if (image.isEmpty) {
              return Image.asset(
                FileConstants.homeBanner2,
                width: double.infinity,
                height: 86.h,
                fit: BoxFit.cover,
                alignment: Alignment.centerLeft,
              );
            }
            return AppNetworkImage(
              url: image,
              height: 86.h,
              width: double.infinity,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(12.r),
            );
          },
        ),
      ),
    );
  }
}

class _BannerShimmer extends StatelessWidget {
  const _BannerShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE9E9E9),
      highlightColor: const Color(0xFFF6F6F6),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
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
        Container(
          width: double.infinity,
          height: 54.h,
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.black.withOpacity(0.08),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              if (!isNumeric) ...[
                Image.asset(
                  FileConstants.orangeSearch,
                  width: 20.w,
                  height: 20.h,
                  fit: BoxFit.contain,
                ),
                SizedBox(width: 10.w),
              ],
              Expanded(
                child: TextField(
                  controller: isNumeric ? numericController : alphaController,
                  focusNode: isNumeric ? numericFocusNode : alphaFocusNode,
                  autofocus: true,
                  keyboardType:
                      isNumeric ? TextInputType.phone : TextInputType.text,
                  textInputAction:
                      isNumeric ? TextInputAction.done : TextInputAction.search,
                  inputFormatters: isNumeric
                      ? [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ]
                      : const [],
                  onChanged: isNumeric ? null : onAlphaChanged,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: isNumeric
                        ? 'Enter mobile number'
                        : 'Search by number or name',
                    prefixText: isNumeric ? '+91 ' : null,
                    prefixStyle: GoogleFonts.plusJakartaSans(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                    ),
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: AppColors.textPrimary.withOpacity(0.45),
                      fontWeight: FontWeight.w500,
                      fontSize: 14.sp,
                    ),
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              _SearchModeToggle(
                mode: searchMode,
                onChanged: onSearchModeChange,
              ),
            ],
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
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
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
                          borderRadius: BorderRadius.circular(14),
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
    Widget chip(String label, _MobilePrepaidSearchMode value) {
      final active = mode == value;
      return InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(70.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(70.r),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: active ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 9.sp,
              height: 1,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 75.w,
      height: 22.h,
      padding: EdgeInsets.all(1.5.w),
      decoration: BoxDecoration(
        color: const Color(0x21DD5428),
        borderRadius: BorderRadius.circular(70.r),
      ),
      child: Row(
        children: [
          Expanded(child: chip('ABC', _MobilePrepaidSearchMode.abc)),
          Expanded(child: chip('123', _MobilePrepaidSearchMode.numeric)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionText,
    this.onAction,
  });

  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          height: 22.h,
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 16.sp,
              height: 22 / 16,
              color: const Color(0xFF292D32),
            ),
          ),
        ),
        const Spacer(),
        if (actionText != null && onAction != null)
          InkWell(
            onTap: onAction,
            child: Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: SizedBox(
                height: 19.h,
                child: Text(
                  actionText!,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFFDD5428),
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                    height: 19 / 14,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LastOnLabel extends StatelessWidget {
  const _LastOnLabel(this.lastOn);

  final String lastOn;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 115.w,
      height: 14.h,
      child: Text(
        'Last On - $lastOn',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 9.sp,
          fontWeight: FontWeight.w500,
          height: 14 / 9,
          color: const Color(0xFF7C7C7C),
        ),
      ),
    );
  }
}

class _ExpiryPill extends StatelessWidget {
  const _ExpiryPill(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18.h,
      padding: EdgeInsets.fromLTRB(12.w, 3.h, 12.w, 3.h),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF801900),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8.r),
          topRight: Radius.circular(16.r),
          bottomRight: Radius.circular(16.r),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 10.sp,
          height: 1,
        ),
      ),
    );
  }
}

class _OrangePillButton extends StatelessWidget {
  const _OrangePillButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96.w,
      height: 27.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDD5428),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.fromLTRB(16.w, 5.h, 16.w, 5.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(23.r),
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            height: 1,
            color: Colors.white,
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
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(16.w, hasDue ? 22.h : 16.h, 16.w, 16.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFE2E2E2), width: 0.5),
          ),
          child: Row(
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
                  children: [
                    Text(
                      mobile,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                        color: const Color(0xFF000000),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    _LastOnLabel(lastOn),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              _OrangePillButton(
                label: 'Recharge',
                onPressed: onRecharge,
              ),
            ],
          ),
        ),
        if (hasDue)
          Positioned(
            top: 0,
            left: 0,
            child: _ExpiryPill(dueLabel!.trim()),
          ),
      ],
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
      return LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          height: 108.h,
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            minWidth: constraints.maxWidth,
            maxWidth: constraints.maxWidth + 16,
            child: SizedBox(
              width: constraints.maxWidth + 16,
              child: child,
            ),
          ),
        ),
      );
    }

    return recentPayments.when(
      loading: () => buildScroller(
        ListView.separated(
          scrollDirection: Axis.horizontal,
          itemBuilder: (_, __) =>
              const MobilePrepaidRecentRechargeCardShimmer(),
          separatorBuilder: (_, __) => SizedBox(width: 12.w),
          itemCount: 2,
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        final display = items.take(10).toList();
        if (display.isEmpty) return const SizedBox.shrink();
        return buildScroller(
          ListView.separated(
            scrollDirection: Axis.horizontal,
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
              badgeLabel: _resolveDueOrExpiryLabel(
                dueDate: display[index].dueDate,
                expiresAt: display[index].expiresAt,
              ),
              onRepeat: () => onRepeat(display[index]),
            ),
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
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
}) {
  DateTime? parse(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty || value.toLowerCase() == 'null') return null;
    return DateTime.tryParse(value);
  }

  final due = parse(dueDate);
  final exp = parse(expiresAt);
  final target = due ?? exp;
  if (target == null) return null;

  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final days = target.difference(startOfToday).inDays;
  if (days <= 0) return (due != null) ? 'Due Today' : 'Expires Today';
  if (days == 1) return (due != null) ? 'Due In 1 Day' : 'Expires In 1 Day';
  return (due != null) ? 'Due In $days Days' : 'Expires In $days Days';
}

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
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Container(
          width: 300.w,
          padding: EdgeInsets.fromLTRB(16.w, showBadge ? 22.h : 16.h, 16.w, 16.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFE2E2E2), width: 0.5),
          ),
          child: Row(
            children: [
              _OperatorIconBadge(
                label: title,
                iconUrl: iconUrl,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title.trim().isNotEmpty ? title : mobile,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF292D32),
                        height: 1.1,
                      ),
                    ),
                    if (mobile.trim().isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        mobile,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF292D32),
                          height: 1.1,
                        ),
                      ),
                    ],
                    SizedBox(height: 3.h),
                    _LastOnLabel(lastOn),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              _OrangePillButton(
                label: 'Repeat',
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
    return SimCardIconContainer(
      url: iconUrl,
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
          0,
          10.h,
          0,
          24.h + MediaQuery.of(context).viewPadding.bottom,
        ),
        children: [
          // Suggested plans block should be at the top (edge-to-edge gradient).
          if (!state.isFetching && state.currentPlans.isNotEmpty)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(gradient: suggestedGradient),
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
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
                  SizedBox(height: 14.h),
                  _SuggestedPlanCards(
                    plans: state.currentPlans,
                    onSelect: controller.selectPlan,
                  ),
                ],
              ),
            ),

          // Search field
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
            child: SearchTextfield(
              hintText: 'Search a plan, eg 299, 5g, etc.',
              controller: planSearchController,
              onChange: onPlanSearchChanged,
            ),
          ),

          // Filters row
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
            child: SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 1 + quickFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 4),
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
                  final isSelected =
                      applied.contains(label) && !isAllSelected;
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
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
            child: _CategoryTabs(
              categories: state.categories,
              selected: state.selectedCategory,
              onSelected: controller.selectCategory,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
            child: Builder(
              builder: (context) {
                if (state.isFetching && state.currentPlans.isEmpty) {
                  return const Center(
                    child: SpinKitCircle(
                      color: AppColors.primary,
                      size: 48,
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
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Center(
                child: SpinKitCircle(
                  color: AppColors.primary,
                  size: 28,
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
            padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 12.h),
            child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: AppColors.lightBorder,
                    width: 1.w,
                  ),
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 83.w,
                            child: Text(
                              '₹ ${plan.amount}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 32.sp,
                                height: 1,
                                color: const Color(0xFF000000),
                              ),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          _buildInfoRow(context, plan),
                          SizedBox(height: 12.h),
                          Text(
                            plan.description.isEmpty
                                ? 'No description available.'
                                : plan.description,
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF222222),
                              height: 1.4,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          // Category name + Change Plan row
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Entertainment',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.bricolageGrotesque(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.sp,
                                    height: 17 / 14,
                                    color: const Color(0xFFDD5428),
                                  ),
                                ),
                              ),
                              SizedBox(width: 20.w),
                              GestureDetector(
                                onTap: () => controller.deselectPlan(),
                                child: Container(
                                  width: 118.w,
                                  height: 30.h,
                                  padding: EdgeInsets.fromLTRB(
                                    14.w,
                                    6.h,
                                    14.w,
                                    6.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF084591),
                                    borderRadius: BorderRadius.circular(48.r),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'Change Plan',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style:
                                              GoogleFonts.bricolageGrotesque(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11.sp,
                                            height: 1,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 6.w),
                                      Icon(
                                        Icons.sync,
                                        size: 12.sp,
                                        color: Colors.white,
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
                    Positioned(
                      top: 27.h,
                      right: 0,
                      child: GetAssuredCoinsBadge(
                        label: plan.assuredBadgeLabel,
                      ),
                    ),
                  ],
                ),
              ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            24.w,
            8.h,
            24.w,
            16.h + MediaQuery.of(context).viewPadding.bottom,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 60.h,
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
                padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 24.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(86.r),
                ),
                elevation: 0,
              ),
              child: state.isRecharging
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: SpinKitCircle(
                        color: Colors.white,
                        size: 20,
                      ),
                    )
                  : Text(
                      'Proceed to Pay',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, PlanItem plan) {
    final hasValidity = plan.validity.isNotEmpty;
    final hasData = plan.data.isNotEmpty;
    final hasBenefitImages = plan.additionalBenefits.isNotEmpty;

    if (!hasValidity && !hasData && !hasBenefitImages) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (hasValidity)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Validity',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary.withOpacity(0.5),
                      fontSize: 12,
                    ),
              ),
              SizedBox(height: 2.h),
              Text(
                plan.validity,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
              ),
            ],
          ),
        if (hasValidity && hasData)
          Container(
            width: 1,
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: Colors.grey.shade300,
          ),
        if (hasData)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary.withOpacity(0.5),
                      fontSize: 12,
                    ),
              ),
              SizedBox(height: 2.h),
              Text(
                plan.data,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
              ),
            ],
          ),
        if ((hasValidity || hasData) && hasBenefitImages) const Spacer(),
        if (hasBenefitImages) _buildBenefitImages(context, plan),
      ],
    );
  }

  Widget _buildBenefitImages(BuildContext context, PlanItem plan) {
    const maxVisible = 5;
    final benefits = plan.additionalBenefits;
    final visibleBenefits = benefits.take(maxVisible).toList();
    final remaining = benefits.length - maxVisible;

    return GestureDetector(
      onTap: () => KDialog.instance.openSheet(
        dialog: PlanDetailsSheet(
          plan: plan,
          onProceedToPay: () => KDialog.instance.openSheet(
            dialog: PrepaidPaymentBottomSheet(
              plan: plan,
              billerName: state.operatorInfo?.operatorName ?? 'Mobile Prepaid',
              ecoinsRestrictionsPercent: state.ecoinsRestrictionsPercent,
            ),
          ),
        ),
      ),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: (visibleBenefits.length * 26.0) + 10,
            height: 36,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (int i = 0; i < visibleBenefits.length; i++)
                  Positioned(
                    left: i * 26.0,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: visibleBenefits[i].image == null
                            ? Container(
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.card_giftcard,
                                  size: 16,
                                ),
                              )
                            : Image.network(
                                visibleBenefits[i].image!,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image, size: 16),
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (remaining > 0)
            Text(
              '+$remaining',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
            ),
        ],
      ),
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
        final size = MediaQuery.of(regionContext).size;
        KDialog.instance.openConstraintsSheet(
          dialog: _RegionSelectSheet(
            onSelected: (region) async {
              if (mobile.trim().isEmpty) return;
              await onSelected(operator, region);
            },
          ),
          maxHeight: size.height * 0.65,
        );
      },
    ),
    maxHeight: MediaQuery.of(currentContext).size.height * 0.6,
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: SpinKitCircle(
                color: AppColors.primary,
                size: 48,
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
                            child: const Icon(
                              Icons.arrow_forward,
                              size: 20,
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: SpinKitCircle(
                color: AppColors.primary,
                size: 48,
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isFilter
              ? const Color(0xFFE5E5E5)
              : selected
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.white,
          borderRadius: BorderRadius.circular(8),
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
                fontSize: 9.sp,
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 14, color: AppColors.textPrimary),
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
      height: 105.h,
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
        height: 105.h,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.lightBorder, width: 1.w),
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
            Positioned(
              left: 18.w,
              top: 15.h,
              right: 44.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹ ${plan.amount}',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w500,
                      fontSize: 22.sp,
                      color: Colors.black,
                      height: 1,
                    ),
                  ),
                  if (validity.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      'Validity: $validity',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.sp,
                        color: const Color(0xFF222222),
                        height: 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (description.isNotEmpty)
              Positioned(
                left: 18.w,
                top: 58.h,
                width: 198.w,
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
            Positioned(
              left: 18.w,
              top: 76.h,
              width: 40.w,
              height: 15.h,
              child: GestureDetector(
                onTap: onTap,
                child: Text(
                  'Details',
                  maxLines: 1,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp,
                    height: 15 / 12,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                    decorationStyle: TextDecorationStyle.solid,
                    decorationThickness: 1,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 212.w,
              top: 12.h,
              child: IgnorePointer(
                child: Image.asset(
                  FileConstants.orangeRight,
                  width: 28.w,
                  height: 28.h,
                  fit: BoxFit.contain,
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
    required this.onSelect,
    required this.onRecharge,
  });

  final String numberForApi;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onRecharge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolved = numberForApi.trim();
    if (resolved.isEmpty) return const SizedBox.shrink();
    final myNumberInfo = ref.watch(mobilePrepaidMyNumberProvider(resolved));
    return myNumberInfo.when(
      loading: () => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'My Number'),
          SizedBox(height: 10),
          MobilePrepaidMyNumberCardShimmer(),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (info) {
        final mobile = info.number.trim();
        if (mobile.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(title: 'My Number'),
            SizedBox(height: 10.h),
            _MyNumberCard(
              dueLabel: (info.dueLabel?.trim().isNotEmpty ?? false)
                  ? info.dueLabel!.trim()
                  : null,
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
    return recentPayments.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Recents',
            actionText: 'View all',
            onAction: onViewAllRecent,
          ),
          SizedBox(height: 10.h),
          _RecentRechargeRow(
            recentPayments: recentPayments,
            onRepeat: onRepeatRecent,
          ),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: 'Recents',
              actionText: 'View all',
              onAction: onViewAllRecent,
            ),
            SizedBox(height: 10.h),
            _RecentRechargeRow(
              recentPayments: recentPayments,
              onRepeat: onRepeatRecent,
            ),
          ],
        );
      },
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
      height: 36.h,
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
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? Colors.black
                          : AppColors.textPrimary.withOpacity(0.45),
                      fontSize: 12.sp,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 6.h),
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
      padding: const EdgeInsets.symmetric(vertical: 24),
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
