import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/deck/domain/models/deck_schedule_status_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';

/// The overdue age counts the local day boundaries since the oldest due card
/// fell due, on calendar dates (BR-STUDY-067).
ReminderDeckWorkload reminderDeckWorkloadOf(
  DeckTileRow row,
  DateTime startOfToday,
) => ReminderDeckWorkload(
  deckId: row.id,
  name: row.name,
  overdueCount: row.overdueCount,
  overdueDays: DeckScheduleStatus.overdueDays(row.oldestDueAt, startOfToday),
  dueTodayCount: row.dueTodayCount,
);
