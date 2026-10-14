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
  /// Warms the audio engine for [asset] so the first [play] call has minimal
  /// latency. Must never throw: preloading is best-effort.
  Future<void> preload(String asset);
  Future<void> dispose();
}

/// One `audioplayers` player per cue, so preloading the popup cue is not
/// undone by playing the spin cue. [stop] stops every cue, which keeps the
/// one-cue-at-a-time rule of [SpinSoundController].
class _AudioplayersSpinAudio implements SpinAudioPlayer {
  final Map<String, AudioPlayer> _players = {};
  final Set<String> _loaded = {};

  Future<AudioPlayer> _playerFor(String asset) async {
    final existing = _players[asset];
    if (existing != null) return existing;
    final player = AudioPlayer();
    _players[asset] = player;
    await player.setReleaseMode(ReleaseMode.stop);
    return player;
  }

  @override
  Future<void> disableLooping() => Future.wait(
        _players.values.map((p) => p.setReleaseMode(ReleaseMode.stop)),
      );

  @override
  Future<void> stop() => Future.wait(_players.values.map((p) => p.stop()));

  @override
  Future<void> play(String asset) async {
    final player = await _playerFor(asset);
    if (_loaded.contains(asset)) {
      await player.seek(Duration.zero);
      await player.resume();
      return;
    }
    await player.play(AssetSource(asset));
    _loaded.add(asset);
  }

  @override
  Future<void> preload(String asset) async {
    final player = await _playerFor(asset);
    await player.setSource(AssetSource(asset));
    _loaded.add(asset);
  }

  @override
  Future<void> dispose() async {
    final players = _players.values.toList();
    _players.clear();
    _loaded.clear();
    await Future.wait(players.map((p) => p.dispose()));
  }
}

/// Dedicated audio player for the Spin & Win screen.
///
/// Deliberately separate from `PaymentSoundController`: that helper is tuned for
/// the payment thank-you flow and must stay untouched. Spin & Win has two cues -
/// the wheel spin and the result popup - and every request stops whatever is
/// already playing before starting, so a cue can never start on top of
/// another and repeated taps never overlap.
///
/// Timing contract: the wheel cue measures 5100ms and [kSpinWheelDuration] is
/// set to exactly that; the wheel starts once the cue has started (see
/// [cueStartTimeout]) and comes to rest as its sound ends. The popup cue
/// (1560ms) is a separate clip started together with the popup.
class SpinSoundController {
  SpinSoundController._();

  /// The 5100ms wheel cue, started on the spin tap. Swapping this file needs no
  /// manifest change (`assets/sounds/` is already registered in `pubspec.yaml`)
  /// plus a full rebuild/restart to re-bundle it - but its duration must be
  /// re-measured with `afinfo` and `kSpinCueDurationMs` updated to match, or the
  /// wheel will stop out of time with its own sound.
  static const String spinAsset = 'sounds/spinandwinfile.mp3';

  /// The 1560ms result cue, started when the popup appears. Same re-measurement
  /// rule applies via `kSpinPopupCueDurationMs`.
  static const String popupAsset = 'sounds/spinandwinpopup.mp3';

  static SpinAudioPlayer? _player;

  /// Bumped per request so a superseded cue can never start after a newer one
  /// has already claimed the shared player.
  static int _generation = 0;

  @visibleForTesting
  static SpinAudioPlayer Function()? playerFactory;

  /// Longest wait for a cue to actually start before the animation it
  /// accompanies goes ahead without it, so a stalled audio platform never
  /// freezes the wheel or the popup.
  static const Duration cueStartTimeout = Duration(milliseconds: 300);

  /// Plays the wheel cue from 0ms. Completes once playback has started.
  static Future<void> playOnSpin() => _play(spinAsset);

  /// Warms the wheel cue so the first spin starts without load latency.
  static Future<void> preloadSpin() => _preload(spinAsset);

  /// Plays the result cue from 0ms. Called the instant the popup is shown.
  static Future<void> playOnPopup() => _play(popupAsset);

  /// Warms the audio engine for the popup cue. Should be called once on
  /// screen mount so the OS audio buffer is ready before the spin finishes.
  /// Fire-and-forget: errors are silently discarded so the spin flow is never
  /// affected by a failed preload.
  static Future<void> preloadPopup() => _preload(popupAsset);

  static Future<void> _preload(String asset) async {
    try {
      final player =
          _player ??= (playerFactory?.call() ?? _AudioplayersSpinAudio());
      await player.preload(asset);
    } catch (_) {
      // Preloading is best-effort. A failure here must never surface to the UI.
    }
  }

  static Future<void> _play(String asset) async {
    final generation = ++_generation;
    try {
      final player =
          _player ??= (playerFactory?.call() ?? _AudioplayersSpinAudio());
      await player.disableLooping();
      await player.stop();
      // A newer cue took over while we were preparing: it owns the player now.
      if (generation != _generation) return;
      await player.play(asset);
    } catch (_) {
      // The cues are decorative - a missing asset or a platform failure must
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
