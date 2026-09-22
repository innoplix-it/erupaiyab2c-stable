import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DigitalGoldTitleLiveBar extends StatelessWidget {
  const DigitalGoldTitleLiveBar({
    super.key,
    required this.title,
    required this.rateText,
    this.onBack,
    this.onHelp,
    this.showBack = true,
    this.padding,
    this.chipLeading,
    this.liveDotColor = const Color(0xFFEF4444),
    this.chipBorderColor = const Color(0xFFC59B17),
    this.chipBackgroundColor = const Color(0xFFFFF7D5),
  });

  final String title;
  final String rateText;
  final VoidCallback? onBack;
  final VoidCallback? onHelp;
  final bool showBack;
  final EdgeInsetsGeometry? padding;
  final Widget? chipLeading;
  final Color liveDotColor;
  final Color chipBorderColor;
  final Color chipBackgroundColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.fromLTRB(8.w, 0.h, 10.w, 2.h),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            )
          else
            SizedBox(width: 12.w),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: chipBackgroundColor,
              borderRadius: BorderRadius.circular(999.r),
              border: Border.all(color: chipBorderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                chipLeading ??
                    Container(
                      width: 6.r,
                      height: 6.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: liveDotColor,
                      ),
                    ),
                SizedBox(width: 6.w),
                Text(
                  rateText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 6.w),
          IconButton(
            onPressed: onHelp,
            icon: const Icon(Icons.help_outline_rounded),
          ),
        ],
      ),
    );
  }
}
