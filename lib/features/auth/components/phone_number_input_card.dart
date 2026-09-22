// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// import '../../../widgets/custom_elevated_button.dart';
// import '../../../widgets/grey_text_form_field.dart';

// class PhoneNumberInputCard extends StatelessWidget {
//   const PhoneNumberInputCard({
//     super.key,
//     required this.controller,
//     required this.onContinue,
//     required this.isConsentAllowed,
//     required this.onConsentChanged,
//     this.helperText,
//     this.placeholder = 'ENTER YOUR MOBILE NUMBER',
//     this.enabled = true,
//   });

//   final TextEditingController controller;
//   final VoidCallback? onContinue;
//   final bool isConsentAllowed;
//   final ValueChanged<bool> onConsentChanged;
//   final bool enabled;
//   final String? helperText;
//   final String placeholder;

// ignore_for_file: deprecated_member_use

//   @override
//   Widget build(BuildContext context) {
//     return DecoratedBox(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(32.r),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.08),
//             blurRadius: 25.r,
//             offset: const Offset(0.w, 8.h),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(24.w),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               placeholder.toUpperCase(),
//               style: Theme.of(context).textTheme.labelMedium?.copyWith(
//                     letterSpacing: 1.5,
//                     fontWeight: FontWeight.w600,
//                   ),
//             ),
//             SizedBox(height: 16.h),
//             GreyTextFormField(
//               controller: controller,
//               enabled: enabled,
//               isNumber: true,
//               hintText: 'Enter mobile number',
//               validator: (value) {
//                 final trimmed = value?.trim() ?? '';
//                 if (trimmed.isEmpty) {
//                   return 'Please enter mobile number';
//                 }
//                 if (trimmed.length != 10) {
//                   return 'Enter 10-digit mobile number';
//                 }
//                 return null;
//               },
//             ),
//             SizedBox(height: 12.h),
//             Row(
//               children: [
//                 Checkbox(
//                   value: isConsentAllowed,
//                   onChanged: enabled
//                       ? (value) => onConsentChanged(value ?? false)
//                       : null,
//                   activeColor: Colors.black87,
//                   visualDensity: VisualDensity.compact,
//                 ),
//                 Expanded(
//                   child: Text(
//                     'Allow e-ruppaiya to access your information and collect data from this device',
//                     style: Theme.of(context).textTheme.bodySmall,
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 16.h),
//             CustomElevatedButton(
//               onPressed: (enabled && isConsentAllowed) ? onContinue : null,
//               label: 'Continue',
//             ),
//             if (helperText != null) ...[
//               SizedBox(height: 12.h),
//               Text(
//                 helperText!,
//                 textAlign: TextAlign.center,
//                 style: Theme.of(context)
//                     .textTheme
//                     .bodySmall
//                     ?.copyWith(color: Colors.black54),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/grey_text_form_field.dart';

class PhoneNumberInputCard extends StatelessWidget {
  const PhoneNumberInputCard({
    super.key,
    required this.controller,
    required this.onContinue,
    required this.isConsentAllowed,
    required this.onConsentChanged,
    this.isLoading = false,
    this.nameController,
    this.helperText,
    this.showHelper = true,
    this.placeholder = 'Start Earning Rewards',
    this.subtitle = 'Register to turn every payment into reward points.',
    this.enabled = true,
  });

  final TextEditingController controller;
  final TextEditingController? nameController;
  final VoidCallback? onContinue;
  final bool isConsentAllowed;
  final ValueChanged<bool> onConsentChanged;
  final bool isLoading;
  final bool enabled;
  final String? helperText;
  final bool showHelper;
  final String placeholder;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    Widget buildBody({
      required bool phoneValid,
      required bool nameValid,
    }) {
      final canContinue = enabled &&
          !isLoading &&
          phoneValid &&
          nameValid &&
          isConsentAllowed &&
          onContinue != null;
      final showConsentError = enabled && phoneValid && !isConsentAllowed;

      return DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 30.r,
              offset: Offset(0.w, 14.h),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                placeholder,
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 20.sp,
                      color: AppColors.textPrimary,
                    ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary.withOpacity(0.6),
                    ),
              ),
              if (nameController != null) ...[
                SizedBox(height: 14.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Enter Name',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ),
                SizedBox(height: 6.h),
                GreyTextFormField(
                  controller: nameController!,
                  enabled: enabled,
                  hintText: 'Ivanshu Patil',
                  height: 40.h,
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
              ],
              SizedBox(height: 14.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Enter Mobile Number',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
              SizedBox(height: 6.h),
              GreyTextFormField(
                controller: controller,
                enabled: enabled,
                isNumber: true,
                centerText: false,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(left: 16.w, right: 10.w),
                  child: Image.asset(
                    FileConstants.indiaFlag,
                    width: 20.w,
                    height: 20.w,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 8.h,
                  horizontal: 4.w,
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return 'Please enter mobile number';
                  }
                  if (trimmed.length != 10) {
                    return 'Enter 10-digit mobile number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    value: isConsentAllowed,
                    onChanged: enabled
                        ? (value) => onConsentChanged(value ?? false)
                        : null,
                    activeColor: AppColors.primary,
                    visualDensity: VisualDensity.compact,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text.rich(
                      const TextSpan(
                        text: 'Allow ',
                        children: [
                          TextSpan(
                            text: 'E-Rupaiya',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text:
                                ' to access your information and collect data from your device',
                          ),
                        ],
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary.withOpacity(0.65),
                          ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18.h),
              CustomElevatedButton(
                onPressed: canContinue ? onContinue : null,
                label: 'Continue',
                isLoading: isLoading,
                backgroundColor:
                    canContinue ? null : Colors.grey.shade400.withOpacity(0.9),
                labelColor: canContinue ? null : Colors.white,
              ),
              // if (showConsentError) ...[
              //   SizedBox(height: 10.h),
              //   Center(
              //     child: Text(
              //       'Please allow access to continue.',
              //       textAlign: TextAlign.center,
              //       style: Theme.of(context).textTheme.bodySmall?.copyWith(
              //             color: Colors.red.shade600,
              //             fontWeight: FontWeight.w600,
              //           ),
              //     ),
              //   ),
              // ],
              if (helperText != null && showHelper) ...[
                SizedBox(height: 12.h),
                Center(
                  child: Text(
                    helperText!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary.withOpacity(0.7),
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    Widget buildFromPhone() {
      final phoneValid = controller.text.trim().length == 10;
      if (nameController == null) {
        return buildBody(phoneValid: phoneValid, nameValid: true);
      }
      return ValueListenableBuilder<TextEditingValue>(
        valueListenable: nameController!,
        builder: (_, __, ___) {
          final nameValid = nameController!.text.trim().isNotEmpty;
          return buildBody(phoneValid: phoneValid, nameValid: nameValid);
        },
      );
    }

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (_, __, ___) => buildFromPhone(),
    );
  }
}
