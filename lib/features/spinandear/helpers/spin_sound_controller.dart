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

  /// Current playback position of [asset]'s cue, or null if unknown.
  Future<Duration?> position(String asset);
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
  Future<Duration?> position(String asset) async =>
      _players[asset]?.getCurrentPosition();

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
/// Timing contract: the wheel cue measures 5100ms; its last click is at
/// [kSpinCueLastClickMs] (4922ms), when the reward slice reaches the pointer,
/// and [kSpinWheelDuration] ends with the cue as that click rings out. The
/// wheel starts once the cue has started (see [cueStartTimeout]) and is
/// keyframed on the cue's clicks ([SpinCuePath]).
/// The popup cue (1560ms) is a separate clip started together with the popup.
class SpinSoundController {
  SpinSoundController._();

  static const String spinAsset = 'sounds/spinandwinfile.mp3';

  static const String popupAsset = 'sounds/spinandwinpopup.mp3';

  static SpinAudioPlayer? _player;

  static int _generation = 0;

  @visibleForTesting
  static SpinAudioPlayer Function()? playerFactory;

  static const Duration cueStartTimeout = Duration(milliseconds: 300);

  /// How long [spinCuePlayhead] waits for the spin cue to start advancing.
  static const Duration cueSyncTimeout = Duration(milliseconds: 1000);

  static const Duration _playheadPoll = Duration(milliseconds: 8);

  static Future<void> playOnSpin() => _play(spinAsset);

  /// Where the spin cue's playhead is once it has actually started advancing,
  /// so the wheel can start at the same point of the cue. `play()` returning
  /// (or [cueStartTimeout]) does not mean the clicks are being heard yet:
  /// seeking, starting and audio output all add delay, and a 300ms delay is
  /// one whole slice of the final slowdown.
  ///
  /// Returns null when the position is unavailable or the cue has not
  /// started within [cueSyncTimeout]; the wheel then starts immediately.
  static Future<Duration?> spinCuePlayhead() async {
    final player = _player;
    if (player == null) return null;
    final polls = cueSyncTimeout.inMicroseconds ~/ _playheadPoll.inMicroseconds;
    for (var i = 0; i < polls; i++) {
      Duration? position;
      try {
        position = await player.position(spinAsset);
      } catch (_) {
        return null;
      }
      if (position == null) return null;
      // Zero: not started yet. Beyond the sync window: a stale position from
      // the previous spin that has not been rewound yet.
      if (position > Duration.zero && position <= cueSyncTimeout) {
        return position;
      }
      await Future<void>.delayed(_playheadPoll);
    }
    return null;
  }

  static Future<void> preloadSpin() => _preload(spinAsset);

  static Future<void> playOnPopup() => _play(popupAsset);

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
