// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unused_element, unused_element_parameter, unused_local_variable

part of 'home_view.dart';

const String _myBillsArrowSvg = '''
<svg width="16" height="16" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect width="16" height="16" rx="8" fill="#DD5428"/>
<path d="M8.53424 11.2L11.7342 8.00005L8.53424 4.80005M11.7342 8.00005H4.26758" stroke="white" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

const String _exploreUtilitiesArrowSvg = '''
<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect width="20" height="20" rx="10" fill="black"/>
<path d="M10.6673 14L14.6673 10L10.6673 6M14.6673 10H5.33398" stroke="white" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

const String _profileIconSvg = '''
<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect width="32" height="32" rx="16" fill="url(#paint0_linear_91152_36472)"/>
<defs>
<linearGradient id="paint0_linear_91152_36472" x1="16" y1="0" x2="16" y2="32" gradientUnits="userSpaceOnUse">
<stop stop-color="#DD5428"/>
<stop offset="1" stop-color="#DD5428"/>
</linearGradient>
</defs>
</svg>
''';

double _homeMin(double a, double b) => a < b ? a : b;

/// Physical-pixel decode size for a square GIF. Uses the larger logical side
/// so BoxFit.cover/contain keeps the source crop instead of stretching it.
int _gifCachePixels(
  BuildContext context,
  double logicalWidth,
  double logicalHeight,
) {
  final logical = logicalWidth > logicalHeight ? logicalWidth : logicalHeight;
  return _cachePixels(context, logical);
}

int _cachePixels(BuildContext context, double logical) {
  if (logical <= 0) return 1;
  final pixels = (logical * MediaQuery.devicePixelRatioOf(context)).round();
  return pixels < 1 ? 1 : pixels;
}

/// Figma SVG exports that wrap a PNG. flutter_svg cannot paint those
/// `<image>` patterns, so we render the extracted PNG sibling instead.
String _rasterHomeAsset(String asset) {
  const mapped = {
    'assets/images/svg/invest_gold.svg': 'assets/images/png/invest_gold.png',
    'assets/images/svg/invest_silver.svg':
        'assets/images/png/invest_silver.png',
    'assets/images/svg/zero_balance_account.svg':
        'assets/images/png/zero_balance_account.png',
    'assets/images/svg/zerobalance.svg': 'assets/images/png/zerobalance_hd.png',
  };
  return mapped[asset] ?? asset;
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 14 : 8,
      height: 8.h,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.lightBorder,
        borderRadius: BorderRadius.circular(10.r),
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
                  padding: EdgeInsets.symmetric(
                    horizontal: 5.w,
                    vertical: 2.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  constraints: const BoxConstraints(minWidth: 16),
                  child: Text(
                    (badgeCount ?? 0) > 9 ? '9+' : '${badgeCount ?? 0}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.sp,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Dot(active: true),
        SizedBox(width: 6.w),
        _Dot(active: false),
        SizedBox(width: 6.w),
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
          fit: BoxFit.contain,
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
        final wrapper = size;
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
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 0.h,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(7.r),
                      border: Border.all(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.sp,
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
    this.profilePhotoUrl,
    required this.walletBalance,
    this.isWalletLoading = false,
    this.hasWalletError = false,
    required this.onSearchTap,
    required this.onReferTap,
    required this.onProfileTap,
    this.compact = false,
  });

  final String initials;
  final String? profilePhotoUrl;
  final double? walletBalance;
  final bool isWalletLoading;
  final bool hasWalletError;
  final VoidCallback onSearchTap;
  final VoidCallback onReferTap;
  final VoidCallback onProfileTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontal = (screenWidth * 0.055).clamp(14.0, 24.0);
    final topGap = (screenWidth * 0.016).clamp(4.0, 8.0);
    final bottomGap = (screenWidth * 0.01).clamp(2.0, 6.0);
    final barHeight = (32.w).clamp(28.0, 34.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontal, topGap, horizontal, bottomGap),
      child: SizedBox(
        height: barHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final gap = (8.w).clamp(4.0, 10.0);
            var referWidth = 111.w;
            var coinWidth = 66.w;
            if (referWidth > 120) referWidth = 120;
            if (coinWidth > 78) coinWidth = 78;
            final chips = referWidth + coinWidth + gap;
            final room = maxWidth - barHeight - gap;
            if (room > 0 && chips > room) {
              final scale = room / chips;
              referWidth *= scale;
              coinWidth *= scale;
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: onProfileTap,
                  child: _ProfileAvatar(
                    initials: initials,
                    profilePhotoUrl: profilePhotoUrl,
                    size: barHeight,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onReferTap,
                  child: _ReferAndEarnChip(
                    compact: compact,
                    height: barHeight,
                    width: referWidth,
                  ),
                ),
                SizedBox(width: gap),
                GestureDetector(
                  onTap: () {
                    context.push(RouteConstants.referAndEarnWallet);
                  },
                  child: _eCoinsPill(context, barHeight, coinWidth),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _eCoinsPill(BuildContext context, double height, double width) {
    final textStyle = GoogleFonts.plusJakartaSans(
      textStyle: Theme.of(context).textTheme.bodySmall,
    );
    final resolvedWalletBalance = walletBalance;
    final displayBalance = resolvedWalletBalance == null
        ? '--'
        : resolvedWalletBalance == resolvedWalletBalance.roundToDouble()
            ? resolvedWalletBalance.toStringAsFixed(0)
            : resolvedWalletBalance.toStringAsFixed(2);
    final iconSide = (height * 0.5).clamp(14.0, 18.0);
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.hardEdge,
      padding: EdgeInsets.symmetric(horizontal: (width * 0.1).clamp(4.0, 8.0)),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(height),
      ),
      child: Row(
        children: [
          Image.asset(
            FileConstants.favicon,
            width: iconSide,
            height: iconSide,
            fit: BoxFit.contain,
          ),
          SizedBox(width: (width * 0.06).clamp(2.0, 4.0)),
          Expanded(
            child: isWalletLoading
                ? Center(
                    child: SizedBox(
                      width: 12.w,
                      height: 12.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      displayBalance,
                      maxLines: 1,
                      style: textStyle.copyWith(
                        color: const Color(0xFF000000),
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp,
                        height: 1,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.initials,
    required this.size,
    this.profilePhotoUrl,
  });
  final String initials;
  final double size;
  final String? profilePhotoUrl;

  @override
  Widget build(BuildContext context) {
    final side = size;
    final photoUrl = profilePhotoUrl?.trim() ?? '';
    return SizedBox(
      width: side,
      height: side,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: photoUrl.isEmpty
            ? _ProfileInitials(initials: initials, side: side)
            : AppNetworkImage(
                url: photoUrl,
                width: side,
                height: side,
                fit: BoxFit.cover,
                showShimmer: false,
                errorWidget: _ProfileInitials(initials: initials, side: side),
              ),
      ),
    );
  }
}

class _ProfileInitials extends StatelessWidget {
  const _ProfileInitials({required this.initials, required this.side});

  final String initials;
  final double side;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: side,
      height: side,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.string(
            _profileIconSvg,
            width: side,
            height: side,
            fit: BoxFit.cover,
          ),
          Text(
            initials,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11.sp,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferAndEarnChip extends StatelessWidget {
  const _ReferAndEarnChip({
    required this.compact,
    required this.height,
    required this.width,
  });

  final bool compact;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    final iconSide = (height * 0.5).clamp(12.0, 16.0);
    final radius = height / 2;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: width,
          height: height,
          padding: EdgeInsets.symmetric(horizontal: (width * 0.08).clamp(6.0, 10.0)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.38),
                Colors.white.withOpacity(0.12),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.45),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              RepaintBoundary(
                child: Image.asset(
                  FileConstants.giftGif,
                  width: iconSide,
                  height: iconSide,
                  cacheWidth: _gifCachePixels(context, iconSide, iconSide),
                  cacheHeight: _gifCachePixels(context, iconSide, iconSide),
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              ),
              SizedBox(width: (width * 0.04).clamp(2.0, 4.0)),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Refer & Earn',
                    maxLines: 1,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF000000),
                      fontWeight: FontWeight.w600,
                      fontSize: 12.sp,
                      height: 1,
                      letterSpacing: 0,
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
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 14.r,
            offset: Offset(0.w, 8.h),
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
    this.payBillsStyle = false,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool payBillsStyle;

  @override
  Widget build(BuildContext context) {
    final titleStyle = homeSectionHeaderStyle();
    final actionStyle = payBillsStyle
        ? GoogleFonts.plusJakartaSans(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            height: 1.2,
            letterSpacing: 0,
            color: const Color(0xFFDD5428),
          )
        : GoogleFonts.plusJakartaSans(
            textStyle: Theme.of(context).textTheme.bodyMedium,
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            height: 1.2,
          );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                homeServiceCardLabelText(title),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
            ),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: actionStyle,
                ),
                SizedBox(width: 6.w),
                if (payBillsStyle)
                  Container(
                    width: 16.w,
                    height: 16.w,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDD5428),
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.string(
                      _myBillsArrowSvg,
                      width: 16.w,
                      height: 16.w,
                      fit: BoxFit.contain,
                    ),
                  )
                else
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
    this.tileWidth = 80,
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
        final minTile = HomeServiceCircle.size;
        final tileSize =
            computedTileSize < minTile ? minTile : computedTileSize;
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
                              label:
                                  labelBuilder?.call(service) ?? service.name,
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
        localAsset: 'assets/images/svg/school_fees.svg',
      );
    }
    if (name.contains('college')) {
      return const _CreditCardIconSpec(
        localAsset: 'assets/images/svg/college_fees.svg',
      );
    }
    if (name.contains('tuition') || name.contains('tution')) {
      return const _CreditCardIconSpec(
        localAsset: 'assets/images/svg/tuition_fees.svg',
      );
    }
    if (name.contains('gym')) {
      return const _CreditCardIconSpec(
        localAsset: 'assets/images/svg/gym_membership.svg',
      );
    }
    if (name.contains('house rent') || name == 'house') {
      return const _CreditCardIconSpec(
        localAsset: 'assets/images/svg/house_rent.svg',
      );
    }
    if (name.contains('shop rent') || name == 'shop') {
      return const _CreditCardIconSpec(
        localAsset: 'assets/images/svg/shop_rent.svg',
      );
    }
    if (name.contains('against property') || name.contains('loan against')) {
      return const _CreditCardIconSpec(
        localAsset: 'assets/images/svg/loan_against_property.svg',
        width: 34,
        height: 34,
      );
    }
    if (name.contains('home loan')) {
      return const _CreditCardIconSpec(
        localAsset: 'assets/images/svg/home_loan.svg',
      );
    }
    if (name.contains('zero balance') || name == 'bank' || name == 'banking') {
      return const _CreditCardIconSpec(
        localAsset: 'assets/images/png/bank.png',
      );
    }
    if (name.contains('business loan')) {
      return const _CreditCardIconSpec(
        localAsset: 'assets/images/svg/business_loan.svg',
      );
    }
    if (name.contains('personal loan')) {
      return const _CreditCardIconSpec(
        localAsset: 'assets/images/svg/personal_loan.svg',
      );
    }
    if (name.contains('life')) {
      return const _CreditCardIconSpec(
        localAsset: 'assets/images/svg/life_insurance.svg',
      );
    }
    if (name.contains('health')) {
      return const _CreditCardIconSpec(
        localAsset: 'assets/images/svg/health_insurance.svg',
      );
    }
    if (name.contains('general')) {
      return const _CreditCardIconSpec(
        localAsset: 'assets/images/svg/general_insurance.svg',
      );
    }
    return const _CreditCardIconSpec();
  }
}

class _CreditCardIconSpec {
  const _CreditCardIconSpec({
    this.width = 34,
    this.height = 34,
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
    this.iconWidth = 34,
    this.iconHeight = 34,
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
    final baseIcon = homeServiceIconSize();
    final iconSizeW = baseIcon * iconWidth / 34;
    final iconSizeH = baseIcon * iconHeight / 34;
    Widget iconWidget = localIconAsset != null
        ? (localIconAsset!.toLowerCase().endsWith('.svg')
            ? SvgPicture.asset(
                localIconAsset!,
                width: iconSizeW,
                height: iconSizeH,
                fit: BoxFit.contain,
              )
            : Image.asset(
                localIconAsset!,
                width: iconSizeW,
                height: iconSizeH,
                fit: BoxFit.contain,
              ))
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

    final content = HomeServiceItem(
      icon: iconWidget,
      label: _labelLines(displayLabel),
      maxLines: _isSingleLineLabel(displayLabel) ? 1 : 2,
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

  /// Fee and gym labels read as one line in Figma.
  bool _isSingleLineLabel(String label) {
    final lower = label.toLowerCase();
    return lower.contains('gym') ||
        lower.contains('school') ||
        lower.contains('college') ||
        lower.contains('tuition') ||
        lower.contains('tution');
  }

  /// Explicit line breaks matching Figma, e.g. "Personal\nLoan",
  /// "Loan Against\nProperty".
  String _labelLines(String label) {
    if (_isSingleLineLabel(label)) return label;
    final words = label.trim().split(RegExp(r'\s+'));
    final last = words.isEmpty ? '' : words.last.toLowerCase();
    if (last == 'property' && words.length > 2) {
      return '${words.sublist(0, words.length - 1).join(' ')}\n${words.last}';
    }
    const splitSuffixes = {'insurance', 'rent', 'loan', 'loans'};
    if (words.length == 2 && splitSuffixes.contains(last)) {
      return '${words[0]}\n${words[1]}';
    }
    return label;
  }

  String _capitalizeLabel(String input) {
    return homeServiceCardLabelText(input);
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

  bool _isElectricityService(QuickActionService service) {
    return service.name.trim().toLowerCase().contains('electricity');
  }

  bool _isMobilePrepaidService(QuickActionService service) {
    final name = service.name.trim().toLowerCase();
    return name.contains('mobile prepaid') ||
        (name.contains('mobile') && name.contains('prepaid'));
  }

  bool _hidesOfferBadge(QuickActionService service) {
    return _isElectricityService(service) || _isMobilePrepaidService(service);
  }

  Widget _serviceTile(QuickActionService service) {
    final isElectricity = _isElectricityService(service);
    return HomeIconTile(
      label: _labelForService(service),
      iconUrl: isElectricity ? null : service.icon,
      lottieAsset: isElectricity ? FileConstants.electricityBulbLottie : null,
      offer: _hidesOfferBadge(service) ? null : service.offers,
      showHalfRing: _isBookGasService(service),
      creditCardCircle: true,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 2 * _billsCardMargin(context);
        // Every offset below is in Figma px on the 392x276 card, scaled by
        // the card's real width so homeIconSection.png is never distorted.
        final s = cardWidth / _billsCardDesignWidth;
        double f(double figmaPx) => figmaPx * s;

        final ringInset = HomeServiceCircle.borderWidth;
        final ringSize = HomeServiceCircle.size + 2 * ringInset;
        final lpgPadding = 4.h;
        final column = (cardWidth - f(16)) / 4;
        final lpgCenterY = f(178);

        return SizedBox(
          width: cardWidth,
          height: f(_billsCardDesignHeight),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _BillsCardPainter(
                    scale: s,
                    borderWidth: 0.5.w,
                  ),
                ),
              ),
              Positioned(
                left: f(8),
                right: f(8),
                top: f(21) - ringInset,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final service in topRow)
                      Expanded(
                        child: service == null
                            ? const SizedBox.shrink()
                            : _serviceTile(service),
                      ),
                  ],
                ),
              ),
              if (bookGas != null) ...[
                Positioned(
                  left: f(8),
                  width: column,
                  top: lpgCenterY - ringSize / 2,
                  child: _serviceTile(bookGas),
                ),
                Positioned(
                  left: f(112),
                  right: 0,
                  top: f(158) - lpgPadding,
                  height: f(41) + 2 * lpgPadding,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: lpgPadding),
                    child: _PromoStrip(
                      asset: FileConstants.bookLpgStrip,
                      height: f(41),
                      radius: f(8),
                    ),
                  ),
                ),
              ],
              Positioned(
                left: f(122),
                right: 0,
                top: f(221),
                height: f(52),
                child: _ExploreUtilitiesRow(
                  onTap: onExploreTap,
                  height: f(52),
                  radius: f(8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

const double _billsCardDesignWidth = 392;
const double _billsCardDesignHeight = 276;

/// White L-shaped Bills & Recharges card (same outline as homeIconSection.png)
/// with the Figma `0.5px solid #E3E3E3CC` border. The bottom-right notch holds
/// the Explore Utilities row, so a rectangular border can't be used.
class _BillsCardPainter extends CustomPainter {
  const _BillsCardPainter({required this.scale, required this.borderWidth});

  final double scale;
  final double borderWidth;

  static const double _radius = 16;
  static const double _topPanelBottom = 214;
  static const double _notchLeft = 113;

  Path _outline(Size size) {
    final inset = borderWidth / 2;
    final left = inset;
    final top = inset;
    final right = size.width - inset;
    final bottom = size.height - inset;
    final r = _radius * scale;
    final panelBottom = _topPanelBottom * scale;
    final notchLeft = _notchLeft * scale;
    final corner = Radius.circular(r);

    return Path()
      ..moveTo(left + r, top)
      ..lineTo(right - r, top)
      ..arcToPoint(Offset(right, top + r), radius: corner)
      ..lineTo(right, panelBottom - r)
      ..arcToPoint(Offset(right - r, panelBottom), radius: corner)
      ..lineTo(notchLeft + r, panelBottom)
      ..arcToPoint(
        Offset(notchLeft, panelBottom + r),
        radius: corner,
        clockwise: false,
      )
      ..lineTo(notchLeft, bottom - r)
      ..arcToPoint(Offset(notchLeft - r, bottom), radius: corner)
      ..lineTo(left + r, bottom)
      ..arcToPoint(Offset(left, bottom - r), radius: corner)
      ..lineTo(left, top + r)
      ..arcToPoint(Offset(left + r, top), radius: corner)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final outline = _outline(size);
    canvas.drawPath(outline, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..color = const Color(0xCCE3E3E3)
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _BillsCardPainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.borderWidth != borderWidth;
  }
}

/// Horizontal margin around the Bills & Recharges card: 24px of the 440px
/// Figma frame on normal phones, tighter on narrow ones so it never overflows.
double _billsCardMargin(BuildContext context) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  return screenWidth < 380 ? 16.w : screenWidth * 24 / 440;
}

/// Subtle breathing room between the sticky header and the scrolling content;
/// short screens get the tighter end of the range.
double _homeHeaderBottomGap(BuildContext context) {
  final screenHeight = MediaQuery.sizeOf(context).height;
  final base = screenHeight < 700 ? 4.h : 6.h;
  return base.clamp(4.0, 8.0);
}

/// Top spacing above "Insurance Premium" after the zero-balance banner.
double _insuranceHeadingTop(BuildContext context) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  return screenWidth < 360 ? 10.h : 12.h;
}

@visibleForTesting
double debugHomeHeaderBottomGap(BuildContext context) =>
    _homeHeaderBottomGap(context);

class _PromoStrip extends StatelessWidget {
  const _PromoStrip({
    required this.asset,
    required this.height,
    required this.radius,
  });
  final String asset;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    // Right side stays square: the strip bleeds into the card's right border.
    return ClipRRect(
      borderRadius: BorderRadius.horizontal(left: Radius.circular(radius)),
      child: Image.asset(
        asset,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        cacheWidth: _cachePixels(context, 1.sw),
        filterQuality: FilterQuality.low,
      ),
    );
  }
}

class _ExploreUtilitiesRow extends StatelessWidget {
  const _ExploreUtilitiesRow({
    required this.onTap,
    required this.height,
    required this.radius,
  });
  final VoidCallback onTap;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(this.radius);
    final arrow = (height * 0.46).clamp(16.0, 20.0);
    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: Container(
        height: double.infinity,
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: const RadialGradient(
            center: Alignment.center,
            radius: 12.77,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFF2894F8),
            ],
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                'Explore All Utilities',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF000000),
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                  height: 1.2,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            SizedBox(
              width: arrow,
              height: arrow,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(arrow),
                child: SvgPicture.string(
                  _exploreUtilitiesArrowSvg,
                  width: arrow,
                  height: arrow,
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

class _InvestmentCircleRow extends StatelessWidget {
  const _InvestmentCircleRow({
    required this.onZeroBalanceTap,
    required this.onGoldTap,
    required this.onSilverTap,
  });

  final VoidCallback onZeroBalanceTap;
  final VoidCallback onGoldTap;
  final VoidCallback onSilverTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _InvestmentCircleTile(
            label: 'Zero Balance\nAccount',
            iconAsset: FileConstants.zeroBalanceAccountIcon,
            lottieAsset: FileConstants.bankLoopLottie,
            onTap: onZeroBalanceTap,
          ),
        ),
        Expanded(
          child: _InvestmentCircleTile(
            label: 'Invest in\nGold',
            iconAsset: FileConstants.investGoldIcon,
            fillColors: HomeServiceCircle.goldFill,
            onTap: onGoldTap,
          ),
        ),
        Expanded(
          child: _InvestmentCircleTile(
            label: 'Invest in\nSilver',
            iconAsset: FileConstants.investSilverIcon,
            fillColors: HomeServiceCircle.silverFill,
            onTap: onSilverTap,
          ),
        ),
        const Expanded(child: SizedBox.shrink()),
      ],
    );
  }
}

class _InvestmentCircleTile extends StatelessWidget {
  const _InvestmentCircleTile({
    required this.label,
    required this.iconAsset,
    required this.onTap,
    this.lottieAsset,
    this.fillColors,
  });

  final String label;
  final String iconAsset;
  final String? lottieAsset;
  final List<Color>? fillColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayAsset = _rasterHomeAsset(iconAsset);
    final isSvg = displayAsset.toLowerCase().endsWith('.svg');
    final iconSize = homeServiceIconSize();
    return GestureDetector(
      onTap: onTap,
      child: HomeServiceItem(
        fillColors: fillColors,
        label: homeServiceCardLabelText(label),
        icon: lottieAsset != null
            ? RepaintBoundary(
                child: Lottie.asset(
                  lottieAsset!,
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.contain,
                  repeat: true,
                ),
              )
            : isSvg
                ? SvgPicture.asset(
                    displayAsset,
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.contain,
                  )
                : Image.asset(
                    displayAsset,
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.contain,
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
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          ClipOval(
            child: SizedBox(
              height: 24.w,
              width: 24.w,
              child: Image.asset(
                arrowAsset,
                fit: BoxFit.cover,
              ),
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
    final cacheWidth = (1.sw * MediaQuery.devicePixelRatioOf(context)).round();
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

class _HomeBleedBanner extends StatelessWidget {
  const _HomeBleedBanner({
    required this.designWidth,
    required this.designHeight,
    this.asset,
    this.child,
    this.isGif = false,
    this.fit = BoxFit.fill,
  });

  final String? asset;
  final Widget? child;
  final double designWidth;
  final double designHeight;
  final bool isGif;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 1.sw;
        final width = available;
        final height = designWidth <= 0
            ? designHeight
            : width * designHeight / designWidth;
        final sourceAsset = asset;
        final resolvedAsset =
            sourceAsset == null ? null : _rasterHomeAsset(sourceAsset);
        final isSvg = (resolvedAsset ?? '').toLowerCase().endsWith('.svg');
        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: child ??
                (isSvg
                    ? SvgPicture.asset(
                        resolvedAsset!,
                        width: width,
                        height: height,
                        fit: fit,
                      )
                    : Image.asset(
                        resolvedAsset!,
                        width: width,
                        height: height,
                        fit: fit,
                        alignment: Alignment.center,
                        gaplessPlayback: isGif,
                        cacheWidth: _cachePixels(context, width),
                        cacheHeight: _cachePixels(context, height),
                        filterQuality: FilterQuality.medium,
                      )),
          ),
        );
      },
    );
  }
}

class _CibilBanner extends StatelessWidget {
  const _CibilBanner();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = _homeMin(392.w, constraints.maxWidth);
        final height = width * (136 / 393);
        return Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: SizedBox(
              width: width,
              height: height,
              child: Image.asset(
                FileConstants.cibilLogoPng,
                width: width,
                height: height,
                fit: BoxFit.fill,
                alignment: Alignment.center,
                cacheWidth: _cachePixels(context, width),
                cacheHeight: _cachePixels(context, height),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TrustedByIndians extends StatelessWidget {
  const _TrustedByIndians();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = _homeMin(392.w, constraints.maxWidth);
        double frame(double px) => width * px / 392;
        return SizedBox(
          width: width,
          height: frame(47),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: width,
                height: frame(23),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Trusted By ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.normal,
                            height: 1,
                            letterSpacing: 0,
                            color: const Color(0xFF000000),
                          ),
                        ),
                        TextSpan(
                          text: '1 Million',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.normal,
                            height: 1,
                            letterSpacing: 0,
                            color: const Color(0xFFDD5428),
                          ),
                        ),
                        TextSpan(
                          text: ' Indians',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.normal,
                            height: 1,
                            letterSpacing: 0,
                            color: const Color(0xFF000000),
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.left,
                    maxLines: 1,
                  ),
                ),
              ),
              SizedBox(height: frame(6)),
              SizedBox(
                width: 155.w,
                height: frame(18),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'eRupaiya, Trusted hai, Secure hai',
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.normal,
                      height: frame(16) / 10.sp,
                      letterSpacing: 0,
                      color: const Color(0xFF000000),
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

class _RentDueBanner extends StatelessWidget {
  const _RentDueBanner({required this.onPayRentNow});

  final VoidCallback onPayRentNow;

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.plusJakartaSans(
      fontSize: 18.sp,
      fontWeight: FontWeight.w700,
      height: 24.h / 18.sp,
      color: const Color(0xFF000000),
    );
    final descriptionStyle = GoogleFonts.plusJakartaSans(
      fontSize: 10.sp,
      fontWeight: FontWeight.w500,
      height: 18.h / 10.sp,
      color: const Color(0xFF000000),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = _homeMin(288.w, constraints.maxWidth);
        return SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: _homeMin(233.w, width),
                height: 48.h,
                child: Text(
                  'Rent Due? Pay With Your Credit Card.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: _homeMin(210.w, width),
                height: 36.h,
                child: Text(
                  'Pay Your Monthly Rent Easily Using Your Credit Card.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: descriptionStyle,
                ),
              ),
              SizedBox(height: 12.h),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPayRentNow,
                  borderRadius: BorderRadius.circular(70.r),
                  child: Container(
                    width: 99.w,
                    height: 29.h,
                    clipBehavior: Clip.hardEdge,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDD5428),
                      borderRadius: BorderRadius.circular(70.r),
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Pay Rent Now',
                          maxLines: 1,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            height: 1,
                            color: Colors.white,
                          ),
                        ),
                      ),
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
          // height: 128.h,
          child: PageView.builder(
            controller: controller,
            itemCount: total,
            onPageChanged: (index) => currentIndex.value = index,
            itemBuilder: (context, index) {
              if (isLoading || banners.isEmpty) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: AppNetworkImage(
                    url: '',
                    // height: 128.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                );
              }

              final banner = banners[index];
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
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
          boxShadow: [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 6.r,
              offset: Offset(0.w, 4.h),
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
          margin:
              gradientBorder == null ? EdgeInsets.zero : EdgeInsets.all(0.5.w),
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
    final screenWidth = 1.sw;
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
          serviceName == 'College Fees' ||
          serviceName.toLowerCase().contains('house rent') ||
          serviceName.toLowerCase().contains('shop rent')) {
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
    final profilePhotoUrl = profileState.profile?.profilePhotoUrl;
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

    const topBannerGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFADFCA),
        Color(0xFFFADFCA),
        Color(0xFFF2BF98),
        Color(0xFFCA8D7B),
      ],
      stops: [0.0, 0.6289, 0.9119, 1.0],
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
      profilePhotoUrl: profilePhotoUrl,
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
      onPayRentNow: () => handleServiceTap('House Rent'),
      onRetryHome: () =>
          ref.read(homeControllerProvider.notifier).fetchQuickActions(),
      onRestart: () => context.go(RouteConstants.splash),
      payBillsServices: payBillsCategory?.services ?? const [],
      educationServices: educationServices,
      insuranceServices: insuranceServices,
      onServiceTap: handleServiceTap,
      onMyBillsTap: () => context.push(RouteConstants.quickActions),
      onExploreUtilitiesTap: () => context.push(RouteConstants.homeSearchView),
      onGoldTap: () => context.push(
        '${RouteConstants.digitalGold}?entry=home',
      ),
      onSilverTap: () => context.push(
        '${RouteConstants.digitalGold}?metal=silver&entry=home',
      ),
      onZeroBalanceTap: () => handleServiceTap('Zero Balance'),
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
    required this.profilePhotoUrl,
    required this.walletBalance,
    required this.isWalletLoading,
    required this.hasWalletError,
    required this.onSearchTap,
    required this.onReferTap,
    required this.onProfileTap,
    required this.onPayRentNow,
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
    required this.onZeroBalanceTap,
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
  final String? profilePhotoUrl;
  final double? walletBalance;
  final bool isWalletLoading;
  final bool hasWalletError;
  final VoidCallback onSearchTap;
  final VoidCallback onReferTap;
  final VoidCallback onProfileTap;
  final VoidCallback onPayRentNow;
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
  final VoidCallback onZeroBalanceTap;
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
    final topInset = MediaQuery.paddingOf(context).top;
    final headerBottomGap = _homeHeaderBottomGap(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFADFCA),
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: topBannerGradient),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: topInset, bottom: headerBottomGap),
              child: _HomeTopBar(
                initials: initials,
                profilePhotoUrl: profilePhotoUrl,
                walletBalance: walletBalance,
                isWalletLoading: isWalletLoading,
                hasWalletError: hasWalletError,
                compact: true,
                onSearchTap: onSearchTap,
                onReferTap: onReferTap,
                onProfileTap: onProfileTap,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: onRefresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  // Later slivers paint over the hero so the white sheet's
                  // rounded top can overlap the banner art.
                  paintOrder: SliverPaintOrder.lastIsTop,
                  slivers: [
                    SliverToBoxAdapter(
                      child: _HomeHeroBanner(onPayRentNow: onPayRentNow),
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
                          onZeroBalanceTap: onZeroBalanceTap,
                          onReferTap: onReferTap,
                          bankingInvestmentBanners: bankingInvestmentBanners,
                          bankingBannerController: bankingBannerController,
                          bankingBannerPage: bankingBannerPage,
                          onBankingBannerPageChanged:
                              onBankingBannerPageChanged,
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
            ),
          ],
        ),
      ),
    );
  }
}

double _homeSheetTopRadius() => 24.r;

@visibleForTesting
Widget debugHomeStickyHeader({
  String initials = 'DN',
  double? walletBalance = 1270,
}) {
  return _HomeTopBar(
    initials: initials,
    walletBalance: walletBalance,
    compact: true,
    onSearchTap: () {},
    onReferTap: () {},
    onProfileTap: () {},
  );
}

@visibleForTesting
Widget debugHomeHeroBanner() => _HomeHeroBanner(onPayRentNow: () {});

@visibleForTesting
Widget debugHomeLoansGrid() => _CurvedIconGrid(
      services: const [
        QuickActionService(name: 'Personal Loan'),
        QuickActionService(name: 'Business Loan'),
        QuickActionService(name: 'Home Loan'),
        QuickActionService(name: 'Loan Against Property'),
      ],
      onTap: (_) async {},
      showCardFrame: false,
    );

@visibleForTesting
Widget debugHomeInvestmentRow() => _InvestmentCircleRow(
      onZeroBalanceTap: () {},
      onGoldTap: () {},
      onSilverTap: () {},
    );

@visibleForTesting
Widget debugHomeBillsCard() {
  return _PayBillsCard(
    services: const [
      QuickActionService(name: 'Electricity'),
      QuickActionService(name: 'Mobile Prepaid'),
      QuickActionService(name: 'Fastag'),
      QuickActionService(name: 'Credit Card'),
      QuickActionService(name: 'Book Gas'),
    ],
    onTap: _debugNoopServiceTap,
    onExploreTap: _debugNoopTap,
  );
}

Future<void> _debugNoopServiceTap(String _) async {}

void _debugNoopTap() {}

class _HomeHeroBanner extends StatelessWidget {
  const _HomeHeroBanner({required this.onPayRentNow});

  final VoidCallback onPayRentNow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final width = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : screenWidth;
        return _buildHero(context, width);
      },
    );
  }

  Widget _buildHero(BuildContext context, double width) {
    // Ratios measured on the 192px-wide Figma export, whose banner art uses
    // the same scale as homescreenimghome.png (1760x1308).
    final imageHeight = width * (1308 / 1760);
    final titleInImage = width * (532 / 1760);
    final titleTop = width * (20 / 192);
    final visibleHeight = width * (89 / 192);
    final radius = _homeSheetTopRadius();
    // The art keeps going `radius` below the layout box so it shows behind
    // the white sheet's rounded corners (the sheet paints on top; see the
    // scroll view's paintOrder).
    final paintedHeight = visibleHeight + radius;
    final maxShift = (imageHeight - paintedHeight).clamp(0.0, double.infinity);
    final shift = (titleInImage - titleTop).clamp(0.0, maxShift);

    return SizedBox(
      width: width,
      height: visibleHeight,
      child: OverflowBox(
        alignment: Alignment.topCenter,
        minWidth: width,
        maxWidth: width,
        minHeight: paintedHeight,
        maxHeight: paintedHeight,
        child: ClipRect(
          child: Stack(
            children: [
              Positioned(
                top: -shift,
                left: 0,
                width: width,
                height: imageHeight,
                child: GestureDetector(
                  onTap: onPayRentNow,
                  behavior: HitTestBehavior.opaque,
                  child: Image.asset(
                    FileConstants.homeScreenImg,
                    width: width,
                    height: imageHeight,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.medium,
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
    required this.onZeroBalanceTap,
    required this.onReferTap,
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
  final VoidCallback onZeroBalanceTap;
  final VoidCallback onReferTap;
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
    final sheetRadius = _homeSheetTopRadius();
    final width = MediaQuery.sizeOf(context).width;
    // Figma (440px frame): title 20px below the sheet edge, card 16px below.
    final titleInset = (width * 20 / 440).clamp(12.0, 26.0);
    final titleToCard = (width * 16 / 440).clamp(10.0, 20.0);
    final billsMargin = _billsCardMargin(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(sheetRadius)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              billsMargin,
              titleInset,
              billsMargin,
              2.w,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  title: 'Bill & Recharges',
                  actionLabel: 'My Bills',
                  onAction: onMyBillsTap,
                  payBillsStyle: true,
                ),
                SizedBox(height: titleToCard),
                RepaintBoundary(
                  child: _PayBillsCard(
                    services: payBillsServices,
                    onTap: onServiceTap,
                    onExploreTap: onExploreUtilitiesTap,
                    isCreditCardLoading: isFetchingCreditCards,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = width * 165 / 440;
              return GestureDetector(
                onTap: onReferTap,
                child: SizedBox(
                  width: width,
                  height: height,
                  child: RepaintBoundary(
                    child: Lottie.asset(
                      'assets/animations/Referral-banner-smooth-promo.json',
                      width: width,
                      height: height,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      repeat: true,
                    ),
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 2.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(
                  title: 'Banking & Investments',
                  payBillsStyle: true,
                ),
                SizedBox(height: 10.h),
                RepaintBoundary(
                  child: _InvestmentCircleRow(
                    onZeroBalanceTap: onZeroBalanceTap,
                    onGoldTap: onGoldTap,
                    onSilverTap: onSilverTap,
                  ),
                ),
              ],
            ),
          ),
          if (bankingInvestmentBanners.isNotEmpty) ...[
            SizedBox(height: 4.h),
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
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 2.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    homeServiceCardLabelText('Pay Via Credit Card'),
                    textAlign: TextAlign.left,
                    style: homeSectionHeaderStyle(),
                  ),
                ),
                SizedBox(height: 10.h),
                RepaintBoundary(
                  child: _CurvedIconGrid(
                    services: educationServices,
                    onTap: onServiceTap,
                    maxItems: 8,
                    showCardFrame: false,
                    labelBuilder: (service) {
                      final name = service.name.trim();
                      final lower = name.toLowerCase();
                      if (lower.contains('gym')) {
                        return 'Gym Membership';
                      }
                      if (lower.contains('house rent')) {
                        return 'House Rent';
                      }
                      if (lower.contains('shop rent')) {
                        return 'Shop Rent';
                      }
                      return name;
                    },
                  ),
                ),
                SizedBox(height: middleBanners.isNotEmpty ? 0.h : 10.h),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SizedBox(height: 12.h),
                GestureDetector(
                  onTap: onZeroBalanceTap,
                  child: RepaintBoundary(
                    child: _HomeBleedBanner(
                      designWidth: 440,
                      designHeight: 90,
                      asset: FileConstants.zeroBalanceBanner,
                    ),
                  ),
                ),
                SizedBox(height: 6.h),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16.w,
              _insuranceHeadingTop(context),
              16.w,
              2.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    homeServiceCardLabelText('Insurance Premium'),
                    textAlign: TextAlign.left,
                    style: homeSectionHeaderStyle(),
                  ),
                ),
                SizedBox(height: 10.h),
                RepaintBoundary(
                  child: _CurvedIconGrid(
                    services: insuranceServices,
                    onTap: onServiceTap,
                    showCardFrame: false,
                    labelBuilder: (service) {
                      final name = service.name.trim();
                      final lower = name.toLowerCase();
                      if (lower.contains('life')) return 'Life Insurance';
                      if (lower.contains('health')) return 'Health Insurance';
                      if (lower.contains('general')) return 'Motor Insurance';
                      if (lower.contains('insurance')) return name;
                      return name;
                    },
                  ),
                ),
                SizedBox(height: 8.h),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 2.h),
            child: const RepaintBoundary(
              child: _CibilBanner(),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 2.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    homeServiceCardLabelText('Loan'),
                    textAlign: TextAlign.left,
                    style: homeSectionHeaderStyle(),
                  ),
                ),
                SizedBox(height: 10.h),
                RepaintBoundary(
                  child: _CurvedIconGrid(
                    services: const [
                      QuickActionService(name: 'Personal Loan'),
                      QuickActionService(name: 'Business Loan'),
                      QuickActionService(name: 'Home Loan'),
                      QuickActionService(name: 'Loan Against Property'),
                    ],
                    onTap: (_) async => _showInvestmentComingSoonMessage(),
                    showCardFrame: false,
                    labelBuilder: (service) => service.name,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              double frame(double px) => width * px / 440;
              return RepaintBoundary(
                child: ColoredBox(
                  color: const Color(0xFFFDFDFD),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        FileConstants.secureImg,
                        width: width,
                        height: frame(180),
                        fit: BoxFit.fill,
                        cacheWidth: _cachePixels(context, width),
                        cacheHeight: _cachePixels(context, frame(180)),
                      ),
                      SizedBox(height: frame(40)),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: frame(24),
                        ),
                        child: const _TrustedByIndians(),
                      ),
                      SizedBox(height: frame(22)),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: frame(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: frame(80),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Powered By',
                                  maxLines: 1,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FontStyle.normal,
                                    height: 1,
                                    letterSpacing: 0,
                                    color: const Color(0xFF000000),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: frame(10)),
                            // Width-driven with the asset's native 352:140
                            // ratio so the logo is never squashed.
                            Image.asset(
                              FileConstants.bharatConnectColor,
                              width: frame(61),
                              height: frame(61) * 140 / 352,
                              fit: BoxFit.contain,
                              alignment: Alignment.centerLeft,
                              filterQuality: FilterQuality.medium,
                              cacheWidth: _cachePixels(context, frame(61)),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: frame(100)),
                    ],
                  ),
                ),
              );
            },
          ),
          /*
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 0.h),
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
                      height: 14.h,
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
            */
        ],
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
              child: AspectRatio(
                aspectRatio: 1336 / 558,
                child: Image.asset(
                  FileConstants.serverDown,
                  fit: BoxFit.contain,
                ),
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
                    blurRadius: 14.r,
                    offset: Offset(0.w, 7.h),
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
