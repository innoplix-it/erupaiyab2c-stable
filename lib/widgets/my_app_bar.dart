import 'package:e_rupaiya/constants/file_constants.dart';
import 'package:e_rupaiya/constants/routes_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MyAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.showHelp = true,
    this.onHelp,
    this.trailing,
    this.height,
    this.backgroundColor,
    this.titleStyle,
    this.bharatConnectWidth,
    this.bharatConnectHeight,
    this.helpIconSize,
  });

  final String title;
  final VoidCallback? onBack;
  final bool showHelp;
  final VoidCallback? onHelp;
  final Widget? trailing;
  final double? height;
  final Color? backgroundColor;
  final TextStyle? titleStyle;
  final double? bharatConnectWidth;
  final double? bharatConnectHeight;
  final double? helpIconSize;

  double get _platformTopPadding {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return 0;
    final view = views.first;
    return view.padding.top / view.devicePixelRatio;
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(height ?? (_platformTopPadding + kToolbarHeight + 1));

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Colors.white;
    final isDark =
        ThemeData.estimateBrightnessForColor(bgColor) == Brightness.dark;
    final overlayStyle =
        (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(statusBarColor: bgColor);
    final topPadding = MediaQuery.paddingOf(context).top;
    final resolvedHeight = height ?? (topPadding + kToolbarHeight + 1);
    // Old design (kept for reference)
    // return SizedBox(
    //   height: height,
    //   child: Stack(
    //     children: [
    //       Positioned.fill(
    //         child: Container(
    //           decoration: BoxDecoration(
    //             gradient: backgroundColor == null
    //                 ? AppColors.onboardingBackground
    //                 : LinearGradient(
    //                     colors: [
    //                       backgroundColor!,
    //                       backgroundColor!.withOpacity(0.92),
    //                     ],
    //                     begin: Alignment.topCenter,
    //                     end: Alignment.bottomCenter,
    //                   ),
    //             borderRadius: const BorderRadius.vertical(
    //               bottom: Radius.circular(28.r),
    //             ),
    //           ),
    //         ),
    //       ),
    //       Positioned(
    //         left: 0,
    //         right: 0,
    //         bottom: -1,
    //         child: Container(
    //           height: 32.h,
    //           decoration: const BoxDecoration(
    //             color: Colors.white,
    //             borderRadius: BorderRadius.vertical(
    //               top: Radius.circular(28.r),
    //             ),
    //           ),
    //         ),
    //       ),
    //       SafeArea(
    //         bottom: false,
    //         child: Padding(
    //           padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
    //           child: Row(
    //             children: [
    //               IconButton(
    //                 icon: Icon(
    //                   Icons.arrow_back,
    //                   color: backgroundColor == null
    //                       ? AppColors.textPrimary
    //                       : Colors.white,
    //                 ),
    //                 onPressed: onBack ?? () => Navigator.of(context).maybePop(),
    //               ),
    //               SizedBox(width: 4.w),
    //               Expanded(
    //                 child: Text(
    //                   title,
    //                   style: Theme.of(context).textTheme.titleMedium?.copyWith(
    //                         color: backgroundColor == null
    //                             ? AppColors.textPrimary
    //                             : Colors.white,
    //                         fontWeight: FontWeight.w700,
    //                       ),
    //                 ),
    //               ),
    //               if (trailing != null) trailing!,
    //               if (trailing == null && showHelp)
    //                 Image.asset(
    //                   FileConstants.bharatConnectColor,
    //                   height: 15.h,
    //                   width: 50.w,
    //                 )
    //               // IconButton(
    //               //   icon: const Icon(Icons.help_outline,
    //               //       color: AppColors.textPrimary),
    //               //   onPressed: onHelp,
    //               // ),
    //             ],
    //           ),
    //         ),
    //       ),
    //     ],
    //   ),
    // );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: SizedBox(
        height: resolvedHeight,
        child: Container(
          color: bgColor,
          child: Column(
            children: [
              SizedBox(height: topPadding),
              SizedBox(
                height: kToolbarHeight,
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: backgroundColor == null
                              ? Colors.black
                              : Colors.white,
                        ),
                        onPressed:
                            onBack ?? () => Navigator.of(context).maybePop(),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          title,
                          style: titleStyle ??
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: backgroundColor == null
                                        ? Colors.black
                                        : Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      if (trailing != null) trailing!,
                      if (showHelp) ...[
                        Image.asset(
                          FileConstants.bharatConnectColor,
                          height: (bharatConnectHeight ?? 15).h,
                          width: (bharatConnectWidth ?? 50).w,
                          fit: BoxFit.contain,
                        ),
                        IconButton(
                          onPressed: onHelp ??
                              () => context.push(RouteConstants.helpSupport),
                          padding: helpIconSize == null
                              ? const EdgeInsets.all(8)
                              : EdgeInsets.zero,
                          constraints: helpIconSize == null
                              ? null
                              : BoxConstraints.tightFor(
                                  width: 32.w,
                                  height: 32.w,
                                ),
                          icon: Icon(
                            Icons.help_outline,
                            size: helpIconSize?.w,
                            color: backgroundColor == null
                                ? const Color(0xFF000000)
                                : Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: Colors.black.withValues(alpha: 0.08),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
