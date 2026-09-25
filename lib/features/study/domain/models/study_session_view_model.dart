import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// The session screen (UC-STUDY-001 steps 6–13; spec §8.2), with the
/// `match` board and the `guess` options of package 2b (graded modes spec
/// §9).
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
    this.board,
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

  /// `match`: the board of [currentItem], whose first pending pair it is;
  /// null in every other mode (BR-STUDY-049).
  final MatchBoard? board;

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
    this.guess,
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

  /// `guess`: the question on this card; null in every other mode.
  final GuessQuestion? guess;
}

/// A `guess` question (BR-STUDY-037, BR-STUDY-043).
final class GuessQuestion {
  const GuessQuestion(this.options);

  /// The five options in the order shown; empty while the question is
  /// blocked.
  final List<GuessOption> options;

  /// Fewer than five options could be built or kept: the question is not
  /// shown and takes no answer (BR-STUDY-040).
  bool get isBlocked => options.isEmpty;
}

/// An option of a `guess` question: a card and its meaning. The answer names
/// the card (BR-STUDY-041).
final class GuessOption {
  const GuessOption({required this.cardId, required this.meaning});

  final String cardId;
  final String meaning;
}

/// The `match` board a session serves (BR-STUDY-049): its terms in position
/// order and its meanings in their stored order.
final class MatchBoard {
  const MatchBoard({required this.terms, required this.meanings});

  final List<MatchTile> terms;
  final List<MatchTile> meanings;
}

/// A tile of a board: one side of a card, and whether its pair is matched in
/// this round, so it stays marked in place (IT-MODE-003).
final class MatchTile {
  const MatchTile({
    required this.cardId,
    required this.text,
    required this.isMatched,
  });

  final String cardId;
  final String text;
  final bool isMatched;
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
