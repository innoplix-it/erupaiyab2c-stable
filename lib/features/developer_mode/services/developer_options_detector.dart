import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Result of probing the Android Developer Options system setting.
enum DeveloperOptionsStatus {
  /// Developer Options are turned OFF — normal app access is allowed.
  off,

  /// Developer Options are turned ON — the app must be blocked.
  on,

  /// Platform where Developer Options do not exist (iOS / web / desktop).
  /// This is a *clearly unsupported* case and is treated as "allow".
  unsupported,

  /// The Android probe itself failed (MethodChannel error / missing
  /// implementation). This is an *ambiguous* result and must NOT be treated
  /// as "off" by the guard — see [DeveloperModeGuard] fail-closed policy.
  error,
}

/// Reads the Android `Settings.Global.DEVELOPMENT_SETTINGS_ENABLED` system
/// setting through a [MethodChannel] implemented in `MainActivity.kt`.
///
/// This intentionally does not rely on USB debugging state and does not
/// hardcode any result — it always reflects the live system setting.
class DeveloperOptionsDetector {
  const DeveloperOptionsDetector();

  static const MethodChannel _channel =
      MethodChannel('com.innoplix.erupaiya/developer_mode');

  /// Returns the current Developer Options status.
  ///
  /// Never throws: any platform/channel failure is surfaced as
  /// [DeveloperOptionsStatus.error] so the caller can apply a fail-closed
  /// policy instead of silently granting access.
  Future<DeveloperOptionsStatus> detect() async {
    if (kIsWeb || !Platform.isAndroid) {
      return DeveloperOptionsStatus.unsupported;
    }
    try {
      final int? value = await _channel.invokeMethod<int>(
        'getDevelopmentSettingsEnabled',
      );
      if (value == null) {
        // No value returned is ambiguous — do not assume "off".
        return DeveloperOptionsStatus.error;
      }
      return value == 1
          ? DeveloperOptionsStatus.on
          : DeveloperOptionsStatus.off;
    } on PlatformException {
      return DeveloperOptionsStatus.error;
    } on MissingPluginException {
      return DeveloperOptionsStatus.error;
    } catch (_) {
      return DeveloperOptionsStatus.error;
    }
  }

  /// Opens the Android Developer Options screen directly
  /// (`Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS`).
  ///
  /// Returns true when the intent was dispatched. Falls back to the generic
  /// app-settings screen when the developer-settings intent is unavailable.
  Future<bool> openDeveloperSettings() async {
    if (kIsWeb || !Platform.isAndroid) {
      return false;
    }
    try {
      final bool? opened = await _channel.invokeMethod<bool>(
        'openDeveloperSettings',
      );
      return opened ?? false;
    } catch (_) {
      return false;
    }
  }
}
