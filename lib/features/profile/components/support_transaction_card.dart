import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_colors.dart';
import '../models/support_latest_transaction.dart';

class SupportTransactionCard extends StatelessWidget {
  const SupportTransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.width,
    this.helpLayout = false,
  });

  final SupportLatestTransaction transaction;
  final VoidCallback? onTap;
  final double? width;

  /// Help & Support bill card. Other screens keep the previous layout.
  final bool helpLayout;

  Color get _statusColor {
    final status = transaction.status.trim().toLowerCase();
    if (status == 'success' || status == 'successful' || status == 'paid') {
      return const Color(0xFF0E8B3E);
    }
    if (status == 'failed' || status == 'failure') {
      return helpLayout ? const Color(0xFFBF0609) : const Color(0xFFC62828);
    }
    return helpLayout ? const Color(0xFFF6A623) : const Color(0xFFF2A98E);
  }

  String get _statusLabel {
    final raw = transaction.status.trim();
    final status = raw.toLowerCase();
    if (!helpLayout) {
      if (raw.isEmpty) return 'Pending';
      return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
    }
    if (status.isEmpty || status == 'pending' || status == 'processing') {
      return 'Pending';
    }
    if (status == 'success' || status == 'successful' || status == 'paid') {
      return 'Success';
    }
    if (status == 'failed' || status == 'failure') return 'Failed';
    if (raw.isEmpty) return 'Pending';
    return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  }

  String _formatDate() {
    final dt = transaction.dateTime;
    if (dt == null) return transaction.date;
    return DateFormat("d MMM''yy").format(dt);
  }

  @override
  Widget build(BuildContext context) {
    if (helpLayout) return _helpCard(context);
    final child = Container(
      width: width ?? 240.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10.r,
            offset: Offset(0.w, 6.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F4),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(14.r),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    transaction.paymentType.isNotEmpty
                        ? transaction.paymentType
                        : 'Transaction',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: _statusColor,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    _statusLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            child: Row(
              children: [
                Container(
                  height: 30.h,
                  width: 30.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0EB),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: Color(0xFFEA5A30),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.billerName.isNotEmpty
                            ? transaction.billerName
                            : '—',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _formatDate(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textPrimary.withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${transaction.amount}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: child,
    );
  }

  Widget _helpCard(BuildContext context) {
    // SVG frame is 269×86. Scale from the card width so a tall phone
    // does not stretch the card, and ScreenUtil is not applied again.
    final cardWidth = width ?? MediaQuery.sizeOf(context).width * (269 / 418);
    final scale = cardWidth / 269;
    final radius = 7.5 * scale;
    final headerHeight = 36 * scale;
    final cardHeight = 86 * scale;
    final iconBox = 24.4 * scale;
    final amount = transaction.amount.trim();
    final amountLabel =
        amount.isEmpty ? '' : (amount.startsWith('₹') ? amount : '₹$amount');

    final card = Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFE4E4E4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: headerHeight,
            padding: EdgeInsets.symmetric(horizontal: 16 * scale),
            color: const Color(0xFFF0F0F0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    transaction.paymentType.isNotEmpty
                        ? transaction.paymentType
                        : 'Transaction',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                      fontSize: 11 * scale,
                      height: 1.1,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                SizedBox(width: 8 * scale),
                Container(
                  height: 16 * scale,
                  padding: EdgeInsets.symmetric(horizontal: 4 * scale),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    borderRadius: BorderRadius.circular(4 * scale),
                  ),
                  child: Text(
                    _statusLabel,
                    maxLines: 1,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 8 * scale,
                      height: 1,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16 * scale,
                0,
                14 * scale,
                0,
              ),
              child: Row(
                children: [
                  Container(
                    height: iconBox,
                    width: iconBox,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.2 * scale),
                      border: Border.all(
                        color: const Color(0xFFE2E2E2),
                        width: 0.4,
                      ),
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      color: const Color(0xFFEA5A30),
                      size: 16 * scale,
                    ),
                  ),
                  SizedBox(width: 10 * scale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          transaction.billerName.isNotEmpty
                              ? transaction.billerName
                              : '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 11 * scale,
                            height: 1.15,
                            letterSpacing: 0,
                          ),
                        ),
                        Text(
                          _formatDate(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFFA6A6A6),
                            fontWeight: FontWeight.w500,
                            fontSize: 8 * scale,
                            height: 1.2,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8 * scale),
                  Text(
                    amountLabel,
                    maxLines: 1,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 13 * scale,
                      height: 1.1,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: card,
    );
  }
}
