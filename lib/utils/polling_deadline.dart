import 'dart:async';

/// Abstraction for polling deadline to enable deterministic testing.
abstract class PollingDeadline {
  /// Returns true if the deadline has been exceeded.
  bool get isExceeded;

  /// Returns the remaining duration before the deadline.
  Duration get remaining;

  /// Delay function to use (real Future.delayed or fake for testing).
  Future<void> delay(Duration duration);

  /// Creates a real-time deadline with the given duration.
  factory PollingDeadline.realtime(Duration duration) {
    return _RealtimePollingDeadline(duration);
  }

  /// Creates a fake deadline for testing with controllable time.
  factory PollingDeadline.fake(Duration duration, {FakeClock? clock}) {
    return _FakePollingDeadline(duration, clock: clock ?? FakeClock());
  }
}

/// Real-time implementation using Stopwatch.
class _RealtimePollingDeadline implements PollingDeadline {
  _RealtimePollingDeadline(this.duration) {
    _stopwatch.start();
  }

  final Duration duration;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  bool get isExceeded => _stopwatch.elapsed >= duration;

  @override
  Duration get remaining {
    final elapsed = _stopwatch.elapsed;
    if (elapsed >= duration) return Duration.zero;
    return duration - elapsed;
  }

  @override
  Future<void> delay(Duration duration) async {
    await Future.delayed(duration);
  }
}

/// Fake implementation for testing with controllable time.
class _FakePollingDeadline implements PollingDeadline {
  _FakePollingDeadline(this.duration, {required this.clock}) {
    _startTime = clock.now;
  }

  final Duration duration;
  final FakeClock clock;
  late final Duration _startTime;

  @override
  bool get isExceeded => clock.now - _startTime >= duration;

  @override
  Duration get remaining {
    final elapsed = clock.now - _startTime;
    if (elapsed >= duration) return Duration.zero;
    return duration - elapsed;
  }

  @override
  Future<void> delay(Duration duration) async {
    // In fake mode, advance the clock and return immediately
    clock.elapse(duration);
  }
}

/// Fake clock for deterministic testing of time-based behavior.
class FakeClock {
  Duration _now = Duration.zero;

  /// Current time in this fake clock.
  Duration get now => _now;

  /// Advances the clock by the given duration.
  void elapse(Duration duration) {
    _now += duration;
  }

  /// Resets the clock to zero.
  void reset() {
    _now = Duration.zero;
  }
}
