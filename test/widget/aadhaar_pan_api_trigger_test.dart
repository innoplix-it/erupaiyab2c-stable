import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:e_rupaiya/features/auth/controllers/auth_controller.dart';
import 'package:e_rupaiya/features/auth/models/auth_state.dart';
import 'package:e_rupaiya/features/auth/repositories/auth_repository.dart';
import 'package:e_rupaiya/features/auth/views/temporary_block_identity_completion_view.dart';
import 'package:e_rupaiya/features/profile/controllers/profile_controller.dart';
import 'package:e_rupaiya/features/profile/repositories/profile_repository.dart';
import 'package:e_rupaiya/widgets/k_dialog.dart' show navigatorKey;
import 'package:e_rupaiya/widgets/custom_elevated_button.dart';
import 'package:e_rupaiya/widgets/grey_text_form_field.dart';

// ---------------------------------------------------------------------------
// Aadhaar (and paired PAN) API-trigger tests for the account-recovery identity
// screen. This flow verifies PAN + Aadhaar together behind an explicit
// "Verify & Continue" button, so it exercises the Aadhaar trigger conditions:
//   * fewer than 12 digits -> no API call
//   * more than 12 digits  -> blocked by the input formatter
//   * a complete valid Aadhaar + valid PAN -> exactly one API call
// ---------------------------------------------------------------------------

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _FakeAuthController extends AuthController {
  _FakeAuthController()
      : super(
          repository: _MockAuthRepository(),
          shouldCheckInitialAuth: false,
        ) {
    state = const AuthState(
      isAuthenticated: false,
      hasTemporaryAccess: true,
      isLoading: false,
      isSubmitting: false,
    );
  }

  final kycCalls = <(String, String)>[];

  @override
  Future<String?> verifyAccountRecoveryKyc({
    required String panNo,
    required String aadhaar,
  }) async {
    // Mirror the real controller flipping the in-flight flag, which is what
    // disables the submit button and prevents duplicate requests.
    state = state.copyWith(isSubmitting: true);
    kycCalls.add((panNo, aadhaar));
    return 'verified';
  }
}

Future<_FakeAuthController> _pump(WidgetTester tester) async {
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = const Size(390, 844) * 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final controller = _FakeAuthController();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((ref) => controller),
        profileControllerProvider.overrideWith(
          (ref) => ProfileController(repository: _MockProfileRepository()),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        fontSizeResolver: FontSizeResolvers.radius,
        builder: (context, _) => MaterialApp(
          navigatorKey: navigatorKey,
          home: const TemporaryBlockIdentityCompletionView(),
        ),
      ),
    ),
  );
  await tester.pump();
  return controller;
}

Finder _editable(int fieldIndex) => find.descendant(
      of: find.byType(GreyTextFormField).at(fieldIndex),
      matching: find.byType(EditableText),
    );

Finder _verifyButton() => find.descendant(
      of: find.byType(Scaffold),
      matching: find.byType(CustomElevatedButton),
    ).first;

Future<void> _typePan(WidgetTester tester, String pan) =>
    tester.enterText(_editable(0), pan);

Future<void> _typeAadhaar(WidgetTester tester, String aadhaar) =>
    tester.enterText(_editable(1), aadhaar);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('5. Aadhaar with 1-11 digits never calls the verify-kyc API',
      (tester) async {
    final controller = await _pump(tester);
    await _typePan(tester, 'ABCDE1234F');

    for (var len = 1; len <= 11; len++) {
      await _typeAadhaar(tester, '23456789012'.substring(0, len));
      await tester.pump();
      await tester.tap(_verifyButton());
      await tester.pump();
    }

    expect(controller.kycCalls, isEmpty);
    // Let the validation snackbars' timers elapse before the test ends.
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('6. Aadhaar longer than 12 digits is capped by the input rules',
      (tester) async {
    await _pump(tester);
    await _typeAadhaar(tester, '1234567890123456');
    await tester.pump();

    final editable = tester.widget<EditableText>(_editable(1));
    final digits = editable.controller.text.replaceAll(RegExp(r'\D'), '');
    expect(digits.length, 12,
        reason: 'the Aadhaar formatter must never keep more than 12 digits');
  });

  testWidgets('7. A complete valid Aadhaar + PAN calls the API once',
      (tester) async {
    final controller = await _pump(tester);
    await _typePan(tester, 'abcde1234f');
    await _typeAadhaar(tester, '1234 5678 9012');
    await tester.pump();
    await tester.tap(_verifyButton());
    await tester.pump();

    expect(controller.kycCalls, [('ABCDE1234F', '123456789012')]);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('8. Invalid PAN blocks the call even with a valid Aadhaar',
      (tester) async {
    final controller = await _pump(tester);
    await _typePan(tester, '1234567890'); // 10 chars, wrong shape
    await _typeAadhaar(tester, '123456789012');
    await tester.pump();
    await tester.tap(_verifyButton());
    await tester.pump();

    expect(controller.kycCalls, isEmpty);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('9. repeated submits while a request is in flight do not stack up',
      (tester) async {
    final controller = await _pump(tester);
    await _typePan(tester, 'ABCDE1234F');
    await _typeAadhaar(tester, '123456789012');
    await tester.pump();

    // Tap, let the button rebuild into its disabled in-flight state, then try
    // again: only the first request should reach the API.
    await tester.tap(_verifyButton());
    await tester.pump();

    // The submit is now in flight: the button is disabled and the blocking
    // verification dialog is on screen, so further taps cannot stack up a
    // second request.
    expect(find.byType(ModalBarrier), findsWidgets);
    await tester.tap(_verifyButton(), warnIfMissed: false);
    await tester.pump();
    await tester.tap(_verifyButton(), warnIfMissed: false);
    await tester.pump();

    expect(controller.kycCalls, hasLength(1));
    await tester.pump(const Duration(seconds: 5));
  });
}
