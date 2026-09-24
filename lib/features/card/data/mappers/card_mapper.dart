import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/domain/models/card_display_status_model.dart';
import 'package:memox/features/card/domain/models/card_due_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/domain/models/review_history_model.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_tree_model.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/tags/domain/entities/tag_entity.dart';

CardEntity cardEntityOf(CardRow row) => CardEntity(
  id: row.id,
  deckId: row.deckId,
  front: row.front,
  back: row.back,
  isFlagged: row.isFlagged == 1,
  example: row.example,
  hint: row.hint,
  pronunciation: row.pronunciation,
  createdAt: row.createdAt,
  updatedAt: row.updatedAt,
);

CardScheduleState scheduleStateOf(CardSchedule row) =>
    CardScheduleState.fromColumns(
      type: SchedulerType.fromCode(row.schedulerType),
      generation: row.generation,
      learnedAt: row.learnedAt,
      dueAt: row.dueAt,
      lastAnsweredAt: row.lastAnsweredAt,
      answerCount: row.answerCount,
      lapseCount: row.lapseCount,
      currentBox: row.currentBox,
      easeFactor: row.easeFactor,
      intervalDays: row.intervalDays,
      repetitions: row.repetitions,
    );

CardListItem listItemOf(
  CardRow card,
  CardSchedule schedule, {
  required List<Tag> tags,
  required DateTime startOfToday,
}) => CardListItem(
  id: card.id,
  front: card.front,
  back: card.back,
  isFlagged: card.isFlagged == 1,
  dueAt: schedule.dueAt,
  displayStatus: CardDisplayStatus.of(scheduleStateOf(schedule)),
  due: CardDue.of(
    isLearned: schedule.learnedAt != null,
    dueAt: schedule.dueAt,
    startOfToday: startOfToday,
  ),
  tags: [for (final tag in tags) TagEntity(id: tag.id, name: tag.name)],
);

/// The deck's workload from its schedule rows, by the rows' own due rule
/// (ruling E-L1).
CardWorkload workloadOf(
  Iterable<CardSchedule> schedules, {
  required DateTime startOfToday,
}) {
  var overdue = 0;
  var today = 0;
  var newCards = 0;
  for (final schedule in schedules) {
    final due = CardDue.of(
      isLearned: schedule.learnedAt != null,
      dueAt: schedule.dueAt,
      startOfToday: startOfToday,
    );
    switch (due.kind) {
      case CardDueKind.overdue:
        overdue++;
      case CardDueKind.today:
        today++;
      case CardDueKind.newCard:
        newCards++;
      case CardDueKind.later:
        break;
    }
  }
  return CardWorkload(overdue: overdue, today: today, newCards: newCards);
}

/// The display state of every schedule row, counted once each.
CardStatusCounts statusCountsOf(Iterable<CardSchedule> schedules) {
  var newCards = 0;
  var beginning = 0;
  var reviewing = 0;
  var mastered = 0;
  for (final schedule in schedules) {
    switch (CardDisplayStatus.of(scheduleStateOf(schedule))) {
      case CardDisplayStatus.newCard:
        newCards++;
      case CardDisplayStatus.beginning:
        beginning++;
      case CardDisplayStatus.reviewing:
        reviewing++;
      case CardDisplayStatus.mastered:
        mastered++;
    }
  }
  return CardStatusCounts(
    newCards: newCards,
    beginning: beginning,
    reviewing: reviewing,
    mastered: mastered,
  );
}

CardDetail cardDetailOf(CardDetailResult row) => CardDetail(
  card: cardEntityOf(row.c),
  tags: [for (final tag in row.tags) TagEntity(id: tag.id, name: tag.name)],
  schedulerType: SchedulerType.fromCode(row.s.schedulerType),
  schedule: scheduleStateOf(row.s),
);

ReviewHistoryEntry historyEntryOf(ReviewLog row) {
  final type = SchedulerType.fromCode(row.schedulerType);
  return ReviewHistoryEntry(
    id: row.id,
    generation: row.generation,
    schedulerType: type,
    kind: ReviewKind.values.byName(row.kind),
    mode: row.mode,
    action: switch (type) {
      SchedulerType.eightBox => EightBoxAction.values.byName(row.action),
      SchedulerType.sm2 => Sm2Action.values.byName(row.action),
    },
    answeredAt: row.answeredAt,
    isTimedOut: row.outcomeReason != null,
    usedHint: switch (row.usedHint) {
      final int flag => flag == 1,
      null => null,
    },
    nextDueAt: row.nextDueAt,
    previousBox: row.previousBox,
    nextBox: row.nextBox,
    previousEaseFactor: row.previousEaseFactor,
    nextEaseFactor: row.nextEaseFactor,
    previousIntervalDays: row.previousIntervalDays,
    nextIntervalDays: row.nextIntervalDays,
  );
}

DeckTreeNode deckTreeNodeOf(DeckForestRow row) => DeckTreeNode(
  id: row.id,
  name: row.name,
  parentId: row.parentId,
  siblingPosition: row.siblingPosition,
  isCandidate: row.isCandidate,
  contentType: DeckContentType.values.byName(row.contentType),
);
