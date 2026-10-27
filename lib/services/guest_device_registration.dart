import 'dart:math';

import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../constants/storage_keys.dart';
import 'device_id_service.dart';
import 'dio_service.dart';
import 'logger_service.dart';
import 'secure_storage_service.dart';

String guestDevicePlatformFor({required bool android, required bool ios}) {
  if (android) return 'ANDROID';
  if (ios) return 'IOS';
  return 'UNKNOWN';
}

class GuestDeviceRegistration {
  const GuestDeviceRegistration({
    required this.installationId,
    required this.devicePlatform,
    required this.fcmToken,
    required this.notificationPermission,
    this.deviceId,
  });

  final String installationId;
  final String devicePlatform;
  final String fcmToken;
  final bool notificationPermission;
  final String? deviceId;
}

abstract class GuestDeviceStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class SecureGuestDeviceStore implements GuestDeviceStore {
  const SecureGuestDeviceStore();

  @override
  Future<String?> read(String key) {
    return SecureStorageService.instance.read(key: key);
  }

  @override
  Future<void> write(String key, String value) {
    return SecureStorageService.instance.write(key: key, value: value);
  }
}

class GuestDeviceRepository {
  GuestDeviceRepository({Dio? dio}) : _dio = dio ?? DioService.instance.client;

  final Dio _dio;

  /// Guest registration is unauthenticated. `skipAuth` matches the other
  /// public auth calls so a leftover session token is not attached.
  Future<void> register(GuestDeviceRegistration request) async {
    final response = await _dio.post(
      ApiConstants.guestDeviceRegisterEndpoint,
      data: {
        'installation_id': request.installationId,
        'device_platform': request.devicePlatform,
        'fcm_token': request.fcmToken,
        'notification_permission': true,
        // 'device_id': request.deviceId,
      },
      options: Options(
        contentType: Headers.jsonContentType,
        extra: const {
          'skipAuth': true,
          'skipAuthRefresh': true,
        },
      ),
    );
    final payload = response.data;
    if (payload is Map && payload['success'] == false) {
      final message = payload['message']?.toString();
      throw Exception(
        message == null || message.isEmpty
            ? 'Guest device registration failed'
            : message,
      );
    }
  }
}

class GuestDeviceRegistrar {
  GuestDeviceRegistrar({
    required this.store,
    required this.isAuthenticated,
    required this.readFcmToken,
    required this.devicePlatform,
    required this.register,
    Future<String?> Function()? readDeviceId,
    String Function()? createInstallationId,
  })  : _readDeviceId = readDeviceId ?? _defaultDeviceId,
        _createInstallationId = createInstallationId ?? _newInstallationId;

  final GuestDeviceStore store;
  final Future<bool> Function() isAuthenticated;
  final Future<String?> Function() readFcmToken;
  final String Function() devicePlatform;
  final Future<void> Function(GuestDeviceRegistration request) register;
  final Future<String?> Function() _readDeviceId;
  final String Function() _createInstallationId;

  static Future<String?> _defaultDeviceId() =>
      const DeviceIdService().getDeviceId();

  Future<void>? _inFlight;

  Future<void> registerIfNeeded() {
    final existing = _inFlight;
    if (existing != null) return existing;
    final future = _register();
    _inFlight = future;
    return future.whenComplete(() {
      if (identical(_inFlight, future)) _inFlight = null;
    });
  }

  Future<void> _register() async {
    if (await isAuthenticated()) return;

    final token = (await readFcmToken())?.trim() ?? '';
    if (token.isEmpty) return;

    final alreadyRegistered =
        await store.read(StorageKeys.guestDeviceRegistered) == 'true';
    final registeredToken =
        (await store.read(StorageKeys.guestRegisteredFcmToken))?.trim() ?? '';
    if (alreadyRegistered && registeredToken == token) return;

    var installationId =
        (await store.read(StorageKeys.guestInstallationId))?.trim() ?? '';
    if (installationId.isEmpty) {
      installationId = _createInstallationId();
      await store.write(StorageKeys.guestInstallationId, installationId);
    }

    String? deviceId;
    try {
      deviceId = (await _readDeviceId())?.trim();
    } catch (e, stackTrace) {
      logger.error(
        'Failed to read device id for guest registration',
        error: e,
        stackTrace: stackTrace,
      );
    }

    try {
      await register(
        GuestDeviceRegistration(
          installationId: installationId,
          devicePlatform: devicePlatform(),
          fcmToken: token,
          notificationPermission: true,
          deviceId: deviceId,
        ),
      );
    } catch (_) {
      logger.error('Guest device registration failed');
      return;
    }
    await store.write(StorageKeys.guestDeviceRegistered, 'true');
    await store.write(StorageKeys.guestRegisteredFcmToken, token);
  }
}

String _newInstallationId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex =
      bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
