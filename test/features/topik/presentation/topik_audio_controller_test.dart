import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/di/topik_audio_repository_provider.dart';
import 'package:memox/features/topik/domain/models/topik_audio_model.dart';
import 'package:memox/features/topik/presentation/controllers/topik_audio_controller.dart';

import '../../../support/topik_fakes.dart';

const _first = TopikAudioClip(asset: 'a.mp3', startMs: 0, endMs: 30000);
const _second = TopikAudioClip(asset: 'a.mp3', startMs: 30000, endMs: 60000);

// Screen 37's player (spec §5.5): a clip loads when its group shows, never
// plays on its own, and a failed one loads again on Retry (BR-TOPIK-017).
void main() {
  late FakeTopikAudioRepository player;
  late TopikAudioController audio;

  setUp(() {
    player = FakeTopikAudioRepository();
    final container = ProviderContainer(
      overrides: [topikAudioRepositoryProvider.overrideWithValue(player)],
    );
    addTearDown(container.dispose);
    container.listen(topikAudioControllerProvider, (_, _) {});
    audio = container.read(topikAudioControllerProvider.notifier);
  });

  test('a group loads its clip once and does not play it', () async {
    await audio.show(_first);
    await audio.show(_first);
    await audio.show(_second);

    expect(player.calls, ['load 0', 'load 30000']);
    expect(player.state.isPlaying, isFalse);
  });

  test('a failed clip loads again when shown or retried', () async {
    player.failsLoads = true;
    await audio.show(_first);
    player.failsLoads = false;
    await audio.retry();
    await audio.show(_first);

    expect(player.calls, ['load 0', 'load 0']);
    expect(player.state.status, TopikAudioStatus.ready);
  });

  test('toggle plays, then pauses; seek and speed go to the player', () async {
    await audio.show(_first);
    await audio.toggle();
    await audio.toggle();
    await audio.seek(12000);
    await audio.setSpeed(1.5);

    expect(player.calls, [
      'load 0',
      'play',
      'pause',
      'seek 12000',
      'speed 1.5',
    ]);
  });
}
