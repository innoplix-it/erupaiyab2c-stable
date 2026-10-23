import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import 'custom_elevated_button.dart';

/// Shared Enter OTP dialog. [onSubmit] returns an error string to show under
/// the field, or null when verification succeeded.
class EnterOtpPopup extends HookWidget {
  const EnterOtpPopup({
    super.key,
    required this.onSubmit,
    this.title = 'Enter OTP',
    this.message =
        'Please enter the 6-digit OTP sent to your registered number.',
    this.hintText = 'OTP',
    this.buttonLabel = 'Verify OTP',
  });

  final Future<String?> Function(String otp) onSubmit;
  final String title;
  final String message;
  final String hintText;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    final otpController = useTextEditingController();
    final isLoading = useState(false);
    final errorText = useState<String?>(null);

    Future<void> verifyOtp() async {
      final otp = otpController.text.trim();
      if (otp.length < 6) {
        errorText.value = 'Please enter the 6-digit OTP.';
        return;
      }
      errorText.value = null;
      isLoading.value = true;
      final error = await onSubmit(otp);
      if (!context.mounted) return;
      isLoading.value = false;
      errorText.value = error;
    }

    final fieldStyle = GoogleFonts.plusJakartaSans(
      fontSize: 14.sp,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    );

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(22.w, 22.h, 22.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
            SizedBox(height: 18.h),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 6,
              style: fieldStyle,
              onChanged: (_) => errorText.value = null,
              decoration: InputDecoration(
                counterText: '',
                hintText: hintText,
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF9A9A9A),
                ),
                errorText: errorText.value,
                errorStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 14.h,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            CustomElevatedButton(
              onPressed: isLoading.value ? null : verifyOtp,
              isLoading: isLoading.value,
              label: buttonLabel,
              uppercaseLabel: false,
              backgroundColor: AppColors.primary,
              height: 48.h,
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
