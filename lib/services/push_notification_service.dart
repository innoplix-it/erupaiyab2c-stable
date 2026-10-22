import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../constants/routes_constant.dart';
import '../constants/storage_keys.dart';
import '../config/app_env.dart';
import '../features/profile/repositories/profile_repository.dart';
import '../firebase/explicit_firebase_options.dart';
import 'guest_device_registration.dart';
import '../utils/utils.dart';
import '../widgets/k_dialog.dart';
import 'logger_service.dart';
import 'notification_badge_service.dart';
import 'secure_storage_service.dart';

const String _defaultChannelId = 'default_notifications';
const String _defaultChannelName = 'General Notifications';
const String _defaultChannelDescription = 'General app notifications.';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

void _debugLog(String message) {
  if (!AppEnv.enableLogs || !kDebugMode) return;
  debugPrint(message);
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    if (Platform.isAndroid) {
      await Firebase.initializeApp(
        options: ExplicitFirebaseOptions.androidErupiya,
      );
    } else {
      await Firebase.initializeApp();
    }
  }
  logger.info('FCM background message: ${message.messageId}');
}

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static const _storage = SecureStorageService.instance;
  static String? _latestToken;
  static String? _lastSyncedToken;
  static bool _initialized = false;
  static bool _permissionsRequested = false;
  static bool _uiReady = false;
  static String? _pendingLocation;
  static Object? _pendingExtra;
  static final GuestDeviceRegistrar _guestRegistrar = GuestDeviceRegistrar(
    store: const SecureGuestDeviceStore(),
    isAuthenticated: Utils.checkAuthentication,
    readFcmToken: _currentFcmToken,
    devicePlatform: _currentDevicePlatform,
    register: GuestDeviceRepository().register,
  );

  static Future<String?> _currentFcmToken() async {
    final token = _latestToken?.trim();
    return _isValidToken(token) ? token : null;
  }

  static String _currentDevicePlatform() {
    return guestDevicePlatformFor(
      android: Platform.isAndroid,
      ios: Platform.isIOS,
    );
  }

  static String? get latestToken => _latestToken;

  static Future<void> _persistToken(String token) async {
    try {
      await _storage.write(key: StorageKeys.deviceToken, value: token);
    } catch (e, stackTrace) {
      logger.error('Failed to persist device token',
          error: e, stackTrace: stackTrace);
    }
  }

  static bool _isValidToken(String? token) {
    final t = token?.trim() ?? '';
    if (t.isEmpty) return false;
    if (t.toLowerCase() == 'null') return false;
    if (t.toLowerCase() == 'undefined') return false;
    return true;
  }

  /// Ensures FCM is initialized and returns a non-empty token when possible.
  /// Some backend flows require `device_token`, so callers can await this
  /// before making requests.
  static Future<String?> ensureTokenReady({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (_isValidToken(_latestToken)) return _latestToken!.trim();

    // Use cached token if available (common on second launch).
    try {
      final stored = await _storage.read(key: StorageKeys.deviceToken);
      if (_isValidToken(stored)) {
        _latestToken = stored!.trim();
        unawaited(initialize(requestPermissions: false));
        return _latestToken;
      }
    } catch (e, stackTrace) {
      logger.error('Failed to read cached device token',
          error: e, stackTrace: stackTrace);
    }

    try {
      await initialize(requestPermissions: false);
    } catch (e, stackTrace) {
      logger.error(
        'PushNotificationService.initialize failed while waiting for token',
        error: e,
        stackTrace: stackTrace,
      );
    }

    // Try fetching again directly.
    try {
      final token = await _messaging.getToken();
      if (_isValidToken(token)) {
        _latestToken = token!.trim();
        await _persistToken(_latestToken!);
        return _latestToken;
      }
    } catch (e, stackTrace) {
      logger.error('Failed to fetch FCM token directly',
          error: e, stackTrace: stackTrace);
    }

    final startedAt = DateTime.now();
    while (DateTime.now().difference(startedAt) < timeout) {
      final token = _latestToken;
      if (_isValidToken(token)) return token!.trim();
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    logger.error(
      'FCM token unavailable after timeout (initialized=$_initialized)',
    );
    return _isValidToken(_latestToken) ? _latestToken!.trim() : null;
  }

  /// Call this once the app's `MaterialApp.router` is mounted (i.e. routing is ready).
  static void markUiReady() {
    _uiReady = true;
    _flushPendingNavigation();
  }

  static Future<void> initialize({bool requestPermissions = true}) async {
    if (_initialized) {
      if (requestPermissions) {
        await ensurePermissionsRequested();
      }
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        if (Platform.isAndroid) {
          await Firebase.initializeApp(
            options: ExplicitFirebaseOptions.androidErupiya,
          );
        } else {
          await Firebase.initializeApp();
        }
      }
    } catch (e, stackTrace) {
      logger.error(
        'Firebase.initializeApp failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initLocalNotifications();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    String? token;
    try {
      token = await _messaging.getToken();
    } catch (e, stackTrace) {
      logger.error(
        'FirebaseMessaging.getToken failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
    final tokenMessage = 'FCM token: $token';
    _debugLog(tokenMessage);
    logger.info(tokenMessage);
    if (_isValidToken(token)) {
      _latestToken = token!.trim();
      await _persistToken(_latestToken!);
    }

    _messaging.onTokenRefresh.listen((newToken) async {
      _latestToken = newToken.trim();
      if (_isValidToken(_latestToken)) {
        await _persistToken(_latestToken!);
      }
      if (await Utils.checkAuthentication()) {
        final token = _latestToken;
        if (_isValidToken(token)) {
          await _sendTokenToServer(token!.trim());
        }
        return;
      }
      await _guestRegistrar.registerIfNeeded();
    });

    _initialized = true;
    await _guestRegistrar.registerIfNeeded();

    if (requestPermissions) {
      await ensurePermissionsRequested();
    }
  }

  static Future<void> ensurePermissionsRequested() async {
    if (_permissionsRequested) return;
    _permissionsRequested = true;
    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    logger.info('Notification permission: ${settings.authorizationStatus}');

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  static Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        logger.info('Local notification tapped: ${response.payload}');
        final payload = response.payload;
        if (payload == null || payload.trim().isEmpty) return;
        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map) {
            final data = decoded['data'];
            _handleNotificationTap(
              data: data is Map
                  ? data.map((k, v) => MapEntry('$k', v))
                  : const <String, dynamic>{},
            );
          }
        } catch (e) {
          logger.error('Failed to parse local notification payload: $e');
        }
      },
    );

    const androidChannel = AndroidNotificationChannel(
      _defaultChannelId,
      _defaultChannelName,
      description: _defaultChannelDescription,
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    logger.info('FCM foreground message: ${message.messageId}');
    await _showLocalNotification(message);
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    logger.info('FCM opened app message: ${message.messageId}');
    _handleNotificationTap(
      data: message.data,
    );
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      _defaultChannelId,
      _defaultChannelName,
      channelDescription: _defaultChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode({
        'title': notification.title,
        'body': notification.body,
        'data': message.data,
      }),
    );

    unawaited(NotificationBadgeService.refreshCount());
  }

  static Future<void> _sendTokenToServer(String token) async {
    try {
      final accessToken = await Utils.getAccessToken();
      if (accessToken == null || accessToken.trim().isEmpty) {
        // Avoid calling auth-protected endpoint before login.
        return;
      }

      final trimmed = token.trim();
      if (trimmed.isEmpty || trimmed == _lastSyncedToken) return;
      final response = await ProfileRepository().updateDeviceToken(token);
      final message =
          'Device token update: ${response.success} - ${response.message}';
      _lastSyncedToken = trimmed;
      logger.info(message);
      _debugLog(message);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to update device token: $e',
        error: e,
        stackTrace: stackTrace,
      );
      _debugLog('Failed to update device token: $e');
    }
  }

  /// Call this after login (e.g. on Home screen) to sync the latest device token
  /// with backend.
  static Future<void> syncTokenToServerIfLoggedIn() async {
    final token = _latestToken;
    if (!_isValidToken(token)) return;
    await _sendTokenToServer(token!.trim());
  }

  static void _handleNotificationTap({
    required Map<String, dynamic> data,
  }) {
    final resolvedLocation = _resolveLocation(data: data);
    if (resolvedLocation == null) return;
    _navigateOrQueue(resolvedLocation);
  }

  static String? _resolveLocation({required Map<String, dynamic> data}) {
    final route = (data['route'] ?? data['screen'] ?? data['redirect'])
        ?.toString()
        .trim();
    if (route != null && route.isNotEmpty) {
      // Preferred: backend sends a full app route, e.g. "/mobile-prepaid".
      if (route.startsWith('/')) return route;
      // Backwards compat: allow shorthand identifiers.
      if (route == 'mobile_prepaid' || route == 'mobile-prepaid') {
        return RouteConstants.mobilePrepaid;
      }
      // Or a RouteConstants value itself.
      if (route == RouteConstants.mobilePrepaid) return route;
    }

    return null;
  }

  static void _navigateOrQueue(String location, {Object? extra}) {
    if (!_uiReady || navigatorKey.currentContext == null) {
      _pendingLocation = location;
      _pendingExtra = extra;
      logger.info('Queued navigation to $location (UI not ready yet).');
      return;
    }

    final context = navigatorKey.currentContext;
    if (context == null) return;
    try {
      context.go(location, extra: extra);
    } catch (e) {
      logger.error('Failed to navigate to $location: $e');
      _pendingLocation = location;
      _pendingExtra = extra;
    }
  }

  static void _flushPendingNavigation() {
    final location = _pendingLocation;
    if (!_uiReady || location == null) return;
    final context = navigatorKey.currentContext;
    if (context == null) return;
    final extra = _pendingExtra;
    _pendingLocation = null;
    _pendingExtra = null;
    try {
      context.go(location, extra: extra);
    } catch (e) {
      logger.error('Failed to flush pending navigation to $location: $e');
      _pendingLocation = location;
      _pendingExtra = extra;
    }
  }
}
