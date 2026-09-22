// ignore_for_file: deprecated_member_use

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../constants/api_constants.dart';
import '../constants/app_colors.dart';
import '../services/dio_service.dart';
import 'app_snackbar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RatingBottomSheet extends StatefulWidget {
  const RatingBottomSheet({
    super.key,
    required this.transactionId,
  });

  final String transactionId;

  @override
  State<RatingBottomSheet> createState() => _RatingBottomSheetState();
}

class _RatingBottomSheetState extends State<RatingBottomSheet> {
  final TextEditingController _reviewController = TextEditingController();
  int _rating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_isSubmitting) return;
    if (_rating == 0) {
      AppSnackbar.show(
        'Please select a rating.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final response = await DioService.instance.client.post(
        ApiConstants.ratingSubmitEndpoint,
        data: {
          'transaction_id': widget.transactionId,
          'rating': _rating,
          'review': _reviewController.text.trim(),
        },
        options: Options(
          contentType: Headers.jsonContentType,
          validateStatus: (status) => status != null && status < 600,
        ),
      );
      final payload = response.data;
      final status = response.statusCode ?? 0;
      final success = status >= 200 &&
          status < 300 &&
          (payload is! Map ||
              payload['success'] == true ||
              payload['status']?.toString().toLowerCase() == 'success');
      if (success) {
        AppSnackbar.show(
          'Thanks for the feedback!',
          backgroundColor: AppColors.primary,
          textColor: Colors.white,
        );
        if (mounted) Navigator.of(context).pop();
      } else {
        AppSnackbar.show(
          'Failed to submit rating. Please try again.',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (_) {
      AppSnackbar.show(
        'Failed to submit rating. Please try again.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildStar(int index) {
    final isSelected = index <= _rating;
    return InkWell(
      onTap: () => setState(() => _rating = index),
      child: Icon(
        isSelected ? Icons.star_rounded : Icons.star_border_rounded,
        color: isSelected ? const Color(0xFFF5B301) : const Color(0xFFDADCE0),
        size: 30,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      width: 32.r,
                      height: 32.r,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE0E0E0),
                        ),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 18.r,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Rate Us & Earn eCoins',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Share your experience and get rewarded\ninstantly',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.7),
                        height: 1.4,
                      ),
                ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) => _buildStar(index + 1)),
                ),
                SizedBox(height: 14.h),
                TextField(
                  controller: _reviewController,
                  minLines: 3,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Write your feedback',
                    hintStyle: TextStyle(
                      color: AppColors.textPrimary.withOpacity(0.35),
                    ),
                    contentPadding: EdgeInsets.all(14.w),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: const BorderSide(color: Color(0xFFE4DFDA)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: const BorderSide(color: Color(0xFFE4DFDA)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                SizedBox(height: 18.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F1F1),
                          foregroundColor: AppColors.textPrimary,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.r),
                          ),
                        ),
                        child: const Text('Maybe Later'),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitRating,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.r),
                          ),
                        ),
                        child: Text(
                          _isSubmitting ? 'Submitting...' : 'Claim 50 eCoins',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

