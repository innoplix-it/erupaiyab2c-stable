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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 14.h, left: 20.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 81.w,
                    height: 44.h,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '₹ ${plan.amount}',
                          maxLines: 1,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 40.sp,
                            color: Colors.black,
                            height: 44 / 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  GetAssuredCoinsBadge(label: assuredLabel),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 4.h, 16.w, 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PlanInfoRow(
                    plan: plan,
                    onBenefitsTap: () => _openPlanDetailsSheet(context),
                  ),
                  SizedBox(height: 10.h),
                  const PlanValidityDivider(),
                  SizedBox(height: 8.h),
                  if (plan.description.trim().isNotEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 44.h,
                      child: Text(
                        plan.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w400,
                          fontSize: 12.sp,
                          height: 22 / 12,
                          color: const Color(0xFF222222),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                  ] else
                    SizedBox(height: 8.h),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onViewDetails ?? onTap,
                        child: SizedBox(
                          width: 83.w,
                          height: 17.h,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'View Details',
                              textAlign: TextAlign.left,
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFFDD5428),
                                fontWeight: FontWeight.w600,
                                fontSize: 14.sp,
                                height: 17 / 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 114.w,
                        height: 32.h,
                        child: _PlanPayNowButton(
                          onTap: onPayNow ?? onTap,
                        ),
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

class PlanValidityDivider extends StatelessWidget {
  const PlanValidityDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 356.w),
        child: Container(
          width: double.infinity,
          height: 0.5,
          color: const Color(0xFFBABABA),
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
              style: GoogleFonts.plusJakartaSans(
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

class PlanInfoRow extends StatelessWidget {
  const PlanInfoRow({
    super.key,
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
    return SizedBox(
      height: 32.h,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 36.w,
            height: 16.h,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF898989),
                  fontWeight: FontWeight.w400,
                  fontSize: 10.sp,
                  height: 16 / 10,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 16.h,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF000000),
                fontSize: 12.sp,
                height: 16 / 12,
              ),
            ),
          ),
        ],
      ),
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
              style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 13.sp,
                    height: 1,
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
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        decoration: BoxDecoration(
          color: const Color(0xFFDD5428),
          borderRadius: BorderRadius.circular(82.r),
        ),
        child: Text(
          'Pay Now',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12.sp,
            height: 1,
          ),
        ),
      ),
    );
  }
}


