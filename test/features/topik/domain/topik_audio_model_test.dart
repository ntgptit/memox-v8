import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_audio_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

import '../../../support/topik_content_fixtures.dart';

// BR-TOPIK-017, spec §5.5.
void main() {
  test('the four practice speeds', () {
    expect(topikAudioSpeeds, [0.75, 1.0, 1.25, 1.5]);
  });

  test(
    'a clip is a range of a section file; equal clips are the same group',
    () {
      const a = TopikAudioClip(asset: 'x.mp3', startMs: 1000, endMs: 4000);
      const b = TopikAudioClip(asset: 'x.mp3', startMs: 1000, endMs: 4000);
      expect(a.lengthMs, 3000);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a == const TopikAudioClip(asset: 'x.mp3', startMs: 4000, endMs: 7000),
        isFalse,
      );
    },
  );

  test('the initial state is idle at normal speed', () {
    expect(TopikAudioState.initial.status, TopikAudioStatus.idle);
    expect(TopikAudioState.initial.speed, 1.0);
    expect(TopikAudioState.initial.isPlaying, isFalse);
  });

  test('a group plays its range of its section file; no file or no range is '
      'no clip', () {
    final listening = topikTestFixture(section: TopikSection.listening);
    final group = listening.groups[1];
    expect(
      topikGroupClip(listening, group),
      TopikAudioClip(
        asset: listening.audioAsset!,
        startMs: group.audio!.startMs,
        endMs: group.audio!.endMs,
      ),
    );
    final reading = topikTestFixture();
    expect(topikGroupClip(reading, reading.groups.first), isNull);
  });
}
