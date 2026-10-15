import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/data/repositories/topik_audio_repository_impl.dart';
import 'package:memox/features/topik/di/topik_audio_repository_provider.dart';

import '../../../support/fake_topik_audio_player.dart';

void main() {
  test('builds the player over the door and releases it on dispose', () async {
    final player = FakeTopikAudioPlayer();
    final container = ProviderContainer(
      overrides: [topikAudioPlayerDataSourceProvider.overrideWithValue(player)],
    );
    final audio = container.read(topikAudioRepositoryProvider);
    expect(audio, isA<TopikAudioRepositoryImpl>());

    container.dispose();
    await pumpEventQueue();

    expect(player.calls.last, 'dispose');
  });
}
