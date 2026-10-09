import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/data/datasources/card_detail_dao.dart';
import 'package:memox/features/card/data/datasources/card_list_dao.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/domain/models/card_display_status_model.dart';
import 'package:memox/features/card/domain/models/card_due_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/domain/models/review_history_model.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_tree_model.dart';
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
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
  required DateTime now,
  required DateTime startOfToday,
}) => CardListItem(
  id: card.id,
  front: card.front,
  back: card.back,
  isFlagged: card.isFlagged == 1,
  dueAt: schedule.dueAt,
  displayStatus: CardDisplayStatus.of(scheduleStateOf(schedule)),
  due: CardDue.of(
    learnedAt: schedule.learnedAt,
    dueAt: schedule.dueAt,
    now: now,
    startOfToday: startOfToday,
  ),
  tags: [for (final tag in tags) TagEntity(id: tag.id, name: tag.name)],
);

/// The display state of every live card of the deck, counted once each by
/// SQL (BR-CARD-008, DEV-211); the thresholds are CardStatusSql's, which a
/// parity test holds to CardDisplayStatus.
CardStatusCounts statusCountsOf(DeckStatusCountsRow row) => CardStatusCounts(
  newCards: row.newCount,
  beginning: row.beginningCount,
  reviewing: row.reviewingCount,
  mastered: row.masteredCount,
);

/// Every live card of the deck by its set of BR-STUDY-068, counted once each
/// by SQL (E-O1), through the one SQL copy of the rule (DEV-221).
CardWorkload workloadOf(DeckStatusCountsRow row) => CardWorkload(
  overdue: row.overdueCount,
  today: row.dueTodayCount,
  newCards: row.newCount,
);

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

DeckTreeNode deckTreeNodeOf(CardMoveTargetRow row) => DeckTreeNode(
  id: row.id,
  name: row.name,
  parentId: row.parentId,
  siblingPosition: row.siblingPosition,
  isCandidate: row.isCandidate,
  contentType: DeckContentType.values.byName(row.contentType),
);
