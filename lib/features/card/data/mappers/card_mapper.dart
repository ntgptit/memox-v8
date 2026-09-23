import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/models/card_display_status_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

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

CardListItem listItemOf(CardRow card, CardSchedule schedule) => CardListItem(
  id: card.id,
  front: card.front,
  back: card.back,
  isFlagged: card.isFlagged == 1,
  dueAt: schedule.dueAt,
  displayStatus: CardDisplayStatus.of(scheduleStateOf(schedule)),
);
