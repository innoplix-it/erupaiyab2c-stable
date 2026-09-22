// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unused_element, unused_element_parameter, unused_local_variable

part of 'home_view.dart';

class _Dot extends StatelessWidget {
  const _Dot({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 14 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.lightBorder,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.onTap,
    this.icon,
    this.iconAsset,
    this.badgeCount,
    this.size = 36,
    this.iconSize = 18,
  }) : assert(icon != null || iconAsset != null);

  final VoidCallback onTap;
  final IconData? icon;
  final String? iconAsset;
  final int? badgeCount;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final resolvedSize = size.r;
    final resolvedIconSize = iconSize.r;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(resolvedSize / 2),
      child: Container(
        height: resolvedSize,
        width: resolvedSize,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: iconAsset != null
                  ? Image.asset(
                      iconAsset!,
                      height: resolvedIconSize,
                      width: resolvedIconSize,
                      color: AppColors.textPrimary,
                    )
                  : Icon(
                      icon,
                      size: resolvedIconSize,
                      color: AppColors.textPrimary,
                    ),
            ),
            if ((badgeCount ?? 0) > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  constraints: const BoxConstraints(minWidth: 16),
                  child: Text(
                    (badgeCount ?? 0) > 9 ? '9+' : '${badgeCount ?? 0}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      decoration: TextDecoration.none,
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

class _PagerDots extends StatelessWidget {
  const _PagerDots();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Dot(active: true),
        SizedBox(width: 6),
        _Dot(active: false),
        SizedBox(width: 6),
        _Dot(active: false),
      ],
    );
  }
}

class _BottomIcon extends StatelessWidget {
  const _BottomIcon({
    required this.asset,
    this.size = 26,
    this.color,
    this.yOffset = 0,
  });
  final String asset;
  final double size;
  final Color? color;
  final double yOffset;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheW = (size * dpr).round();
    final icon = SizedBox(
      height: size,
      width: size,
      child: Center(
        child: Image.asset(
          asset,
          height: size,
          width: size,
          fit: BoxFit.cover,
          color: color,
          cacheWidth: cacheW,
          cacheHeight: cacheW,
        ),
      ),
    );
    if (yOffset == 0) return icon;
    return Transform.translate(offset: Offset(0, yOffset), child: icon);
  }
}

class _BottomIconWithBadge extends StatelessWidget {
  const _BottomIconWithBadge({
    required this.asset,
    this.size = 20,
    this.color,
    this.yOffset = 0,
  });

  final String asset;
  final double size;
  final Color? color;
  final double yOffset;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationBadgeService.unreadCount,
      builder: (context, unreadCount, _) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final cacheW = (size * dpr).round();
        final wrapper = size + 10;
        return SizedBox(
          height: wrapper,
          width: wrapper,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: Offset(0, yOffset),
                child: Image.asset(
                  asset,
                  height: size,
                  width: size,
                  fit: BoxFit.contain,
                  color: color,
                  cacheWidth: cacheW,
                  cacheHeight: cacheW,
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 0,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GradientFabIcon extends StatelessWidget {
  const _GradientFabIcon({
    required this.asset,
    this.size = 24,
    this.iconColor,
  });
  final String asset;
  final double size;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65.h,
      width: 55.w,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Image.asset(
          asset,
          height: 35.h,
          width: 20.w,
          color: iconColor ?? Colors.white,
        ),
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({
    required this.initials,
    required this.walletBalance,
    this.isWalletLoading = false,
    this.hasWalletError = false,
    required this.onSearchTap,
    required this.onReferTap,
    required this.onProfileTap,
    this.compact = false,
  });

  final String initials;
  final double? walletBalance;
  final bool isWalletLoading;
  final bool hasWalletError;
  final VoidCallback onSearchTap;
  final VoidCallback onReferTap;
  final VoidCallback onProfileTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.plusJakartaSans(
      textStyle: Theme.of(context).textTheme.bodySmall,
    );
    final resolvedWalletBalance = walletBalance;
    final displayBalance = resolvedWalletBalance == null
        ? '--'
        : resolvedWalletBalance == resolvedWalletBalance.roundToDouble()
            ? resolvedWalletBalance.toStringAsFixed(0)
            : resolvedWalletBalance.toStringAsFixed(2);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: onProfileTap,
              child: _ProfileAvatar(
                initials: initials,
                size: compact ? 32 : 36,
              ),
            ),
            SizedBox(width: 8.w),
            _HeaderIconButton(
              icon: Icons.search,
              size: compact ? 32 : 36,
              iconSize: compact ? 16 : 18,
              onTap: onSearchTap,
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: onReferTap,
              child: Image.asset(
                FileConstants.referandearn,
                height: compact ? 26.h : 30.h,
                width: compact ? 120.w : 132.w,
                fit: BoxFit.contain,
              ),
            ),
            GestureDetector(
              onTap: () {
                context.push(RouteConstants.referAndEarnWallet);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      FileConstants.coin_3d,
                      width: compact ? 14.w : 16.w,
                      height: compact ? 14.w : 16.w,
                    ),
                    SizedBox(width: 6.w),
                    if (isWalletLoading)
                      SizedBox(
                        width: compact ? 12.w : 14.w,
                        height: compact ? 12.w : 14.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: AppColors.textPrimary,
                        ),
                      )
                    else
                      Text(
                        displayBalance,
                        style: textStyle.copyWith(
                          color: hasWalletError
                              ? AppColors.textPrimary.withOpacity(0.55)
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: compact ? 10.sp : 11.sp,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.initials, required this.size});
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size.r,
      width: size.r,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.plusJakartaSans(
            textStyle: Theme.of(context).textTheme.bodySmall,
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.child, this.padding});
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (actionLabel != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(18.r),
            child: Row(
              children: [
                Text(
                  actionLabel!,
                  style: GoogleFonts.plusJakartaSans(
                    textStyle: Theme.of(context).textTheme.bodyMedium,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 6.w),
                Container(
                  height: 20.r,
                  width: 20.r,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 14.r,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _HomeIconGrid extends StatelessWidget {
  const _HomeIconGrid({
    required this.services,
    required this.onTap,
    this.maxItems = 8,
    this.columns = 4,
    this.tileWidth = 64,
  });

  final List<QuickActionService> services;
  final Future<void> Function(String serviceName) onTap;
  final int maxItems;
  final int columns;
  final double tileWidth;

  @override
  Widget build(BuildContext context) {
    final visibleItems = services.take(maxItems).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final spacing = 12.w;
        final computedTileSize = (maxWidth - spacing * (columns - 1)) / columns;
        final tileSize =
            computedTileSize > tileWidth.r ? tileWidth.r : computedTileSize;
        return Wrap(
          spacing: spacing.w,
          runSpacing: 16.h,
          children: List.generate(visibleItems.length, (index) {
            final service = visibleItems[index];
            return SizedBox(
              width: tileSize,
              child: HomeIconTile(
                label: service.name,
                iconUrl: service.icon,
                offer: service.offers,
                onTap: () async {
                  await onTap(service.name);
                },
              ),
            );
          }),
        );
      },
    );
  }
}

class _CurvedIconGrid extends StatelessWidget {
  const _CurvedIconGrid({
    required this.services,
    required this.onTap,
    this.maxItems = 4,
    this.labelBuilder,
    this.showCardFrame = true,
  });

  final List<QuickActionService> services;
  final Future<void> Function(String serviceName) onTap;
  final int maxItems;
  final String Function(QuickActionService service)? labelBuilder;
  final bool showCardFrame;

  @override
  Widget build(BuildContext context) {
    final visibleItems = services.take(maxItems).toList();
    const columns = 4;
    final rows = <List<QuickActionService?>>[];
    for (var i = 0; i < visibleItems.length; i += columns) {
      final row = <QuickActionService?>[
        ...visibleItems.skip(i).take(columns),
      ];
      while (row.length < columns) {
        row.add(null);
      }
      rows.add(row);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final service in rows[r])
                Expanded(
                  child: service == null
                      ? const SizedBox.shrink()
                      : Builder(
                          builder: (context) {
                            final spec = _iconSpecFor(service);
                            return _CurvedIconTile(
                              label: labelBuilder?.call(service) ??
                                  service.name,
                              iconUrl: service.icon ?? '',
                              localIconAsset: spec.localAsset,
                              iconWidth: spec.width,
                              iconHeight: spec.height,
                              iconTopOffset: spec.topOffset,
                              showCardFrame: showCardFrame,
                              onTap: () async {
                                await onTap(service.name);
                              },
                            );
                          },
                        ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  _CreditCardIconSpec _iconSpecFor(QuickActionService service) {
    final name = service.name.trim().toLowerCase();
    if (name.contains('school')) {
      return const _CreditCardIconSpec(
        width: 34,
        height: 34,
        localAsset: 'assets/images/png/schoolfees.png',
      );
    }
    if (name.contains('college')) {
      return const _CreditCardIconSpec(
        width: 26.72,
        height: 35.15,
        localAsset: 'assets/images/png/collegefees.png',
      );
    }
    if (name.contains('tuition') || name.contains('tution')) {
      return const _CreditCardIconSpec(
        width: 32.33,
        height: 34.21,
        localAsset: 'assets/images/png/tuitionfees.png',
      );
    }
    if (name.contains('gym')) {
      return const _CreditCardIconSpec(
        width: 30,
        height: 30,
        localAsset: 'assets/images/png/gymmembership.png',
      );
    }
    if (name.contains('house rent') || name == 'house') {
      return const _CreditCardIconSpec(
        width: 28.5,
        height: 24.65,
        localAsset: 'assets/images/png/houserent.png',
      );
    }
    if (name.contains('shop rent') || name == 'shop') {
      return const _CreditCardIconSpec(
        width: 28,
        height: 24.45,
        topOffset: 1.78,
        localAsset: 'assets/images/png/shoprent.png',
      );
    }
    if (name.contains('life')) {
      return const _CreditCardIconSpec(width: 24.65, height: 30.26);
    }
    if (name.contains('health')) {
      return const _CreditCardIconSpec(width: 26.5, height: 29.58);
    }
    if (name.contains('general')) {
      return const _CreditCardIconSpec(width: 26.5, height: 28.78);
    }
    return const _CreditCardIconSpec(width: 28, height: 28);
  }
}

class _CreditCardIconSpec {
  const _CreditCardIconSpec({
    required this.width,
    required this.height,
    this.topOffset = 0,
    this.localAsset,
  });

  final double width;
  final double height;
  final double topOffset;
  final String? localAsset;
}

class _CurvedIconTile extends StatelessWidget {
  const _CurvedIconTile({
    required this.label,
    required this.iconUrl,
    required this.onTap,
    this.localIconAsset,
    this.iconWidth = 28,
    this.iconHeight = 28,
    this.iconTopOffset = 0,
    this.showCardFrame = true,
  });

  final String label;
  final String iconUrl;
  final String? localIconAsset;
  final double iconWidth;
  final double iconHeight;
  final double iconTopOffset;
  final VoidCallback onTap;
  final bool showCardFrame;

  @override
  Widget build(BuildContext context) {
    final displayLabel = _capitalizeLabel(label.trim());
    final iconSizeW = iconWidth.w;
    final iconSizeH = iconHeight.w;
    Widget iconWidget = localIconAsset != null
        ? Image.asset(
            localIconAsset!,
            width: iconSizeW,
            height: iconSizeH,
            fit: BoxFit.contain,
          )
        : AppNetworkImage(
            url: iconUrl,
            width: iconSizeW,
            height: iconSizeH,
            fit: BoxFit.contain,
            showShimmer: false,
            errorWidget: Image.asset(
              FileConstants.appLogo,
              height: iconSizeH,
              width: iconSizeW,
              fit: BoxFit.contain,
            ),
          );
    if (iconTopOffset != 0) {
      iconWidget = Padding(
        padding: EdgeInsets.only(top: iconTopOffset.w),
        child: iconWidget,
      );
    }

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _creditCardIconCircle(iconWidget),
        SizedBox(height: 10.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          child: _creditCardIconLabel(displayLabel),
        ),
      ],
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(showCardFrame ? 8.r : 80.r),
      child: showCardFrame
          ? Container(
              width: 89.w,
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xffFAFAFA),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: const Color(0xffEAEAEA)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Image.asset(
                        FileConstants.bottomOrangeCurve,
                        height: 8.h,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),
                    ),
                    content,
                  ],
                ),
              ),
            )
          : SizedBox(
              width: double.infinity,
              child: content,
            ),
    );
  }

  Widget _creditCardIconCircle(Widget iconWidget) {
    final size = 68.w;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFFFFFFF),
          width: 2.w,
        ),
        gradient: const RadialGradient(
          center: Alignment(0, 0),
          radius: 0.7868,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFEEF3FD),
          ],
          stops: [0.0, 1.0],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xD9EEF3FD),
            offset: Offset(0, 1),
            blurRadius: 1,
          ),
          BoxShadow(
            color: Color(0x80EEF3FD),
            offset: Offset(0, 2),
            blurRadius: 1,
          ),
          BoxShadow(
            color: Color(0x26EEF3FD),
            offset: Offset(0, 3),
            blurRadius: 1,
          ),
          BoxShadow(
            color: Color(0x05EEF3FD),
            offset: Offset(0, 5),
            blurRadius: 1,
          ),
        ],
      ),
      child: Center(child: iconWidget),
    );
  }

  Widget _creditCardIconLabel(String label) {
    final words = label.trim().split(RegExp(r'\s+'));
    final last = words.isEmpty ? '' : words.last.toLowerCase();
    final wrapsTwoLines = words.length == 2 &&
        (last == 'insurance' || last == 'rent');
    final text = wrapsTwoLines ? '${words[0]}\n${words[1]}' : label;
    return Text(
      text,
      maxLines: wrapsTwoLines ? 2 : 1,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11.sp,
        fontWeight: FontWeight.w600,
        height: wrapsTwoLines ? 1.2 : 1,
        letterSpacing: 0,
        color: const Color(0xFF000000),
      ),
    );
  }

  String _capitalizeLabel(String input) {
    if (input.isEmpty) return input;
    return input
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

class _PayBillsCard extends StatelessWidget {
  const _PayBillsCard({
    required this.services,
    required this.onTap,
    required this.onExploreTap,
    this.isCreditCardLoading = false,
  });

  final List<QuickActionService> services;
  final Future<void> Function(String serviceName) onTap;
  final VoidCallback onExploreTap;
  final bool isCreditCardLoading;

  QuickActionService? _findService(Set<String> used, List<String> names) {
    for (final name in names) {
      for (final service in services) {
        if (service.name == name && !used.contains(service.name)) {
          used.add(service.name);
          return service;
        }
      }
    }
    return null;
  }

  QuickActionService? _nextUnused(Set<String> used) {
    for (final service in services) {
      if (!used.contains(service.name)) {
        used.add(service.name);
        return service;
      }
    }
    return null;
  }

  String _labelForService(QuickActionService service) {
    return service.name;
  }

  Widget _serviceTile(QuickActionService service) {
    return HomeIconTile(
      label: _labelForService(service),
      iconUrl: service.icon,
      offer: service.offers,
      labelSpacing: 4.h,
      showHalfRing: _isBookGasService(service),
      isLoading: isCreditCardLoading && _isCreditCardService(service),
      onTap: () async {
        await onTap(service.name);
      },
    );
  }

  bool _isBookGasService(QuickActionService service) {
    final name = service.name.trim().toLowerCase();
    // Ring highlight only for "Book Gas" style actions (not all gas types).
    return name.contains('book') &&
        (name.contains('gas') || name.contains('lpg'));
  }

  bool _isCreditCardService(QuickActionService service) {
    return service.name.trim().toLowerCase() == 'credit card';
  }

  @override
  Widget build(BuildContext context) {
    final used = <String>{};

    final electricity = _findService(used, const ['Electricity']);
    final recharge = _findService(
      used,
      const ['Mobile Prepaid', 'Mobile Postpaid', 'Recharge'],
    );
    final fastag = _findService(used, const ['Fastag', 'FASTag']);
    final credit = _findService(used, const ['Credit Card']);
    final bookGas = _findService(
          used,
          const ['LPG Gas', 'Book Gas Cylinder', 'Pipe Gas', 'Book Gas'],
        ) ??
        _nextUnused(used);

    final topRow = <QuickActionService?>[
      electricity ?? _nextUnused(used),
      recharge ?? _nextUnused(used),
      fastag ?? _nextUnused(used),
      credit ?? _nextUnused(used),
    ];

    const imageAspectRatio = 1960 / 1380;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = width / imageAspectRatio - 4.h;
            final tileWidth = width * 0.18;
            final bookTileWidth = width * 0.2;
            final horizontalInset = width * 0.06;
            final topRowSpacing =
                (width - (horizontalInset * 2) - (tileWidth * 4)) / 3;
            final firstTileCenter = horizontalInset + (tileWidth / 2);

            Widget positionedTile({
              required double x,
              required double y,
              required QuickActionService? service,
              required double tileW,
            }) {
              if (service == null) return const SizedBox.shrink();
              return Positioned(
                left: x - (tileW / 2),
                top: y,
                width: tileW,
                child: _serviceTile(service),
              );
            }

            return SizedBox(
              width: width,
              height: height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      FileConstants.homeIconSection,
                      fit: BoxFit.fill,
                    ),
                  ),
                  positionedTile(
                    x: firstTileCenter,
                    y: height * 0.08,
                    service: topRow[0],
                    tileW: tileWidth,
                  ),
                  positionedTile(
                    x: firstTileCenter + tileWidth + topRowSpacing,
                    y: height * 0.08,
                    service: topRow[1],
                    tileW: tileWidth,
                  ),
                  positionedTile(
                    x: firstTileCenter + ((tileWidth + topRowSpacing) * 2),
                    y: height * 0.08,
                    service: topRow[2],
                    tileW: tileWidth,
                  ),
                  positionedTile(
                    x: firstTileCenter + ((tileWidth + topRowSpacing) * 3),
                    y: height * 0.08,
                    service: topRow[3],
                    tileW: tileWidth,
                  ),
                  positionedTile(
                    x: width * 0.15,
                    y: height * 0.5,
                    service: bookGas,
                    tileW: bookTileWidth,
                  ),
                  if (bookGas != null)
                    Positioned(
                      left: width * 0.32,
                      right: 0,
                      top: height * 0.54,
                      child: _PromoStrip(
                        asset: FileConstants.bookLpgStrip,
                      ),
                    ),
                  Positioned(
                    right: width * 0.01,
                    // left: width * 0.01,
                    bottom: height * 0.01,
                    child: _ExploreUtilitiesRow(onTap: onExploreTap),
                  ),
                ],
              ),
            );
          },
        ),
        // SizedBox(height: 18.h),
        // const _ReferStrip(),
      ],
    );
  }
}

class _PromoStrip extends StatelessWidget {
  const _PromoStrip({required this.asset});
  final String asset;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(10),
        bottomLeft: Radius.circular(10),
      ),
      child: Image.asset(
        asset,
        height: 30.h,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _ExploreUtilitiesRow extends StatelessWidget {
  const _ExploreUtilitiesRow({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        height: 38.h,
        width: 220.w,
        padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: const Color(0xFFFBE6DE),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Explore All Services',
              style: GoogleFonts.plusJakartaSans(
                textStyle: Theme.of(context).textTheme.bodyMedium,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              height: 24.r,
              width: 24.r,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward,
                size: 14.r,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferStrip extends StatelessWidget {
  const _ReferStrip();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ReferAndEarnView(),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          image: DecorationImage(
            image: AssetImage(FileConstants.referBg),
            fit: BoxFit.cover,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 18.r,
              width: 18.r,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                FileConstants.coin_3d,
                height: 12.r,
                width: 12.r,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'Refer Your First Friend And Grab 1000 E-Coins',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  textStyle: Theme.of(context).textTheme.bodySmall,
                  color: Colors.white,
                  letterSpacing: -0.25,
                  fontWeight: FontWeight.w600,
                  fontSize: 10.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvestmentTile extends StatelessWidget {
  const _InvestmentTile({
    required this.label,
    required this.iconAsset,
    required this.arrowAsset,
    required this.borderColor,
    required this.textColor,
    this.backgroundGradient,
  });

  final String label;
  final String iconAsset;
  final String arrowAsset;
  final Color borderColor;
  final Color textColor;
  final Gradient? backgroundGradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: backgroundGradient == null ? Colors.white : null,
        gradient: backgroundGradient,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 20.r,
            width: 20.r,
            child: Image.asset(
              iconAsset,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                textStyle: Theme.of(context).textTheme.bodySmall,
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          SizedBox(
            height: 22.r,
            width: 22.r,
            child: Image.asset(
              arrowAsset,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageBanner extends StatelessWidget {
  const _ImageBanner({required this.asset, required this.height});
  final String asset;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cacheWidth = (MediaQuery.sizeOf(context).width *
            MediaQuery.devicePixelRatioOf(context))
        .round();
    return Image.asset(
      asset,
      height: height,
      width: double.infinity,
      fit: BoxFit.contain,
      cacheWidth: cacheWidth,
      filterQuality: FilterQuality.low,
    );
  }
}

class InsuranceBannerCarousel extends HookWidget {
  const InsuranceBannerCarousel({
    super.key,
    required this.onApply,
    this.banners = const [],
    this.isLoading = false,
    this.placeholderCount = 1,
  });

  final VoidCallback onApply;
  final List<BannerModel> banners;
  final bool isLoading;
  final int placeholderCount;

  @override
  Widget build(BuildContext context) {
    final controller = usePageController();
    final currentIndex = useState(0);

    final resolvedPlaceholderCount =
        placeholderCount < 1 ? 1 : placeholderCount;
    final total = (isLoading || banners.isEmpty)
        ? resolvedPlaceholderCount
        : banners.length;

    return Stack(
      children: [
        SizedBox(
          // height: 128,
          child: PageView.builder(
            controller: controller,
            itemCount: total,
            onPageChanged: (index) => currentIndex.value = index,
            itemBuilder: (context, index) {
              if (isLoading || banners.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: AppNetworkImage(
                    url: '',
                    // height: 128,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                );
              }

              final banner = banners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () => BannerRedirectMapper.handle(
                    context,
                    banner.redirectUrl,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: AppNetworkImage(
                      url: banner.image,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        ///DOTS OVERLAY
        Positioned(
          left: 18.w, // match your padding
          bottom: 5.h, // just below button visually
          child: Row(
            children: List.generate(
              total,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: EdgeInsets.only(right: 4.w),
                height: 6.h,
                width: currentIndex.value == index ? 14.w : 6.w,
                decoration: BoxDecoration(
                  color: currentIndex.value == index
                      ? Colors.white
                      : Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InsuranceBannerItem extends StatelessWidget {
  const _InsuranceBannerItem({
    required this.image,
    required this.onApply,
    required this.currentIndex,
    required this.total,
  });

  final String image;
  final VoidCallback onApply;
  final int currentIndex;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F8A4B),
            Color(0xFF0C6B3B),
          ],
        ),
      ),
      child: Row(
        children: [
          /// LEFT CONTENT
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Your Future',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Health, Motor & Life Insurance In\nMinutes',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: 10.h),

                /// APPLY BUTTON
                InkWell(
                  onTap: onApply,
                  borderRadius: BorderRadius.circular(18.r),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18.r),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFDD5428),
                          Color(0xFF772D16),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Apply Now',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Icon(Icons.north_east, size: 12.r, color: Colors.white),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 8.h),

                Row(
                  children: List.generate(
                    total,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: EdgeInsets.only(right: 4.w),
                      height: 6.h,
                      width: currentIndex == index ? 14.w : 6.w,
                      decoration: BoxDecoration(
                        color: currentIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 8.w),

          /// RIGHT IMAGE
          SizedBox(
            height: 96.h,
            width: 120.w,
            child: Image.asset(
              image,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsuranceBanner extends StatelessWidget {
  const _InsuranceBanner({required this.onApply});

  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F8A4B),
            Color(0xFF0C6B3B),
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Your Future',
                  style: GoogleFonts.plusJakartaSans(
                    textStyle: Theme.of(context).textTheme.bodyLarge,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Health, Motor & Life Insurance In\nMinutes',
                  style: GoogleFonts.plusJakartaSans(
                    textStyle: Theme.of(context).textTheme.bodySmall,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: 10.h),
                InkWell(
                  onTap: onApply,
                  borderRadius: BorderRadius.circular(18.r),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18.r),
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xFFDD5428),
                          Color(0xFF772D16),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Apply Now',
                          style: GoogleFonts.plusJakartaSans(
                            textStyle: Theme.of(context).textTheme.bodySmall,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Icon(
                          Icons.north_east,
                          size: 12.r,
                          color: Colors.white,
                        ),
                        SizedBox(
                          height: 10.h,
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          SizedBox(
            height: 96.h,
            width: 120.w,
            child: Image.asset(
              FileConstants.homeBannerGif,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

// class _MiniImageCard extends StatelessWidget {
//   const _MiniImageCard({
//     required this.asset,
//     required this.title,
//     required this.onTap,
//   });
//   final String asset;
//   final String title;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12.r),
//       child: Container(
//         padding: EdgeInsets.all(12.w),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12.r),
//           border: Border.all(color: AppColors.lightBorder),
//         ),
//         child: Row(
//           children: [
//             Image.asset(asset, height: 30.h, width: 30.h, fit: BoxFit.contain),
//             SizedBox(width: 8.w),
//             Expanded(
//               child: Text(
//                 title,
//                 style: GoogleFonts.plusJakartaSans(
//                   textStyle: Theme.of(context).textTheme.bodySmall,
//                   color: AppColors.textPrimary,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//             Container(
//               height: 20.r,
//               width: 20.r,
//               decoration: BoxDecoration(
//                 color: AppColors.primary.withOpacity(0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 Icons.chevron_right,
//                 size: 14.r,
//                 color: AppColors.primary,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class _MiniActionCard extends StatelessWidget {
  const _MiniActionCard({
    required this.title,
    required this.subtitle,
    required this.asset,
    required this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.gradientBorder,
  });

  final String title;
  final String subtitle;
  final String asset;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final Gradient? gradientBorder;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          gradient: gradientBorder,
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 6,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: gradientBorder == null
                ? Border.all(
                    color: borderColor ?? AppColors.lightBorder,
                    width: 0.5,
                  )
                : null,
          ),
          margin: gradientBorder == null
              ? EdgeInsets.zero
              : const EdgeInsets.all(0.5),
          child: Row(
            children: [
              Image.asset(asset,
                  height: 20.h, width: 20.h, fit: BoxFit.contain),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        textStyle: Theme.of(context).textTheme.bodySmall,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        textStyle: Theme.of(context).textTheme.bodySmall,
                        color: AppColors.textPrimary.withOpacity(0.6),
                        fontSize: 9.sp,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              Image.asset(
                FileConstants.rightArrow,
                height: 28.r,
                width: 28.r,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({required this.title, required this.onTap});
  final String title;
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
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: Row(
          children: [
            Image.asset(FileConstants.faqIcon,
                height: 20.h, width: 20.h, fit: BoxFit.contain),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  textStyle: Theme.of(context).textTheme.bodySmall,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Image.asset(
              FileConstants.rightArrow,
              height: 28.r,
              width: 28.r,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends HookConsumerWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeControllerProvider);
    final profileState = ref.watch(profileControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final homeRepository = useMemoized(HomeRepository.new);
    final hasInternet = ref.watch(connectivityStatusProvider).value ?? true;
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final bannerCacheWidth = (screenWidth * devicePixelRatio).round();

    final didShowCompleteProfile = useRef(false);
    final didShowTemporaryBlock = useRef(false);
    final didShowReminderPopup = useRef(false);
    // Track auth transitions across navigation; initialize to false so that if
    // Home is already mounted (behind login) we still refresh once on login.
    final wasAuthenticated = useRef<bool>(false);

    useEffect(() {
      Future.microtask(() {
        ref.read(homeControllerProvider.notifier).fetchQuickActionsIfNeeded();
        ref
            .read(homeControllerProvider.notifier)
            .fetchAllQuickActionsIfNeeded();
        ref.read(spinOptionsControllerProvider.notifier).fetchSpinOptions();
        ref.read(profileControllerProvider.notifier).fetchProfileIfNeeded();
      });
      return null;
    }, const []);

    // If Home stays mounted across login (ex: PIN unlock/login), the initial
    // `useEffect(const [])` won't re-run. Trigger a refresh when auth flips
    // from unauthenticated -> authenticated.
    useEffect(() {
      final prev = wasAuthenticated.value;
      final next = authState.isAuthenticated;
      wasAuthenticated.value = next;
      if (prev == false && next == true) {
        Future.microtask(() {
          ref
              .read(homeControllerProvider.notifier)
              .fetchQuickActionsIfNeeded(force: true);
          ref
              .read(homeControllerProvider.notifier)
              .fetchAllQuickActionsIfNeeded(force: true);
          ref
              .read(profileControllerProvider.notifier)
              .fetchProfileIfNeeded(force: true);
        });
      }
      return null;
    }, [authState.isAuthenticated]);

    useEffect(() {
      final needsProfile =
          homeState.isNameEmailExist == false && homeState.quickActions != null;
      if (!needsProfile || didShowCompleteProfile.value) return null;
      didShowCompleteProfile.value = true;
      Future.microtask(() {
        KDialog.instance.openDialog(
          barrierDismissible: false,
          dialog: CompleteProfileDialog(
            onCompleted: () {
              ref
                  .read(profileControllerProvider.notifier)
                  .fetchProfileIfNeeded(force: true);
              ref
                  .read(homeControllerProvider.notifier)
                  .fetchQuickActionsIfNeeded(force: true);
            },
          ),
        );
      });
      return null;
    }, [homeState.isNameEmailExist, homeState.quickActions]);

    final temporaryBlockFlow = _resolveTemporaryBlockFlow(profileState.profile);
    useEffect(() {
      if (temporaryBlockFlow == null || didShowTemporaryBlock.value) {
        return null;
      }
      if (profileState.profile == null) {
        return null;
      }
      didShowTemporaryBlock.value = true;
      Future.microtask(() async {
        if (!context.mounted) return;
        await KDialog.instance.openDialog(
          barrierDismissible: false,
          dialog: TemporaryBlockDialog(
            flowType: temporaryBlockFlow,
            onSupportTap: () {
              Navigator.of(context, rootNavigator: true).pop();
              Future.microtask(() {
                if (!context.mounted) return;
                context.push(RouteConstants.helpSupport);
              });
            },
            onPrimaryTap: () {
              final profile = profileState.profile;
              final successRoute =
                  temporaryBlockFlow == TemporaryBlockFlowType.noKyc
                      ? RouteConstants.kycVerification
                      : RouteConstants.temporaryBlockIdentityCompletion;
              final flowQueryValue =
                  temporaryBlockFlow == TemporaryBlockFlowType.noKyc
                      ? 'noKyc'
                      : 'kycVerified';
              Navigator.of(context, rootNavigator: true).pop();
              Future.microtask(() {
                if (!context.mounted) return;
                context.push(
                  '${RouteConstants.temporaryBlockOtp}?flow=$flowQueryValue&phone=${profile?.mobile ?? ''}',
                  extra: OtpVerificationArgs(
                    phoneNumber: profile?.mobile,
                    title: 'Verify Your Identity',
                    heading: 'Verify Your Identity',
                    description:
                        'Enter the OTPs sent to your registered mobile number and email address to verify your identity.',
                    primaryButtonLabel: 'Verify & Continue',
                    successDialogTitle:
                        'Mobile and Email verified successfully',
                    successDialogMessage:
                        'This device has been successfully verified and added to your trusted device list. You can now access your account securely.',
                    successButtonLabel: 'Complete KYC',
                    successRoute: successRoute,
                    successRouteExtra:
                        successRoute == RouteConstants.kycVerification
                            ? false
                            : null,
                    temporaryBlockFlowType: temporaryBlockFlow,
                  ),
                );
              });
            },
          ),
        );
      });
      return null;
    }, [temporaryBlockFlow, profileState.profile?.id]);

    useEffect(() {
      final hasLoadedHome = homeState.quickActions != null;
      final needsProfile = homeState.isNameEmailExist == false && hasLoadedHome;
      if (!hasLoadedHome ||
          needsProfile ||
          temporaryBlockFlow != null ||
          didShowReminderPopup.value) {
        return null;
      }
      didShowReminderPopup.value = true;
      Future.microtask(() async {
        if (!context.mounted) return;
        try {
          final response = await homeRepository.fetchBillReminders(
            page: 1,
            limit: 20,
          );
          if (!context.mounted || !response.status || response.items.isEmpty) {
            return;
          }
          final reminder = response.items.first;
          final biller = Biller(
            billerId: reminder.billerId,
            billerName: reminder.billerName,
            icon: reminder.billerIcon,
          );
          final paymentType = reminder.paymentType.trim();
          final normalizedPaymentType = paymentType.toLowerCase();
          final maskedDigits =
              reminder.maskedIdentifier.replaceAll(RegExp(r'\D'), '');
          final cardLast4 = maskedDigits.length >= 4
              ? maskedDigits.substring(maskedDigits.length - 4)
              : null;
          final reminderIdentifier = _resolveReminderPrefillValue(reminder);
          final reminderMobile = reminder.customerMobile.trim();
          final canAutoFetchReminder = normalizedPaymentType.contains('credit')
              ? reminderMobile.isNotEmpty && cardLast4 != null
              : reminderIdentifier.isNotEmpty;
          await KDialog.instance.openDialog(
            dialog: _HomeReminderDialog(
              data: reminder,
              onPrimaryTap: reminder.canPayNow
                  ? () {
                      Navigator.of(context, rootNavigator: true).pop();
                      ref
                          .read(billerDetailControllerProvider.notifier)
                          .selectBiller(
                            biller,
                            categoryName:
                                paymentType.isNotEmpty ? paymentType : null,
                          );
                      context.push(
                        RouteConstants.billerDetail,
                        extra: BillerDetailArgs(
                          biller: biller,
                          isCreditCard:
                              normalizedPaymentType.contains('credit'),
                          paymentType:
                              paymentType.isNotEmpty ? paymentType : null,
                          mobileNumber: normalizedPaymentType.contains('credit')
                              ? (reminderMobile.isNotEmpty
                                  ? reminderMobile
                                  : null)
                              : (reminderIdentifier.isNotEmpty
                                  ? reminderIdentifier
                                  : null),
                          cardLast4: cardLast4,
                          autoFetchBill: canAutoFetchReminder,
                          autoOpenPaymentSheet: false,
                        ),
                      );
                    }
                  : null,
            ),
          );
        } catch (_) {}
      });
      return null;
    }, [
      homeState.quickActions,
      homeState.isNameEmailExist,
      temporaryBlockFlow,
      homeRepository,
    ]);

    final topBanners = homeState.banners?['top'] ?? [];
    final middleBanners = homeState.banners?['middle'] ?? [];
    final bottomBanners = homeState.banners?['bottom'] ?? [];
    final bankingInvestmentBanners =
        homeState.banners?['banking_investment'] ?? [];

    final topBannerPage = useState(0);
    final topBannerController = useMemoized(() => PageController(), const []);
    useEffect(() {
      if (topBanners.length < 2) return null;
      final timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!topBannerController.hasClients) return;
        final next = (topBannerPage.value + 1) % topBanners.length;
        topBannerController.animateToPage(
          next.toInt(),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
      return timer.cancel;
    }, [topBanners.length]);

    final quickActions = homeState.quickActions;

    final showBannerPlaceholder = topBanners.isEmpty &&
        homeState.errorMessage == null &&
        (homeState.isFetching || quickActions == null);
    final topBannerHeight = 120.h;
    final bannerAreaHeight = (topBanners.isNotEmpty || showBannerPlaceholder)
        ? topBannerHeight
        : 0.h;

    final middleBannerPage = useState(0);
    final middleBannerController =
        useMemoized(() => PageController(), const []);
    useEffect(() {
      if (middleBanners.length < 2) return null;
      final timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!middleBannerController.hasClients) return;
        final next = (middleBannerPage.value + 1) % middleBanners.length;
        middleBannerController.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
      return timer.cancel;
    }, [middleBanners.length]);

    final bottomBannerPage = useState(0);
    final bottomBannerController =
        useMemoized(() => PageController(), const []);
    useEffect(() {
      if (bottomBanners.length < 2) return null;
      final timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!bottomBannerController.hasClients) return;
        final next = (bottomBannerPage.value + 1) % bottomBanners.length;
        bottomBannerController.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
      return timer.cancel;
    }, [bottomBanners.length]);

    final bankingBannerPage = useState(0);
    final bankingBannerController =
        useMemoized(() => PageController(), const []);
    useEffect(() {
      if (bankingInvestmentBanners.length < 2) return null;
      final timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!bankingBannerController.hasClients) return;
        final next =
            (bankingBannerPage.value + 1) % bankingInvestmentBanners.length;
        bankingBannerController.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
      return timer.cancel;
    }, [bankingInvestmentBanners.length]);

    QuickActionCategory? findCategory(
      List<QuickActionCategory> categories,
      List<String> keywords,
    ) {
      for (final category in categories) {
        final label = category.category.toLowerCase();
        if (keywords.any((keyword) => label.contains(keyword))) {
          return category;
        }
      }
      return categories.isNotEmpty ? categories.first : null;
    }

    Future<void> handleServiceTap(String serviceName) async {
      if (!hasInternet) {
        AppSnackbar.show('No internet connection. Please try again.');
        return;
      }
      if (serviceName == 'Credit Card') {
        if (homeState.isFetchingCreditCards) {
          return;
        }
        await ref
            .read(homeControllerProvider.notifier)
            .fetchCreditCardActions();
        final cards = ref.read(homeControllerProvider).creditCardActions;
        if (cards != null && cards.isNotEmpty) {
          context.push(RouteConstants.creditCardMyCards);
        } else {
          context.push(RouteConstants.creditCardListing);
        }
      } else if (serviceName == 'Mobile Prepaid') {
        context.push(RouteConstants.mobileRecentRecharges);
      } else if (serviceName == 'Tuition Fees' ||
          serviceName == 'Tution Fees' ||
          serviceName == 'School Fees' ||
          serviceName == 'College Fees') {
        context.push(
          RouteConstants.educationFeesAmount,
          extra: serviceName,
        );
      } else {
        context.push(
          RouteConstants.billerListing,
          extra: serviceName,
        );
      }
    }

    final initials = profileState.profile?.initials.isNotEmpty == true
        ? profileState.profile!.initials
        : '';
    final walletBalance = profileState.profile?.walletBalance;
    final isWalletLoading =
        profileState.profile == null && profileState.isFetching;
    final hasWalletError =
        profileState.profile == null && profileState.errorMessage != null;
    final payBillsCategory = quickActions == null
        ? null
        : findCategory(quickActions, ['utilities', 'bills', 'expenses']);
    final educationCategory = quickActions == null
        ? null
        : findCategory(quickActions, ['education', 'lifestyle']);
    final insuranceCategory = quickActions == null
        ? null
        : findCategory(quickActions, ['insurance', 'rent', 'property']);
    bool isHouseOrShopRent(QuickActionService service) {
      final name = service.name.trim().toLowerCase();
      return name.contains('house rent') ||
          name.contains('shop rent') ||
          name == 'house rent' ||
          name == 'shop rent';
    }

    final educationServices = [
      ...(educationCategory?.services ?? const <QuickActionService>[]),
      ...?insuranceCategory?.services.where(
        (service) =>
            isHouseOrShopRent(service) &&
            !(educationCategory?.services ?? const []).any(
              (existing) =>
                  existing.name.trim().toLowerCase() ==
                  service.name.trim().toLowerCase(),
            ),
      ),
    ];
    final insuranceServices = (insuranceCategory?.services ?? const [])
        .where((service) => !isHouseOrShopRent(service))
        .toList()
      ..sort((a, b) {
        int rank(String name) {
          final n = name.toLowerCase();
          if (n.contains('life')) return 0;
          if (n.contains('health')) return 1;
          if (n.contains('general')) return 2;
          return 3;
        }

        return rank(a.name).compareTo(rank(b.name));
      });

    final activeTopBanner = topBanners.isEmpty
        ? null
        : topBanners[(topBannerPage.value.clamp(0, topBanners.length - 1))];
    final topBannerGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        activeTopBanner?.colorStart ?? const Color(0xFFFF835C),
        activeTopBanner?.colorEnd ?? const Color(0xFF994F37),
      ],
    );

    return _HomeScaffoldBody(
      topBannerGradient: topBannerGradient,
      onRefresh: () => Future.wait([
        ref.read(homeControllerProvider.notifier).fetchQuickActions(),
        ref.read(homeControllerProvider.notifier).fetchAllQuickActions(),
        ref.read(spinOptionsControllerProvider.notifier).fetchSpinOptions(),
        ref.read(profileControllerProvider.notifier).fetchProfile(),
      ]),
      quickActions: quickActions,
      homeErrorMessage: homeState.errorMessage,
      isServerUnavailable: homeState.isServerUnavailable,
      bannerAreaHeight: bannerAreaHeight,
      topBanners: topBanners,
      topBannerController: topBannerController,
      topBannerPage: topBannerPage.value,
      onTopBannerPageChanged: (page) => topBannerPage.value = page,
      showBannerPlaceholder: showBannerPlaceholder,
      topBannerHeight: topBannerHeight,
      initials: initials,
      walletBalance: walletBalance,
      isWalletLoading: isWalletLoading,
      hasWalletError: hasWalletError,
      onSearchTap: () {
        PersistentNavBarNavigator.pushNewScreen(
          context,
          screen: const HomeSearchView(),
          withNavBar: false,
        );
      },
      onReferTap: () {
        PersistentNavBarNavigator.pushNewScreen(
          context,
          screen: const ReferAndEarnView(),
          withNavBar: false,
        );
      },
      onProfileTap: () {
        PersistentNavBarNavigator.pushNewScreen(
          context,
          screen: const ProfileView(),
          withNavBar: false,
        );
      },
      onRetryHome: () =>
          ref.read(homeControllerProvider.notifier).fetchQuickActions(),
      onRestart: () => context.go(RouteConstants.splash),
      payBillsServices: payBillsCategory?.services ?? const [],
      educationServices: educationServices,
      insuranceServices: insuranceServices,
      onServiceTap: handleServiceTap,
      onMyBillsTap: () => context.push(RouteConstants.quickActions),
      onExploreUtilitiesTap: () => context.push(RouteConstants.homeSearchView),
      onGoldTap: _showInvestmentComingSoonMessage,
      onSilverTap: _showInvestmentComingSoonMessage,
      bankingInvestmentBanners: bankingInvestmentBanners,
      bankingBannerController: bankingBannerController,
      bankingBannerPage: bankingBannerPage.value,
      onBankingBannerPageChanged: (page) => bankingBannerPage.value = page,
      onBankingBannerTap: () {
        final index = bankingBannerPage.value;
        final banner = index >= 0 && index < bankingInvestmentBanners.length
            ? bankingInvestmentBanners[index]
            : null;
        final redirectUrl = banner?.redirectUrl;
        if (redirectUrl != null && redirectUrl.trim().isNotEmpty) {
          BannerRedirectMapper.handle(context, redirectUrl);
          return;
        }
        _showInvestmentComingSoonMessage();
      },
      middleBanners: middleBanners,
      middleBannerController: middleBannerController,
      middleBannerPage: middleBannerPage.value,
      onMiddleBannerPageChanged: (page) => middleBannerPage.value = page,
      bottomBanners: bottomBanners,
      bottomBannerController: bottomBannerController,
      bottomBannerPage: bottomBannerPage.value,
      onBottomBannerPageChanged: (page) => bottomBannerPage.value = page,
      onMiddleBannerTap: (index) => BannerRedirectMapper.handle(
        context,
        middleBanners[index].redirectUrl,
      ),
      onBottomBannerTap: (index) => BannerRedirectMapper.handle(
        context,
        bottomBanners[index].redirectUrl,
      ),
      onSpinTap: () => context.push(RouteConstants.spinAndWin),
      onFaqTap: () => context.push(RouteConstants.faq),
      isFetchingCreditCards: homeState.isFetchingCreditCards,
    );
  }
}

class _HomeScaffoldBody extends StatelessWidget {
  const _HomeScaffoldBody({
    required this.topBannerGradient,
    required this.onRefresh,
    required this.quickActions,
    required this.homeErrorMessage,
    required this.isServerUnavailable,
    required this.bannerAreaHeight,
    required this.topBanners,
    required this.topBannerController,
    required this.topBannerPage,
    required this.onTopBannerPageChanged,
    required this.showBannerPlaceholder,
    required this.topBannerHeight,
    required this.initials,
    required this.walletBalance,
    required this.isWalletLoading,
    required this.hasWalletError,
    required this.onSearchTap,
    required this.onReferTap,
    required this.onProfileTap,
    required this.onRetryHome,
    required this.onRestart,
    required this.payBillsServices,
    required this.educationServices,
    required this.insuranceServices,
    required this.onServiceTap,
    required this.onMyBillsTap,
    required this.onExploreUtilitiesTap,
    required this.onGoldTap,
    required this.onSilverTap,
    required this.bankingInvestmentBanners,
    required this.bankingBannerController,
    required this.bankingBannerPage,
    required this.onBankingBannerPageChanged,
    required this.onBankingBannerTap,
    required this.middleBanners,
    required this.middleBannerController,
    required this.middleBannerPage,
    required this.onMiddleBannerPageChanged,
    required this.bottomBanners,
    required this.bottomBannerController,
    required this.bottomBannerPage,
    required this.onBottomBannerPageChanged,
    required this.onMiddleBannerTap,
    required this.onBottomBannerTap,
    required this.onSpinTap,
    required this.onFaqTap,
    required this.isFetchingCreditCards,
  });

  final Gradient topBannerGradient;
  final RefreshCallback onRefresh;
  final List<QuickActionCategory>? quickActions;
  final String? homeErrorMessage;
  final bool isServerUnavailable;
  final double bannerAreaHeight;
  final List<BannerModel> topBanners;
  final PageController topBannerController;
  final int topBannerPage;
  final ValueChanged<int> onTopBannerPageChanged;
  final bool showBannerPlaceholder;
  final double topBannerHeight;
  final String initials;
  final double? walletBalance;
  final bool isWalletLoading;
  final bool hasWalletError;
  final VoidCallback onSearchTap;
  final VoidCallback onReferTap;
  final VoidCallback onProfileTap;
  final VoidCallback onRetryHome;
  final VoidCallback onRestart;
  final List<QuickActionService> payBillsServices;
  final List<QuickActionService> educationServices;
  final List<QuickActionService> insuranceServices;
  final Future<void> Function(String serviceName) onServiceTap;
  final VoidCallback onMyBillsTap;
  final VoidCallback onExploreUtilitiesTap;
  final VoidCallback onGoldTap;
  final VoidCallback onSilverTap;
  final List<BannerModel> bankingInvestmentBanners;
  final PageController bankingBannerController;
  final int bankingBannerPage;
  final ValueChanged<int> onBankingBannerPageChanged;
  final VoidCallback onBankingBannerTap;
  final List<BannerModel> middleBanners;
  final PageController middleBannerController;
  final int middleBannerPage;
  final ValueChanged<int> onMiddleBannerPageChanged;
  final List<BannerModel> bottomBanners;
  final PageController bottomBannerController;
  final int bottomBannerPage;
  final ValueChanged<int> onBottomBannerPageChanged;
  final ValueChanged<int> onMiddleBannerTap;
  final ValueChanged<int> onBottomBannerTap;
  final VoidCallback onSpinTap;
  final VoidCallback onFaqTap;
  final bool isFetchingCreditCards;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: topBannerGradient),
            ),
          ),
          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: onRefresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _HomeTopSliverAppBar(
                  gradient: topBannerGradient,
                  bannerAreaHeight: bannerAreaHeight,
                  topBanners: topBanners,
                  topBannerController: topBannerController,
                  topBannerPage: topBannerPage,
                  onTopBannerPageChanged: onTopBannerPageChanged,
                  showBannerPlaceholder: showBannerPlaceholder,
                  topBannerHeight: topBannerHeight,
                  initials: initials,
                  walletBalance: walletBalance,
                  isWalletLoading: isWalletLoading,
                  hasWalletError: hasWalletError,
                  onSearchTap: onSearchTap,
                  onReferTap: onReferTap,
                  onProfileTap: onProfileTap,
                ),
                if (quickActions == null && homeErrorMessage == null)
                  const HomeShimmer()
                else if (homeErrorMessage != null && quickActions == null)
                  SliverToBoxAdapter(
                    child: _HomeErrorState(
                      isServerUnavailable: isServerUnavailable,
                      onRetry: onRetryHome,
                      onRestart: onRestart,
                    ),
                  )
                else if (quickActions != null)
                  SliverToBoxAdapter(
                    child: _HomeMainSections(
                      payBillsServices: payBillsServices,
                      educationServices: educationServices,
                      insuranceServices: insuranceServices,
                      isFetchingCreditCards: isFetchingCreditCards,
                      onServiceTap: onServiceTap,
                      onMyBillsTap: onMyBillsTap,
                      onExploreUtilitiesTap: onExploreUtilitiesTap,
                      onGoldTap: onGoldTap,
                      onSilverTap: onSilverTap,
                      bankingInvestmentBanners: bankingInvestmentBanners,
                      bankingBannerController: bankingBannerController,
                      bankingBannerPage: bankingBannerPage,
                      onBankingBannerPageChanged: onBankingBannerPageChanged,
                      onBankingBannerTap: onBankingBannerTap,
                      middleBanners: middleBanners,
                      middleBannerController: middleBannerController,
                      middleBannerPage: middleBannerPage,
                      onMiddleBannerPageChanged: onMiddleBannerPageChanged,
                      bottomBanners: bottomBanners,
                      bottomBannerController: bottomBannerController,
                      bottomBannerPage: bottomBannerPage,
                      onBottomBannerPageChanged: onBottomBannerPageChanged,
                      onMiddleBannerTap: onMiddleBannerTap,
                      onBottomBannerTap: onBottomBannerTap,
                      onSpinTap: onSpinTap,
                      onFaqTap: onFaqTap,
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

class _HomeTopSliverAppBar extends StatelessWidget {
  const _HomeTopSliverAppBar({
    required this.gradient,
    required this.bannerAreaHeight,
    required this.topBanners,
    required this.topBannerController,
    required this.topBannerPage,
    required this.onTopBannerPageChanged,
    required this.showBannerPlaceholder,
    required this.topBannerHeight,
    required this.initials,
    required this.walletBalance,
    required this.isWalletLoading,
    required this.hasWalletError,
    required this.onSearchTap,
    required this.onReferTap,
    required this.onProfileTap,
  });

  final Gradient gradient;
  final double bannerAreaHeight;
  final List<BannerModel> topBanners;
  final PageController topBannerController;
  final int topBannerPage;
  final ValueChanged<int> onTopBannerPageChanged;
  final bool showBannerPlaceholder;
  final double topBannerHeight;
  final String initials;
  final double? walletBalance;
  final bool isWalletLoading;
  final bool hasWalletError;
  final VoidCallback onSearchTap;
  final VoidCallback onReferTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: 0,
      backgroundColor: const Color(0xffD66D4D),
      elevation: 0,
      toolbarHeight: 54.h,
      expandedHeight: MediaQuery.of(context).padding.top +
          36.h +
          14.h +
          bannerAreaHeight +
          (topBanners.length > 1 ? 16.h : 0.h),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.none,
        background: Container(
          decoration: BoxDecoration(gradient: gradient),
          child: Padding(
            padding: EdgeInsets.only(
              left: 16.w,
              right: 16.w,
              top: MediaQuery.of(context).padding.top + 58.h + 10.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 6.h),
                if (showBannerPlaceholder)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: AppNetworkImage(
                      url: '',
                      width: double.infinity,
                      height: topBannerHeight,
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  )
                else if (topBanners.isNotEmpty)
                  SizedBox(
                    height: topBannerHeight,
                    child: PageView.builder(
                      controller: topBannerController,
                      onPageChanged: onTopBannerPageChanged,
                      itemCount: topBanners.length,
                      itemBuilder: (_, index) {
                        final banner = topBanners[index];
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: GestureDetector(
                            onTap: () => BannerRedirectMapper.handle(
                              context,
                              banner.redirectUrl,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14.r),
                              child: AppNetworkImage(
                                url: banner.image,
                                width: double.infinity,
                                height: topBannerHeight,
                                fit: BoxFit.contain,
                                placeholder: AppNetworkImage(
                                  url: '',
                                  width: double.infinity,
                                  height: topBannerHeight,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                SizedBox(height: 4.h),
                if (topBanners.length > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      topBanners.length,
                      (index) => Padding(
                        padding: EdgeInsets.symmetric(horizontal: 3.w),
                        child: _Dot(active: topBannerPage == index),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      title: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: _HomeTopBar(
          initials: initials,
          walletBalance: walletBalance,
          isWalletLoading: isWalletLoading,
          hasWalletError: hasWalletError,
          compact: true,
          onSearchTap: onSearchTap,
          onReferTap: onReferTap,
          onProfileTap: onProfileTap,
        ),
      ),
    );
  }
}

class _HomeMainSections extends StatelessWidget {
  const _HomeMainSections({
    required this.payBillsServices,
    required this.educationServices,
    required this.insuranceServices,
    required this.isFetchingCreditCards,
    required this.onServiceTap,
    required this.onMyBillsTap,
    required this.onExploreUtilitiesTap,
    required this.onGoldTap,
    required this.onSilverTap,
    required this.bankingInvestmentBanners,
    required this.bankingBannerController,
    required this.bankingBannerPage,
    required this.onBankingBannerPageChanged,
    required this.onBankingBannerTap,
    required this.middleBanners,
    required this.middleBannerController,
    required this.middleBannerPage,
    required this.onMiddleBannerPageChanged,
    required this.bottomBanners,
    required this.bottomBannerController,
    required this.bottomBannerPage,
    required this.onBottomBannerPageChanged,
    required this.onMiddleBannerTap,
    required this.onBottomBannerTap,
    required this.onSpinTap,
    required this.onFaqTap,
  });

  final List<QuickActionService> payBillsServices;
  final List<QuickActionService> educationServices;
  final List<QuickActionService> insuranceServices;
  final bool isFetchingCreditCards;
  final Future<void> Function(String serviceName) onServiceTap;
  final VoidCallback onMyBillsTap;
  final VoidCallback onExploreUtilitiesTap;
  final VoidCallback onGoldTap;
  final VoidCallback onSilverTap;
  final List<BannerModel> bankingInvestmentBanners;
  final PageController bankingBannerController;
  final int bankingBannerPage;
  final ValueChanged<int> onBankingBannerPageChanged;
  final VoidCallback onBankingBannerTap;
  final List<BannerModel> middleBanners;
  final PageController middleBannerController;
  final int middleBannerPage;
  final ValueChanged<int> onMiddleBannerPageChanged;
  final List<BannerModel> bottomBanners;
  final PageController bottomBannerController;
  final int bottomBannerPage;
  final ValueChanged<int> onBottomBannerPageChanged;
  final ValueChanged<int> onMiddleBannerTap;
  final ValueChanged<int> onBottomBannerTap;
  final VoidCallback onSpinTap;
  final VoidCallback onFaqTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(18.r),
        topRight: Radius.circular(18.r),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18.r),
            topRight: Radius.circular(18.r),
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 20,
              offset: Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    title: 'Pay Bills & Expenses',
                    actionLabel: 'My Bills',
                    onAction: onMyBillsTap,
                  ),
                  SizedBox(height: 14.h),
                  _PayBillsCard(
                    services: payBillsServices,
                    onTap: onServiceTap,
                    onExploreTap: onExploreUtilitiesTap,
                    isCreditCardLoading: isFetchingCreditCards,
                  ),
                  SizedBox(height: 12.h),
                  const _SectionHeader(title: 'Banking & Investments'),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: onGoldTap,
                          child: _InvestmentTile(
                            label: 'Buy Gold',
                            iconAsset: FileConstants.digitalGoldGif,
                            arrowAsset: FileConstants.goldArrow,
                            borderColor: const Color(0xFFE0C46A),
                            textColor: const Color(0xFF8B6B12),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: GestureDetector(
                          onTap: onSilverTap,
                          child: _InvestmentTile(
                            label: 'Buy Silver',
                            iconAsset: FileConstants.digitalSilverGif,
                            arrowAsset: FileConstants.silverArrow,
                            borderColor: const Color(0xFFE1E1E1),
                            textColor: const Color(0xFF6B6B6B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (bankingInvestmentBanners.isNotEmpty) ...[
              SizedBox(height: 18.h),
              InkWell(
                onTap: onBankingBannerTap,
                child: SizedBox(
                  height: 60.h,
                  width: double.infinity,
                  child: PageView.builder(
                    controller: bankingBannerController,
                    onPageChanged: onBankingBannerPageChanged,
                    itemCount: bankingInvestmentBanners.length,
                    itemBuilder: (_, index) => AppNetworkImage(
                      url: bankingInvestmentBanners[index].image,
                      width: double.infinity,
                      height: 60.h,
                      fit: BoxFit.contain,
                      placeholder: AppNetworkImage(
                        url: '',
                        width: double.infinity,
                        height: 60.h,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'PAY VIA CREDIT CARD',
                      textAlign: TextAlign.left,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        color: AppColors.textPrimary.withOpacity(0.45),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _CurvedIconGrid(
                    services: educationServices,
                    onTap: onServiceTap,
                    maxItems: 8,
                    showCardFrame: false,
                    labelBuilder: (service) {
                      final name = service.name.trim();
                      final lower = name.toLowerCase();
                      if (lower.contains('house rent')) {
                        return 'House Rent';
                      }
                      if (lower.contains('shop rent')) {
                        return 'Shop Rent';
                      }
                      return name;
                    },
                  ),
                  SizedBox(height: middleBanners.isNotEmpty ? 0.h : 18.h),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  if (middleBanners.isNotEmpty) SizedBox(height: 18.h),
                  if (middleBanners.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: SizedBox(
                        height: 110.h,
                        child: PageView.builder(
                          controller: middleBannerController,
                          onPageChanged: onMiddleBannerPageChanged,
                          itemCount: middleBanners.length,
                          itemBuilder: (_, index) => GestureDetector(
                            onTap: () => onMiddleBannerTap(index),
                            child: AppNetworkImage(
                              url: middleBanners[index].image,
                              width: double.infinity,
                              height: 110.h,
                              fit: BoxFit.contain,
                              placeholder: AppNetworkImage(
                                url: '',
                                width: double.infinity,
                                height: 110.h,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (middleBanners.isNotEmpty) SizedBox(height: 6.h),
                  if (middleBanners.length > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        middleBanners.length,
                        (index) => Padding(
                          padding: EdgeInsets.symmetric(horizontal: 3.w),
                          child: _Dot(active: middleBannerPage == index),
                        ),
                      ),
                    ),
                  if (middleBanners.isNotEmpty) SizedBox(height: 18.h),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0.h, 16.w, 8.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'INSURANCE',
                      textAlign: TextAlign.left,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        color: AppColors.textPrimary.withOpacity(0.45),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _CurvedIconGrid(
                    services: insuranceServices,
                    onTap: onServiceTap,
                    showCardFrame: false,
                    labelBuilder: (service) {
                      final name = service.name.trim();
                      final lower = name.toLowerCase();
                      if (lower.contains('life')) return 'Life Insurance';
                      if (lower.contains('health')) return 'Health Insurance';
                      if (lower.contains('general')) return 'General Insurance';
                      if (lower.contains('insurance')) return name;
                      return name;
                    },
                  ),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: _ImageBanner(
                asset: FileConstants.homeBanner9,
                height: 60.h,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MiniActionCard(
                          title: 'Gift card',
                          subtitle: 'Gift your friends',
                          asset: FileConstants.giftGif,
                          backgroundColor: const Color(0xFFFFF3EE),
                          gradientBorder: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFFFF9776),
                              Color(0xFFDD5428),
                            ],
                          ),
                          onTap: () {},
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _MiniActionCard(
                          title: 'Spin & Win',
                          subtitle: 'Win big prizes',
                          asset: FileConstants.spinIcon,
                          backgroundColor: const Color(0xFFEAF2FF),
                          borderColor: const Color(0xFF002352),
                          onTap: onSpinTap,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  _SupportTile(
                    title: 'FAQ & Support',
                    onTap: onFaqTap,
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
            if (bottomBanners.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                height: 130.h,
                child: PageView.builder(
                  controller: bottomBannerController,
                  onPageChanged: onBottomBannerPageChanged,
                  itemCount: bottomBanners.length,
                  itemBuilder: (_, index) => GestureDetector(
                    onTap: () => onBottomBannerTap(index),
                    child: AppNetworkImage(
                      url: bottomBanners[index].image,
                      width: double.infinity,
                      height: 130.h,
                      fit: BoxFit.cover,
                      placeholder: AppNetworkImage(
                        url: '',
                        width: double.infinity,
                        height: 130.h,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 6.h),
              if (bottomBanners.length > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    bottomBanners.length,
                    (index) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3.w),
                      child: _Dot(active: bottomBannerPage == index),
                    ),
                  ),
                ),
            ],
            Container(
              decoration: const BoxDecoration(color: Color(0XFFFDFDFD)),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 24.h),
                child: Row(
                  children: [
                    Text(
                      'Powered by',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                    ),
                    SizedBox(width: 6.w),
                    Image.asset(
                      FileConstants.bharatConnectColor,
                      height: 25.h,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

TemporaryBlockFlowType? _resolveTemporaryBlockFlow(ProfileModel? profile) {
  if (TemporaryBlockDebugConfig.enabled) {
    return TemporaryBlockDebugConfig.flowType;
  }
  return null;
}

class _HomeErrorState extends StatelessWidget {
  const _HomeErrorState({
    this.isServerUnavailable = false,
    required this.onRetry,
    required this.onRestart,
  });

  final bool isServerUnavailable;
  final VoidCallback onRetry;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    if (isServerUnavailable) {
      return Padding(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
        child: Column(
          children: [
            Text(
              'Opps!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 20.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1ED),
                borderRadius: BorderRadius.circular(22.r),
              ),
              child: Image.asset(
                FileConstants.serverDown,
                height: 160.h,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 28.h),
            Text(
              'Something Went Wrong',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 10.h),
            Text(
              'We’re currently facing a temporary server issue.\nYour account and funds remain safe and secure.\nPlease try again after a few minutes.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.8),
                    height: 1.55,
                  ),
            ),
            SizedBox(height: 18.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE5DE),
                borderRadius: BorderRadius.circular(999.r),
              ),
              child: Text(
                'Error Code: ERU-SRV-503',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 32.h),
      child: Column(
        children: [
          Image.asset(
            FileConstants.somethingWentWrong,
            width: 170.w,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 20.h),
          Text(
            'Something Went Wrong',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: 6.h),
          Text(
            'We’re facing a temporary issue loading your data. Please try again.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.7),
                  height: 1.4,
                ),
          ),
          SizedBox(height: 18.h),
          Row(
            children: [
              Expanded(
                child: CustomElevatedButton(
                  onPressed: onRetry,
                  label: 'Retry',
                  uppercaseLabel: false,
                  height: 35.h,
                  isBorder: true,
                  backgroundColor: Colors.white,
                  borderColor: AppColors.primary,
                  labelColor: AppColors.primary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: CustomElevatedButton(
                  onPressed: onRestart,
                  label: 'Restart',
                  uppercaseLabel: false,
                  height: 35.h,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeReminderDialog extends StatelessWidget {
  const _HomeReminderDialog({
    required this.data,
    this.onPrimaryTap,
  });

  final BillReminderItem data;
  final VoidCallback? onPrimaryTap;

  void _close(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 30.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 18.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: const Color(0xFF7A2E11),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _billReminderTitle(data.paymentType),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 16.sp,
                  ),
            ),
            SizedBox(height: 4.h),
            Text(
              _billReminderDueText(data),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5.sp,
                  ),
            ),
            SizedBox(height: 14.h),
            Container(
              width: 82.w,
              height: 82.w,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE8E8E8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: data.billerIcon.trim().isNotEmpty
                  ? ClipOval(
                      child: AppNetworkImage(
                        url: data.billerIcon,
                        fit: BoxFit.contain,
                        showShimmer: false,
                      ),
                    )
                  : Image.asset(
                      FileConstants.bharatConnectColor,
                      fit: BoxFit.contain,
                    ),
            ),
            SizedBox(height: 12.h),
            Text(
              _billReminderIdentifier(data),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFF05A28),
                    fontWeight: FontWeight.w500,
                    fontSize: 15.sp,
                  ),
            ),
            SizedBox(height: 6.h),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.black,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                    ),
                children: [
                  const TextSpan(text: 'Amount Due: '),
                  TextSpan(
                    text: _formatReminderAmount(data.lastBillAmount),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.black,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 10.h,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Text(
                _billReminderMessage(data),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black.withOpacity(0.78),
                      fontSize: 12.sp,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: CustomElevatedButton(
                    onPressed: () => _close(context),
                    label: 'Later',
                    uppercaseLabel: false,
                    height: 40.h,
                    isBorder: true,
                    backgroundColor: Colors.white,
                    borderColor: const Color(0xFFF05A28),
                    labelColor: const Color(0xFFF05A28),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: CustomElevatedButton(
                    onPressed: onPrimaryTap,
                    label: 'Pay Now',
                    uppercaseLabel: false,
                    height: 40.h,
                    backgroundColor: const Color(0xFFF05A28),
                    labelColor: Colors.white,
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

String _billReminderTitle(String paymentType) {
  final trimmed = paymentType.trim();
  if (trimmed.isEmpty) return 'Reminder';
  if (trimmed.toLowerCase() == 'recharge') return 'Recharge Reminder';
  return '$trimmed Reminder';
}

String _billReminderMessage(BillReminderItem data) {
  final description = data.description?.trim() ?? '';
  if (description.isNotEmpty) return description;
  return 'Pay before the due date to avoid late payment charges.';
}

String _billReminderDueText(BillReminderItem data) {
  final dueDate = _formatReminderDate(data.dueDate);
  final daysRemaining = data.daysRemaining;
  if (daysRemaining > 0 && dueDate.isNotEmpty) {
    final label = daysRemaining == 1 ? 'Day' : 'Days';
    return 'Due in $daysRemaining $label : $dueDate';
  }
  final note = data.note.trim();
  if (note.isNotEmpty && dueDate.isNotEmpty) {
    return '$note : $dueDate';
  }
  if (dueDate.isNotEmpty) return dueDate;
  return note;
}

String _billReminderIdentifier(BillReminderItem data) {
  final paymentType = data.paymentType.trim().toLowerCase();
  final masked = data.maskedIdentifier.trim();
  final mobile = data.customerMobile.trim();
  if (paymentType.contains('mobile') || paymentType.contains('recharge')) {
    if (mobile.isNotEmpty) return mobile;
    if (masked.isNotEmpty) return masked;
    return data.billerId.trim();
  }
  if (masked.isNotEmpty) return masked;
  if (mobile.isNotEmpty) return mobile;
  return data.billerId.trim();
}

String _resolveReminderPrefillValue(BillReminderItem data) {
  final paymentType = data.paymentType.trim().toLowerCase();
  final masked = data.maskedIdentifier.trim();
  final mobile = data.customerMobile.trim();
  if (paymentType.contains('credit')) {
    return mobile;
  }
  if (paymentType.contains('mobile') || paymentType.contains('recharge')) {
    if (mobile.isNotEmpty) return mobile;
    return masked;
  }
  if (masked.isNotEmpty) return masked;
  return mobile;
}

String _formatReminderAmount(double amount) {
  final absolute = amount.abs();
  final isWhole = absolute == absolute.truncateToDouble();
  final value =
      isWhole ? absolute.toStringAsFixed(0) : absolute.toStringAsFixed(2);
  return '₹$value';
}

String _formatReminderDate(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
}
