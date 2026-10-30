import 'package:e_rupaiya/constants/storage_keys.dart';
import 'package:e_rupaiya/services/secure_storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory stand-in for the real [FlutterSecureStorage] so the session
/// clear can be verified behaviourally (AUD-032) without platform channels.
class _FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      values[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeSecureStorage storage;

  setUp(() {
    storage = _FakeSecureStorage();
  });

  Future<void> seedFullSession() async {
    for (final key in sessionStorageKeys) {
      storage.values[key] = 'value-for-$key';
    }
    // Unrelated persistent data that must survive any session clear.
    storage.values[StorageKeys.deviceToken] = 'fcm-device-token';
    storage.values[StorageKeys.pendingReferralCode] = 'REF123';
    storage.values[StorageKeys.themeMode] = 'light';
    storage.values[StorageKeys.locationAccessEnabled] = 'true';
    storage.values[StorageKeys.guestInstallationId] = 'guest-install-id';
    storage.values['savedBillers'] = 'user-persistent-data';
  }

  group('sessionStorageKeys contract (AUD-032)', () {
    test('includes refreshTokenExpiresAt', () {
      expect(sessionStorageKeys, contains('refreshTokenExpiresAt'));
    });

    test('covers every auth/session key written at login and refresh', () {
      expect(
          sessionStorageKeys,
          containsAll(<String>[
            'accessToken',
            'refreshToken',
            'tokenType',
            'tokenExpiresAt',
            'refreshTokenExpiresAt',
            'userId',
            'mobile',
            StorageKeys.tempAccessToken,
          ]));
    });
  });

  group('clearSessionStorage', () {
    test('removes every stored session key', () async {
      await seedFullSession();

      await clearSessionStorage(storage);

      for (final key in sessionStorageKeys) {
        expect(storage.values.containsKey(key), isFalse,
            reason: 'session key "$key" must be removed on clear');
      }
    });

    test('specifically removes refreshTokenExpiresAt', () async {
      await seedFullSession();
      expect(storage.values, contains('refreshTokenExpiresAt'));

      await clearSessionStorage(storage);

      expect(storage.values.containsKey('refreshTokenExpiresAt'), isFalse);
    });

    test('is safe when session keys are already missing', () async {
      // Empty storage: deleting absent keys must not throw.
      await expectLater(clearSessionStorage(storage), completes);

      // Partial session: also must not throw.
      storage.values['accessToken'] = 'only-access';
      await expectLater(clearSessionStorage(storage), completes);
      expect(storage.values.containsKey('accessToken'), isFalse);
    });

    test('does not delete unrelated persistent data', () async {
      await seedFullSession();

      await clearSessionStorage(storage);

      expect(storage.values[StorageKeys.deviceToken], 'fcm-device-token');
      expect(storage.values[StorageKeys.pendingReferralCode], 'REF123');
      expect(storage.values[StorageKeys.themeMode], 'light');
      expect(storage.values[StorageKeys.locationAccessEnabled], 'true');
      expect(
          storage.values[StorageKeys.guestInstallationId], 'guest-install-id');
      expect(storage.values['savedBillers'], 'user-persistent-data');
    });
  });
}
