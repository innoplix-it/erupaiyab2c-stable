import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/file_constants.dart';

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

  @override
  Widget build(BuildContext context) {
    final barHeight = height ?? 320.h;
    return SizedBox(
      height: barHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              FileConstants.bluebg,
              fit: BoxFit.cover,
              cacheWidth: (MediaQuery.sizeOf(context).width *
                  MediaQuery.devicePixelRatioOf(context))
                  .round()
                  .clamp(1, 4096),
            ),
          ),
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
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                        icon: const Icon(Icons.help_outline, color: Colors.white),
                        onPressed: onHelp,
                      ),
                    ],
                  ),
                ),
                if (body != null)
                  Expanded(
                    child: Padding(
                      // Reserve space for the white strip plus the panel that
                      // is translated up over the bar by the owning view.
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