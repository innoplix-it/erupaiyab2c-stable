// ignore_for_file: deprecated_member_use

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/custom_elevated_button.dart';

class EducationPaymentThankYouView extends StatelessWidget {
  const EducationPaymentThankYouView({
    super.key,
    required this.amount,
    this.transactionTime = '',
  });

  final String amount;
  final String transactionTime;

  @override
  Widget build(BuildContext context) {
    final formattedAmount = _formatRupee(amount);
    final formattedDate = _formatHeaderDate(
      transactionTime.trim().isEmpty
          ? DateTime.now().toIso8601String()
          : transactionTime,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(RouteConstants.home);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF149248),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(48.r),
                  bottomRight: Radius.circular(48.r),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 36.h),
                  child: Column(
                    children: [
                      Image.asset(
                        FileConstants.successIcon,
                        width: 64.w,
                        height: 64.w,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 18.h),
                      Text(
                        'Thank You for\nEducation Payment',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 22.sp,
                              height: 1.25,
                            ),
                      ),
                      SizedBox(height: 16.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 18.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E7340),
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                        child: Text(
                          formattedAmount,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16.sp,
                                  ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        formattedDate,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12.sp,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 0),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24.r),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              FileConstants.homeBanner2,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 12.h,
                              right: 12.w,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.92),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  'Ad',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11.sp,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    CustomElevatedButton(
                      onPressed: () => context.go(RouteConstants.home),
                      label: 'Done',
                      uppercaseLabel: false,
                      showArrow: false,
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'powered by',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.black,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        SizedBox(width: 4.w),
                        Image.asset(
                          FileConstants.bharatConnectColor,
                          width: 52.w,
                          height: 24.h,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
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

String _formatRupee(String raw) {
  final parsed = double.tryParse(
    raw.replaceAll(',', '').replaceAll('₹', '').trim(),
  );
  if (parsed == null) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '₹0.00';
    return trimmed.startsWith('₹') ? trimmed : '₹$trimmed';
  }
  final parts = parsed.toStringAsFixed(2).split('.');
  final whole = parts.first;
  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    final remaining = whole.length - i;
    if (i > 0 && remaining % 3 == 0) buffer.write(',');
    buffer.write(whole[i]);
  }
  return '₹${buffer.toString()}.${parts.last}';
}

String _formatHeaderDate(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return '';
  final normalized = value.contains(' ') ? value.replaceFirst(' ', 'T') : value;
  final parsed = DateTime.tryParse(normalized);
  if (parsed == null) return value;
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final day = parsed.day.toString();
  final month = months[parsed.month - 1];
  final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
  final minute = parsed.minute.toString().padLeft(2, '0');
  final ampm = parsed.hour >= 12 ? 'pm' : 'am';
  return '$day $month ${parsed.year}, $hour.$minute$ampm';
}
