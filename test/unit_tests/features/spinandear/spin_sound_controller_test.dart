import 'dart:async';

import 'package:e_rupaiya/features/spinandear/components/spin_wheel.dart';
import 'package:e_rupaiya/features/spinandear/helpers/spin_sound_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the calls [SpinSoundController] makes so playback ordering — the
/// whole point of the helper — can be asserted without a real audio platform.
class _RecordingSpinAudio implements SpinAudioPlayer {
  final List<String> calls = [];

  /// Optional hook to hold a call open and exercise concurrent requests.
  Future<void> Function(String call)? gate;

  void _record(String call) => calls.add(call);

  @override
  Future<void> disableLooping() async {
    _record('disableLooping');
    await gate?.call('disableLooping');
  }

  @override
  Future<void> stop() async {
    _record('stop');
    await gate?.call('stop');
  }

  @override
  Future<void> play(String asset) async {
    _record('play:$asset');
    await gate?.call('play');
  }

  @override
  Future<void> preload(String asset) async {
    _record('preload:$asset');
    await gate?.call('preload');
  }

  @override
  Future<void> dispose() async {
    _record('dispose');
    await gate?.call('dispose');
  }

  int get playCount => calls.where((c) => c.startsWith('play:')).length;
  int get stopCount => calls.where((c) => c == 'stop').length;
  int get preloadCount => calls.where((c) => c.startsWith('preload:')).length;
}

void main() {
  late _RecordingSpinAudio audio;

  setUp(() {
    SpinSoundController.reset();
    audio = _RecordingSpinAudio();
    SpinSoundController.playerFactory = () => audio;
  });

  tearDown(() {
    SpinSoundController.reset();
  });

  group('SpinSoundController', () {
    test('wheel duration equals the measured 5100ms spin cue', () {

      expect(kSpinCueDurationMs, 5100, reason: 'measured with afinfo');
      expect(kSpinPopupCueDurationMs, 1560, reason: 'measured with afinfo');
      expect(kSpinWheelDuration, const Duration(milliseconds: 5100));
      expect(
        kSpinWheelDuration.inMilliseconds,
        equals(kSpinCueDurationMs),
        reason: 'the wheel must stop in time with its own sound',
      );
    });

    test('the two cues point at different assets', () {
      expect(SpinSoundController.spinAsset, 'sounds/spinandwinfile.mp3');
      expect(SpinSoundController.popupAsset, 'sounds/spinandwinpopup.mp3');
      expect(SpinSoundController.spinAsset,
          isNot(equals(SpinSoundController.popupAsset)));
    });

    test('stops any previous playback before starting the new cue', () async {
      await SpinSoundController.playOnSpin();

      expect(audio.calls, [
        'disableLooping',
        'stop',
        'play:${SpinSoundController.spinAsset}',
      ]);
    });

    test('the popup cue stops the spin cue before playing itself', () async {
      await SpinSoundController.playOnSpin();
      await SpinSoundController.playOnPopup();

      expect(audio.calls, [
        'disableLooping',
        'stop',
        'play:${SpinSoundController.spinAsset}',
        'disableLooping',
        'stop',
        'play:${SpinSoundController.popupAsset}',
      ]);
      expect(audio.playCount, 2);
      expect(audio.stopCount, 2);
    });

    test('every spin gets its own sound - repeated spins each start one clip',
        () async {
      await SpinSoundController.playOnSpin();
      await SpinSoundController.playOnSpin();
      await SpinSoundController.playOnSpin();

      expect(audio.stopCount, 3, reason: 'each spin must cancel the last cue');
      expect(audio.playCount, 3, reason: 'no spin may end up silent');
    });

    test('overlapping spin requests play only one cue, never two at once',
        () async {
      // Hold the prepare phase open so a second tap arrives mid-flight.
      final gate = Completer<void>();
      audio.gate = (call) => call == 'stop' ? gate.future : Future<void>.value();

      final first = SpinSoundController.playOnSpin();
      final second = SpinSoundController.playOnSpin();
      gate.complete();
      await Future.wait([first, second]);

      expect(audio.playCount, 1, reason: 'a superseded spin must not double up');
    });

    test('a popup cue arriving mid-spin wins and the stale spin stays silent',
        () async {
      final gate = Completer<void>();
      audio.gate = (call) => call == 'stop' ? gate.future : Future<void>.value();

      final spin = SpinSoundController.playOnSpin();
      final popup = SpinSoundController.playOnPopup();
      gate.complete();
      await Future.wait([spin, popup]);

      expect(audio.playCount, 1, reason: 'only the newest cue may be heard');
      expect(audio.calls.last, 'play:${SpinSoundController.popupAsset}');
    });

    test('repeated popup requests never stack up', () async {
      await SpinSoundController.playOnPopup();
      await SpinSoundController.playOnPopup();

      expect(audio.playCount, 2);
      expect(
        audio.calls.where((c) => c == 'play:${SpinSoundController.popupAsset}'),
        hasLength(2),
      );
    });

    test('a failing player never throws into the spin flow', () async {
      audio.gate = (call) async {
        throw Exception('audio platform unavailable');
      };

      await expectLater(
        SpinSoundController.playOnSpin(),
        completes,
        reason: 'the cue is decorative and must not break a spin',
      );
      await expectLater(
        SpinSoundController.playOnPopup(),
        completes,
        reason: 'the popup cue must not break the result flow either',
      );
      expect(audio.playCount, 0);
    });

    test('dispose releases the player and a later spin rebuilds it', () async {
      await SpinSoundController.playOnSpin();
      SpinSoundController.dispose();

      expect(audio.calls, contains('dispose'));

      final rebuilt = _RecordingSpinAudio();
      SpinSoundController.playerFactory = () => rebuilt;
      await SpinSoundController.playOnSpin();

      expect(rebuilt.playCount, 1);
    });

    test('preloadPopup warms the popup asset without triggering play', () async {
      await SpinSoundController.preloadPopup();

      expect(audio.preloadCount, 1,
          reason: 'exactly one preload call is expected');
      expect(
        audio.calls,
        contains('preload:${SpinSoundController.popupAsset}'),
      );
      // preload must NOT issue a play - the popup cue is reserved for the
      // exact moment the result popup becomes visible.
      expect(audio.playCount, 0,
          reason: 'preloading must not start playback');
    });

    test('preloadSpin warms the spin asset without triggering play', () async {
      await SpinSoundController.preloadSpin();
      await SpinSoundController.preloadPopup();

      expect(audio.calls, [
        'preload:${SpinSoundController.spinAsset}',
        'preload:${SpinSoundController.popupAsset}',
      ]);
      expect(audio.playCount, 0);
    });

    test('a stalled cue start is bounded by cueStartTimeout', () async {
      audio.gate = (call) =>
          call == 'play' ? Completer<void>().future : Future<void>.value();
      final watch = Stopwatch()..start();
      await SpinSoundController.playOnSpin().timeout(
        SpinSoundController.cueStartTimeout,
        onTimeout: () {},
      );
      expect(
        watch.elapsed,
        lessThan(
          SpinSoundController.cueStartTimeout +
              const Duration(milliseconds: 200),
        ),
      );
      expect(audio.playCount, 1);
    });

    test('preloadPopup errors are silently swallowed', () async {
      audio.gate = (call) async {
        if (call == 'preload') throw Exception('platform unavailable');
      };

      await expectLater(
        SpinSoundController.preloadPopup(),
        completes,
        reason: 'a preload failure must never surface to the UI',
      );
      // The spin and popup flows must still work after a failed preload.
      await SpinSoundController.playOnSpin();
      expect(audio.playCount, 1);
    });

    test(
        'playOnPopup after preloadPopup still stops any previous cue and '
        'plays exactly once', () async {
      await SpinSoundController.preloadPopup();
      await SpinSoundController.playOnSpin();
      await SpinSoundController.playOnPopup();

      // The popup cue must be the last play call.
      expect(audio.calls.last, 'play:${SpinSoundController.popupAsset}');
      expect(audio.playCount, 2, reason: 'spin cue + popup cue = 2 plays');
      // Each play must be preceded by a stop to prevent overlap.
      expect(audio.stopCount, 2);
    });
  });
}
