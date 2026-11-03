import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static TextStyle? bodySmallSemibold(BuildContext context, {Color? color}) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: color ?? AppColors.textPrimary,
          fontSize: 10.sp,
        );
  }

  static TextStyle? bodySmall(BuildContext context, {Color? color}) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: color ?? AppColors.textPrimary,
          fontSize: 9.sp,
        );
  }

  static TextStyle? bodySmallMuted(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textPrimary.withValues(alpha: 0.65),
          height: 1.4,
        );
  }

  static TextStyle? bodyMediumBold(BuildContext context, {Color? color}) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: color ?? AppColors.textPrimary,
        );
  }

  static TextStyle? titleMediumBold(BuildContext context, {Color? color}) {
    return Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: color ?? AppColors.textPrimary,
        );
  }

  /// Shared operator / biller provider-name text used across the service
  /// listing modules (Electricity/DTH/Gas "Fetch Your Provider", Credit Card
  /// "Select Your Bank", ...) so every provider name renders at one size.
  /// height 1.3 matches the Credit Card grid tile's two-line spacing; as a
  /// unitless multiplier it scales with the responsive 13.sp font (ScreenUtil).
  static TextStyle operatorName(BuildContext context, {Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontWeight: FontWeight.w500,
      fontSize: 13.sp,
      height: 1.3,
      letterSpacing: 0,
      color: color ?? const Color(0xFF000000),
    );
  }

  static TextStyle? tabLabel(BuildContext context, {required bool isActive}) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isActive
              ? AppColors.primary
              : AppColors.textPrimary.withValues(alpha: 0.5),
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
        );
  }
}
