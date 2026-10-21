import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/file_constants.dart';
import '../../../widgets/my_app_bar.dart';
import 'refer_help_icon_button.dart';

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
    this.skipBackground = false,
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

  /// When true, paints no fill so a parent [DecoratedBox] (e.g. wallet dark
  /// gradient) shows through.
  final bool skipBackground;

  /// When true, skips the white rounded strip (home view draws its own panel).
  final bool hideBottomStrip;

  @override
  Widget build(BuildContext context) {
    final barHeight = height ?? 320.h;
    return SizedBox(
      height: barHeight,
      child: Stack(
        children: [
          if (!skipBackground)
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
                          // Same title text props as common [MyAppBar].
                          style: MyAppBar.sharedTitleStyle(
                            context,
                            color: Colors.white,
                          )?.merge(titleStyle),
                        ),
                      ),
                      // Figma white circular `?` (20×20) across Refer & Earn.
                      ReferHelpIconButton(onPressed: onHelp),
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
