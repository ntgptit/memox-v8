import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/data/repositories/topik_audio_repository_impl.dart';
import 'package:memox/features/topik/di/topik_audio_repository_provider.dart';

import '../../../support/fake_just_audio_platform.dart';
import '../../../support/fake_topik_audio_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('builds the player over the door, and leaves the door alone when '
      'rebuilt', () async {
    final player = FakeTopikAudioPlayer();
    final container = ProviderContainer(
      overrides: [topikAudioPlayerDataSourceProvider.overrideWithValue(player)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      topikAudioRepositoryProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    expect(subscription.read(), isA<TopikAudioRepositoryImpl>());

    container.invalidate(topikAudioRepositoryProvider);
    container.read(topikAudioRepositoryProvider);
    await pumpEventQueue();

    expect(player.calls, isNot(contains('dispose')));
  });

  test('the real door is released with its provider', () async {
    FakeJustAudioPlatform.install();
    final container = ProviderContainer();
    final door = container
        .listen(topikAudioPlayerDataSourceProvider, (_, _) {})
        .read();
    var isReleased = false;
    door.snapshots.listen((_) {}, onDone: () => isReleased = true);

    container.dispose();
    await pumpEventQueue();

    expect(isReleased, isTrue);
  });
}
