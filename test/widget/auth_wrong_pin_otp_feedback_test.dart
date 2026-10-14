import 'package:e_rupaiya/config/temporary_block_debug_config.dart';
import 'package:e_rupaiya/constants/app_colors.dart';
import 'package:e_rupaiya/constants/app_error_messages.dart';
import 'package:e_rupaiya/constants/routes_constant.dart';
import 'package:e_rupaiya/features/auth/components/auth_code_fields.dart';
import 'package:e_rupaiya/features/auth/components/auth_feedback.dart';
import 'package:e_rupaiya/features/auth/components/auth_step_parts.dart';
import 'package:e_rupaiya/features/auth/controllers/auth_controller.dart';
import 'package:e_rupaiya/features/auth/models/auth_flow.dart';
import 'package:e_rupaiya/features/auth/models/auth_login_result.dart';
import 'package:e_rupaiya/features/auth/models/auth_state.dart';
import 'package:e_rupaiya/features/auth/models/otp_verification_args.dart';
import 'package:e_rupaiya/features/auth/repositories/auth_repository.dart';
import 'package:e_rupaiya/features/auth/views/app_lock_view.dart';
import 'package:e_rupaiya/features/auth/views/login_view.dart';
import 'package:e_rupaiya/features/auth/views/otp_verification_view.dart';
import 'package:e_rupaiya/features/auth/views/reset_mpin_view.dart';
import 'package:e_rupaiya/features/profile/controllers/profile_controller.dart';
import 'package:e_rupaiya/features/profile/repositories/profile_repository.dart';
import 'package:e_rupaiya/widgets/custom_elevated_button.dart';
import 'package:e_rupaiya/widgets/k_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// ignore: depend_on_referenced_packages
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pinput/pinput.dart';

import '../helpers/responsive_test_sizes.dart';

const _secureStorage =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
const _appLinks = MethodChannel('com.llfbandit.app_links/messages');
const _appLinksEvents = EventChannel('com.llfbandit.app_links/events');
const _phoneHint = MethodChannel('com.innoplix.erupaiya/phone_hint');
const _sms = MethodChannel('sms_autofill');

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _FakeProfileController extends ProfileController {
  _FakeProfileController() : super(repository: _MockProfileRepository());

  @override
  Future<void> fetchProfileIfNeeded({
    Duration ttl = const Duration(minutes: 1),
    bool force = false,
  }) async {}
}

/// Every check fails with [failureMessage] until [accept] is set.
class _FakeAuth extends AuthController {
  _FakeAuth()
      : super(repository: _MockAuthRepository(), shouldCheckInitialAuth: false) {
    state = const AuthState(
      isAuthenticated: false,
      hasTemporaryAccess: false,
      isLoading: false,
      isSubmitting: false,
    );
  }

  bool accept = false;
  String failureMessage = 'Invalid credentials';
  final attempts = <String>[];

  void _fail() => state = state.copyWith(errorMessage: failureMessage);

  @override
  Future<AuthFlow?> checkLogin({required String mobile}) async =>
      AuthFlow.login;

  @override
  Future<AuthLoginResult> login({
    required String mobile,
    required String pin,
  }) async {
    attempts.add(pin);
    if (accept) return const AuthLoginResult.success();
    return AuthLoginResult.failure(message: failureMessage);
  }

  @override
  Future<bool> pinLock({required String mobile, required String pin}) async {
    attempts.add(pin);
    if (!accept) _fail();
    return accept;
  }

  @override
  Future<bool> verifyOtp({required String otp, String? mobile}) async {
    attempts.add(otp);
    if (!accept) _fail();
    return accept;
  }

  @override
  Future<String?> sendDeviceOtp({required String verificationId}) async =>
      'OTP sent';

  @override
  Future<String?> verifyDeviceOtp({
    required String verificationId,
    required String mobileOtp,
    required String emailOtp,
  }) async {
    attempts.add('$mobileOtp/$emailOtp');
    if (accept) return 'Device verified';
    _fail();
    return null;
  }

  @override
  Future<String?> requestForgotPinOtp({String? mobile}) async => 'OTP sent';

  @override
  Future<String?> forgotPin({
    required String otp,
    required String pin,
    String? mobile,
  }) async {
    attempts.add(otp);
    if (accept) return 'MPIN reset successfully';
    _fail();
    return null;
  }
}

class _NoBiometrics extends LocalAuthPlatform {
  @override
  Future<bool> deviceSupportsBiometrics() async => false;

  @override
  Future<bool> isDeviceSupported() async => false;

  @override
  Future<List<BiometricType>> getEnrolledBiometrics() async => const [];
}

void _mockPlatform() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(_secureStorage, (call) async {
    if (call.method == 'read' &&
        (call.arguments as Map?)?['key'] == 'mobile') {
      return '9876543210';
    }
    return null;
  });
  messenger.setMockMethodCallHandler(_appLinks, (_) async => null);
  messenger.setMockStreamHandler(
    _appLinksEvents,
    MockStreamHandler.inline(onListen: (_, __) {}),
  );
  messenger.setMockMethodCallHandler(_phoneHint, (_) async => null);
  messenger.setMockMethodCallHandler(_sms, (call) async {
    if (call.method == 'getAppSignature') return 'sig';
    return null;
  });
}

void _clearPlatform() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final channel in [_secureStorage, _appLinks, _phoneHint, _sms]) {
    messenger.setMockMethodCallHandler(channel, null);
  }
  messenger.setMockStreamHandler(_appLinksEvents, null);
}

enum _Screen { loginPin, verifyOtp, resetMpin, appLock }

const _start = '/start';
const _target = '/target';

late GoRouter _router;

/// Top of the stack; `uri` stays on the base location after a push.
String _location() =>
    _router.routerDelegate.currentConfiguration.last.matchedLocation;

const _deviceOtpArgs = OtpVerificationArgs(
  phoneNumber: '9876543210',
  title: 'Verify Your Identity',
  heading: 'Verify Your Identity',
  primaryButtonLabel: 'Verify & Continue',
  successDialogTitle: 'Device Verified',
  successDialogMessage: 'This device has been verified.',
  successButtonLabel: 'Continue to Login',
  successRoute: RouteConstants.login,
  successRouteUseGo: true,
  deviceVerificationId: 'device-test',
  temporaryBlockFlowType: TemporaryBlockFlowType.deviceVerification,
);

Future<_FakeAuth> _pump(
  WidgetTester tester,
  _Screen screen, {
  Size size = const Size(390, 844),
  Widget? viewOverride,
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = size * 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final auth = _FakeAuth();
  final Widget view = viewOverride ??
      switch (screen) {
    _Screen.loginPin => const LoginView(),
    _Screen.verifyOtp => const OtpVerificationView(
        args: OtpVerificationArgs(phoneNumber: '9876543210'),
      ),
    _Screen.resetMpin => const ResetMpinView(mobile: '9876543210'),
    _Screen.appLock => const AppLockView(),
  };
  // Views that pop on success are pushed over a start page.
  final pushed = screen == _Screen.resetMpin || screen == _Screen.appLock;
  final router = _router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: pushed ? _start : _target,
    routes: [
      GoRoute(
        path: _start,
        builder: (_, __) => const Scaffold(body: Text('start page')),
      ),
      GoRoute(path: _target, builder: (_, __) => view),
      GoRoute(
        path: RouteConstants.home,
        builder: (_, __) => const Scaffold(body: Text('home page')),
      ),
      GoRoute(
        path: RouteConstants.otpSuccess,
        builder: (_, __) => const Scaffold(body: Text('otp success page')),
      ),
      GoRoute(
        path: RouteConstants.login,
        builder: (_, __) => const Scaffold(body: Text('login page')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith((ref) => auth),
        profileControllerProvider
            .overrideWith((ref) => _FakeProfileController()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        fontSizeResolver: FontSizeResolvers.radius,
        builder: (_, __) => MaterialApp.router(routerConfig: router),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  if (pushed) {
    router.push(_target);
    await _settle(tester);
  }
  if (screen == _Screen.loginPin) {
    await tester.enterText(
      find.descendant(
        of: find.byType(AuthMobileField),
        matching: find.byType(EditableText),
      ),
      '9876543210',
    );
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.byType(CustomElevatedButton));
    await _settle(tester);
  }
  return auth;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Lets the snackbar and any page timers finish, then disposes the tree.
Future<void> _finish(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

Finder _codeField(int index) => find.descendant(
      of: find.byType(Pinput).at(index),
      matching: find.byType(EditableText),
    );

/// Enters a full code and lets the async check complete, stopping at the
/// first frame of any shake. OTP screens keep a rejected code in the boxes,
/// so each [attempt] types a different one.
Future<void> _submit(
  WidgetTester tester,
  _Screen screen, {
  int attempt = 0,
}) async {
  switch (screen) {
    case _Screen.loginPin:
    case _Screen.appLock:
      await tester.enterText(_codeField(0), '123$attempt');
    case _Screen.verifyOtp:
      await tester.enterText(_codeField(0), '12345$attempt');
    case _Screen.resetMpin:
      await tester.enterText(_codeField(0), '12345$attempt');
      await tester.enterText(_codeField(1), '111$attempt');
      await tester.enterText(_codeField(2), '111$attempt');
  }
  await tester.pump();
  await tester.pump();
}

String _messageFor(_Screen screen) => switch (screen) {
      _Screen.loginPin || _Screen.appLock => authInvalidPinMessage,
      _Screen.verifyOtp || _Screen.resetMpin => authInvalidOtpMessage,
    };

AuthShakeController _shake(WidgetTester tester) =>
    tester.widget<AuthShake>(find.byType(AuthShake).first).controller;

double _shakeOffset(WidgetTester tester) => tester
    .widget<Transform>(
      find
          .descendant(
            of: find.byType(AuthShake).first,
            matching: find.byType(Transform),
          )
          .first,
    )
    .transform
    .getTranslation()
    .x;

/// The message sits once, in red, inside the row under the boxes and
/// between that row's two ends.
void _expectInlineMessage(WidgetTester tester, _Screen screen) {
  final text = _messageFor(screen);
  expect(find.text(text), findsOneWidget, reason: 'no snackbar copy');
  final isPin = screen == _Screen.loginPin || screen == _Screen.appLock;
  final row = isPin
      ? find.byType(AuthPinActionsRow)
      : find.byType(AuthOtpTimerRow).first;
  final message = find.descendant(of: row, matching: find.text(text));
  expect(message, findsOneWidget);
  expect(tester.widget<Text>(message).style!.color, AppColors.red);

  final messageRect = tester.getRect(message);
  final Rect start;
  final Rect end;
  if (isPin) {
    start = tester.getRect(
      find.descendant(of: row, matching: find.byType(AuthVisibilityToggle)),
    );
    end = tester.getRect(
      find.descendant(of: row, matching: find.text('Forget PIN')),
    );
  } else {
    start = tester.getRect(
      find.descendant(of: row, matching: find.byType(SvgPicture)).first,
    );
    end = tester.getRect(find.descendant(of: row, matching: find.text('Resend')));
  }
  expect(messageRect.left, greaterThanOrEqualTo(start.right - 0.5));
  expect(messageRect.right, lessThanOrEqualTo(end.left + 0.5));
  final boxes = tester.getRect(find.byType(Pinput).first);
  expect(messageRect.top, greaterThanOrEqualTo(boxes.bottom - 0.5));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _mockPlatform();
    LocalAuthPlatform.instance = _NoBiometrics();
  });
  tearDown(_clearPlatform);

  for (final screen in _Screen.values) {
    group('${screen.name}:', () {
      testWidgets('wrong code jiggles the boxes and shows the red message',
          (tester) async {
        final auth = await _pump(tester, screen);
        expect(_shake(tester).playCount, 0);

        await _submit(tester, screen);
        expect(auth.attempts, hasLength(1));
        expect(_shake(tester).playCount, 1);

        await tester.pump(const Duration(milliseconds: 60));
        expect(_shakeOffset(tester).abs(), greaterThan(0.5));
        await tester.pump(const Duration(milliseconds: 500));
        expect(_shakeOffset(tester), 0);

        _expectInlineMessage(tester, screen);
        await _finish(tester);
      });

      testWidgets('wrong code keeps the same screen open', (tester) async {
        final auth = await _pump(tester, screen);
        final view = find.byType(switch (screen) {
          _Screen.loginPin => LoginView,
          _Screen.verifyOtp => OtpVerificationView,
          _Screen.resetMpin => ResetMpinView,
          _Screen.appLock => AppLockView,
        });

        for (var attempt = 0; attempt < 2; attempt++) {
          await _submit(tester, screen, attempt: attempt);
          await _settle(tester);
          await tester.pump(const Duration(seconds: 1));
          expect(_location(), _target);
          expect(view, findsOneWidget);
          for (final page in [
            'start page',
            'home page',
            'otp success page',
            'login page',
          ]) {
            expect(find.text(page), findsNothing);
          }
          expect(find.text(_messageFor(screen)), findsOneWidget);
        }
        expect(auth.attempts, hasLength(2));
        await _finish(tester);
      });

      // App lock has its own isUnlocking guard.
      if (screen != _Screen.appLock) {
        testWidgets('a code submitted while a check is running is ignored',
            (tester) async {
          final auth = await _pump(tester, screen);
          auth.state = auth.state.copyWith(isSubmitting: true);
          await _submit(tester, screen);
          await tester.pump(const Duration(milliseconds: 600));
          expect(auth.attempts, isEmpty);
          expect(_shake(tester).playCount, 0);
          expect(_location(), _target);
          auth.state = auth.state.copyWith(isSubmitting: false);
          await _finish(tester);
        });
      }

      testWidgets('typing never triggers the feedback', (tester) async {
        await _pump(tester, screen);
        await tester.enterText(_codeField(0), '12');
        await tester.pump(const Duration(milliseconds: 500));
        expect(_shake(tester).playCount, 0);
        expect(find.text(_messageFor(screen)), findsNothing);
        await _finish(tester);
      });

      testWidgets('a correct code continues without any feedback',
          (tester) async {
        final auth = await _pump(tester, screen)..accept = true;
        final shake = _shake(tester);
        await _submit(tester, screen);
        await _settle(tester);
        expect(auth.attempts, hasLength(1));
        expect(shake.playCount, 0);
        expect(find.text(_messageFor(screen)), findsNothing);
        final destination = switch (screen) {
          _Screen.loginPin => 'home page',
          _Screen.verifyOtp => 'otp success page',
          _Screen.resetMpin || _Screen.appLock => 'start page',
        };
        expect(find.text(destination), findsOneWidget);
        await _finish(tester);
      });

      testWidgets('repeated failures shake each time with one message',
          (tester) async {
        final auth = await _pump(tester, screen);
        await _submit(tester, screen);
        await tester.pump(const Duration(milliseconds: 600));
        _expectInlineMessage(tester, screen);

        await _submit(tester, screen, attempt: 1);
        await tester.pump(const Duration(milliseconds: 600));
        expect(auth.attempts, hasLength(2));
        expect(_shake(tester).playCount, 2);
        _expectInlineMessage(tester, screen);

        await _submit(tester, screen, attempt: 2);
        await tester.pump(const Duration(milliseconds: 600));
        expect(_shake(tester).playCount, 3);
        _expectInlineMessage(tester, screen);
        await _finish(tester);
      });

      testWidgets('typing a new code clears the message', (tester) async {
        await _pump(tester, screen);
        await _submit(tester, screen);
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.text(_messageFor(screen)), findsOneWidget);

        await tester.enterText(_codeField(0), '9');
        await tester.pump();
        expect(find.text(_messageFor(screen)), findsNothing);
        await _finish(tester);
      });

      testWidgets('connection errors keep their message and do not shake',
          (tester) async {
        final auth = await _pump(tester, screen)
          ..failureMessage = AppErrorMessages.network;
        await _submit(tester, screen);
        await tester.pump(const Duration(milliseconds: 600));
        expect(_shake(tester).playCount, 0);
        expect(find.text(_messageFor(screen)), findsNothing);
        expect(find.text(AppErrorMessages.network), findsWidgets);
        expect(auth.attempts, hasLength(1));
        await _finish(tester);
      });
    });
  }

  group('new-device verification OTP', () {
    Future<_FakeAuth> pumpDevice(WidgetTester tester) => _pump(
          tester,
          _Screen.verifyOtp,
          viewOverride: const OtpVerificationView(args: _deviceOtpArgs),
        );

    Future<void> submitBoth(WidgetTester tester, {int attempt = 0}) async {
      await tester.enterText(_codeField(0), '11122$attempt');
      await tester.enterText(_codeField(1), '33344$attempt');
      await tester.pump();
      await tester.tap(find.byType(CustomElevatedButton));
      await _settle(tester);
    }

    testWidgets('wrong OTP stays on the screen with shake and inline error',
        (tester) async {
      final auth = await pumpDevice(tester);
      await submitBoth(tester);
      await tester.pump(const Duration(seconds: 1));

      // One shake() jiggles both the mobile and the email boxes, and each
      // box's AuthShake counts its own run.
      final boxes = find.byType(AuthShake).evaluate().length;
      expect(boxes, 2);
      expect(auth.attempts, ['111220/333440']);
      expect(_shake(tester).playCount, boxes);
      expect(_location(), _target);
      expect(find.byType(OtpVerificationView), findsOneWidget);
      expect(find.text('login page'), findsNothing);
      expect(find.text(authInvalidOtpMessage), findsWidgets);
      expect(find.text('Verification failed. Please login again.'),
          findsNothing);

      await submitBoth(tester, attempt: 1);
      await tester.pump(const Duration(seconds: 1));
      expect(auth.attempts, hasLength(2));
      expect(_shake(tester).playCount, boxes * 2);
      expect(_location(), _target);
      await _finish(tester);
    });

    testWidgets('connection error keeps its message without shaking',
        (tester) async {
      final auth = await pumpDevice(tester)
        ..failureMessage = AppErrorMessages.network;
      await submitBoth(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(auth.attempts, hasLength(1));
      expect(_shake(tester).playCount, 0);
      expect(find.text(AppErrorMessages.network), findsWidgets);
      expect(_location(), _target);
      await _finish(tester);
    });

    testWidgets('correct OTP still shows the success dialog and goes to login',
        (tester) async {
      final auth = await pumpDevice(tester)..accept = true;
      await submitBoth(tester);
      expect(auth.attempts, hasLength(1));
      expect(_shake(tester).playCount, 0);
      expect(find.text('Device Verified'), findsOneWidget);

      // The dialog sits above the screen, so its button is the last one.
      await tester.tap(find.byType(CustomElevatedButton).last);
      await _settle(tester);
      await _settle(tester);
      expect(_location(), RouteConstants.login);
      expect(find.text('login page'), findsOneWidget);
      await _finish(tester);
    });
  });

  for (final screen in const [_Screen.loginPin, _Screen.verifyOtp]) {
    group('${screen.name} wrong-code feedback across shared sizes', () {
      for (final size in responsiveTestScreenSizes) {
        testWidgets('${size.width}x${size.height}', (tester) async {
          await _pump(tester, screen, size: size);
          await _submit(tester, screen);
          await tester.pump(const Duration(milliseconds: 60));
          expect(tester.takeException(), isNull);
          expect(_shake(tester).playCount, 1);

          // MediaQuery-based amplitude, bounded so boxes stay on screen.
          final maxShift = (size.width * 8 / 360).clamp(6.0, 12.0);
          expect(_shakeOffset(tester).abs(), lessThanOrEqualTo(maxShift));
          final boxes = find.descendant(
            of: find.byType(Pinput).first,
            matching: find.byType(AnimatedContainer),
          );
          expect(tester.getRect(boxes.first).left, greaterThanOrEqualTo(0));
          expect(
            tester.getRect(boxes.last).right,
            lessThanOrEqualTo(size.width),
          );
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);
          _expectInlineMessage(tester, screen);
          final message = tester.getRect(find.text(_messageFor(screen)));
          expect(message.left, greaterThanOrEqualTo(0));
          expect(message.right, lessThanOrEqualTo(size.width));
          await _finish(tester);
        });
      }
    });
  }

  group('AuthShake', () {
    Future<AuthShakeController> pumpShake(
      WidgetTester tester, {
      bool disableAnimations = false,
    }) async {
      final controller = AuthShakeController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(360, 690),
              disableAnimations: disableAnimations,
            ),
            child: AuthShake(
              controller: controller,
              child: const SizedBox(width: 100, height: 40),
            ),
          ),
        ),
      );
      return controller;
    }

    testWidgets('a shake requested mid-shake does not overlap',
        (tester) async {
      final controller = await pumpShake(tester);
      controller.shake();
      await tester.pump(const Duration(milliseconds: 100));
      controller.shake();
      controller.shake();
      await tester.pump(const Duration(milliseconds: 100));
      expect(controller.playCount, 1);

      await tester.pump(const Duration(milliseconds: 400));
      expect(_shakeOffset(tester), 0);
      controller.shake();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(controller.playCount, 2);
      expect(_shakeOffset(tester).abs(), greaterThan(0.5));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('reduced motion skips the movement', (tester) async {
      final controller = await pumpShake(tester, disableAnimations: true);
      controller.shake();
      await tester.pump(const Duration(milliseconds: 60));
      expect(controller.playCount, 1);
      expect(_shakeOffset(tester), 0);
    });
  });
}
