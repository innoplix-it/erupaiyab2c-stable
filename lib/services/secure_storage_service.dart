import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/storage_keys.dart';

class SecureStorageService {
  SecureStorageService._();

  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  static const FlutterSecureStorage instance = FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );
}

/// AUD-032: single source of truth for every auth/session key written during
/// login and token refresh. Logout, the "suspected account" primary-session
/// reset and the Dio interceptor session-clear path must all use
/// [clearSessionStorage] instead of keeping their own key lists (which is how
/// `refreshTokenExpiresAt` drifted out of sync).
const List<String> sessionStorageKeys = [
  'accessToken',
  'refreshToken',
  'tokenType',
  'tokenExpiresAt',
  'refreshTokenExpiresAt',
  'userId',
  'mobile',
  StorageKeys.tempAccessToken,
];

/// Deletes every authentication/session key from [storage].
/// Deleting a key that is already absent is a no-op for FlutterSecureStorage,
/// so this is safe to call from any cleanup path. Unrelated persistent data
/// (preferences, saved billers, device/guest identifiers) is intentionally
/// NOT part of [sessionStorageKeys] and is never touched here.
Future<void> clearSessionStorage(FlutterSecureStorage storage) async {
  for (final key in sessionStorageKeys) {
    await storage.delete(key: key);
  }
}
