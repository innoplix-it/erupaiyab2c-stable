import 'package:e_rupaiya/features/auth/controllers/auth_controller.dart';
import 'package:e_rupaiya/features/auth/models/auth_state.dart';
import 'package:e_rupaiya/features/auth/repositories/auth_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockAuthRepository mockRepository;
  late MockFlutterSecureStorage mockSecureStorage;
  late AuthController controller;

  setUp(() {
    mockRepository = MockAuthRepository();
    mockSecureStorage = MockFlutterSecureStorage();
    when(() => mockRepository.secureStorage).thenReturn(mockSecureStorage);
    controller = AuthController(
      repository: mockRepository,
      shouldCheckInitialAuth: false,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  group('AuthController.verifyOtp', () {
    test('uses pending mobile when explicit mobile is absent', () async {
      controller.state = const AuthState(
        isAuthenticated: false,
        hasTemporaryAccess: true,
        isLoading: false,
        isSubmitting: false,
        pendingMobile: '9552529513',
      );

      when(() => mockSecureStorage.read(key: 'mobile'))
          .thenAnswer((_) async => null);
      when(
        () => mockRepository.verifyOtp(
          mobile: '9552529513',
          otp: '1234',
        ),
      ).thenAnswer((_) async {
        return null;
      });

      final success = await controller.verifyOtp(otp: '1234');

      expect(success, isTrue);
      expect(controller.state.pendingMobile, '9552529513');
      expect(controller.state.errorMessage, isNull);
      verify(
        () => mockRepository.verifyOtp(
          mobile: '9552529513',
          otp: '1234',
        ),
      ).called(1);
    });

    test('returns false when no mobile is available', () async {
      when(() => mockSecureStorage.read(key: 'mobile'))
          .thenAnswer((_) async => null);

      final success = await controller.verifyOtp(otp: '1234');

      expect(success, isFalse);
      expect(
        controller.state.errorMessage,
        'Missing mobile number. Please try again.',
      );
      verifyNever(
        () => mockRepository.verifyOtp(
          mobile: any(named: 'mobile'),
          otp: any(named: 'otp'),
        ),
      );
    });
  });

  group('AuthController.requestForgotPinOtp', () {
    test('returns error when no mobile is available', () async {
      when(() => mockSecureStorage.read(key: 'mobile'))
          .thenAnswer((_) async => null);

      final message = await controller.requestForgotPinOtp();

      expect(message, isNull);
      expect(
        controller.state.errorMessage,
        'Missing mobile number. Please try again.',
      );
      verifyNever(
        () => mockRepository.requestForgotPinOtp(
          mobile: any(named: 'mobile'),
          appHash: any(named: 'appHash'),
        ),
      );
    });
  });
}
