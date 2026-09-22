// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';
import '../constants/file_constants.dart';
import 'app_html.dart';
import 'app_network_image.dart';

class BillSampleTermsCard extends StatelessWidget {
  const BillSampleTermsCard({
    super.key,
    required this.isExpanded,
    required this.onToggle,
    this.billImageUrl,
    this.termsText,
  });

  final bool isExpanded;
  final VoidCallback onToggle;
  final String? billImageUrl;
  final String? termsText;

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

  @override
  Widget build(BuildContext context) {
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
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: (billImageUrl ?? '').trim().isNotEmpty
                  ? AppNetworkImage(
                      url: billImageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      showShimmer: true,
                    )
                  : Image.asset(
                      FileConstants.sampleBill,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
            SizedBox(height: 16.h),
            (termsText ?? '').trim().isNotEmpty
                ? AppHtml(html: _normalizeTermsToHtml(termsText!))
                : Text(
                    'Terms are not available at the moment.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary.withOpacity(0.7),
                          height: 1.5,
                        ),
                  ),
          ],
        ],
      ),
    );
  }
}
