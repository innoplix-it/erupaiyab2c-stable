import 'package:e_rupaiya/features/developer_mode/controllers/developer_mode_guard.dart';
import 'package:e_rupaiya/features/developer_mode/services/developer_options_detector.dart';
import 'package:flutter_test/flutter_test.dart';

/// Configurable fake that lets each validation-matrix case be exercised
/// without a real Android platform channel.
class _FakeDetector implements DeveloperOptionsDetector {
  _FakeDetector(this.status);

  DeveloperOptionsStatus status;
  int detectCalls = 0;

  @override
  Future<DeveloperOptionsStatus> detect() async {
    detectCalls++;
    return status;
  }

  @override
  Future<bool> openDeveloperSettings() async => true;
}

void main() {
  const String splash = '/splash';
  const String dev = '/developer-mode-enabled';

  group('developerModeGuardRedirect (validation matrix)', () {
    test('CASE A: flag FALSE bypasses protection even when blocked', () {
      expect(
        developerModeGuardRedirect(
          featureFlagEnabled: false,
          lockState: DeveloperModeLockState.blocked,
          location: '/',
          splashRoute: splash,
          developerRoute: dev,
        ),
        isNull,
      );
    });

    test('CASE B/C: flag TRUE + blocked collapses every normal route to lock', () {
      for (final location in ['/', '/home-search', '/transactions', '/electricity']) {
        expect(
          developerModeGuardRedirect(
            featureFlagEnabled: true,
            lockState: DeveloperModeLockState.blocked,
            location: location,
            splashRoute: splash,
            developerRoute: dev,
          ),
          dev,
          reason: 'blocked must redirect $location to the lock route',
        );
      }
    });

    test('CASE C: blocked on the lock route stays put (no redirect loop)', () {
      expect(
        developerModeGuardRedirect(
          featureFlagEnabled: true,
          lockState: DeveloperModeLockState.blocked,
          location: dev,
          splashRoute: splash,
          developerRoute: dev,
        ),
        isNull,
      );
    });

    test('CASE B: flag TRUE + allowed leaves normal routes untouched', () {
      expect(
        developerModeGuardRedirect(
          featureFlagEnabled: true,
          lockState: DeveloperModeLockState.allowed,
          location: '/',
          splashRoute: splash,
          developerRoute: dev,
        ),
        isNull,
      );
    });

    test('CASE G: allowed on the lock route vacates back to splash', () {
      expect(
        developerModeGuardRedirect(
          featureFlagEnabled: true,
          lockState: DeveloperModeLockState.allowed,
          location: dev,
          splashRoute: splash,
          developerRoute: dev,
        ),
        splash,
      );
    });

    test('CASE E: deep link to a normal route while pending is held on splash', () {
      expect(
        developerModeGuardRedirect(
          featureFlagEnabled: true,
          lockState: DeveloperModeLockState.pending,
          location: '/',
          splashRoute: splash,
          developerRoute: dev,
        ),
        splash,
      );
    });

    test('pending on splash / lock route does not loop', () {
      expect(
        developerModeGuardRedirect(
          featureFlagEnabled: true,
          lockState: DeveloperModeLockState.pending,
          location: splash,
          splashRoute: splash,
          developerRoute: dev,
        ),
        isNull,
      );
      expect(
        developerModeGuardRedirect(
          featureFlagEnabled: true,
          lockState: DeveloperModeLockState.pending,
          location: dev,
          splashRoute: splash,
          developerRoute: dev,
        ),
        isNull,
      );
    });
  });

  group('DeveloperModeGuard.recheck', () {
    test('off -> allowed (CASE B)', () async {
      final guard = DeveloperModeGuard(detector: _FakeDetector(DeveloperOptionsStatus.off));
      await guard.recheck();
      expect(guard.lockState, DeveloperModeLockState.allowed);
      expect(guard.isBlocked, isFalse);
    });

    test('on -> blocked (CASE C)', () async {
      final guard = DeveloperModeGuard(detector: _FakeDetector(DeveloperOptionsStatus.on));
      await guard.recheck();
      expect(guard.lockState, DeveloperModeLockState.blocked);
      expect(guard.isBlocked, isTrue);
    });

    test('unsupported platform -> allowed (clearly unsupported)', () async {
      final guard =
          DeveloperModeGuard(detector: _FakeDetector(DeveloperOptionsStatus.unsupported));
      await guard.recheck();
      expect(guard.lockState, DeveloperModeLockState.allowed);
    });

    test('detector error -> blocked, fail-closed (CASE I)', () async {
      final guard = DeveloperModeGuard(detector: _FakeDetector(DeveloperOptionsStatus.error));
      await guard.recheck();
      expect(guard.lockState, DeveloperModeLockState.blocked);
      expect(guard.isBlocked, isTrue);
    });

    test('notifies listeners only on a real state change', () async {
      final guard = DeveloperModeGuard(detector: _FakeDetector(DeveloperOptionsStatus.on));
      var notifications = 0;
      guard.addListener(() => notifications++);
      await guard.recheck(); // pending -> blocked
      await guard.recheck(); // blocked -> blocked (no notify)
      expect(notifications, 1);
    });
  });

  group('DeveloperModeGuard.recheckIfLocked (lifecycle re-check)', () {
    test('does NOT re-probe when already allowed', () async {
      final detector = _FakeDetector(DeveloperOptionsStatus.off);
      final guard = DeveloperModeGuard(detector: detector);
      await guard.recheck();
      detector.detectCalls = 0;
      await guard.recheckIfLocked();
      expect(detector.detectCalls, 0);
    });

    test('re-probes when locked (returning from settings)', () async {
      final detector = _FakeDetector(DeveloperOptionsStatus.on);
      final guard = DeveloperModeGuard(detector: detector);
      await guard.recheck();
      expect(guard.isBlocked, isTrue);

      // User disables Developer Options in settings, then resumes.
      detector.status = DeveloperOptionsStatus.off;
      await guard.recheckIfLocked();
      expect(detector.detectCalls, greaterThanOrEqualTo(2));
      expect(guard.lockState, DeveloperModeLockState.allowed);
    });

    test('stays blocked if still ON after resume (CASE F)', () async {
      final detector = _FakeDetector(DeveloperOptionsStatus.on);
      final guard = DeveloperModeGuard(detector: detector);
      await guard.recheck();
      await guard.recheckIfLocked(); // still ON
      expect(guard.lockState, DeveloperModeLockState.blocked);
    });
  });
}
