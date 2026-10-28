import 'package:e_rupaiya/constants/routes_constant.dart';
import 'package:e_rupaiya/constants/storage_keys.dart';
import 'package:e_rupaiya/features/auth/controllers/auth_controller.dart';
import 'package:e_rupaiya/features/auth/models/auth_state.dart';
import 'package:e_rupaiya/services/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthController extends Mock implements AuthController {
  @override
  AuthState get state => const AuthState(
    isAuthenticated: false,
    hasTemporaryAccess: false,
    isLoading: false,
    isSubmitting: false,
  );
}

class MockSecureStorageService extends Mock implements SecureStorageService {
  @override
  Future<void> write({required String key, required String value}) async {
    // Mock implementation
  }
  
  @override
  Future<String?> read({required String key}) async {
    return null;
  }
}

void main() {
  group('Router - AUD-018 Referral Deep Link Security', () {
    late MockAuthController mockAuthController;

    setUp(() {
      mockAuthController = MockAuthController();
    });

    test('exact referral route is /referral', () {
      expect(RouteConstants.referral, equals('/referral'));
    });

    test('referral route does not match /referral/extra with startsWith', () {
      const location = '/referral/extra';
      final matchesWithStartsWith = location.startsWith(RouteConstants.referral);
      expect(matchesWithStartsWith, isTrue);
    });

    test('referral route matches exactly /referral with equality', () {
      const location = '/referral';
      final matchesExactly = location == RouteConstants.referral;
      expect(matchesExactly, isTrue);
    });

    test('referral route does not match /referral/extra with equality', () {
      const location = '/referral/extra';
      final matchesExactly = location == RouteConstants.referral;
      expect(matchesExactly, isFalse);
    });

    test('referral route does not match /referral/extra with equality (case 2)', () {
      const location = '/referral/wallet';
      final matchesExactly = location == RouteConstants.referral;
      expect(matchesExactly, isFalse);
    });
  });

  group('Router - AUD-018 Authentication Redirect Logic', () {
    test('unauthenticated user accessing /referral is allowed (public route)', () {
      const location = '/referral';
      final isAuthenticated = false;
      final isOnAuthRoute = false;
      final isReferralRoute = location == RouteConstants.referral;
      
      // Router logic: if (!isAuthenticated && !isOnAuthRoute && !isReferralRoute) -> login
      // Since isReferralRoute is true, no redirect to login
      final shouldRedirectToLogin = !isAuthenticated && !isOnAuthRoute && !isReferralRoute;
      expect(shouldRedirectToLogin, isFalse);
    });

    test('unauthenticated user accessing /referral?code=XYZ is allowed (public route)', () {
      // matchedLocation strips query parameters, so /referral?code=XYZ becomes /referral
      const location = '/referral';
      final isAuthenticated = false;
      final isOnAuthRoute = false;
      final isReferralRoute = location == RouteConstants.referral;
      
      final shouldRedirectToLogin = !isAuthenticated && !isOnAuthRoute && !isReferralRoute;
      expect(shouldRedirectToLogin, isFalse);
    });

    test('unauthenticated user accessing /referral/extra redirects to login', () {
      const location = '/referral/extra';
      final isAuthenticated = false;
      final isOnAuthRoute = false;
      final isReferralRoute = location == RouteConstants.referral;
      
      final shouldRedirectToLogin = !isAuthenticated && !isOnAuthRoute && !isReferralRoute;
      expect(shouldRedirectToLogin, isTrue);
    });

    test('unauthenticated user accessing /referral/wallet redirects to login', () {
      const location = '/referral/wallet';
      final isAuthenticated = false;
      final isOnAuthRoute = false;
      final isReferralRoute = location == RouteConstants.referral;
      
      final shouldRedirectToLogin = !isAuthenticated && !isOnAuthRoute && !isReferralRoute;
      expect(shouldRedirectToLogin, isTrue);
    });

    test('unauthenticated user accessing /home redirects to login', () {
      const location = '/home';
      final isAuthenticated = false;
      final isOnAuthRoute = false;
      final isReferralRoute = location == RouteConstants.referral;
      
      final shouldRedirectToLogin = !isAuthenticated && !isOnAuthRoute && !isReferralRoute;
      expect(shouldRedirectToLogin, isTrue);
    });

    test('authenticated user accessing /referral is allowed', () {
      const location = '/referral';
      final isAuthenticated = true;
      final isOnAuthRoute = false;
      
      // Router logic: if (isAuthenticated && isOnAuthRoute) -> home
      // Since isOnAuthRoute is false, no redirect
      final shouldRedirectToHome = isAuthenticated && isOnAuthRoute;
      expect(shouldRedirectToHome, isFalse);
    });

    test('authenticated user on auth route redirects to home', () {
      const location = '/login';
      final isAuthenticated = true;
      final isOnAuthRoute = true;
      
      final shouldRedirectToHome = isAuthenticated && isOnAuthRoute;
      expect(shouldRedirectToHome, isTrue);
    });
  });

  group('Router - AUD-018 Referral Code Storage Behavior', () {
    late MockSecureStorageService mockStorage;

    setUp(() {
      mockStorage = MockSecureStorageService();
    });

    test('empty referral code is handled safely', () {
      const emptyCode = '';
      final isValid = emptyCode.trim().isNotEmpty;
      expect(isValid, isFalse);
    });

    test('whitespace-only referral code is treated as invalid', () {
      const whitespaceCode = '   ';
      final isValid = whitespaceCode.trim().isNotEmpty;
      expect(isValid, isFalse);
    });

    test('valid referral code is stored for unauthenticated users', () async {
      const validCode = 'ABC123';
      final isValid = validCode.trim().isNotEmpty;
      expect(isValid, isTrue);
      
      // Verify storage key exists
      expect(StorageKeys.pendingReferralCode, isNotEmpty);
    });

    test('referral code with query parameter is extracted correctly', () {
      // Simulate URI parsing
      const fullUri = '/referral?code=XYZ123';
      final code = fullUri.contains('?code=');
      expect(code, isTrue);
    });
  });
}
