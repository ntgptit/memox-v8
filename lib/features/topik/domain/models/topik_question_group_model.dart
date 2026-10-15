import 'package:memox/features/topik/domain/models/topik_text_model.dart';

/// The text or picture a group's questions share.
final class TopikPassage {
  const TopikPassage({this.textKo, this.image});

  final String? textKo;

  /// An asset path.
  final String? image;
}

/// The stretch of the section's audio file a listening group plays
/// (BR-TOPIK-004): `[startMs, endMs)`.
final class TopikGroupAudio {
  const TopikGroupAudio({
    required this.startMs,
    required this.endMs,
    required this.playCount,
  });

  final int startMs;
  final int endMs;

  /// Plays in the real exam; only Exam mode (Phase B) uses it.
  final int playCount;
}

/// Questions that share one instruction, passage and audio, such as
/// `[21～22]` (BR-TOPIK-004).
final class TopikQuestionGroup {
  const TopikQuestionGroup({
    required this.groupId,
    required this.instructionKo,
    required this.questionNos,
    this.passage,
    this.audio,
    this.script,
    this.scriptTranslation,
  });

  final String groupId;
  final String instructionKo;
  final List<int> questionNos;
  final TopikPassage? passage;
  final TopikGroupAudio? audio;

  /// The listening script (듣기 대본).
  final String? script;
  final TopikText? scriptTranslation;
}
