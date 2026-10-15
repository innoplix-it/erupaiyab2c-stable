import 'dart:async';
import 'dart:math' as math;

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

  /// Spin cue playhead reports, served in order (the last one repeats).
  /// Empty: position unknown.
  List<Duration> playheads = [];
  int positionQueries = 0;
  bool positionThrows = false;

  @override
  Future<Duration?> position(String asset) async {
    _record('position:$asset');
    if (positionThrows) throw StateError('no position');
    if (playheads.isEmpty) return null;
    final i = math.min(positionQueries++, playheads.length - 1);
    return playheads[i];
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
    test('wheel timing matches the spin cue\'s measured clicks', () {
      expect(kSpinCueDurationMs, 5100, reason: 'measured with afinfo');
      expect(kSpinPopupCueDurationMs, 1560, reason: 'measured with afinfo');
      expect(kSpinCueLastClickMs, 4922, reason: 'measured from decoded PCM');
      expect(kSpinCueClickMs.first, 31, reason: 'first audible click');
      expect(kSpinCueClickMs.last, kSpinCueLastClickMs);
      expect(
        kSpinCueClickMs.sublist(kSpinCueClickMs.length - 4),
        [3837, 4236, 4565, 4922],
        reason: 'the four distinct clicks of the final slowdown',
      );
      expect(
        kSpinWheelDuration,
        const Duration(milliseconds: kSpinCueDurationMs),
        reason: 'the wheel settles while the last click rings out',
      );
    });

    group('SpinCuePath', () {
      const n = 8;
      const slice = 2 * math.pi / n;
      double targetAngleFor(int index) => (n - index) * slice - slice / 2;
      // Slice i spans [i, i + 1) slices clockwise from the top pointer, and
      // a positive rotation turns the wheel clockwise.
      int sliceUnderPointer(double rotation) =>
          ((-rotation) % (2 * math.pi) / slice).floor() % n;

      final starts = [0.0, for (var i = 0; i < n; i++) targetAngleFor(i)];
      final finals = kSpinCueClickMs
          .sublist(kSpinCueClickMs.length - kSpinFinalClickCount);
      final lastFour = kSpinCueClickMs.sublist(kSpinCueClickMs.length - 4);

      /// Every change of the slice under the pointer in (from, to], sampled
      /// at 1ms, as (time, slice entered).
      List<(int, int)> transitions(SpinCuePath path, int from, int to) {
        final out = <(int, int)>[];
        var current = sliceUnderPointer(path.rotationAt(from.toDouble()));
        for (var t = from + 1; t <= to; t++) {
          final s = sliceUnderPointer(path.rotationAt(t.toDouble()));
          if (s != current) out.add((t, s));
          current = s;
        }
        return out;
      }

      for (final start in starts) {
        for (var index = 0; index < n; index++) {
          final label = 'start ${start.toStringAsFixed(2)} -> slice $index';
          final path = SpinCuePath.plan(
            start: start,
            targetAngle: targetAngleFor(index),
            sliceCount: n,
          );

          test('$label: begins in place and rests on the selected centre', () {
            expect(path.rotationAt(0), start);
            expect(path.rotationAt(kSpinCueDurationMs.toDouble()), path.end);
            expect(path.rotationAt(kSpinCueDurationMs + 1000.0), path.end);
            expect(sliceUnderPointer(path.end), index);
            final offCentre =
                (path.end - targetAngleFor(index)) % (2 * math.pi);
            expect(
                math.min(offCentre, 2 * math.pi - offCentre), lessThan(1e-9));
            final turns = (path.end - start) / (2 * math.pi);
            expect(turns, inInclusiveRange(6, 8));
          });

          test('$label: never runs backwards', () {
            var last = path.rotationAt(0);
            for (var t = 1; t <= kSpinCueDurationMs; t++) {
              final r = path.rotationAt(t.toDouble());
              expect(r, greaterThanOrEqualTo(last - 1e-9), reason: '${t}ms');
              last = r;
            }
          });

          test('$label: last four clicks are exactly four slice changes', () {
            // Slice under the pointer just before the first of the four.
            final before =
                sliceUnderPointer(path.rotationAt(lastFour.first - 1.0));
            expect(before, (index + 4) % n);

            final changes = transitions(path, lastFour.first - 1, 6000);
            expect(changes, hasLength(4),
                reason: 'four clicks must show four slice changes, not three');
            for (var k = 0; k < 4; k++) {
              final (t, entered) = changes[k];
              expect(t, inInclusiveRange(lastFour[k], lastFour[k] + 1),
                  reason: 'change ${k + 1} lands on click ${lastFour[k]}ms');
              expect(entered, (before - k - 1) % n,
                  reason: 'each click advances exactly one slice');
            }
            expect(changes.last.$2, index, reason: 'the 4th enters the reward');
            expect(changes.last.$1, lessThanOrEqualTo(kSpinCueLastClickMs + 1),
                reason: 'no fifth change after the last click');
          });

          test('$label: every final click is one slice change', () {
            final changes =
                transitions(path, finals.first - 1, kSpinCueDurationMs);
            expect(changes.map((c) => c.$1).toList(), [
              for (var k = 0; k < finals.length; k++)
                inInclusiveRange(finals[k], finals[k] + 1),
            ]);
            expect(changes.map((c) => c.$2).toSet(),
                hasLength(kSpinFinalClickCount));
          });

          test('$label: speed follows the opening, rattle and ending', () {
            double slicesBetween(int a, int b) =>
                (path.rotationAt(b.toDouble()) -
                    path.rotationAt(a.toDouble())) /
                slice;
            // Already moving at the opening click rate, no wind-up.
            final opening = slicesBetween(0, 10) / 10;
            final openingClickRate =
                1 / (kSpinCueClickMs[1] - kSpinCueClickMs[0]);
            expect(opening, greaterThan(openingClickRate * 0.5));
            // About one slice per click through the fast rattle.
            final rattleClicks = kSpinCueClickMs.indexOf(2357);
            final rattle = slicesBetween(kSpinCueClickMs.first, 2357);
            expect(rattle / rattleClicks, inInclusiveRange(0.9, 1.1));
            // Settles only the last half slice after the last click and
            // comes to rest as the cue ends.
            expect(
              slicesBetween(kSpinCueLastClickMs, kSpinCueDurationMs),
              moreOrLessEquals(0.5, epsilon: 1e-9),
            );
            expect(
              slicesBetween(kSpinCueDurationMs - 1, kSpinCueDurationMs),
              lessThan(0.001),
            );
          });
        }
      }
    });

    group('spinCuePlayhead', () {
      test('is null before any cue has a player', () async {
        expect(await SpinSoundController.spinCuePlayhead(), isNull);
      });

      test('is null when the platform cannot report a position', () async {
        await SpinSoundController.playOnSpin();
        expect(await SpinSoundController.spinCuePlayhead(), isNull);
        expect(audio.calls.last, 'position:${SpinSoundController.spinAsset}');
      });

      test('is null when reading the position fails', () async {
        await SpinSoundController.playOnSpin();
        audio.positionThrows = true;
        expect(await SpinSoundController.spinCuePlayhead(), isNull);
      });

      test('waits until the cue is audibly advancing and returns where it is',
          () async {
        await SpinSoundController.playOnSpin();
        audio.playheads = [
          Duration.zero,
          Duration.zero,
          Duration.zero,
          const Duration(milliseconds: 42),
        ];
        expect(
          await SpinSoundController.spinCuePlayhead(),
          const Duration(milliseconds: 42),
        );
        expect(audio.positionQueries, 4);
      });

      test('ignores a stale position from the previous spin', () async {
        await SpinSoundController.playOnSpin();
        audio.playheads = [
          const Duration(milliseconds: kSpinCueDurationMs),
          Duration.zero,
          const Duration(milliseconds: 16),
        ];
        expect(
          await SpinSoundController.spinCuePlayhead(),
          const Duration(milliseconds: 16),
        );
      });

      test('gives up after cueSyncTimeout if the cue never starts', () async {
        await SpinSoundController.playOnSpin();
        audio.playheads = [Duration.zero];
        final watch = Stopwatch()..start();
        expect(await SpinSoundController.spinCuePlayhead(), isNull);
        expect(watch.elapsed,
            greaterThanOrEqualTo(SpinSoundController.cueSyncTimeout));
      });
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
      audio.gate =
          (call) => call == 'stop' ? gate.future : Future<void>.value();

      final first = SpinSoundController.playOnSpin();
      final second = SpinSoundController.playOnSpin();
      gate.complete();
      await Future.wait([first, second]);

      expect(audio.playCount, 1,
          reason: 'a superseded spin must not double up');
    });

    test('a popup cue arriving mid-spin wins and the stale spin stays silent',
        () async {
      final gate = Completer<void>();
      audio.gate =
          (call) => call == 'stop' ? gate.future : Future<void>.value();

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

    test('preloadPopup warms the popup asset without triggering play',
        () async {
      await SpinSoundController.preloadPopup();

      expect(audio.preloadCount, 1,
          reason: 'exactly one preload call is expected');
      expect(
        audio.calls,
        contains('preload:${SpinSoundController.popupAsset}'),
      );
      // preload must NOT issue a play - the popup cue is reserved for the
      // exact moment the result popup becomes visible.
      expect(audio.playCount, 0, reason: 'preloading must not start playback');
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
