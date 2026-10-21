import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/file_constants.dart';
import '../../../widgets/my_app_bar.dart';
import 'refer_and_earn_figma_metrics.dart';
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
    this.showNavRow = true,
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

  /// When false, the nav row is replaced by an equal-height gap so a pinned
  /// copy can sit on top without doubling the back and help buttons.
  final bool showNavRow;

  @override
  Widget build(BuildContext context) {
    final barHeight = height ?? context.referH(320);
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
                height: context.referH(36),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(context.referR(28)),
                  ),
                ),
              ),
            ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                if (showNavRow)
                  ReferAndEarnNavRow(
                    title: title,
                    onBack: onBack,
                    onHelp: onHelp,
                    centerTitle: centerTitle,
                    titleStyle: titleStyle,
                  )
                else
                  SizedBox(height: ReferAndEarnNavRow.heightOf(context)),
                if (body != null)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: bottomReserve ?? context.referH(52),
                      ),
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

/// Back, title, and help row shared by the scrolling hero and the pinned bar.
class ReferAndEarnNavRow extends StatelessWidget {
  const ReferAndEarnNavRow({
    super.key,
    required this.title,
    this.onBack,
    this.onHelp,
    this.centerTitle = false,
    this.titleStyle,
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onHelp;
  final bool centerTitle;
  final TextStyle? titleStyle;

  /// Padding plus the 48dp icon button. Matches the row painted below.
  static double heightOf(BuildContext context) => context.referH(8) + 48;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.referW(12),
        vertical: context.referH(4),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: centerTitle ? TextAlign.center : TextAlign.start,
              style: MyAppBar.sharedTitleStyle(
                context,
                color: Colors.white,
              )?.merge(titleStyle),
            ),
          ),
          ReferHelpIconButton(onPressed: onHelp),
        ],
      ),
    );
  }
}
