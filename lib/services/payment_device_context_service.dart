import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';

import 'logger_service.dart';

class PaymentDeviceContextService {
  const PaymentDeviceContextService();

  static const _cacheTtl = Duration(seconds: 30);
  static Future<Map<String, dynamic>>? _pending;
  static Map<String, dynamic>? _cache;
  static DateTime? _cacheAt;

  Future<Map<String, dynamic>> collect() async {
    final cached = _cache;
    final cachedAt = _cacheAt;
    if (cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _cacheTtl) {
      return Map<String, dynamic>.from(cached)
        ..['timestamp'] = DateTime.now().millisecondsSinceEpoch.toString();
    }

    final pending = _pending;
    if (pending != null) return pending;

    final future = _collectFresh();
    _pending = future;
    try {
      final result = await future;
      _cache = result;
      _cacheAt = DateTime.now();
      return result;
    } finally {
      if (identical(_pending, future)) {
        _pending = null;
      }
    }
  }

  Future<Map<String, dynamic>> _collectFresh() async {
    final now = DateTime.now();
    final deviceIdFuture = _deviceId();
    final vpnFuture = _isVpnLikely();
    final rootedFuture = _isRootedLikely();
    final locationFuture = _safeLocation();

    final deviceId = await deviceIdFuture;
    final vpn = await vpnFuture;
    final rooted = await rootedFuture;
    final location = await locationFuture;

    return <String, dynamic>{
      'latitude': location.latitude,
      'longitude': location.longitude,
      'isMock': location.isMocked,
      'isVpn': vpn,
      'isRooted': rooted,
      'deviceId': deviceId,
      'device_id': deviceId,
      'timestamp': now.millisecondsSinceEpoch.toString(),
    };
  }

  Future<String> _deviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        final androidId = android.id;
        if (androidId.trim().isNotEmpty) {
          return androidId.trim();
        }
        return android.id.toString();
      }
      if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        return (ios.identifierForVendor ?? ios.name).toString();
      }
    } catch (e, stackTrace) {
      logger.error('Failed to resolve payment device ID',
          error: e, stackTrace: stackTrace);
    }
    return '';
  }

  Future<bool> _isVpnLikely() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        includeLinkLocal: true,
      );
      for (final iface in interfaces) {
        final name = iface.name.toLowerCase();
        if (name.contains('tun') ||
            name.contains('ppp') ||
            name.contains('ipsec') ||
            name.contains('utun') ||
            name.contains('wg')) {
          return true;
        }
      }
    } catch (e, stackTrace) {
      logger.error('Failed to inspect VPN state for payment context',
          error: e, stackTrace: stackTrace);
    }
    return false;
  }

  Future<bool> _isRootedLikely() async {
    try {
      if (Platform.isAndroid) {
        const paths = <String>[
          '/system/app/Superuser.apk',
          '/sbin/su',
          '/system/bin/su',
          '/system/xbin/su',
          '/data/local/xbin/su',
          '/data/local/bin/su',
          '/system/sd/xbin/su',
          '/system/bin/failsafe/su',
          '/data/local/su',
        ];
        for (final path in paths) {
          if (File(path).existsSync()) return true;
        }
      }
      if (Platform.isIOS) {
        const paths = <String>[
          '/Applications/Cydia.app',
          '/Library/MobileSubstrate/MobileSubstrate.dylib',
          '/bin/bash',
          '/usr/sbin/sshd',
          '/etc/apt',
        ];
        for (final path in paths) {
          if (File(path).existsSync()) return true;
        }
      }
    } catch (e, stackTrace) {
      logger.error('Failed to inspect root/jailbreak state for payment context',
          error: e, stackTrace: stackTrace);
    }
    return false;
  }

  Future<_LocationSnapshot> _safeLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return const _LocationSnapshot.empty();

      final permission = await Geolocator.checkPermission();
      // Do not request permission here; payment should never be blocked by a
      // permission prompt/denial. Just send empty coordinates if unavailable.
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const _LocationSnapshot.empty();
      }

      // Use last-known only so create-order is never blocked on a GPS fix.
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        return _LocationSnapshot(
          latitude: last.latitude.toString(),
          longitude: last.longitude.toString(),
          isMocked: last.isMocked,
        );
      }
    } catch (e, stackTrace) {
      logger.error('Failed to collect payment location context',
          error: e, stackTrace: stackTrace);
    }
    return const _LocationSnapshot.empty();
  }
}

class _LocationSnapshot {
  const _LocationSnapshot({
    required this.latitude,
    required this.longitude,
    required this.isMocked,
  });

  const _LocationSnapshot.empty()
      : latitude = '',
        longitude = '',
        isMocked = false;

  final String latitude;
  final String longitude;
  final bool isMocked;
}
