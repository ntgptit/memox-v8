import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// The session screen (UC-STUDY-001 steps 6–13; spec §8.2). Package 2b adds
/// the `match` board, the `guess` options and the `recall` timer.
final class StudySessionView {
  const StudySessionView({
    required this.sessionId,
    required this.deckId,
    required this.deckName,
    required this.kind,
    required this.status,
    required this.endReason,
    required this.currentMode,
    required this.direction,
    required this.stages,
    required this.currentItem,
    required this.progress,
    required this.summary,
  });

  final String sessionId;
  final String deckId;
  final String deckName;
  final SessionKind kind;
  final SessionStatus status;

  /// Why the session ended short of its queue (BR-STUDY-012); null while it
  /// runs and once it completes.
  final SessionEndReason? endReason;
  final StudyMode currentMode;

  /// The choice of an sm2 `self_assess` review (BR-MODE-013); null elsewhere.
  final DirectionChoice? direction;

  /// The stages the session has rows in, in the order it runs them
  /// (IT-MODE-001).
  final List<StudyMode> stages;

  /// The card the session serves (BR-STUDY-005); null once the session has
  /// ended, and while it is stalled.
  final StudyItem? currentItem;

  /// The rows of [currentItem]'s round, done and in all: the counter
  /// measures the whole round (BR-STUDY-049). Null with no current item.
  final RoundProgress? progress;

  /// Once the session has ended (spec D11).
  final SessionSummary? summary;

  int get currentStageIndex => stages.indexOf(currentMode);

  /// The round the session serves in its current stage.
  int? get currentRound => currentItem?.round;

  /// Open, with nothing to serve: the cards of its current round were
  /// deleted. Continue settles it (spec D12).
  bool get isStalled =>
      status == SessionStatus.inProgress && currentItem == null;
}

/// The card a session serves, with its queue row (spec §8.2).
final class StudyItem {
  const StudyItem({
    required this.cardId,
    required this.front,
    required this.back,
    required this.example,
    required this.hint,
    required this.pronunciation,
    required this.round,
    required this.answersInSession,
    required this.direction,
    required this.remainingMs,
    required this.isRevealed,
  });

  final String cardId;
  final String front;
  final String back;
  final String? example;
  final String? hint;
  final String? pronunciation;
  final int round;

  /// The turns the row has taken (BR-STUDY-073).
  final int answersInSession;

  /// The side this card asks from in an sm2 `self_assess` review
  /// (BR-MODE-015); null elsewhere.
  final QuestionDirection? direction;

  /// `recall` only: the time left of a turn in progress (BR-STUDY-036).
  final int? remainingMs;
  final bool isRevealed;
}

/// The rows of a round, done and in all.
final class RoundProgress {
  const RoundProgress({required this.completed, required this.total});

  final int completed;
  final int total;
}

/// What a session did, once it has ended (spec D11; IT-CONT-005).
final class SessionSummary {
  const SessionSummary({
    required this.cardCount,
    required this.learnedCardCount,
    required this.wrongTurnCount,
  });

  /// The distinct cards of the queue.
  final int cardCount;

  /// In a learning session, its cards that are now learned; null in a
  /// review.
  final int? learnedCardCount;

  /// The session's turns whose action was a lapse (BR-SRS-018).
  final int wrongTurnCount;
}
