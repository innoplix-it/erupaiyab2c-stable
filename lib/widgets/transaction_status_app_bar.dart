import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';

class TransactionStatusAppBar extends StatelessWidget {
  const TransactionStatusAppBar({
    super.key,
    required this.title,
    required this.backgroundColor,
    this.backgroundGradient,
    this.onBack,
    this.height = 150,
    this.trailing,
  });

  final String title;
  final Color backgroundColor;
  final Gradient? backgroundGradient;
  final VoidCallback? onBack;
  final double height;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height.h,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: backgroundGradient ??
                    LinearGradient(
                      colors: [
                        backgroundColor,
                        backgroundColor.withOpacity(0.92),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28.r),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: -1,
            child: Container(
              height: 32.h,
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
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                  if (trailing == null)
                    SizedBox(width: 24.r,
                      height: 24.r,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
