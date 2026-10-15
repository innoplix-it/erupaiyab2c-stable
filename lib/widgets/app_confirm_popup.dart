// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Icon badge fill and border, shared with the app's other confirmation
/// dialogs (Delete Account, Disable Notifications, ...).
const Color kAppConfirmIconFill = Color(0xFFFFF1EB);
const Color kAppConfirmIconBorder = Color(0xFFF2B9A6);

/// Shows an [AppConfirmPopup]. Resolves to true when [confirmLabel] is
/// tapped, false for [cancelLabel].
Future<bool> showAppConfirmPopup({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  IconData icon = Icons.info_outline,
  bool barrierDismissible = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) => AppConfirmPopup(
      icon: icon,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      onConfirm: () => Navigator.of(dialogContext).pop(true),
      onCancel: () => Navigator.of(dialogContext).pop(false),
    ),
  );
  return result ?? false;
}

/// Common confirmation popup in the app's standard style: white card, orange
/// icon badge, title, message, the confirm action as a white outlined button
/// on the left and the safe (cancel) action filled with the primary colour
/// on the right.
class AppConfirmPopup extends StatelessWidget {
  const AppConfirmPopup({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onConfirm,
    required this.onCancel,
    this.icon = Icons.info_outline,
  });

  final IconData icon;
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.r),
    );
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(22.w, 22.h, 22.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64.r,
              height: 64.r,
              decoration: BoxDecoration(
                color: kAppConfirmIconFill,
                shape: BoxShape.circle,
                border: Border.all(color: kAppConfirmIconBorder),
              ),
              child: Icon(icon, color: AppColors.primary, size: 34.r),
            ),
            SizedBox(height: 14.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                textStyle: textTheme.titleLarge,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                textStyle: textTheme.bodyMedium,
                color: AppColors.textPrimary.withOpacity(0.75),
                height: 1.35,
              ),
            ),
            SizedBox(height: 18.h),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44.h,
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.white,
                        shape: buttonShape.copyWith(
                          side: BorderSide(
                            color: AppColors.textPrimary.withOpacity(0.18),
                          ),
                        ),
                      ),
                      child: Text(
                        confirmLabel,
                        style: GoogleFonts.plusJakartaSans(
                          textStyle: textTheme.bodyMedium,
                          color: AppColors.textPrimary.withOpacity(0.8),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: SizedBox(
                    height: 44.h,
                    child: ElevatedButton(
                      onPressed: onCancel,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.primary,
                        shape: buttonShape,
                      ),
                      child: Text(
                        cancelLabel,
                        style: GoogleFonts.plusJakartaSans(
                          textStyle: textTheme.bodyMedium,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
