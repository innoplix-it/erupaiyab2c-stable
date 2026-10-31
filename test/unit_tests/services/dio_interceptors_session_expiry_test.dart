import 'package:dio/dio.dart';
import 'package:e_rupaiya/core/barrel_file.dart';
import 'package:e_rupaiya/features/auth/controllers/auth_controller.dart';
import 'package:e_rupaiya/features/auth/models/auth_state.dart';
import 'package:e_rupaiya/features/auth/repositories/auth_repository.dart';
import 'package:e_rupaiya/services/dio_interceptors.dart';
import 'package:e_rupaiya/services/secure_storage_service.dart';
import 'package:e_rupaiya/widgets/k_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

// AUD-037 G1 — behavioral tests for terminal session-expiration handling.
//
// The secure storage of the interceptor/Utils is SecureStorageService.instance
// (a const FlutterSecureStorage), so the platform channel is mocked with an
// in-memory map and the REAL cleanup paths execute — no source-text checks
// are used where behavior can be exercised directly.
class MockErrorHandler extends Mock implements ErrorInterceptorHandler {}

class MockAuthDio extends Mock implements Dio {}

const _storageChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(
      DioException(requestOptions: RequestOptions(path: '/fallback')),
    );
  });

  final store = <String, String>{};

  setUp(() {
    store.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_storageChannel, (call) async {
      final args = call.arguments as Map;
      final key = args['key'] as String?;
      switch (call.method) {
        case 'read':
          return store[key];
        case 'write':
          store[key!] = args['value'] as String;
          return null;
        case 'delete':
          store.remove(key);
          return null;
        case 'readAll':
          return store;
        case 'deleteAll':
          store.clear();
          return null;
        default:
          return null;
      }
    });
    DioInterceptors.onLocalSessionExpired = null;
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_storageChannel, null);
    DioInterceptors.onLocalSessionExpired = null;
  });

  DioException unauthorized() {
    final options = RequestOptions(
      path: 'https://api.test/some/endpoint',
      extra: {'retried': true}, // skip the refresh attempt entirely
    );
    return DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: options,
        statusCode: 401,
        data: const <String, dynamic>{},
      ),
    );
  }

  void seedFullSession({required DateTime refreshExpiresAt}) {
    for (final key in sessionStorageKeys) {
      store[key] = 'value-for-$key';
    }
    store['refreshTokenExpiresAt'] = refreshExpiresAt.toIso8601String();
    // Unrelated persistent data that must survive every cleanup path.
    store['deviceToken'] = 'device-token-value';
    store['themeMode'] = 'light';
  }

  group('AUD-037 G1 — expiry with NO navigator context (acceptance path)', () {
    test('clears every session key AND fires the local auth-state reset',
        () async {
      expect(navigatorKey.currentContext, isNull);
      seedFullSession(
          refreshExpiresAt: DateTime.now().subtract(const Duration(days: 1)));
      var localResetCalls = 0;
      DioInterceptors.onLocalSessionExpired = () => localResetCalls++;

      final interceptor = DioInterceptors();
      final handler = MockErrorHandler();
      when(() => handler.next(any())).thenAnswer((_) {});

      await interceptor.onError(unauthorized(), handler);

      // 1. All authentication session keys are gone from storage.
      for (final key in sessionStorageKeys) {
        expect(store.containsKey(key), isFalse, reason: '$key must be cleared');
      }
      // 2. The in-memory auth reset hook fired exactly once.
      expect(localResetCalls, 1);
      // 10. Unrelated stored preferences untouched.
      expect(store['deviceToken'], 'device-token-value');
      expect(store['themeMode'], 'light');
    });

    test('concurrent 401s run cleanup only once (no duplicate handling)',
        () async {
      seedFullSession(
          refreshExpiresAt: DateTime.now().subtract(const Duration(days: 1)));
      var localResetCalls = 0;
      DioInterceptors.onLocalSessionExpired = () => localResetCalls++;

      final interceptor = DioInterceptors();
      final h1 = MockErrorHandler();
      final h2 = MockErrorHandler();
      when(() => h1.next(any())).thenAnswer((_) {});
      when(() => h2.next(any())).thenAnswer((_) {});

      // Fire both without awaiting so both reach the terminal branch.
      final first = interceptor.onError(unauthorized(), h1);
      final second = interceptor.onError(unauthorized(), h2);
      await Future.wait([first, second]);

      expect(localResetCalls, 1);
      for (final key in sessionStorageKeys) {
        expect(store.containsKey(key), isFalse);
      }
    });

    test('valid (non-expired) refresh token does NOT clear session', () async {
      seedFullSession(
          refreshExpiresAt: DateTime.now().add(const Duration(days: 1)));
      var localResetCalls = 0;
      DioInterceptors.onLocalSessionExpired = () => localResetCalls++;

      final interceptor = DioInterceptors();
      final handler = MockErrorHandler();
      when(() => handler.next(any())).thenAnswer((_) {});

      await interceptor.onError(unauthorized(), handler);

      // Temporary/token-still-valid failures must not log the user out.
      expect(localResetCalls, 0);
      for (final key in sessionStorageKeys) {
        expect(store.containsKey(key), isTrue, reason: '$key must survive');
      }
    });

    test('HTTP 500 and 503 never clear the session or fire the reset hook',
        () async {
      seedFullSession(
          refreshExpiresAt: DateTime.now().add(const Duration(days: 1)));
      var localResetCalls = 0;
      DioInterceptors.onLocalSessionExpired = () => localResetCalls++;
      final interceptor = DioInterceptors();

      for (final code in [500, 503]) {
        final options = RequestOptions(path: 'https://api.test/x');
        final err = DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: code,
            data: const <String, dynamic>{},
          ),
        );
        final handler = MockErrorHandler();
        when(() => handler.next(any())).thenAnswer((_) {});
        await interceptor.onError(err, handler);
      }

      expect(localResetCalls, 0);
      for (final key in sessionStorageKeys) {
        expect(store.containsKey(key), isTrue);
      }
    });
  });

  group('AUD-037 G1 — real AuthState transitions via the registered hook', () {
    Future<ProviderContainer> buildAuthenticatedContainer() async {
      // Seed a still-valid access token BEFORE the controller is constructed:
      // _checkInitialAuth reads storage as soon as the provider is created,
      // so the authenticated short-circuit must already be in place (this
      // also keeps the repository/network completely untouched).
      store['accessToken'] = 'valid-token';
      store['tokenExpiresAt'] =
          DateTime.now().add(const Duration(hours: 1)).toIso8601String();
      store['refreshTokenExpiresAt'] =
          DateTime.now().add(const Duration(days: 1)).toIso8601String();

      final mockDio = MockAuthDio();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWith(
            (ref) => AuthRepository(dio: mockDio),
          ),
        ],
      );
      addTearDown(container.dispose);
      // Reading routerProvider performs the AUD-037 registration itself.
      final router = container.read(routerProvider);
      expect(router, isA<GoRouter>());

      await untilState(container, (s) => !s.isLoading);
      expect(container.read(authControllerProvider).isAuthenticated, isTrue);
      return container;
    }

    test(
        'routerProvider registers the interceptor hook; hook flips '
        'AuthState.isAuthenticated to false (local-only)', () async {
      final container = await buildAuthenticatedContainer();
      expect(DioInterceptors.onLocalSessionExpired, isNotNull,
          reason: 'routerProvider must register the G1 hook');

      var authChanges = 0;
      final sub = container.listen<AuthState>(
        authControllerProvider,
        (_, __) => authChanges++,
      );
      addTearDown(sub.close);

      // The interceptor calls this after clearSessionStorage() when there is
      // no navigator context. It must reset state with no network request.
      DioInterceptors.onLocalSessionExpired!();

      final state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.hasTemporaryAccess, isFalse);
      // The change actually notifies listeners — this is the same notification
      // the GoRouter ref.listen refresh depends on (chain verified behaviorally).
      expect(authChanges, greaterThanOrEqualTo(1));
    });

    test('expireSessionLocally makes no network request (recursion-safe)',
        () async {
      final mockDio = MockAuthDio();
      await buildAuthenticatedContainer();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWith(
            (ref) => AuthRepository(dio: mockDio),
          ),
        ],
      );
      addTearDown(container.dispose);
      await untilState(container, (s) => !s.isLoading);

      container.read(authControllerProvider.notifier).expireSessionLocally();

      verifyZeroInteractions(mockDio);
      expect(container.read(authControllerProvider).isAuthenticated, isFalse);
    });
  });

  group('AUD-037 G1 — context-available expiry path (existing behaviour)', () {
    testWidgets('logout resets AuthState and navigates to Login',
        (tester) async {
      seedFullSession(
        refreshExpiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      // Make _checkInitialAuth see an authenticated session without network.
      store['tokenExpiresAt'] =
          DateTime.now().add(const Duration(hours: 1)).toIso8601String();

      final mockDio = MockAuthDio();
      // Repository logout catches its own errors, so the POST failing here
      // still exercises the full finally-clear path.
      when(
        () => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/logout'),
        type: DioExceptionType.connectionError,
      ));

      final router = GoRouter(
        navigatorKey: navigatorKey,
        initialLocation: RouteConstants.home,
        routes: [
          GoRoute(
            path: RouteConstants.home,
            builder: (_, __) => const Scaffold(body: Text('HOME')),
          ),
          GoRoute(
            path: RouteConstants.login,
            builder: (_, __) => const Scaffold(body: Text('LOGIN')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWith(
              (ref) => AuthRepository(dio: mockDio),
            ),
          ],
          // ScreenUtilInit is required because AppSnackbar's widget tree uses
          // flutter_screenutil extensions (same harness as MyApp).
          child: ScreenUtilInit(
            designSize: const Size(360, 690),
            builder: (_, __) => MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
      expect(navigatorKey.currentContext, isNotNull);

      final interceptor = DioInterceptors();
      final handler = MockErrorHandler();
      when(() => handler.next(any())).thenAnswer((_) {});

      await interceptor.onError(unauthorized(), handler);
      await tester.pumpAndSettle();

      // Storage cleared, unrelated data untouched.
      for (final key in sessionStorageKeys) {
        expect(store.containsKey(key), isFalse);
      }
      expect(store['deviceToken'], 'device-token-value');
      // Login navigation preserved on the context-available path.
      expect(find.text('LOGIN'), findsOneWidget);
      // Advance past the snackbar auto-dismiss timer so the test tears down
      // with no pending timers (fake-async clock only moves via pump).
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
    });
  });
}

Future<void> untilState(
  ProviderContainer container,
  bool Function(AuthState state) condition,
) async {
  for (var i = 0; i < 100; i++) {
    if (condition(container.read(authControllerProvider))) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  throw StateError('auth state condition not met in time');
}
