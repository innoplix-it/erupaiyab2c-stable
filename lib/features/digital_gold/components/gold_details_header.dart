import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/routes_constant.dart';

class GoldDetailsHeader extends StatelessWidget {
  const GoldDetailsHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.onHelp,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 22.r),
          ),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          IconButton(
            onPressed:
                onHelp ?? () => context.push(RouteConstants.helpSupport),
            icon: Icon(Icons.help_outline, color: AppColors.textPrimary, size: 22.r),
          ),
        ],
      ),
    );
  }
}
