import 'package:e_rupaiya/features/auth/components/auth_mobile_step.dart';
import 'package:e_rupaiya/features/auth/components/login_services_slider.dart';
import 'package:e_rupaiya/features/auth/controllers/auth_controller.dart';
import 'package:e_rupaiya/features/auth/repositories/auth_repository.dart';
import 'package:e_rupaiya/features/auth/views/login_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _FakeAuthController extends AuthController {
  _FakeAuthController()
      : super(
          repository: _MockAuthRepository(),
          shouldCheckInitialAuth: false,
        );
}

Widget _wrapLogin({Size size = const Size(360, 690)}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const LoginView(),
      ),
      GoRoute(
        path: '/terms-privacy',
        builder: (_, __) => const Scaffold(body: Text('Terms')),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (_, __) => const Scaffold(body: Text('Privacy')),
      ),
    ],
  );

  // Apply [size] above ScreenUtilInit so .w/.h/.sp match layout constraints.
  // Skip AuthController's 3s initial-auth timeout so FakeTimers don't linger.
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith((ref) => _FakeAuthController()),
    ],
    child: MediaQuery(
      data: MediaQueryData(size: size),
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, __) => MaterialApp.router(
          routerConfig: router,
        ),
      ),
    ),
  );
}

Future<void> _pumpLogin(WidgetTester tester,
    {Size size = const Size(360, 690)}) async {
  await tester.pumpWidget(_wrapLogin(size: size));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoginView Figma mobile step', () {
    testWidgets('shows Welcome to eRupaiya, slider, and Figma mobile field', (
      tester,
    ) async {
      await _pumpLogin(tester);

      expect(find.byType(AuthMobileStep), findsOneWidget);
      expect(find.byType(LoginServicesSlider), findsOneWidget);
      expect(find.byKey(const ValueKey('login-erupaiya-wordmark')),
          findsOneWidget);
      expect(find.text('Welcome to eRupaiya'), findsOneWidget);
      expect(
        find.text('Enter your mobile number to continue.'),
        findsOneWidget,
      );
      expect(find.text('Mobile Number'), findsOneWidget);
      expect(find.text('+91'), findsOneWidget);
      expect(find.text('Enter 10 Digit Mobile Number'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.textContaining('Terms of Use'), findsOneWidget);
      expect(find.textContaining('Privacy Policy'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('Continue enables after 10 digits', (tester) async {
      await _pumpLogin(tester);

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Continue'),
      );
      expect(button.onPressed, isNull);

      await tester.enterText(find.byType(TextField), '9876543210');
      await tester.pump();

      final enabled = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Continue'),
      );
      expect(enabled.onPressed, isNotNull);
    });

    testWidgets('applies peach-to-white vertical gradient', (tester) async {
      await _pumpLogin(tester);

      final decorated = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((w) => w.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.gradient is LinearGradient)
          .toList();

      expect(decorated, isNotEmpty);
      final gradients =
          decorated.map((d) => d.gradient! as LinearGradient).toList();
      // Full-screen peach→white band from AppColors.loginPeachCoralGradient.
      expect(
        gradients.any(
          (g) =>
              g.begin == Alignment.topCenter &&
              g.colors.contains(const Color(0xFFF2AA91)) &&
              g.colors.contains(const Color(0xFFFFFFFF)),
        ),
        isTrue,
      );
    });

    testWidgets('stays within bounds on compact height', (tester) async {
      await _pumpLogin(tester, size: const Size(320, 568));

      expect(tester.takeException(), isNull);
      expect(find.text('Welcome to eRupaiya'), findsOneWidget);
      expect(find.byType(LoginServicesSlider), findsOneWidget);
    });
  });
}
