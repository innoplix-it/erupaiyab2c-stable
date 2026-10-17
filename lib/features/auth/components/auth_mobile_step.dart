import 'package:e_rupaiya/constants/app_colors.dart';
import 'package:e_rupaiya/constants/file_constants.dart';
import 'package:e_rupaiya/constants/routes_constant.dart';
import 'package:e_rupaiya/features/auth/components/auth_step_parts.dart';
import 'package:e_rupaiya/features/auth/components/login_services_slider.dart';
import 'package:e_rupaiya/widgets/custom_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// Login mobile step: Figma "Pay Bills & Earn" layout with a slow service
/// marquee, peach→white gradient, and a local +91 field (not [AuthMobileField]).
class AuthMobileStep extends StatelessWidget {
  const AuthMobileStep({
    super.key,
    required this.controller,
    this.focusNode,
    this.isLoading = false,
    this.onContinue,
    this.referralBanner,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool isLoading;
  final VoidCallback? onContinue;
  final Widget? referralBanner;

  static const LinearGradient _backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFA68A),
      Color(0xFFFFFFFF),
    ],
    stops: [0.0, 1.0],
  );

  static const Color _ink = Color(0xFF000000);

  bool get _phoneValid {
    final digits = controller.text.replaceAll(RegExp(r'\D'), '');
    return digits.length == 10;
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final fieldEnabled = !isLoading;
    // Keyboard inset is handled solely by the parent Scaffold's
    // resizeToAvoidBottomInset — do not also pad by viewInsets here.
    // Keyboard open: tight above keyboard. Closed: respect safe-area like Figma.
    final termsBottomGap = keyboardOpen ? 8.h : bottomSafe + 16.h;

    return AuthKeyboardOnOpen(
      focusNode: focusNode,
      enabled: fieldEnabled,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: _backgroundGradient),
        child: SafeArea(
          top: false,
          bottom: false,
          child: LayoutBuilder(
            builder: (context, viewport) {
              // Budget from actual parent height (already keyboard-shrunk by
              // Scaffold) — never from full MediaQuery height alone.
              final topPad = topInset + 8.h;
              final sliderBudget =
                  ((viewport.maxHeight - topPad) * (keyboardOpen ? 0.32 : 0.55))
                      .clamp(72.0, viewport.maxHeight * 0.58);

              return Column(
                children: [
                  SizedBox(height: topPad),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: sliderBudget),
                    child: const LoginServicesSlider(),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: authHorizontalPadding,
                          ),
                          child: Align(
                            // Bottom-oriented when closed; Scaffold shrinks this
                            // region when the keyboard opens so the same alignment
                            // lifts branding + form above the keyboard.
                            alignment: Alignment.bottomCenter,
                            child: SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: authContentMaxWidth(context),
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(height: 8.h),
                                    Center(
                                      child: Image.asset(
                                        FileConstants.erupaiyaLogo,
                                        width: 72.r,
                                        height: 72.r,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    SizedBox(height: 10.h),
                                    Text(
                                      'Pay Bills & Earn',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 22.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                        height: 1.2,
                                      ),
                                    ),
                                    SizedBox(height: 6.h),
                                    Text(
                                      'Enter your mobile number to continue.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.textPrimary,
                                        height: 1.3,
                                      ),
                                    ),
                                    if (referralBanner != null) ...[
                                      SizedBox(height: 16.h),
                                      referralBanner!,
                                    ],
                                    SizedBox(height: 22.h),
                                    Text(
                                      'Mobile Number',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w700,
                                        color: _ink,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    _FigmaMobileField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      enabled: fieldEnabled,
                                    ),
                                    SizedBox(height: 16.h),
                                    ListenableBuilder(
                                      listenable: controller,
                                      builder: (context, _) {
                                        final canContinue =
                                            _phoneValid && !isLoading;
                                        return CustomElevatedButton(
                                          label: 'Continue',
                                          uppercaseLabel: false,
                                          onPressed:
                                              canContinue ? onContinue : null,
                                          isLoading: isLoading,
                                          backgroundColor: canContinue
                                              ? AppColors.primary
                                              : authDisabledFill,
                                          labelColor: canContinue
                                              ? Colors.white
                                              : const Color(0xFF71717A),
                                          height: authButtonHeight(context),
                                        );
                                      },
                                    ),
                                    SizedBox(height: 20.h),
                                    Text(
                                      'By continuing, you agree to our',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        GestureDetector(
                                          onTap: () => context.push(
                                            RouteConstants.termsPrivacy,
                                          ),
                                          child: Text(
                                            'Terms of Use',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w400,
                                              color: AppColors.primary,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor:
                                                  AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          ' & ',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w400,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => context.push(
                                            RouteConstants.privacyPolicy,
                                          ),
                                          child: Text(
                                            'Privacy Policy',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w400,
                                              color: AppColors.primary,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor:
                                                  AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: termsBottomGap),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Figma-styled +91 / divider / placeholder field (local to this step).
class _FigmaMobileField extends StatelessWidget {
  const _FigmaMobileField({
    required this.controller,
    this.focusNode,
    this.enabled = true,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;

  static const Color _ink = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    final height = authWidthFraction(context, 48 / 360, min: 44, max: 56);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Row(
        children: [
          Text(
            '+91',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: _ink,
            ),
          ),
          SizedBox(width: 10.w),
          Container(
            width: 1,
            height: 20.h,
            color: const Color(0xFFE4E4E7),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              autofocus: true,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: _ink,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Enter 10 Digit Mobile Number',
                hintStyle: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFA1A1AA),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
