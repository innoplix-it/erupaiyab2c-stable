// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constants/app_colors.dart';
import '../../../widgets/k_dialog.dart';
import '../models/plan_item.dart';
import 'plan_details_sheet.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.isSelected,
    required this.onTap,
    this.onViewDetails,
    this.onPayNow,
  });

  final PlanItem plan;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onViewDetails;
  final VoidCallback? onPayNow;

  void _openPlanDetailsSheet(BuildContext context) {
    KDialog.instance.openSheet(
      dialog: PlanDetailsSheet(
        plan: plan,
        onProceedToPay: onPayNow ?? onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assuredLabel = plan.assuredBadgeLabel;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.lightBorder,
            width: isSelected ? 1.5.w : 1.w,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 12.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 171.w),
                    child: Text(
                      '₹ ${plan.amount}',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 24.sp,
                        color: Colors.black,
                        height: 1,
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  _PlanInfoRow(
                    plan: plan,
                    onBenefitsTap: () => _openPlanDetailsSheet(context),
                  ),
                  SizedBox(height: 10.h),
                  if (plan.description.trim().isNotEmpty) ...[
                    Text(
                      plan.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w400,
                        fontSize: 11.sp,
                        height: 15 / 12,
                        color: const Color(0xFF222222),
                      ),
                    ),
                    SizedBox(height: 12.h),
                  ] else
                    SizedBox(height: 16.h),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onViewDetails ?? onTap,
                        child: Text(
                          'View Details',
                          style: GoogleFonts.bricolageGrotesque(
                            color: const Color(0xFFDD5428),
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                            height: 17 / 14,
                          ),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 183.w,
                        height: 43.h,
                        child: _PlanPayNowButton(
                          onTap: onPayNow ?? onTap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 16.h,
              right: 0,
              child: GetAssuredCoinsBadge(label: assuredLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class GetAssuredCoinsBadge extends StatelessWidget {
  const GetAssuredCoinsBadge({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 163.w,
      height: 27.h,
      padding: EdgeInsets.fromLTRB(12.w, 5.h, 16.w, 5.h),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF193459),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(50.r),
          bottomLeft: Radius.circular(50.r),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.bricolageGrotesque(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11.sp,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanInfoRow extends StatelessWidget {
  const _PlanInfoRow({
    required this.plan,
    this.onBenefitsTap,
  });

  final PlanItem plan;
  final VoidCallback? onBenefitsTap;

  @override
  Widget build(BuildContext context) {
    final hasValidity = plan.validity.isNotEmpty;
    final dataValue = extractPlanDataValue(plan);
    final hasData = dataValue.isNotEmpty;
    final hasBenefitImages = plan.additionalBenefits.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasValidity)
                      _PlanInfoColumn(
                        label: 'Validity',
                        value: plan.validity,
                      ),
                    if (hasValidity && hasData) ...[
                      SizedBox(width: 14.w),
                      VerticalDivider(
                        width: 12.w,
                        thickness: 1,
                        color: AppColors.lightBorder,
                      ),
                      SizedBox(width: 14.w),
                    ],
                    if (hasData)
                      _PlanInfoColumn(
                        label: 'Data',
                        value: dataValue,
                      ),
                  ],
                ),
              ),
            ),
            if (hasBenefitImages)
              _PlanBenefitImages(
                benefits: plan.additionalBenefits,
                onTap: onBenefitsTap,
              ),
          ],
        );
      },
    );
  }
}

class _PlanInfoColumn extends StatelessWidget {
  const _PlanInfoColumn({
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
            color: const Color(0xFF7C7C7C),
            fontWeight: FontWeight.w400,
            fontSize: 12.sp,
            height: 1,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontSize: 12.sp,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _PlanBenefitImages extends StatelessWidget {
  const _PlanBenefitImages({
    required this.benefits,
    this.onTap,
  });

  final List<AdditionalBenefit> benefits;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const maxVisible = 5;
    final visibleBenefits = benefits.take(maxVisible).toList();
    final remaining = benefits.length - maxVisible;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: (visibleBenefits.length * 22.0).w + 8.w,
            height: 26.h,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (int i = 0; i < visibleBenefits.length; i++)
                  Positioned(
                    left: (i * 22.0).w,
                    child: _BenefitIconAvatar(benefit: visibleBenefits[i]),
                  ),
              ],
            ),
          ),
          if (remaining > 0)
            Text(
              '+$remaining',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 13.sp,
                  ),
            ),
        ],
      ),
    );
  }
}

class _BenefitIconAvatar extends StatelessWidget {
  const _BenefitIconAvatar({required this.benefit});

  final AdditionalBenefit benefit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30.w,
      height: 30.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
          ),
        ],
      ),
      child: ClipOval(
        child: benefit.image == null
            ? Container(
                color: Colors.grey.shade200,
                child: Icon(Icons.card_giftcard, size: 14.sp),
              )
            : Image.network(
                benefit.image!,
                width: 30.w,
                height: 30.w,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: Icon(Icons.image, size: 14.sp),
                ),
              ),
      ),
    );
  }
}

class _PlanPayNowButton extends StatelessWidget {
  const _PlanPayNowButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          color: const Color(0xFFDD5428),
          borderRadius: BorderRadius.circular(82.r),
        ),
        child: Text(
          'Pay Now',
          style: GoogleFonts.bricolageGrotesque(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
            height: 1,
          ),
        ),
      ),
    );
  }
}


