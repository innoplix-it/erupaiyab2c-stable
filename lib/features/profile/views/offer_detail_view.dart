// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/api_constants.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_network_image.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../models/offer_model.dart';

class OfferDetailView extends StatelessWidget {
  const OfferDetailView({super.key, required this.offer});

  final OfferModel offer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          offer.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // MyAppBar(
          //   title: offer.category,
          //   onBack: () => context.pop(),
          //   trailing: IconButton(
          //     icon:
          //         const Icon(Icons.help_outline, color: AppColors.textPrimary),
          //     onPressed: () {},
          //   ),
          // ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 0.h, 20.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: AppNetworkImage(
                      url: offer.banner.trim().isEmpty
                          ? ''
                          : _resolveBannerUrl(offer.banner),
                      width: double.infinity,
                      height: 110.h,
                      fit: BoxFit.fill,
                      placeholder: _bannerPlaceholder(),
                      errorWidget: _bannerPlaceholder(),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    offer.summary,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      Container(
                        height: 34.r,
                        width: 34.r,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: Icon(
                            _iconFor(offer.iconType),
                            color: AppColors.primary,
                            size: 18.sp,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          offer.title,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'VALID UNTIL:',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.textPrimary.withOpacity(0.5),
                                  letterSpacing: 0.4,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          Text(
                            offer.endDate.isNotEmpty ? offer.endDate : 'N/A',
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
                    ],
                  ),
                  SizedBox(height: 16.h),
                  if (offer.cashbackValue.trim().isNotEmpty) ...[
                    Text(
                      'Cashback',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      offer.cashbackType.trim().isNotEmpty
                          ? '${offer.cashbackValue} (${offer.cashbackType})'
                          : offer.cashbackValue,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary.withOpacity(0.7),
                            height: 1.5,
                          ),
                    ),
                    SizedBox(height: 16.h),
                  ],
                  Text(
                    'Offer Summary',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    offer.summary.isNotEmpty
                        ? offer.summary
                        : 'No summary available for this offer.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary.withOpacity(0.7),
                          height: 1.5,
                        ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'How To Claim',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  SizedBox(height: 6.h),
                  ..._buildBullets(
                    _splitLines(offer.howToClaim),
                    fallback: 'No claim instructions available.',
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Terms & Conditions',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  SizedBox(height: 6.h),
                  ..._buildBullets(
                    _splitLines(offer.termsConditions),
                    fallback: 'No terms available.',
                  ),
                  SizedBox(height: 24.h),
                  CustomElevatedButton(
                    onPressed: () => _handleOfferAction(context),
                    label: 'Recharge Now',
                    uppercaseLabel: false,
                    height: 42.h,
                  ),
                ],
              ),
            ),
          ),
        ],
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

  Widget _bannerPlaceholder() {
    return Image.asset(
      FileConstants.homeBanner2,
      width: double.infinity,
      height: 150.h,
      fit: BoxFit.cover,
    );
  }

  void _handleOfferAction(BuildContext context) {
    final text = '${offer.title} ${offer.summary}'.toLowerCase();
    if (text.contains('dth')) {
      context.push(RouteConstants.billerListing, extra: 'DTH');
      return;
    }
    if (text.contains('mobile') ||
        text.contains('recharge') ||
        text.contains('prepaid')) {
      context.push(RouteConstants.mobilePrepaid);
      return;
    }
    AppSnackbar.show('No service mapped for this offer yet.');
  }

  String _resolveBannerUrl(String banner) {
    final trimmed = banner.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return '${ApiConstants.offersBannerBaseUrl}/$trimmed';
  }

  List<String> _splitLines(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return [];
    return value
        .replaceAll('\r\n', '\n')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  List<Widget> _buildBullets(List<String> lines, {required String fallback}) {
    if (lines.isEmpty) {
      return [
        _Bullet(text: fallback),
      ];
    }
    return lines.map((line) => _Bullet(text: line)).toList();
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.7),
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
