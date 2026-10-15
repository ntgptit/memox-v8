import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/features/topik/data/datasources/plugin_topik_audio_player_data_source.dart';
import 'package:memox/features/topik/data/repositories/topik_audio_repository_impl.dart';
import 'package:memox/features/topik/domain/models/topik_audio_model.dart';

import '../../../support/fake_just_audio_platform.dart';
import '../../../support/recording_log_sink.dart';

const _clip = TopikAudioClip(asset: 'l.mp3', startMs: 10000, endMs: 40000);
const _next = TopikAudioClip(asset: 'l.mp3', startMs: 40000, endMs: 70000);

/// Lets the player's channel messages and streams settle.
Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await pumpEventQueue();
  }
}

// BR-TOPIK-017, spec §13.8: the rules over the real just_audio 0.10.6 player,
// whose native side is faked at its channels.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeJustAudioPlatform native;
  late TopikAudioRepositoryImpl audio;
  late RecordingLogSink log;
  late AppLogger previous;
  setUp(() {
    native = FakeJustAudioPlatform.install();
    final door = PluginTopikAudioPlayerDataSource(player: HostAudioPlayer());
    audio = TopikAudioRepositoryImpl(door);
    addTearDown(door.dispose);
    addTearDown(audio.dispose);
    log = RecordingLogSink();
    previous = appLogger;
    AppLogger.install(AppLogger(sinks: [log]));
    addTearDown(() => AppLogger.install(previous));
  });

  Future<void> loadAndPlay() async {
    await audio.load(_clip);
    await audio.play();
    await _settle();
  }

  test('a file that fails while playing is failed, with one warning, and '
      'Retry recovers', () async {
    await loadAndPlay();
    expect(audio.state.status, TopikAudioStatus.playing);

    native.failMidPlay();
    await _settle();

    expect(audio.state.status, TopikAudioStatus.failed);
    expect(log.events.where((e) => e == 'topik.audio_failed'), hasLength(1));
    await audio.load(_clip);
    await _settle();
    expect(audio.state.status, TopikAudioStatus.ready);
  });

  test('stop returns to the start: the next play begins at 0', () async {
    await loadAndPlay();
    await audio.seek(12000);
    await _settle();
    await audio.stop();
    await _settle();

    await audio.play();
    await _settle();

    expect(native.isPlaying, isTrue);
    expect(native.position, Duration.zero);
  });

  test('dragging a finished clip moves it without playing it', () async {
    await loadAndPlay();
    native.complete();
    await _settle();
    expect(audio.state.status, TopikAudioStatus.completed);

    await audio.seek(5000);
    await _settle();

    expect(native.isPlaying, isFalse);
    expect(audio.state.isPlaying, isFalse);
  });

  test('play after the end replays from the start', () async {
    await loadAndPlay();
    native.complete();
    await _settle();

    await audio.play();
    await _settle();

    expect(native.isPlaying, isTrue);
    expect(native.position, Duration.zero);
    expect(audio.state.status, TopikAudioStatus.playing);
  });

  test('another group pauses the one playing and does not autoplay', () async {
    await loadAndPlay();

    await audio.load(_next);
    await _settle();

    expect(native.isPlaying, isFalse);
    expect(audio.state.clip, _next);
    expect(audio.state.status, TopikAudioStatus.ready);
  });

  test('a file that does not load is failed with one warning; Retry '
      'recovers', () async {
    native.failLoad = true;
    await audio.load(_clip);
    await _settle();
    expect(audio.state.status, TopikAudioStatus.failed);
    expect(log.events.where((e) => e == 'topik.audio_failed'), hasLength(1));

    native.failLoad = false;
    await audio.load(_clip);
    await _settle();
    expect(audio.state.status, TopikAudioStatus.ready);
  });

  test('B, then A, then back to B quickly: B is what is loaded', () async {
    await audio.load(_next);
    await _settle();

    final toA = audio.load(_clip);
    final backToB = audio.load(_next);
    await Future.wait([toA, backToB]);
    await _settle();

    expect(audio.state.clip, _next);
    expect(audio.state.status, TopikAudioStatus.ready);
    expect(log.events, isNot(contains('topik.audio_failed')));
  });
}
