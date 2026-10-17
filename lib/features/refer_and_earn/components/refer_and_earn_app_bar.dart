import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';

class ReferAndEarnAppBar extends HookWidget {
  const ReferAndEarnAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.onHelp,
    this.height,
    this.body,
    this.titleStyle,
    this.bottomReserve,
    this.centerTitle = false,
    this.backgroundColor,
    this.whiteHelpBadge = false,
    this.hideBottomStrip = false,
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onHelp;

  /// Already ScreenUtil-scaled. Omitted height uses the 320 design-unit default once.
  final double? height;

  /// Optional hero content laid out below the nav row and centred in the
  /// remaining space, with a bottom reserve so a panel translated up over
  /// the bar never covers it. Only used by the Refer & Earn home view.
  final Widget? body;

  /// Optional override merged over the default title style.
  final TextStyle? titleStyle;

  /// Already ScreenUtil-scaled space kept free at the bottom of [body].
  /// Omitted uses the 52 design-unit default once.
  final double? bottomReserve;

  /// Centres the title between the two actions (Figma Wallet header). The
  /// icon buttons are equal width, so the expanded middle slot is the
  /// screen centre. Defaults to the original leading-aligned title.
  final bool centerTitle;

  /// Solid Figma hero fill (e.g. `#084591`). When null, uses [FileConstants.bluebg].
  final Color? backgroundColor;

  /// Figma help control: white circular badge with a tinted `?`.
  final bool whiteHelpBadge;

  /// When true, skips the white rounded strip (home view draws its own panel).
  final bool hideBottomStrip;

  @override
  Widget build(BuildContext context) {
    final barHeight = height ?? 320.h;
    final helpTint = backgroundColor ?? const Color(0xFF084591);
    return SizedBox(
      height: barHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: backgroundColor != null
                ? ColoredBox(color: backgroundColor!)
                : Image.asset(
                    FileConstants.bluebg,
                    fit: BoxFit.cover,
                    cacheWidth: (MediaQuery.sizeOf(context).width *
                            MediaQuery.devicePixelRatioOf(context))
                        .round()
                        .clamp(1, 4096),
                  ),
          ),
          if (!hideBottomStrip)
            Positioned(
              left: 0,
              right: 0,
              bottom: -1,
              child: Container(
                height: 36.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28.r),
                  ),
                ),
              ),
            ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed:
                            onBack ?? () => Navigator.of(context).maybePop(),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign:
                              centerTitle ? TextAlign.center : TextAlign.start,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              )
                              .merge(titleStyle),
                        ),
                      ),
                      IconButton(
                        icon: whiteHelpBadge
                            ? Builder(
                                builder: (context) {
                                  // Figma 440 frame → ScreenUtil 360 design once.
                                  final badge = (28 * 360 / 440).r;
                                  final qSize = (16 * 360 / 440).sp;
                                  return Container(
                                    width: badge,
                                    height: badge,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '?',
                                      style: TextStyle(
                                        color: helpTint,
                                        fontWeight: FontWeight.w700,
                                        fontSize: qSize,
                                        height: 1,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : const Icon(Icons.help_outline,
                                color: Colors.white),
                        onPressed: onHelp ??
                            () => context.push(RouteConstants.helpSupport),
                      ),
                    ],
                  ),
                ),
                if (body != null)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: bottomReserve ?? 52.h),
                      child: body!,
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
