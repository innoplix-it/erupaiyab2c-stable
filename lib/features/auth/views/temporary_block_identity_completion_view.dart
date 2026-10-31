import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../helpers/kyc_helpers.dart';
import '../../../helpers/kyc_input_formatters.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/grey_text_form_field.dart';
import '../../../widgets/k_dialog.dart';
import '../../profile/controllers/profile_controller.dart';
import '../components/auth_step_parts.dart';
import '../controllers/auth_controller.dart';

class TemporaryBlockIdentityCompletionView extends HookConsumerWidget {
  const TemporaryBlockIdentityCompletionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final profile = ref.watch(profileControllerProvider).profile;
    final panController = useTextEditingController(
      text: (profile?.panNo ?? '').trim(),
    );
    final aadhaarController = useTextEditingController(
      text: '',
    );
    final panFocus = useFocusNode();
    final aadhaarFocus = useFocusNode();
    final panKeyboardSegment = useState(
      panKeyboardSegmentForLength(panController.text.length),
    );

    useEffect(() {
      void syncPanKeyboard() {
        final next = panKeyboardSegmentForLength(panController.text.length);
        if (next != panKeyboardSegment.value) {
          panKeyboardSegment.value = next;
        }
      }

      panController.addListener(syncPanKeyboard);
      return () => panController.removeListener(syncPanKeyboard);
    }, [panController]);

    // Re-attach the input connection when the PAN stage changes so the OS
    // keyboard flips letters <-> numbers and reliably reopens, instead of
    // being dismissed by a widget-key rebuild. Text/caret live in the
    // controller and survive the focus toggle.
    final lastPanSeg = useRef(panKeyboardSegment.value);
    useEffect(() {
      if (panKeyboardSegment.value == lastPanSeg.value) return null;
      lastPanSeg.value = panKeyboardSegment.value;
      if (!panFocus.hasFocus) return null;
      panFocus.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        panFocus.requestFocus();
      });
      return null;
    }, [panKeyboardSegment.value]);

    Future<void> handleContinue() async {
      final pan = panController.text.trim().toUpperCase();
      final aadhaar = aadhaarController.text.replaceAll(RegExp(r'\s+'), '');

      if (!isValidPanFormat(pan)) {
        AppSnackbar.show('Please enter a valid PAN number.');
        return;
      }
      if (!isValidAadhaarNumber(aadhaar)) {
        AppSnackbar.show('Please enter a valid 12 digit Aadhaar number.');
        return;
      }

      final message = await ref
          .read(authControllerProvider.notifier)
          .verifyAccountRecoveryKyc(
            panNo: pan,
            aadhaar: aadhaar,
          );
      if (message == null) {
        final latestState = ref.read(authControllerProvider);
        AppSnackbar.show(
          latestState.errorMessage ?? 'Something went wrong. Please try again.',
        );
        return;
      }

      await KDialog.instance.openDialog(
        barrierDismissible: false,
        dialog: _TemporaryBlockSuccessDialog(
          onContinue: () async {
            navigatorKey.currentState?.pop();
            await ref.read(authControllerProvider.notifier).logout();
            navigatorKey.currentContext?.go(RouteConstants.login);
          },
        ),
      );
    }

    // GreyTextFormField defaults to 48.h, which shrinks to ~33px on short
    // phones; size it from the screen width instead.
    final fieldHeight = authWidthFraction(context, 48 / 360, min: 44, max: 64);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Complete Identity Verification',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        centerTitle: true,
      ),
      // Scaffold leaves bottomNavigationBar behind the keyboard, so the CTA is
      // lifted by the keyboard height like the other auth screens.
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16.w,
            0.h,
            16.w,
            18.h + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: AuthButtonTheme(
            child: CustomElevatedButton(
              onPressed: authState.isSubmitting ? null : handleContinue,
              label:
                  authState.isSubmitting ? 'Verifying...' : 'Verify & Continue',
              uppercaseLabel: false,
              height: authButtonHeight(context, fraction: 42 / 360),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              FileConstants.resetPinIcon,
              height: authWidthFraction(context, 72 / 360, min: 52, max: 104),
              fit: BoxFit.contain,
            ),
            SizedBox(height: 18.h),
            Text(
              'Complete Identity Verification',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Verify your PAN and Aadhaar details to reactivate your account and continue using our services securely.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.72),
                    height: 1.45,
                  ),
            ),
            SizedBox(height: 18.h),
            Text(
              'PAN Number',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: 6.h),
            GreyTextFormField(
              controller: panController,
              focusNode: panFocus,
              enabled: true,
              autofocus: true,
              blockCopy: true,
              height: fieldHeight,
              hintText: 'ABCDE1234F',
              centerText: false,
              keyboardType: panKeyboardSegment.value == 1
                  ? TextInputType.number
                  : TextInputType.text,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => aadhaarFocus.requestFocus(),
              inputFormatters: const [PanInputFormatter()],
            ),
            SizedBox(height: 14.h),
            Text(
              'Aadhaar Number',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: 6.h),
            GreyTextFormField(
              controller: aadhaarController,
              focusNode: aadhaarFocus,
              enabled: true,
              blockCopy: true,
              height: fieldHeight,
              hintText: '1234 5678 9012',
              isNumber: true,
              centerText: false,
              maxLength: 14,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                aadhaarFocus.unfocus();
                if (!authState.isSubmitting) handleContinue();
              },
              inputFormatters: const [
                AadhaarInputFormatter(),
              ],
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6F2),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 18.r,
                    color: const Color(0xFFE85A2C),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Your information is encrypted and securely processed for verification purposes only.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                AppColors.textPrimary.withValues(alpha: 0.68),
                            height: 1.4,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemporaryBlockSuccessDialog extends StatelessWidget {
  const _TemporaryBlockSuccessDialog({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 22.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64.r,
              height: 64.r,
              decoration: const BoxDecoration(
                color: Color(0xFF1B8E36),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: Colors.white, size: 34.r),
            ),
            SizedBox(height: 14.h),
            Text(
              'Account Verification Successful',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Your PAN and Aadhaar details have been successfully verified. Your account has been reactivated, and you can now securely access all services.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.72),
                    height: 1.45,
                  ),
            ),
            SizedBox(height: 18.h),
            AuthButtonTheme(
              child: CustomElevatedButton(
                onPressed: onContinue,
                label: 'Continue to Login',
                showArrow: false,
                height: authButtonHeight(context, fraction: 40 / 360),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
