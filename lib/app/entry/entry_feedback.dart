import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

abstract interface class EntryFeedbackPlayer {
  Future<void> prepare();

  Future<void> playSwish();

  Future<void> dispose();
}

class AssetEntryFeedbackPlayer implements EntryFeedbackPlayer {
  AssetEntryFeedbackPlayer({this.volume = 0.32});

  static const assetPath = 'audio/entry_swish.wav';
  static const _playbackWindow = Duration(milliseconds: 240);

  final double volume;

  AudioPool? _pool;
  Future<void>? _preparing;
  StopFunction? _stop;
  Timer? _stopTimer;
  bool _disposed = false;

  @override
  Future<void> prepare() {
    if (_disposed) return Future<void>.value();
    return _preparing ??= _prepare();
  }

  Future<void> _prepare() async {
    final pool = await AudioPool.create(
      source: AssetSource(assetPath),
      maxPlayers: 1,
      minPlayers: 1,
      playerMode: PlayerMode.lowLatency,
      audioContext: AudioContext(
        android: const AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.assistanceSonification,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
      ),
    );
    if (_disposed) {
      await pool.dispose();
      return;
    }
    _pool = pool;
  }

  @override
  Future<void> playSwish() async {
    if (_disposed) return;
    final pool = _pool;
    if (pool == null) return;
    final stop = await pool.start(volume: volume);
    if (_disposed) {
      await stop();
      return;
    }
    _stopTimer?.cancel();
    final previousStop = _stop;
    _stop = stop;
    if (previousStop != null) await previousStop();
    _stopTimer = Timer(_playbackWindow, () {
      final activeStop = _stop;
      _stop = null;
      if (activeStop != null) unawaited(activeStop());
    });
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _stopTimer?.cancel();
    _stopTimer = null;
    final stop = _stop;
    _stop = null;
    if (stop != null) await stop();
    final pool = _pool;
    _pool = null;
    if (pool != null) await pool.dispose();
  }
}
