/// The audio plugin's processing phase, as plain values.
enum TopikPlayerPhase { idle, loading, ready, completed }

/// What the plugin reports: whether it plays, its phase, and the position in
/// the loaded clip in milliseconds.
typedef TopikPlayerSnapshot = ({
  bool playing,
  TopikPlayerPhase phase,
  int positionMs,
});

/// The audio plugin (spec §13.8). The one implementation is
/// `PluginTopikAudioPlayerDataSource`, the only file that imports
/// `just_audio` (guard `topik_audio_plugin_has_one_door`); every method may
/// throw on a platform failure, which the repository turns into a state.
abstract interface class TopikAudioPlayerDataSource {
  Stream<TopikPlayerSnapshot> get snapshots;

  /// Loads `[startMs, endMs)` of the bundled [asset].
  Future<void> setClip({
    required String asset,
    required int startMs,
    required int endMs,
  });

  /// Starts playing and returns at once.
  Future<void> play();

  Future<void> pause();

  Future<void> seek(int positionMs);

  Future<void> setSpeed(double speed);

  Future<void> stop();

  Future<void> dispose();
}
