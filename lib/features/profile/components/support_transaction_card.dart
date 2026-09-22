import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_colors.dart';
import '../models/support_latest_transaction.dart';

class SupportTransactionCard extends StatelessWidget {
  const SupportTransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.width,
  });

  final SupportLatestTransaction transaction;
  final VoidCallback? onTap;
  final double? width;

  Color get _statusColor {
    final status = transaction.status.trim().toLowerCase();
    if (status == 'success' || status == 'successful') {
      return const Color(0xFF0E8B3E);
    }
    if (status == 'failed' || status == 'failure') {
      return const Color(0xFFC62828);
    }
    return const Color(0xFFF2A98E);
  }

  String get _statusLabel {
    final status = transaction.status.trim();
    if (status.isEmpty) return 'Pending';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  String _formatDate() {
    final dt = transaction.dateTime;
    if (dt == null) return transaction.date;
    return DateFormat("d MMM''yy").format(dt);
  }

  @override
  Widget build(BuildContext context) {
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
}
