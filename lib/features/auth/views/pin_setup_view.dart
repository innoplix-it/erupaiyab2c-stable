// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pinput/pinput.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/file_constants.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/blocking_loading_overlay.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../controllers/auth_controller.dart';

class PinSetupView extends HookConsumerWidget {
  const PinSetupView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final newPinController = useTextEditingController();
    final confirmPinController = useTextEditingController();
    final newPinFocus = useFocusNode();
    final confirmPinFocus = useFocusNode();
    final errorText = useState<String?>(null);

    useEffect(() {
      return () {
        newPinController.dispose();
        confirmPinController.dispose();
        newPinFocus.dispose();
        confirmPinFocus.dispose();
      };
    }, const []);

    Future<void> handleSubmit() async {
      final newPin = newPinController.text.trim();
      final confirmPin = confirmPinController.text.trim();
      if (newPin.length != 4 || confirmPin.length != 4) {
        errorText.value = 'Please enter a valid 4-digit MPIN.';
        return;
      }
      if (newPin != confirmPin) {
        errorText.value = 'MPIN does not match.';
        return;
      }
      errorText.value = null;
      final message =
          await ref.read(authControllerProvider.notifier).setPin(pin: newPin);
      if (message != null) {
        AppSnackbar.show(message);
        if (context.mounted) {
          context.go(RouteConstants.login);
        }
      } else {
        final latestState = ref.read(authControllerProvider);
        AppSnackbar.show(
          latestState.errorMessage ?? 'Failed to set PIN. Please try again.',
        );
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: BlockingLoadingOverlay(
        isLoading: authState.isSubmitting,
        message: 'Setting your MPIN...',
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(8.w, 6.h, 16.w, 0.h),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: AppColors.textPrimary,
                      onPressed: () => context.pop(),
                    ),
                    const Spacer(),
                    Image.asset(
                      FileConstants.bharatConnectColor,
                      height: 18.h,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(width: 6.w),
                    IconButton(
                      icon: const Icon(Icons.help_outline),
                      color: AppColors.textPrimary,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16.w, 0.h, 16.w, 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create MPIN',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Set a 4-digit MPIN to secure your E-Rupaiya wallet.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary.withOpacity(0.7),
                              height: 1.4,
                            ),
                      ),
                      SizedBox(height: 18.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: const Color(0xFFD6D6D6)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add New PIN',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            SizedBox(height: 10.h),
                            Pinput(
                              controller: newPinController,
                              focusNode: newPinFocus,
                              length: 4,
                              obscureText: true,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              autofocus: true,
                              onChanged: (_) => errorText.value = null,
                              onCompleted: (_) =>
                                  confirmPinFocus.requestFocus(),
                              defaultPinTheme: PinTheme(
                                width: 52.w,
                                height: 52.w,
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: const Color(0xFFD6D6D6),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'Re-enter your MPIN to confirm.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            SizedBox(height: 10.h),
                            Pinput(
                              controller: confirmPinController,
                              focusNode: confirmPinFocus,
                              length: 4,
                              obscureText: true,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              onChanged: (_) => errorText.value = null,
                              onCompleted: (_) => handleSubmit(),
                              defaultPinTheme: PinTheme(
                                width: 52.w,
                                height: 52.w,
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: const Color(0xFFD6D6D6),
                                  ),
                                ),
                              ),
                            ),
                            if (errorText.value != null &&
                                errorText.value!.isNotEmpty) ...[
                              SizedBox(height: 10.h),
                              Text(
                                errorText.value!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      CustomElevatedButton(
                        onPressed: authState.isSubmitting ? null : handleSubmit,
                        label: 'Confirm',
                        uppercaseLabel: false,
                        showArrow: false,
                        height: 44.h,
                      ),
                      SizedBox(height: 8.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
