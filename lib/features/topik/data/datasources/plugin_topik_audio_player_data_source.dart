import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:memox/features/topik/data/datasources/topik_audio_player_data_source.dart';

/// The one door to `just_audio` (spec §13.8, guard
/// `topik_audio_plugin_has_one_door`): a group's range plays natively
/// through `ClippingAudioSource`. `AudioPlayer.play` completes only when
/// playback stops, so [play] does not wait for it; a failure it or the
/// plugin's streams report later reaches [snapshots] as an error, never the
/// zone (BR-TOPIK-017).
final class PluginTopikAudioPlayerDataSource
    implements TopikAudioPlayerDataSource {
  PluginTopikAudioPlayerDataSource({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  late final _snapshots = StreamController<TopikPlayerSnapshot>.broadcast(
    onListen: _listenToPlayer,
    onCancel: _stopListening,
  );
  final _subscriptions = <StreamSubscription<Object>>[];

  /// The latest report of each plugin stream, combined into one snapshot.
  PlayerState? _state;
  Duration _position = Duration.zero;

  @override
  Stream<TopikPlayerSnapshot> get snapshots => _snapshots.stream;

  @override
  Future<void> setClip({
    required String asset,
    required int startMs,
    required int endMs,
  }) async {
    await _player.setAudioSource(
      ClippingAudioSource(
        child: AudioSource.asset(asset),
        start: Duration(milliseconds: startMs),
        end: Duration(milliseconds: endMs),
      ),
    );
  }

  @override
  Future<void> play() async => unawaited(
    _player.play().catchError(
      (Object error, StackTrace stack) => _addError(error, stack),
    ),
  );

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(int positionMs) =>
      _player.seek(Duration(milliseconds: positionMs));

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() async {
    await _stopListening();
    await _snapshots.close();
    await _player.dispose();
  }

  void _listenToPlayer() {
    _subscriptions
      ..add(
        _player.playerStateStream.listen((state) {
          _state = state;
          _report();
        }, onError: _addError),
      )
      ..add(
        _player.positionStream.listen((position) {
          _position = position;
          _report();
        }, onError: _addError),
      );
  }

  Future<void> _stopListening() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  void _report() {
    final state = _state;
    if (state == null || _snapshots.isClosed) return;
    _snapshots.add((
      playing: state.playing,
      phase: _phaseOf(state.processingState),
      positionMs: _position.inMilliseconds,
    ));
  }

  void _addError(Object error, [StackTrace? stack]) {
    if (!_snapshots.isClosed) _snapshots.addError(error, stack);
  }

  static TopikPlayerPhase _phaseOf(ProcessingState state) => switch (state) {
    ProcessingState.idle => TopikPlayerPhase.idle,
    ProcessingState.loading ||
    ProcessingState.buffering => TopikPlayerPhase.loading,
    ProcessingState.ready => TopikPlayerPhase.ready,
    ProcessingState.completed => TopikPlayerPhase.completed,
  };
}
