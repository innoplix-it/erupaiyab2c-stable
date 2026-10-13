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
  Future<void> dispose() async {
    _record('dispose');
    await gate?.call('dispose');
  }

  int get playCount => calls.where((c) => c.startsWith('play:')).length;
  int get stopCount => calls.where((c) => c == 'stop').length;
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
    test('wheel duration is derived from the measured 5736ms cue', () {
      // Guards the bug class where the cue length is assumed: the wheel stops
      // early enough that the popup arrives with the sound's last 2 seconds
      // still playing, and the clip then ends naturally.
      expect(kSpinCueDurationMs, 5736, reason: 'measured with afinfo');
      expect(kSpinPopupTailMs, 2000);
      expect(kSpinWheelDuration, const Duration(milliseconds: 3736));
      expect(
        kSpinWheelDuration.inMilliseconds + kSpinPopupTailMs,
        equals(kSpinCueDurationMs),
        reason: 'wheel stop + audible tail must equal the cue length',
      );
    });

    test('stops any previous playback before starting the new cue', () async {
      await SpinSoundController.playOnSpin();

      expect(audio.calls, [
        'disableLooping',
        'stop',
        'play:${SpinSoundController.asset}',
      ]);
    });

    test('every spin gets its own sound - repeated spins each start one clip',
        () async {
      await SpinSoundController.playOnSpin();
      await SpinSoundController.playOnSpin();
      await SpinSoundController.playOnSpin();

      expect(audio.stopCount, 3, reason: 'each spin must cancel the last cue');
      expect(audio.playCount, 3, reason: 'no spin may end up silent');
    });

    test('overlapping requests play only one cue, never two at once',
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

    test('a failing player never throws into the spin flow', () async {
      audio.gate = (call) async {
        throw Exception('audio platform unavailable');
      };

      await expectLater(
        SpinSoundController.playOnSpin(),
        completes,
        reason: 'the cue is decorative and must not break a spin',
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
  });
}
