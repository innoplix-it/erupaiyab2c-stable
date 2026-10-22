import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:e_rupaiya/constants/api_constants.dart';
import 'package:e_rupaiya/constants/storage_keys.dart';
import 'package:e_rupaiya/services/guest_device_registration.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStore implements GuestDeviceStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

class _CaptureAdapter implements HttpClientAdapter {
  RequestOptions? options;
  int statusCode = 200;
  String body = '{"success":true}';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    this.options = options;
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MemoryStore store;
  late List<GuestDeviceRegistration> calls;
  late bool authenticated;
  late String? token;
  late String platform;
  late int installationIds;
  late Future<void> Function(GuestDeviceRegistration request) register;

  GuestDeviceRegistrar build() {
    return GuestDeviceRegistrar(
      store: store,
      isAuthenticated: () async => authenticated,
      readFcmToken: () async => token,
      devicePlatform: () => platform,
      register: (request) => register(request),
      createInstallationId: () {
        installationIds += 1;
        return 'install-$installationIds';
      },
    );
  }

  setUp(() {
    store = _MemoryStore();
    calls = [];
    authenticated = false;
    token = 'real-fcm-token';
    platform = 'ANDROID';
    installationIds = 0;
    register = (request) async {
      calls.add(request);
    };
  });

  test('first unregistered launch sends one registration request', () async {
    final registrar = build();
    await registrar.registerIfNeeded();
    await registrar.registerIfNeeded();

    expect(calls, hasLength(1));
    expect(calls.single.installationId, 'install-1');
    expect(calls.single.fcmToken, 'real-fcm-token');
    expect(calls.single.devicePlatform, 'ANDROID');
    expect(calls.single.notificationPermission, isTrue);
  });

  test('a later launch does not register again', () async {
    await build().registerIfNeeded();
    calls.clear();

    await build().registerIfNeeded();

    expect(calls, isEmpty);
  });

  test('an authenticated user is excluded', () async {
    authenticated = true;

    await build().registerIfNeeded();

    expect(calls, isEmpty);
    expect(
        store.values.containsKey(StorageKeys.guestDeviceRegistered), isFalse);
  });

  test('success persists registration state', () async {
    await build().registerIfNeeded();

    expect(store.values[StorageKeys.guestDeviceRegistered], 'true');
    expect(store.values[StorageKeys.guestRegisteredFcmToken], 'real-fcm-token');
    expect(store.values[StorageKeys.guestInstallationId], 'install-1');
  });

  test('failure does not persist success and can be retried', () async {
    var fail = true;
    register = (request) async {
      calls.add(request);
      if (fail) throw Exception('offline');
    };

    await build().registerIfNeeded();
    expect(
        store.values.containsKey(StorageKeys.guestDeviceRegistered), isFalse);
    expect(store.values[StorageKeys.guestInstallationId], 'install-1');

    fail = false;
    await build().registerIfNeeded();

    expect(calls, hasLength(2));
    expect(calls[1].installationId, 'install-1');
    expect(store.values[StorageKeys.guestDeviceRegistered], 'true');
  });

  test('request uses the live token and platform with permission true',
      () async {
    token = 'device-token-42';
    platform = 'IOS';

    await build().registerIfNeeded();

    expect(calls.single.fcmToken, 'device-token-42');
    expect(calls.single.devicePlatform, 'IOS');
    expect(calls.single.notificationPermission, isTrue);
    expect(calls.single.installationId, isNot('eRupaiya-guest-test-10001'));
  });

  test('token refresh updates registration once', () async {
    await build().registerIfNeeded();
    calls.clear();

    token = 'refreshed-fcm-token';
    await build().registerIfNeeded();
    await build().registerIfNeeded();

    expect(calls, hasLength(1));
    expect(calls.single.fcmToken, 'refreshed-fcm-token');
    expect(calls.single.installationId, 'install-1');
    expect(
      store.values[StorageKeys.guestRegisteredFcmToken],
      'refreshed-fcm-token',
    );
  });

  test('a failed token refresh can be retried', () async {
    await build().registerIfNeeded();
    calls.clear();
    token = 'refreshed-fcm-token';
    register = (request) async {
      calls.add(request);
      throw Exception('offline');
    };

    await build().registerIfNeeded();
    expect(store.values[StorageKeys.guestRegisteredFcmToken], 'real-fcm-token');

    register = (request) async {
      calls.add(request);
    };
    await build().registerIfNeeded();

    expect(calls, hasLength(2));
    expect(store.values[StorageKeys.guestRegisteredFcmToken],
        'refreshed-fcm-token');
  });

  test('missing FCM token does not register or mark success', () async {
    token = '   ';

    await build().registerIfNeeded();

    expect(calls, isEmpty);
    expect(
        store.values.containsKey(StorageKeys.guestDeviceRegistered), isFalse);
  });

  test('notification permission is always sent as true', () async {
    await build().registerIfNeeded();

    expect(calls.single.notificationPermission, isTrue);
    expect(store.values[StorageKeys.guestDeviceRegistered], 'true');
  });

  test('platform values follow the backend contract', () {
    expect(guestDevicePlatformFor(android: true, ios: false), 'ANDROID');
    expect(guestDevicePlatformFor(android: false, ios: true), 'IOS');
  });

  test('overlapping calls share one request', () async {
    final gate = Completer<void>();
    register = (request) async {
      calls.add(request);
      await gate.future;
    };
    final registrar = build();

    final first = registrar.registerIfNeeded();
    final second = registrar.registerIfNeeded();
    gate.complete();
    await Future.wait([first, second]);

    expect(calls, hasLength(1));
  });

  test('repository posts the documented body without auth', () async {
    final adapter = _CaptureAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = GuestDeviceRepository(dio: dio);

    await repository.register(
      const GuestDeviceRegistration(
        installationId: 'install-1',
        devicePlatform: 'ANDROID',
        fcmToken: 'real-fcm-token',
        notificationPermission: false,
      ),
    );

    final options = adapter.options!;
    expect(options.method, 'POST');
    expect(options.uri.toString(), ApiConstants.guestDeviceRegisterEndpoint);
    expect(options.data, {
      'installation_id': 'install-1',
      'device_platform': 'ANDROID',
      'fcm_token': 'real-fcm-token',
      'notification_permission': true,
    });
    expect(options.extra['skipAuth'], isTrue);
    expect(options.extra['skipAuthRefresh'], isTrue);
  });

  test('repository treats an explicit failure body as unsuccessful', () async {
    final adapter = _CaptureAdapter()
      ..body = '{"success":false,"message":"no"}';
    final dio = Dio()..httpClientAdapter = adapter;

    expect(
      GuestDeviceRepository(dio: dio).register(
        const GuestDeviceRegistration(
          installationId: 'install-1',
          devicePlatform: 'IOS',
          fcmToken: 'real-fcm-token',
          notificationPermission: false,
        ),
      ),
      throwsException,
    );
  });
}
