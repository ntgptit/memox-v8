import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/data/datasources/topik_audio_player_data_source.dart';
import 'package:memox/features/topik/data/repositories/topik_audio_repository_impl.dart';
import 'package:memox/features/topik/domain/models/topik_audio_model.dart';

import '../../../support/fake_topik_audio_player.dart';

const _clip = TopikAudioClip(asset: 'l.mp3', startMs: 10000, endMs: 40000);
const _next = TopikAudioClip(asset: 'l.mp3', startMs: 40000, endMs: 70000);

/// What `load(_clip)` sends: the clip, then the chosen speed.
const _loadCalls = ['setClip:l.mp3:10000-40000', 'speed:1.0'];

// BR-TOPIK-017, spec §5.5.
void main() {
  late FakeTopikAudioPlayer player;
  late TopikAudioRepositoryImpl audio;
  setUp(() {
    player = FakeTopikAudioPlayer();
    audio = TopikAudioRepositoryImpl(player);
  });

  test('load readies the clip without playing it (no autoplay)', () async {
    await audio.load(_clip);
    expect(player.calls, _loadCalls);
    expect(audio.state.status, TopikAudioStatus.ready);
    expect(audio.state.clip, _clip);
  });

  test('the same clip again changes nothing, playing or not', () async {
    await audio.load(_clip);
    await audio.play();
    player.report(playing: true, positionMs: 3000);
    await pumpEventQueue();
    await audio.load(_clip);
    expect(player.calls, [..._loadCalls, 'play']);
    expect(audio.state.isPlaying, isTrue);
  });

  test('another group stops the previous one and loads its own', () async {
    await audio.load(_clip);
    await audio.play();
    await audio.load(_next);
    expect(player.calls.skip(3), [
      'stop',
      'setClip:l.mp3:40000-70000',
      'speed:1.0',
    ]);
    expect(audio.state.clip, _next);
    expect(audio.state.status, TopikAudioStatus.ready);
  });

  test('a load overtaken by another group leaves that group loading', () async {
    final first = Completer<void>();
    player.setClipGate = first;
    final loadingFirst = audio.load(_clip);
    await pumpEventQueue();
    player.setClipGate = null;
    final loadingNext = audio.load(_next);
    first.complete();
    await loadingFirst;
    expect(audio.state.clip, _next);
    expect(audio.state.status, isNot(TopikAudioStatus.ready));
    await loadingNext;
    expect(audio.state.status, TopikAudioStatus.ready);
  });

  test('an overtaken load that fails does not fail the next group', () async {
    final first = Completer<void>();
    player.setClipGate = first;
    final loadingFirst = audio.load(_clip);
    await pumpEventQueue();
    player.setClipGate = null;
    await audio.load(_next);
    player.failSetClip = true;
    first.complete();
    await loadingFirst;
    expect(audio.state.clip, _next);
    expect(audio.state.status, TopikAudioStatus.ready);
  });

  test(
    'reports map to the state; the position is clamped to the clip',
    () async {
      await audio.load(_clip);
      player.report(playing: true, positionMs: 5000);
      await pumpEventQueue();
      expect(audio.state.status, TopikAudioStatus.playing);
      expect(audio.state.positionMs, 5000);
      player.report(phase: TopikPlayerPhase.completed, positionMs: 30500);
      await pumpEventQueue();
      expect(audio.state.status, TopikAudioStatus.completed);
      expect(audio.state.positionMs, 30000);
    },
  );

  test('play after completing replays from the start', () async {
    await audio.load(_clip);
    player.report(phase: TopikPlayerPhase.completed, positionMs: 30000);
    await pumpEventQueue();
    await audio.play();
    expect(player.calls.skip(2), ['seek:0', 'play']);
  });

  test('seek is clamped to the clip', () async {
    await audio.load(_clip);
    await audio.seek(-5);
    await audio.seek(99999);
    expect(player.calls.skip(2), ['seek:0', 'seek:30000']);
  });

  test('only the four speeds', () async {
    await audio.load(_clip);
    await audio.setSpeed(1.25);
    expect(audio.state.speed, 1.25);
    expect(() => audio.setSpeed(2.0), throwsArgumentError);
  });

  test('a speed chosen before the clip loads reaches the plugin', () async {
    await audio.setSpeed(0.75);
    expect(player.calls, isEmpty);
    await audio.load(_clip);
    expect(player.calls, ['setClip:l.mp3:10000-40000', 'speed:0.75']);
    expect(audio.state.speed, 0.75);
  });

  test('a file that does not load is failed, and Retry recovers', () async {
    player.failSetClip = true;
    await audio.load(_clip);
    expect(audio.state.status, TopikAudioStatus.failed);
    player.failSetClip = false;
    await audio.load(_clip);
    expect(audio.state.status, TopikAudioStatus.ready);
  });

  test('a failure to play is a state, never an exception', () async {
    await audio.load(_clip);
    player.failPlay = true;
    await audio.play();
    expect(audio.state.status, TopikAudioStatus.failed);
  });

  test('stop returns to the start; dispose releases the plugin', () async {
    await audio.load(_clip);
    await audio.stop();
    expect(audio.state.positionMs, 0);
    expect(audio.state.status, TopikAudioStatus.ready);
    await audio.dispose();
    expect(player.calls.last, 'dispose');
  });

  test('watchState starts with the current state', () async {
    await audio.load(_clip);
    expect((await audio.watchState().first).clip, _clip);
  });
}
