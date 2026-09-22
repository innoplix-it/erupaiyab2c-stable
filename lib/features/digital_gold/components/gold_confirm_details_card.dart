import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_colors.dart';

class GoldConfirmDetailsCard extends StatelessWidget {
  const GoldConfirmDetailsCard({
    super.key,
    required this.name,
    required this.mobile,
    required this.email,
    required this.pan,
  });

  final String name;
  final String mobile;
  final String email;
  final String pan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F1EE),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        children: [
          _InfoRow(label: 'Name', value: name),
          SizedBox(height: 8.h),
          _InfoRow(label: 'Mobile', value: mobile),
          SizedBox(height: 8.h),
          _InfoRow(label: 'Email', value: email),
          SizedBox(height: 8.h),
          _InfoRow(label: 'PAN', value: pan),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 80.w,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.6),
                ),
          ),
        ),
        Text(
          ':',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary.withOpacity(0.6),
              ),
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
