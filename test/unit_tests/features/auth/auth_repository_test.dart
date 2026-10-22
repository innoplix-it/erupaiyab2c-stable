import 'package:dio/dio.dart';
import 'package:e_rupaiya/constants/api_constants.dart';
import 'package:e_rupaiya/constants/storage_keys.dart';
import 'package:e_rupaiya/features/auth/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';

class MockHTTPClient extends Mock implements Dio {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

/// Matches the unauthenticated JSON POST options the repository sends.
Matcher _publicJsonOptions() {
  return isA<Options>()
      .having((options) => options.contentType, 'contentType',
          Headers.jsonContentType)
      .having((options) => options.extra?['skipAuth'], 'skipAuth', true)
      .having(
        (options) => options.extra?['skipAuthRefresh'],
        'skipAuthRefresh',
        true,
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthRepository authRepository;
  late MockHTTPClient mockDioClient;
  late MockFlutterSecureStorage mockSecureStorage;

  setUpAll(() {
    registerFallbackValue(Options());
  });

  setUp(() {
    mockDioClient = MockHTTPClient();
    mockSecureStorage = MockFlutterSecureStorage();
    authRepository = AuthRepository(
      dio: mockDioClient,
      secureStorage: mockSecureStorage,
    );
  });

  group('AuthRepository - verifyOtp', () {
    test('posts mobile and otp payload', () async {
      const mobile = '9552529513';
      const otp = '1234';

      when(
        () => mockDioClient.post(
          ApiConstants.verifyOtpEndpoint,
          data: {
            'mobile': mobile,
            'otp': otp,
          },
          options: any(named: 'options', that: _publicJsonOptions()),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: const {
            'success': true,
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ApiConstants.verifyOtpEndpoint),
        ),
      );

      await authRepository.verifyOtp(mobile: mobile, otp: otp);

      verify(
        () => mockDioClient.post(
          ApiConstants.verifyOtpEndpoint,
          data: {
            'mobile': mobile,
            'otp': otp,
          },
          options: any(named: 'options', that: _publicJsonOptions()),
        ),
      ).called(1);
    });
  });

  group('AuthRepository - requestForgotPinOtp', () {
    test('posts mobile and appHash payload', () async {
      const mobile = '9552529513';
      const appHash = '+s+TkP8jIGp';

      when(
        () => mockDioClient.post(
          ApiConstants.requestForgotPinOtpEndpoint,
          data: {
            'mobile': mobile,
            'appHash': appHash,
          },
          options: any(named: 'options', that: _publicJsonOptions()),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: const {
            'success': true,
            'message': 'OTP sent',
          },
          statusCode: 200,
          requestOptions:
              RequestOptions(path: ApiConstants.requestForgotPinOtpEndpoint),
        ),
      );

      final message = await authRepository.requestForgotPinOtp(
        mobile: mobile,
        appHash: appHash,
      );

      expect(message, 'OTP sent');
      verify(
        () => mockDioClient.post(
          ApiConstants.requestForgotPinOtpEndpoint,
          data: {
            'mobile': mobile,
            'appHash': appHash,
          },
          options: any(named: 'options', that: _publicJsonOptions()),
        ),
      ).called(1);
    });
  });

  group('AuthRepository - setPin', () {
    const persistedInstallationId = 'install-from-device-register';

    void stubInstallationId(String? value) {
      when(
        () => mockSecureStorage.read(key: StorageKeys.guestInstallationId),
      ).thenAnswer((_) async => value);
    }

    void stubSetPin({
      required Map<String, dynamic> data,
      Map<String, dynamic> response = const {
        'success': true,
        'message': 'PIN set successfully.',
      },
    }) {
      when(
        () => mockDioClient.post(
          ApiConstants.setPinEndpoint,
          data: data,
          options: any(named: 'options', that: _publicJsonOptions()),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: response,
          statusCode: 200,
          requestOptions: RequestOptions(path: ApiConstants.setPinEndpoint),
        ),
      );
    }

    Map<String, dynamic> requestBody() {
      return {
        'post_otp_token': 'otp-token',
        'pin': '1234',
        'installation_id': persistedInstallationId,
      };
    }

    test('sends the installation id stored by guest device registration',
        () async {
      stubInstallationId(persistedInstallationId);
      stubSetPin(data: requestBody());

      final message = await authRepository.setPin(
        postOtpToken: 'otp-token',
        pin: '1234',
      );

      expect(message, 'PIN set successfully.');
      verify(
        () => mockSecureStorage.read(key: StorageKeys.guestInstallationId),
      ).called(1);
      verify(
        () => mockDioClient.post(
          ApiConstants.setPinEndpoint,
          data: requestBody(),
          options: any(named: 'options', that: _publicJsonOptions()),
        ),
      ).called(1);
      verifyNever(
        () => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      );
    });

    test('uses the same persisted id after a new repository instance',
        () async {
      stubInstallationId(persistedInstallationId);
      stubSetPin(data: requestBody());
      final restarted = AuthRepository(
        dio: mockDioClient,
        secureStorage: mockSecureStorage,
      );

      await restarted.setPin(postOtpToken: 'otp-token', pin: '1234');

      verify(
        () => mockDioClient.post(
          ApiConstants.setPinEndpoint,
          data: requestBody(),
          options: any(named: 'options', that: _publicJsonOptions()),
        ),
      ).called(1);
      expect(requestBody()['installation_id'], persistedInstallationId);
      expect(
        requestBody()['installation_id'],
        isNot('eRupaiya-guest-test-10001'),
      );
    });

    test('does not post when the persisted installation id is missing',
        () async {
      stubInstallationId('  ');

      await expectLater(
        authRepository.setPin(postOtpToken: 'otp-token', pin: '1234'),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            'Exception: Missing installation ID.',
          ),
        ),
      );
      verifyNever(
        () => mockDioClient.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      );
    });

    test('keeps the existing failure message when set PIN is rejected',
        () async {
      stubInstallationId(persistedInstallationId);
      stubSetPin(
        data: requestBody(),
        response: const {
          'success': false,
          'message': 'Set PIN failed',
        },
      );

      await expectLater(
        authRepository.setPin(postOtpToken: 'otp-token', pin: '1234'),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            'Exception: Set PIN failed',
          ),
        ),
      );
    });
  });

  group('AuthRepository - logout', () {
    test('deletes all user-related keys from secure storage', () async {
      when(() => mockSecureStorage.read(key: 'refreshToken'))
          .thenAnswer((_) async => null);
      when(
        () => mockSecureStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});

      await authRepository.logout();

      verify(() => mockSecureStorage.read(key: 'refreshToken')).called(1);
      verify(() => mockSecureStorage.delete(key: 'accessToken')).called(1);
      verify(() => mockSecureStorage.delete(key: 'refreshToken')).called(1);
      verify(() => mockSecureStorage.delete(key: 'tokenType')).called(1);
      verify(() => mockSecureStorage.delete(key: 'tokenExpiresAt')).called(1);
      verify(() => mockSecureStorage.delete(key: 'userId')).called(1);
      verify(() => mockSecureStorage.delete(key: 'mobile')).called(1);
      verify(() => mockSecureStorage.delete(key: 'tempAccessToken')).called(1);
      verifyNoMoreInteractions(mockSecureStorage);
    });
  });
}
