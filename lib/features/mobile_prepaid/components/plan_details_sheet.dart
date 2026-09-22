// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/app_colors.dart';
import '../models/plan_item.dart';

String extractPlanDataValue(PlanItem plan) {
  final direct = plan.data.trim();
  if (direct.isNotEmpty) return direct;
  final description = plan.description;
  if (description.isEmpty) return '';
  final match = RegExp(r'Data\\s*[:\\-]\\s*([^|]+)', caseSensitive: false)
      .firstMatch(description);
  if (match == null) return '';
  return match.group(1)?.trim() ?? '';
}

class PlanDetailsSheet extends StatelessWidget {
  const PlanDetailsSheet({
    super.key,
    required this.plan,
    required this.onProceedToPay,
  });

  final PlanItem plan;
  final VoidCallback onProceedToPay;

  @override
  Widget build(BuildContext context) {
    final dataValue = extractPlanDataValue(plan);
    final benefits = plan.additionalBenefits;
    final maxHeight = MediaQuery.of(context).size.height * 0.82;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return SizedBox(
      height: maxHeight,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Plan Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            fontSize: 16.sp,
                          ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20.r),
                      child: Padding(
                        padding: EdgeInsets.all(6.r),
                        child: Icon(Icons.close, size: 20.sp),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹ ${plan.amount}',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                fontSize: 26.sp,
                              ),
                    ),
                    SizedBox(width: 14.w),
                    if (plan.validity.isNotEmpty) ...[
                      _VerticalDivider(height: 34.h),
                      SizedBox(width: 14.w),
                      _PlanDetailMiniColumn(
                        label: 'Validity',
                        value: plan.validity,
                      ),
                    ],
                    if (dataValue.isNotEmpty) ...[
                      SizedBox(width: 14.w),
                      _VerticalDivider(height: 34.h),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: _PlanDetailMiniColumn(
                          label: 'Data',
                          value: dataValue,
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 14.h),
                Divider(color: AppColors.lightBorder, height: 1.h),
                SizedBox(height: 14.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Additional Benefits',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          fontSize: 14.sp,
                        ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: benefits.isEmpty
                  ? Center(
                      child: Text(
                        'No additional benefits available.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary.withOpacity(0.6),
                            ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: benefits.length,
                      separatorBuilder: (_, __) => Divider(
                        color: AppColors.lightBorder.withOpacity(0.7),
                        height: 18.h,
                      ),
                      itemBuilder: (context, index) {
                        final benefit = benefits[index];
                        return _BenefitRow(
                          benefit: benefit,
                          validity: plan.validity,
                        );
                      },
                    ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              24.w,
              10.h,
              24.w,
              16.h + bottomInset,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onProceedToPay();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDD5428),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(86.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Proceed To Pay',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp,
                        height: 1,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanDetailMiniColumn extends StatelessWidget {
  const _PlanDetailMiniColumn({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF000000),
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 13.sp,
              ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.w,
      height: height,
      color: AppColors.lightBorder,
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.benefit,
    required this.validity,
  });

  final AdditionalBenefit benefit;
  final String validity;

  @override
  Widget build(BuildContext context) {
    final subtitle = validity.isEmpty ? '' : 'Included for $validity.';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BenefitLeadingIcon(benefit: benefit),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                benefit.text.isEmpty ? 'Benefit' : benefit.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontSize: 13.sp,
                    ),
              ),
              if (subtitle.isNotEmpty) ...[
                SizedBox(height: 3.h),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.55),
                        fontSize: 11.sp,
                        height: 1.25,
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BenefitLeadingIcon extends StatelessWidget {
  const _BenefitLeadingIcon({required this.benefit});

  final AdditionalBenefit benefit;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        width: 48.w,
        height: 48.w,
        color: Colors.grey.shade100,
        child: benefit.image == null
            ? Icon(Icons.card_giftcard, size: 24.sp, color: AppColors.primary)
            : Image.network(
                benefit.image!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.image,
                  size: 24.sp,
                  color: AppColors.primary,
                ),
              ),
      ),
    );
  }
}
