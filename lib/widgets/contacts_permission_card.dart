// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';
import '../constants/file_constants.dart';

class ContactsPermissionCard extends StatelessWidget {
  const ContactsPermissionCard({
    super.key,
    required this.onAllow,
    this.title = 'Recharge For Family & Friends',
    this.description =
        'Select Numbers From Your Contacts\nFor Faster Recharge And Bill Payments.',
    this.buttonLabel = 'Allow Contact Access',
    this.outerPadding,
  });

  final VoidCallback onAllow;
  final String title;
  final String description;
  final String buttonLabel;
  final EdgeInsetsGeometry? outerPadding;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Padding(
      padding: outerPadding ??
          EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h + bottomInset),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(18.w, 24.h, 18.w, 22.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Column(
          children: [
            Container(
              height: 84.w,
              width: 84.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 18.r,
                    offset: Offset(0.w, 10.h),
                  ),
                ],
              ),
              child: Center(
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFE85A2C),
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    FileConstants.contactLogo,
                    width: 34.w,
                    height: 34.w,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            SizedBox(height: 18.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            SizedBox(height: 10.h),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
            ),
            SizedBox(height: 18.h),
            SizedBox(
              width: double.infinity,
              height: 40.h,
              child: ElevatedButton(
                onPressed: onAllow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE85A2C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  buttonLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
