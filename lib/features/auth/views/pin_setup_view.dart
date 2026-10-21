import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/routes_constant.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/blocking_loading_overlay.dart';
import '../components/auth_mpin_setup_step.dart';
import '../components/auth_mpin_success_step.dart';
import '../controllers/auth_controller.dart';

const Duration _successDisplayDuration = Duration(seconds: 2);

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
    final mpinCreated = useState(false);

    useEffect(() {
      if (!mpinCreated.value) return null;
      final timer = Timer(_successDisplayDuration, () {
        if (context.mounted) context.go(RouteConstants.login);
      });
      return timer.cancel;
    }, [mpinCreated.value]);

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
        // The success screen replaces the old toast, then redirects to login.
        mpinCreated.value = true;
      } else {
        final latestState = ref.read(authControllerProvider);
        AppSnackbar.show(
          latestState.errorMessage ?? 'Failed to set PIN. Please try again.',
        );
      }
    }

    if (mpinCreated.value) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: AuthMpinSuccessStep(
          onBack: () => context.go(RouteConstants.login),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.loginPeachCoral,
      body: BlockingLoadingOverlay(
        isLoading: authState.isSubmitting,
        message: 'Setting your MPIN...',
        child: AuthMpinSetupStep(
          newPinController: newPinController,
          confirmPinController: confirmPinController,
          newPinFocusNode: newPinFocus,
          confirmPinFocusNode: confirmPinFocus,
          errorText: errorText.value,
          isSubmitting: authState.isSubmitting,
          onPinChanged: (_) => errorText.value = null,
          onNewPinCompleted: (_) => confirmPinFocus.requestFocus(),
          onConfirmPinCompleted: (_) => handleSubmit(),
          onSubmit: handleSubmit,
          // Reached through context.go after OTP success, so there may be
          // nothing to pop.
          onBack: () => context.canPop()
              ? context.pop()
              : context.go(RouteConstants.login),
        ),
      ),
    );
  }
}
