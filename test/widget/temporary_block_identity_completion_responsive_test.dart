// Responsive coverage for TemporaryBlockIdentityCompletionView and its
// success dialog.
//
// Uses the canonical `responsiveTestScreenSizes` matrix from
// test/helpers/responsive_test_sizes.dart - the device list is never
// duplicated here. No Figma reference exists for this screen, so these tests
// check layout safety and the existing validation wiring only.

import 'package:e_rupaiya/features/auth/controllers/auth_controller.dart';
import 'package:e_rupaiya/features/auth/models/auth_state.dart';
import 'package:e_rupaiya/features/auth/repositories/auth_repository.dart';
import 'package:e_rupaiya/features/auth/views/temporary_block_identity_completion_view.dart';
import 'package:e_rupaiya/features/profile/controllers/profile_controller.dart';
import 'package:e_rupaiya/features/profile/repositories/profile_repository.dart';
import 'package:e_rupaiya/widgets/custom_elevated_button.dart';
import 'package:e_rupaiya/widgets/grey_text_form_field.dart';
import 'package:e_rupaiya/widgets/k_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/responsive_test_sizes.dart';

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
    kycCalls.add((panNo, aadhaar));
    return 'verified';
  }
}

Future<_FakeAuthController> _pumpView(
  WidgetTester tester, {
  Size size = const Size(360, 690),
  double textScale = 1.0,
  double keyboardInset = 0,
  EdgeInsets padding = EdgeInsets.zero,
}) async {
  const dpr = 2.0;
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = size * dpr;
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
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              padding: padding,
              viewPadding: padding,
              viewInsets: EdgeInsets.only(bottom: keyboardInset),
            ),
            child: child!,
          ),
          home: const TemporaryBlockIdentityCompletionView(),
        ),
      ),
    ),
  );
  await tester.pump();
  return controller;
}

Finder get _fields => find.byType(GreyTextFormField);

Finder get _verify => find.descendant(
      of: find.byType(Scaffold),
      matching: find.byType(CustomElevatedButton),
    );

Future<void> _submitValidDetails(WidgetTester tester) async {
  await tester.enterText(
    find.descendant(of: _fields.at(0), matching: find.byType(EditableText)),
    'abcde1234f',
  );
  await tester.enterText(
    find.descendant(of: _fields.at(1), matching: find.byType(EditableText)),
    '123412341234',
  );
  await tester.pump();
  await tester.tap(_verify.first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Identity completion renders without overflow across shared sizes', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpView(tester, size: size);
        expect(tester.takeException(), isNull);

        final fieldHeight = (size.width * 48 / 360).clamp(44.0, 64.0);
        for (var i = 0; i < 2; i++) {
          final field = tester.getRect(_fields.at(i));
          expect(field.left, greaterThanOrEqualTo(0));
          expect(field.right, lessThanOrEqualTo(size.width));
          expect(field.height, closeTo(fieldHeight, 0.01));
        }

        final button = tester.getRect(_verify);
        expect(button.left, greaterThanOrEqualTo(0));
        expect(button.right, lessThanOrEqualTo(size.width));
        expect(button.bottom, lessThanOrEqualTo(size.height));
        expect(
          button.height,
          closeTo((size.width * 42 / 360).clamp(40.0, 56.0), 0.01),
        );
      });
    }
  });

  group('Identity completion with the keyboard open', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        final inset = size.height * 0.4;
        await _pumpView(tester, size: size, keyboardInset: inset);
        expect(tester.takeException(), isNull);
        expect(tester.getRect(_verify).bottom,
            lessThanOrEqualTo(size.height - inset));
        // Both inputs can still be scrolled above the keyboard.
        for (var i = 0; i < 2; i++) {
          await tester.ensureVisible(_fields.at(i));
          await tester.pump();
          expect(tester.getRect(_fields.at(i)).bottom,
              lessThanOrEqualTo(size.height - inset));
        }
      });
    }
  });

  group('Identity completion respects safe-area insets', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpView(
          tester,
          size: size,
          padding: const EdgeInsets.only(top: 47, bottom: 34),
        );
        expect(tester.takeException(), isNull);
        expect(tester.getRect(find.byIcon(Icons.arrow_back)).top,
            greaterThanOrEqualTo(47));
        expect(tester.getRect(_verify).bottom,
            lessThanOrEqualTo(size.height - 34));
      });
    }
  });

  group('Identity completion supported text scales', () {
    for (final scale in const [0.85, 1.15]) {
      for (final size in responsiveTestScreenSizes) {
        testWidgets('${size.width}x${size.height} @${scale}x', (tester) async {
          await _pumpView(tester, size: size, textScale: scale);
          expect(tester.takeException(), isNull);
          expect(
              tester.getRect(_verify).bottom, lessThanOrEqualTo(size.height));
        });
      }
    }
  });

  testWidgets('opens with the PAN field focused and the keyboard visible',
      (tester) async {
    await _pumpView(tester);
    final pan = tester.widget<EditableText>(
      find.descendant(of: _fields.at(0), matching: find.byType(EditableText)),
    );
    expect(pan.focusNode.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('an invalid PAN never reaches the API', (tester) async {
    final controller = await _pumpView(tester);
    await tester.enterText(
      find.descendant(of: _fields.at(0), matching: find.byType(EditableText)),
      'ABC',
    );
    await tester.tap(_verify);
    await tester.pump();
    expect(controller.kycCalls, isEmpty);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('valid details are sent once, normalised as before',
      (tester) async {
    final controller = await _pumpView(tester);
    await _submitValidDetails(tester);
    expect(controller.kycCalls, [('ABCDE1234F', '123412341234')]);
    expect(find.text('Account Verification Successful'), findsOneWidget);
  });

  group('Verification success dialog across shared sizes', () {
    for (final size in responsiveTestScreenSizes) {
      testWidgets('${size.width}x${size.height}', (tester) async {
        await _pumpView(tester, size: size);
        await _submitValidDetails(tester);
        expect(tester.takeException(), isNull);

        final dialog = tester.getRect(find.byType(Dialog));
        expect(dialog.left, greaterThanOrEqualTo(0));
        expect(dialog.right, lessThanOrEqualTo(size.width));
        expect(dialog.top, greaterThanOrEqualTo(0));
        expect(dialog.bottom, lessThanOrEqualTo(size.height));

        final button = find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(CustomElevatedButton),
        );
        expect(tester.getRect(button).bottom, lessThanOrEqualTo(dialog.bottom));
        expect(
          tester.getRect(button).height,
          closeTo((size.width * 40 / 360).clamp(40.0, 56.0), 0.01),
        );
      });
    }
  });
}
