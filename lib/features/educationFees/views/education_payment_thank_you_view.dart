// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/custom_elevated_button.dart';

class EducationPaymentThankYouView extends StatelessWidget {
  const EducationPaymentThankYouView({
    super.key,
    required this.amount,
    this.payableAmount = '',
    this.transactionTime = '',
    this.bannerImage = '',
    this.paymentType = '',
  });

  final String amount;
  final String payableAmount;
  final String transactionTime;
  final String bannerImage;
  final String paymentType;

  @override
  Widget build(BuildContext context) {
    final displayAmount =
        payableAmount.trim().isNotEmpty ? payableAmount : amount;
    final formattedAmount = _formatRupee(displayAmount);
    final formattedDate = _formatHeaderDate(transactionTime);
    final imageUrl = bannerImage.trim();
    final title = _thankYouTitle(paymentType);
    final sx = MediaQuery.sizeOf(context).width / 441.0;
    double x(double value) => value * sx;
    final headerTop = MediaQuery.paddingOf(context).top + 40.h;
    final dateStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontSize: 10.5.sp,
            ) ??
        TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 10.5.sp,
        );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(RouteConstants.home);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: x(-409),
              left: x(-199),
              child: Container(
                width: x(838),
                height: x(756),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.elliptical(x(838) / 2, x(756) / 2),
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF004C1E),
                      Color(0xFF149248),
                      Color(0xFF136E3C),
                      Color(0xFF007340),
                    ],
                    stops: [0.0, 0.3446, 0.9055, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              top: headerTop,
              left: 24.w,
              right: 24.w,
              child: Column(
                children: [
                  Image.asset(
                    FileConstants.successIcon,
                    width: 52.w,
                    height: 52.w,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: x(16)),
                  SizedBox(
                    width: x(287),
                    height: x(116),
                    child: Column(
                      children: [
                        SizedBox(
                          width: x(287),
                          height: x(50),
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFFFFFFF),
                              fontWeight: FontWeight.w600,
                              fontSize: 20 * sx,
                              height: 1,
                            ),
                          ),
                        ),
                        SizedBox(height: x(16)),
                        Container(
                          width: 106,
                          height: 34,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          decoration: BoxDecoration(
                            color: const Color(0x1AFFFFFF),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            formattedAmount,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFFFFFFF),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: x(16)),
                  Text(
                    formattedDate,
                    textAlign: TextAlign.center,
                    style: dateStyle,
                  ),
                ],
              ),
            ),
            Positioned(
              top: x(376),
              left: x(24),
              child: SizedBox(
                width: x(392),
                height: x(450),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: x(392),
                        height: x(450),
                        child: AppNetworkImage(
                          url: imageUrl,
                          width: x(392),
                          height: x(450),
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    Positioned(
                      top: x(20),
                      right: 0,
                      child: Container(
                        width: x(43),
                        height: x(28),
                        padding: EdgeInsets.fromLTRB(x(12), x(5), x(12), x(5)),
                        decoration: const BoxDecoration(
                          color: Color(0x4D000000),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(50),
                            bottomLeft: Radius.circular(50),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Ad',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFFFFFFFF),
                            fontWeight: FontWeight.w600,
                            fontSize: 11 * sx,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: x(24),
              right: x(24),
              bottom: 16.h + MediaQuery.paddingOf(context).bottom,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                        style: GoogleFonts.plusJakartaSans(
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _thankYouTitle(String paymentType) {
  final raw = paymentType.trim();
  if (raw.isEmpty) return 'Thank You for\nEducation Payment';
  final lower = raw.toLowerCase();
  if (lower.contains('thank you')) return raw;
  if (lower.endsWith(' payment')) return 'Thank You for\n$raw';
  return 'Thank You for\n$raw Payment';
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
