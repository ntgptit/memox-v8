import 'dart:async';

import 'package:memox/features/topik/data/datasources/topik_audio_player_data_source.dart';

/// The plugin with its calls recorded and its reports pushed by the test.
final class FakeTopikAudioPlayer implements TopikAudioPlayerDataSource {
  final calls = <String>[];
  final _snapshots = StreamController<TopikPlayerSnapshot>.broadcast();
  bool failSetClip = false;
  bool failPlay = false;

  /// When set, `setClip` waits for it, so a test can overlap two loads.
  Completer<void>? setClipGate;

  void report({
    bool playing = false,
    TopikPlayerPhase phase = TopikPlayerPhase.ready,
    int positionMs = 0,
  }) =>
      _snapshots.add((playing: playing, phase: phase, positionMs: positionMs));

  @override
  Stream<TopikPlayerSnapshot> get snapshots => _snapshots.stream;

  @override
  Future<void> setClip({
    required String asset,
    required int startMs,
    required int endMs,
  }) async {
    calls.add('setClip:$asset:$startMs-$endMs');
    final gate = setClipGate;
    if (gate != null) await gate.future;
    if (failSetClip) throw StateError('no such asset');
  }

  @override
  Future<void> play() async {
    calls.add('play');
    if (failPlay) throw StateError('decoder');
  }

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> seek(int positionMs) async => calls.add('seek:$positionMs');

  @override
  Future<void> setSpeed(double speed) async => calls.add('speed:$speed');

  @override
  Future<void> stop() async => calls.add('stop');

  @override
  Future<void> dispose() async {
    calls.add('dispose');
    await _snapshots.close();
  }
}
