import 'package:memox/features/topik/domain/models/topik_audio_model.dart';

/// The listening player (BR-TOPIK-017, spec §5.5). The one implementation
/// is `TopikAudioRepositoryImpl` over the `just_audio` door; tests use a
/// fake. Nothing here throws for a file that does not play: that is the
/// [TopikAudioStatus.failed] state.
abstract interface class TopikAudioRepository {
  /// The current state, then every change.
  Stream<TopikAudioState> watchState();

  TopikAudioState get state;

  /// Readies [clip] without playing it (no autoplay). The clip already
  /// loaded and not failed is left as it is, playing or not: moving between
  /// the questions of one group keeps the audio.
  Future<void> load(TopikAudioClip clip);

  /// Plays; after the clip completed, replays it from its start.
  Future<void> play();

  Future<void> pause();

  /// Moves inside the clip; clamped to `[0, lengthMs]`.
  Future<void> seek(int positionMs);

  /// One of [topikAudioSpeeds]; anything else is an `ArgumentError`.
  Future<void> setSpeed(double speed);

  /// Stops and returns to the start of the clip.
  Future<void> stop();

  Future<void> dispose();
}
