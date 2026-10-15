import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:memox/features/topik/data/datasources/plugin_topik_audio_player_data_source.dart';
import 'package:memox/features/topik/data/datasources/topik_audio_player_data_source.dart';

/// The plugin with its calls recorded instead of sent. With the session
/// flags off the constructor reaches no platform channel (just_audio 0.10.6,
/// `just_audio.dart:239-380`).
class _FakePlayer extends AudioPlayer {
  _FakePlayer()
    : super(
        handleInterruptions: false,
        handleAudioSessionActivation: false,
        androidApplyAudioAttributes: false,
      );

  final calls = <String>[];
  AudioSource? source;
  Object? playFailure;

  /// What the plugin reports, pushed by the test.
  final states = StreamController<PlayerState>.broadcast();
  final positions = StreamController<Duration>.broadcast();
  @override
  Stream<PlayerState> get playerStateStream => states.stream;

  @override
  Stream<Duration> get positionStream => positions.stream;

  /// Where just_audio 0.10 reports a playback error.
  final errors = StreamController<PlayerException>.broadcast();

  @override
  Stream<PlayerException> get errorStream => errors.stream;

  @override
  Future<Duration?> setAudioSource(
    AudioSource source, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
  }) async {
    this.source = source;
    calls.add('setAudioSource');
    return null;
  }

  @override
  Future<void> play() async {
    calls.add('play');
    final failure = playFailure;
    if (failure != null) throw failure;
  }

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> seek(Duration? position, {int? index}) async =>
      calls.add('seek:${position?.inMilliseconds}');

  @override
  Future<void> setSpeed(double speed) async => calls.add('speed:$speed');

  @override
  Future<void> stop() async => calls.add('stop');
}

// Spec §13.8: the one door to just_audio plays the clip natively.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a clip is a ClippingAudioSource over the bundled asset', () async {
    final player = _FakePlayer();
    final door = PluginTopikAudioPlayerDataSource(player: player);

    await door.setClip(asset: 'assets/topik/l.mp3', startMs: 1000, endMs: 4000);

    final source = player.source! as ClippingAudioSource;
    expect(source.start, const Duration(milliseconds: 1000));
    expect(source.end, const Duration(milliseconds: 4000));
    expect(source.child.uri.toString(), contains('assets/topik/l.mp3'));
  });

  test('controls go to the plugin; play does not wait for the end', () async {
    final player = _FakePlayer();
    final door = PluginTopikAudioPlayerDataSource(player: player);

    await door.play();
    await door.pause();
    await door.seek(2500);
    await door.setSpeed(0.75);
    await door.stop();

    // Stop returns to the start: just_audio keeps the position across it.
    expect(player.calls, [
      'play',
      'pause',
      'seek:2500',
      'speed:0.75',
      'stop',
      'seek:0',
    ]);
  });

  test('state and position reports become one snapshot', () async {
    final player = _FakePlayer();
    final door = PluginTopikAudioPlayerDataSource(player: player);
    final seen = <TopikPlayerSnapshot>[];
    final subscription = door.snapshots.listen(seen.add);
    addTearDown(subscription.cancel);

    // The plugin reports one event at a time.
    for (final push in [
      () => player.positions.add(const Duration(milliseconds: 1200)),
      () => player.states.add(PlayerState(true, ProcessingState.buffering)),
      () => player.states.add(PlayerState(true, ProcessingState.completed)),
      () => player.positions.add(const Duration(milliseconds: 3000)),
    ]) {
      push();
      await pumpEventQueue();
    }

    // Each report carries its own values; a position before any state
    // waits for the first state.
    expect(seen, [
      (playing: true, phase: TopikPlayerPhase.loading, positionMs: 1200),
      (playing: true, phase: TopikPlayerPhase.completed, positionMs: 1200),
      (playing: true, phase: TopikPlayerPhase.completed, positionMs: 3000),
    ]);
  });

  test('a playback failure reaches the snapshots as an error, never the '
      'zone', () async {
    final player = _FakePlayer()..playFailure = StateError('decoder');
    final door = PluginTopikAudioPlayerDataSource(player: player);
    final errors = <Object>[];
    final subscription = door.snapshots.listen((_) {}, onError: errors.add);
    addTearDown(subscription.cancel);

    await door.play();
    player.errors.add(PlayerException(1, 'decoder', 0));
    await pumpEventQueue();

    expect(errors, [isStateError, isA<PlayerException>()]);
  });
}
