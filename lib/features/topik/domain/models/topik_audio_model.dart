/// The speeds Practice mode offers (BR-TOPIK-017).
const List<double> topikAudioSpeeds = [0.75, 1.0, 1.25, 1.5];

/// Where the player is (BR-TOPIK-017). [failed] shows an error with Retry
/// inside the player; the attempt is untouched.
enum TopikAudioStatus { idle, loading, ready, playing, completed, failed }

/// A listening group's range `[startMs, endMs)` of its section file
/// (BR-TOPIK-004). Two equal clips are the same group.
final class TopikAudioClip {
  const TopikAudioClip({
    required this.asset,
    required this.startMs,
    required this.endMs,
  });

  final String asset;
  final int startMs;
  final int endMs;

  int get lengthMs => endMs - startMs;

  @override
  bool operator ==(Object other) =>
      other is TopikAudioClip &&
      other.asset == asset &&
      other.startMs == startMs &&
      other.endMs == endMs;

  @override
  int get hashCode => Object.hash(asset, startMs, endMs);
}

/// What the player shows: its status, the clip, the position inside the
/// clip in milliseconds, and the speed.
final class TopikAudioState {
  const TopikAudioState({
    required this.status,
    required this.clip,
    required this.positionMs,
    required this.speed,
  });

  static const TopikAudioState initial = TopikAudioState(
    status: TopikAudioStatus.idle,
    clip: null,
    positionMs: 0,
    speed: 1.0,
  );

  final TopikAudioStatus status;
  final TopikAudioClip? clip;
  final int positionMs;
  final double speed;

  bool get isPlaying => status == TopikAudioStatus.playing;

  TopikAudioState copyWith({
    TopikAudioStatus? status,
    TopikAudioClip? clip,
    int? positionMs,
    double? speed,
  }) => TopikAudioState(
    status: status ?? this.status,
    clip: clip ?? this.clip,
    positionMs: positionMs ?? this.positionMs,
    speed: speed ?? this.speed,
  );
}
