// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/routes_constant.dart';
import 'auth_step_parts.dart';

class AuthMobileStep extends StatelessWidget {
  const AuthMobileStep({
    super.key,
    required this.controller,
    required this.onContinue,
    required this.isConsentAllowed,
    required this.onConsentChanged,
    this.isLoading = false,
    this.referralBanner,
    this.focusNode,
  });

  final TextEditingController controller;
  final VoidCallback? onContinue;
  final bool isConsentAllowed;
  final ValueChanged<bool> onConsentChanged;
  final bool isLoading;
  final Widget? referralBanner;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return AuthStepLayout(

      footer: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final phoneValid =
              value.text.trim().length == AuthMobileField.mobileLength;

          final canContinue = !isLoading &&
              phoneValid &&
              isConsentAllowed &&
              onContinue != null;
          return AuthPrimaryButton(
            label: 'Continue',
            enabled: canContinue,
            onPressed: onContinue,
            isLoading: isLoading,
          );
        },
      ),
      children: [
        const AuthBrandRow(),
        SizedBox(height: 22.h),
        const AuthWelcomeHeading(),
        SizedBox(height: 22.h),
        if (referralBanner != null) ...[
          referralBanner!,
          SizedBox(height: 12.h),
        ],
        const AuthFieldLabel('Mobile Number'),
        SizedBox(height: 8.h),
        AuthMobileField(
          controller: controller,
          enabled: !isLoading,
          autofocus: true,
          focusNode: focusNode,
        ),
        SizedBox(height: 14.h),
        _buildConsent(context),
      ],
    );
  }

  Widget _buildConsent(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 2.h),
          child: SizedBox.square(
            dimension: authWidthFraction(context, 28 / 360, min: 24, max: 36),
            child: Checkbox(
              value: isConsentAllowed,
              onChanged: isLoading
                  ? null
                  : (value) => onConsentChanged(value ?? false),
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.r),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 9.h),
            child: Wrap(
              // The Figma consent line. Only the copy changed - the checkbox
              // still gates Continue through the same canContinue rule below.
              children: [
                Text('by continuing, I agree to', style: _consentStyle),
                SizedBox(width: 3.w),
                _policyLink(
                  context,
                  label: 'terms of use policy',
                  route: RouteConstants.termsPrivacy,
                ),
                SizedBox(width: 3.w),
                Text('&', style: _consentStyle),
                SizedBox(width: 3.w),
                _policyLink(
                  context,
                  label: 'privacy policy',
                  route: RouteConstants.privacyPolicy,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Underlined policy link that reuses the routes the app already registers -
  /// the same `context.push` pattern `policies_screen.dart` uses.
  Widget _policyLink(
    BuildContext context, {
    required String label,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Text(label, style: _linkStyle),
    );
  }

  TextStyle get _consentStyle => TextStyle(
        fontFamily: authFontFamily,
        fontSize: 10.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary.withOpacity(0.7),
        height: 1.2,
        letterSpacing: 0,
      );

  TextStyle get _linkStyle =>
      _consentStyle.copyWith(decoration: TextDecoration.underline);
}
