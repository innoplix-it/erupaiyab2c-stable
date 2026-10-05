// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/file_constants.dart';
import '../features/services/components/fetch_provider_metrics.dart';
import 'app_html.dart';
import 'app_network_image.dart';

class BillSampleTermsCard extends StatelessWidget {
  const BillSampleTermsCard({
    super.key,
    required this.isExpanded,
    required this.onToggle,
    this.billImageUrl,
    this.termsText,
    this.viewSampleBillStyle = false,
  });

  static const viewSampleBillLabel = 'View Sample Bill';
  static const viewSampleBillIcon = 'assets/images/svg/view_sample_bill.svg';

  final bool isExpanded;
  final VoidCallback onToggle;
  final String? billImageUrl;
  final String? termsText;

  /// Figma "View Sample Bill" header (Electricity Pay Now). The expanded
  /// image and terms content is the same as the default style.
  final bool viewSampleBillStyle;

  String _normalizeTermsToHtml(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';

    final looksLikeHtml = RegExp(r'<\s*\/?\s*[a-zA-Z][^>]*>').hasMatch(trimmed);
    if (looksLikeHtml) return trimmed;

    // Backend sometimes sends plain text with newlines/bullets; convert it into
    // safe HTML while preserving line breaks.
    final escaped = const HtmlEscape().convert(trimmed);
    final withBreaks = escaped.replaceAll(RegExp(r'\r\n|\r|\n'), '<br/>');
    return '<div>$withBreaks</div>';
  }

  Widget _buildSampleImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: (billImageUrl ?? '').trim().isNotEmpty
          ? AppNetworkImage(
              url: billImageUrl,
              width: double.infinity,
              fit: BoxFit.contain,
              showShimmer: true,
            )
          : Image.asset(
              FileConstants.sampleBill,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
    );
  }

  Widget _buildTerms(BuildContext context) {
    return (termsText ?? '').trim().isNotEmpty
        ? AppHtml(html: _normalizeTermsToHtml(termsText!))
        : Text(
            'Terms are not available at the moment.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.7),
                  height: 1.5,
                ),
          );
  }

  @override
  Widget build(BuildContext context) {
    if (viewSampleBillStyle) return _buildViewSampleBill(context);

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12.r,
            offset: Offset(0.w, 6.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            child: Row(
              children: [
                Container(
                  width: 26.w,
                  height: 26.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 16.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'Bill Sample & Terms conditions',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.textPrimary.withOpacity(0.6),
                  size: 20.sp,
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            SizedBox(height: 12.h),
            Text(
              'Bill Sample',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 10.h),
            _buildSampleImage(),
            SizedBox(height: 16.h),
            _buildTerms(context),
          ],
        ],
      ),
    );
  }

  Widget _buildViewSampleBill(BuildContext context) {
    const accent = Color(0xFFDD5428);
    const stroke = Color(0xFFD7D7D7);
    final radius = BorderRadius.circular(FetchProviderMetrics.r(12));
    final inset = FetchProviderMetrics.w(16);
    final iconSize = FetchProviderMetrics.r(20);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        border: Border.all(color: stroke, width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onToggle,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: FetchProviderMetrics.r(54),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: inset,
                    vertical: FetchProviderMetrics.h(8),
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        viewSampleBillIcon,
                        width: iconSize,
                        height: iconSize,
                      ),
                      SizedBox(width: FetchProviderMetrics.w(8)),
                      Expanded(
                        child: Text(
                          viewSampleBillLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w500,
                            fontSize: 14.sp,
                            height: 1,
                            letterSpacing: 0,
                            color: accent,
                          ),
                        ),
                      ),
                      SizedBox(width: FetchProviderMetrics.w(8)),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: const Color(0xFF000000),
                        size: FetchProviderMetrics.r(24),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isExpanded) ...[
              const Divider(height: 0.5, thickness: 0.5, color: stroke),
              Padding(
                padding: EdgeInsets.all(inset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bill Sample',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    SizedBox(height: FetchProviderMetrics.h(10)),
                    _buildSampleImage(),
                    SizedBox(height: FetchProviderMetrics.h(16)),
                    _buildTerms(context),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
