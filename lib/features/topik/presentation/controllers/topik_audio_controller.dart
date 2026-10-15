import 'package:memox/features/topik/di/topik_audio_repository_provider.dart';
import 'package:memox/features/topik/domain/models/topik_audio_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_audio_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'topik_audio_controller.g.dart';

/// Screen 37's player (spec §5.5, §13.8), one per attempt screen; its state
/// is the player's. A group's clip loads when its bar shows and is never
/// played on its own; loading another group's clip pauses the previous one
/// (the repository does that).
@riverpod
class TopikAudioController extends _$TopikAudioController {
  @override
  Stream<TopikAudioState> build() =>
      ref.watch(topikAudioRepositoryProvider).watchState();

  TopikAudioRepository get _player => ref.read(topikAudioRepositoryProvider);

  /// Loads [clip], unless it is the clip already loaded and not failed:
  /// moving between the questions of one group keeps the audio as it is.
  Future<void> show(TopikAudioClip clip) async {
    final current = _player.state;
    final isLoaded =
        current.clip == clip && current.status != TopikAudioStatus.failed;
    if (isLoaded) return;
    await _player.load(clip);
  }

  /// Loads the current clip again after it failed (BR-TOPIK-017).
  Future<void> retry() async {
    final clip = _player.state.clip;
    if (clip == null) return;
    await _player.load(clip);
  }

  Future<void> toggle() =>
      _player.state.isPlaying ? _player.pause() : _player.play();

  Future<void> seek(int positionMs) => _player.seek(positionMs);

  Future<void> setSpeed(double speed) => _player.setSpeed(speed);
}
