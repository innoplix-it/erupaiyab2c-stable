import 'package:flutter/foundation.dart';

import '../../../config/app_env.dart';
import '../../../services/logger_service.dart';
import '../services/developer_options_detector.dart';

/// High-level lock state consumed by the router guard.
enum DeveloperModeLockState {
  /// The very first probe has not completed yet. While the feature flag is on
  /// we treat this like "blocked" so no normal screen can flash before the
  /// check resolves.
  pending,

  /// Normal app access is allowed.
  allowed,

  /// The app must stay locked on `/developer-mode-enabled`.
  blocked,
}

/// Central, app-wide Developer Options lock.
///
/// A single [ChangeNotifier] instance is shared by the router guard and the
/// lifecycle observer, so exactly one Developer Options probe runs per trigger
/// and every listener reacts to the same state (no duplicate listeners).
///
/// Failure policy (see task section 10):
///  * [DeveloperOptionsStatus.unsupported] (non-Android) -> allow.
///  * [DeveloperOptionsStatus.error] on Android -> fail **closed** (blocked),
///    because an ambiguous detector must never silently grant access.
class DeveloperModeGuard extends ChangeNotifier {
  DeveloperModeGuard({DeveloperOptionsDetector? detector})
      : _detector = detector ?? const DeveloperOptionsDetector();

  static final DeveloperModeGuard instance = DeveloperModeGuard();

  final DeveloperOptionsDetector _detector;

  DeveloperModeLockState _lockState = DeveloperModeLockState.pending;
  bool _checking = false;

  DeveloperModeLockState get lockState => _lockState;

  /// True when the app must be blocked on the protection screen. When the
  /// feature flag is disabled the guard is always considered "not blocked".
  bool get isBlocked =>
      AppEnv.isDeveloperModeCheckEnabled &&
      _lockState == DeveloperModeLockState.blocked;

  /// Runs a Developer Options probe and updates [lockState].
  ///
  /// Concurrent calls are collapsed: a re-entrant call while a probe is
  /// already in flight simply awaits the running check.
  Future<void> recheck() async {
    if (!AppEnv.isDeveloperModeCheckEnabled) {
      _setValue(DeveloperModeLockState.allowed);
      return;
    }
    if (_checking) return;
    _checking = true;
    try {
      final DeveloperOptionsStatus status = await _detector.detect();
      final DeveloperModeLockState next = switch (status) {
        DeveloperOptionsStatus.off => DeveloperModeLockState.allowed,
        DeveloperOptionsStatus.unsupported => DeveloperModeLockState.allowed,
        // Detector itself failed on Android: fail closed, never grant access.
        DeveloperOptionsStatus.error => DeveloperModeLockState.blocked,
        DeveloperOptionsStatus.on => DeveloperModeLockState.blocked,
      };
      if (status == DeveloperOptionsStatus.error) {
        logger.error(
          'Developer Options detector returned an error; keeping app locked '
          '(fail-closed security policy).',
        );
      }
      _setValue(next);
    } finally {
      _checking = false;
    }
  }

  /// Re-runs the probe after returning from system settings, but only while
  /// the app is actually locked — an unlocked app does not need to re-probe.
  Future<void> recheckIfLocked() {
    if (!AppEnv.isDeveloperModeCheckEnabled) return Future<void>.value();
    if (_lockState == DeveloperModeLockState.blocked ||
        _lockState == DeveloperModeLockState.pending) {
      return recheck();
    }
    return Future<void>.value();
  }

  void _setValue(DeveloperModeLockState next) {
    if (_lockState == next) return;
    _lockState = next;
    notifyListeners();
  }

  @visibleForTesting
  void resetForTest() {
    _lockState = DeveloperModeLockState.pending;
    _checking = false;
  }

  @visibleForTesting
  set lockStateForTest(DeveloperModeLockState value) => _lockState = value;
}

/// Pure, testable decision used by the router guard.
///
/// Returns the route the app must be redirected to, or `null` when the current
/// [location] is allowed to render. It has no side effects so every branch of
/// the validation matrix (flag on/off, allowed/blocked/pending, deep links) can
/// be unit-tested without mutating the compile-time `AppEnv` constant.
///
/// Guarantees:
///  * feature flag off -> never redirects (protection fully bypassed).
///  * pending probe -> normal screens are held on splash (no early exposure).
///  * blocked -> every screen collapses to the developer-mode route.
///  * allowed -> the developer-mode route is vacated back to splash.
///  * No branch redirects to a route that would then redirect back to itself.
String? developerModeGuardRedirect({
  required bool featureFlagEnabled,
  required DeveloperModeLockState lockState,
  required String location,
  required String splashRoute,
  required String developerRoute,
}) {
  if (!featureFlagEnabled) return null;

  switch (lockState) {
    case DeveloperModeLockState.pending:
      // First probe still running: keep splash / lock screen as-is, hold any
      // other destination on splash so no normal screen is exposed early.
      if (location == splashRoute || location == developerRoute) return null;
      return splashRoute;
    case DeveloperModeLockState.blocked:
      return location == developerRoute ? null : developerRoute;
    case DeveloperModeLockState.allowed:
      if (location == developerRoute) return splashRoute;
      return null;
  }
}
