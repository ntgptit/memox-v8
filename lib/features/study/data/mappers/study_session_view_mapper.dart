import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/models/schedulers_model.dart';
import 'package:memox/features/study/data/datasources/study_view_dao.dart';
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study_mode/domain/models/guess_mode.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// The row a session serves, with its card and the counts of its round;
/// its question's options in `guess`, and its board in `match`.
typedef ServedRow = ({
  StudyQueueItem row,
  CardRow card,
  RoundCounts round,
  List<OptionRecord>? options,
  List<BoardPairRecord>? board,
});

/// The stored `review_log.action` codes of [type]'s lapses (BR-SRS-018).
List<String> lapseActionsOf(SchedulerType type) {
  final scheduler = schedulerFor(type);
  return [
    for (final action in scheduler.supportedActions)
      if (scheduler.isLapse(action)) (action as Enum).name,
  ];
}

/// The session screen (spec §8.2) of [row]: [modes] are the modes its queue
/// has rows in, [served] the row an open session serves, and [counts] what
/// the summary of an ended one shows.
StudySessionView studySessionViewOf(
  SessionViewRow row, {
  required Set<String> modes,
  required ServedRow? served,
  required SummaryCounts? counts,
}) {
  final session = row.session;
  final kind = SessionKind.values.byName(session.sessionKind);
  final chain = stageSequenceOf(SchedulerType.fromCode(row.schedulerType));
  return StudySessionView(
    sessionId: session.id,
    deckId: session.deckId,
    deckName: row.deckName,
    kind: kind,
    status: SessionStatus.fromCode(session.status),
    endReason: switch (session.endReason) {
      final String code => SessionEndReason.fromCode(code),
      null => null,
    },
    currentMode: StudyMode.fromCode(session.currentMode),
    direction: switch (session.direction) {
      final String code => DirectionChoice.fromCode(code),
      null => null,
    },
    stages: [
      for (final mode in chain)
        if (modes.contains(mode.code)) mode,
    ],
    currentItem: served == null ? null : _itemOf(served),
    progress: served == null
        ? null
        : RoundProgress(
            completed: served.round.completed,
            total: served.round.total,
          ),
    summary: counts == null
        ? null
        : SessionSummary(
            cardCount: counts.cardCount,
            learnedCardCount: switch (kind) {
              SessionKind.learning => counts.learnedCount,
              SessionKind.reviewing => null,
            },
            wrongTurnCount: counts.wrongCount,
            answeredCardCount: counts.answeredCount,
            turnCount: counts.turnCount,
          ),
    board: switch (served?.board) {
      final List<BoardPairRecord> pairs => _boardOf(pairs),
      null => null,
    },
  );
}

/// The terms in position order, the meanings by their slot (graded modes
/// spec §9).
MatchBoard _boardOf(List<BoardPairRecord> pairs) {
  final bySlot = [...pairs]
    ..sort(
      (a, b) => (a.meaningSlot ?? pairs.length).compareTo(
        b.meaningSlot ?? pairs.length,
      ),
    );
  return MatchBoard(
    terms: [
      for (final pair in pairs)
        MatchTile(
          cardId: pair.cardId,
          text: pair.front,
          isMatched: pair.isCompleted,
        ),
    ],
    meanings: [
      for (final pair in bySlot)
        MatchTile(
          cardId: pair.cardId,
          text: pair.back,
          isMatched: pair.isCompleted,
        ),
    ],
  );
}

/// The question of a `guess` row, blocked unless all five options are
/// stored (BR-STUDY-040).
GuessQuestion _questionOf(List<OptionRecord> options) => GuessQuestion(
  options.length != guessOptionCount
      ? const []
      : [
          for (final option in options)
            GuessOption(cardId: option.cardId, meaning: option.back),
        ],
);

StudyItem _itemOf(ServedRow served) => StudyItem(
  cardId: served.card.id,
  front: served.card.front,
  back: served.card.back,
  example: served.card.example,
  hint: served.card.hint,
  pronunciation: served.card.pronunciation,
  round: served.row.round,
  answersInSession: served.row.answersInSession,
  direction: switch (served.row.direction) {
    final String code => QuestionDirection.fromCode(code),
    null => null,
  },
  remainingMs:
      served.row.remainingMs ??
      StudyMode.fromCode(served.row.mode).handler.turnTimeMs,
  isRevealed: served.row.isRevealed == 1,
  isHintShown: served.row.hintShown == 1,
  guess: switch (served.options) {
    final List<OptionRecord> options => _questionOf(options),
    null => null,
  },
);
