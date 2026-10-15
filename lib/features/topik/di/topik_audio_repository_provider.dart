import 'package:memox/features/topik/data/datasources/plugin_topik_audio_player_data_source.dart';
import 'package:memox/features/topik/data/datasources/topik_audio_player_data_source.dart';
import 'package:memox/features/topik/data/repositories/topik_audio_repository_impl.dart';
import 'package:memox/features/topik/domain/repositories/topik_audio_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'topik_audio_repository_provider.g.dart';

/// The plugin door, released with it; tests override it with a fake.
@riverpod
TopikAudioPlayerDataSource topikAudioPlayerDataSource(Ref ref) {
  final door = PluginTopikAudioPlayerDataSource();
  ref.onDispose(door.dispose);
  return door;
}

/// One player per attempt screen; released with it.
@riverpod
TopikAudioRepository topikAudioRepository(Ref ref) {
  final audio = TopikAudioRepositoryImpl(
    ref.watch(topikAudioPlayerDataSourceProvider),
  );
  ref.onDispose(audio.dispose);
  return audio;
}
