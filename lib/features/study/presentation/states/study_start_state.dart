import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// What a start on the Study Entry asked for, kept so Try again repeats it
/// (screen 14).
sealed class StudyStart {
  const StudyStart();
}

/// Learn new cards (UC-STUDY-001 step 3, BR-STUDY-051).
final class LearnStart extends StudyStart {
  const LearnStart();
}

/// A review in [mode], asked [direction] when the mode takes one
/// (UC-STUDY-001 step 4, UC-STUDY-003).
final class ReviewStart extends StudyStart {
  const ReviewStart({required this.mode, this.direction});

  final StudyMode mode;
  final DirectionChoice? direction;
}

/// Continue today's open session (UC-STUDY-001 A3b).
final class ContinueStart extends StudyStart {
  const ContinueStart(this.sessionId);

  final String sessionId;
}

enum StudyStartStatus {
  idle,

  /// A session is opening: every action is locked (BR-STUDY-004).
  starting,

  /// The store refused: the cards or the session changed since the screen
  /// opened (screen 14 refused).
  refused,

  /// The write failed; nothing was saved (BR-STUDY-018, screen 14
  /// startFailed).
  failed,
}

/// The Study Entry's start, as screen 14 draws it.
final class StudyStartState {
  const StudyStartState({
    this.status = StudyStartStatus.idle,
    this.refusal,
    this.lastStart,
  });

  final StudyStartStatus status;

  /// Why the store refused; null unless [status] is refused.
  final StudyRejection? refusal;

  /// What Try again repeats: the start that was refused or failed, or runs.
  final StudyStart? lastStart;

  bool get isStarting => status == StudyStartStatus.starting;
}
