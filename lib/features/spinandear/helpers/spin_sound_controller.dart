import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Audio backend seam for [SpinSoundController].
///
/// The real implementation wraps `audioplayers`; tests substitute a recorder so
/// the overlap-prevention ordering can be asserted without a platform player.
abstract interface class SpinAudioPlayer {
  Future<void> disableLooping();
  Future<void> stop();
  Future<void> play(String asset);
  Future<void> dispose();
}

class _AudioplayersSpinAudio implements SpinAudioPlayer {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> disableLooping() => _player.setReleaseMode(ReleaseMode.stop);

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> play(String asset) => _player.play(AssetSource(asset));

  @override
  Future<void> dispose() => _player.dispose();
}

/// Dedicated spin-cue player for the Spin & Win screen.
///
/// Deliberately separate from `PaymentSoundController`: that helper is tuned for
/// the payment thank-you flow and must stay untouched. Here a single shared
/// clip is used and every request stops the previous playback before starting,
/// so two cues can never overlap and each valid spin is guaranteed its sound.
///
/// Timing contract: the cue measures 5736ms and [kSpinWheelDuration] is derived
/// from it as 5736 - 2000 = 3736ms. The clip is started once, on the spin tap,
/// so its first 3736ms run under the spinning wheel and its final 2 seconds are
/// still playing when the wheel stops and the result popup appears, finishing
/// naturally on their own. The cue is never seeked, restarted or replayed.
class SpinSoundController {
  SpinSoundController._();

  /// The 5736ms cue. Swapping this file needs no manifest change (the
  /// `assets/sounds/` folder is already registered in `pubspec.yaml`) plus a
  /// full rebuild/restart to re-bundle it - but the replacement's duration must
  /// be re-measured with `afinfo` and `kSpinCueDurationMs` updated to match,
  /// otherwise the popup drifts away from the sound's tail.
  static const String asset = 'sounds/spinand2winsound.mp3.mpeg';

  static SpinAudioPlayer? _player;

  /// Bumped per request so a superseded spin can never start a clip after a
  /// newer one has already claimed the shared player.
  static int _generation = 0;

  @visibleForTesting
  static SpinAudioPlayer Function()? playerFactory;

  /// Plays the cue from 0ms. Called the instant the wheel starts turning.
  static Future<void> playOnSpin() async {
    final generation = ++_generation;
    try {
      final player =
          _player ??= (playerFactory?.call() ?? _AudioplayersSpinAudio());
      await player.disableLooping();
      await player.stop();
      // A newer spin took over while we were preparing: it owns the player now.
      if (generation != _generation) return;
      await player.play(asset);
    } catch (_) {
      // The cue is decorative - a missing asset or a platform failure must
      // never break the spin or its result flow.
    }
  }

  static void dispose() {
    final player = _player;
    _player = null;
    player?.dispose();
  }

  @visibleForTesting
  static void reset() {
    _generation = 0;
    _player = null;
    playerFactory = null;
  }
}
