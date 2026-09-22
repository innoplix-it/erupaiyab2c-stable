// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../models/offer_model.dart';

class OfferCard extends StatelessWidget {
  const OfferCard({
    super.key,
    required this.offer,
    this.onViewOffer,
    this.onTap,
  });

  final OfferModel offer;
  final VoidCallback? onViewOffer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? onViewOffer,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 16.r,
                offset: Offset(0.w, 6.h),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: orange pill + valid until
                    Padding(
                      padding: EdgeInsets.fromLTRB(0.w, 0.h, 16.w, 0.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Orange pill badge
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16.r),
                                bottomRight: Radius.circular(16.r),
                              ),
                            ),
                            child: Text(
                              offer.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                            ),
                          ),
                          const Spacer(),
                          Padding(
                            padding: EdgeInsets.only(top: 10.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'VALID UNTIL:',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppColors.textPrimary
                                            .withOpacity(0.5),
                                        letterSpacing: 0.4,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                Text(
                                  offer.endDate.isNotEmpty
                                      ? offer.endDate
                                      : 'N/A',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    // Icon + description
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 36.r,
                            width: 36.r,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Center(
                              child: Icon(
                                _iconFor(offer.iconType),
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: 56.w),
                              child: Text(
                                offer.summary,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      height: 1.4,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 14.h),
                    // View Offer
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 0.h, 0.w, 20.h),
                      child: GestureDetector(
                        onTap: onViewOffer ?? onTap,
                        child: Text(
                          'View Offer',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.textPrimary,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Frame213 orange circle at bottom-right
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Image.asset(
                    FileConstants.frame213,
                    height: 60.r,
                    width: 60.r,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(OfferIconType type) {
    switch (type) {
      case OfferIconType.mobile:
        return Icons.smartphone;
      case OfferIconType.creditCard:
        return Icons.credit_card;
      case OfferIconType.dth:
        return Icons.tv;
      case OfferIconType.wallet:
        return Icons.account_balance_wallet_outlined;
      case OfferIconType.generic:
        return Icons.local_offer_outlined;
    }
  }
}
