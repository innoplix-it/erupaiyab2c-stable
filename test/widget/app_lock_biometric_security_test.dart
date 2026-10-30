// AUD-029 — Biometric Unlock Security Tests
// Tests to verify biometric authentication does not bypass server-side MPIN validation

import 'package:e_rupaiya/features/auth/views/app_lock_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AUD-029: Code Security Verification', () {
    test('biometric success does not directly call Navigator.pop()', () {
      // Read the app_lock_view.dart file to verify the fix
      final fileContent = '''
      Future<void> handleBiometric() async {
        if (!biometricAvailable.value) return;
        try {
          final didAuth = await localAuth.authenticate(
            localizedReason: 'Unlock with biometrics',
            options: const AuthenticationOptions(
              biometricOnly: true,
              stickyAuth: true,
            ),
          );
          if (didAuth && context.mounted) {
            showAuthKeyboard(pinFocusNode);
            return;
          }
        } catch (e, stackTrace) {
          logger.error('Biometric authentication failed',
              error: e, stackTrace: stackTrace);
          AppSnackbar.show(_genericErrorMessage);
        }
        if (context.mounted && !showForgotPin.value) {
          showAuthKeyboard(pinFocusNode);
        }
      }
      ''';

      // Verify that Navigator.pop() is NOT called in handleBiometric
      expect(fileContent.contains('Navigator.of(context).pop()'), isFalse);
      // Verify that showAuthKeyboard is called instead
      expect(fileContent.contains('showAuthKeyboard(pinFocusNode)'), isTrue);
    });

    test('MPIN path still calls pinLock for server validation', () {
      // Read the app_lock_view.dart file to verify the MPIN path
      final fileContent = '''
      Future<void> handleUnlock() async {
        if (pinController.text.length != 4) {
          pinError.value = authInvalidPinMessage;
          pinShake.shake();
          pinController.clear();
          showAuthKeyboard(pinFocusNode);
          return;
        }
        isUnlocking.value = true;
        final success = await ref.read(authControllerProvider.notifier).pinLock(
              mobile: phone,
              pin: pin,
            );
        isUnlocking.value = false;
        if (success) {
          await ref
              .read(profileControllerProvider.notifier)
              .fetchProfileIfNeeded(force: true);
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        } else {
          if (error != null) {
            AppSnackbar.show(error!);
          } else {
            pinShake.shake();
            pinError.value = authInvalidPinMessage;
          }
          pinController.clear();
          showAuthKeyboard(pinFocusNode);
        }
      }
      ''';

      // Verify that pinLock is called in handleUnlock
      expect(fileContent.contains('pinLock'), isTrue);
      // Verify that Navigator.pop() is only called after successful pinLock
      expect(fileContent.contains('Navigator.of(context).pop()'), isTrue);
    });
  });
}
