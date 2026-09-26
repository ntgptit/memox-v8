import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/data/datasources/study_view_dao.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// The Study tab from the rows of its snapshot (Study Home spec §6.4): the
/// root decks, the resumable session and the counts of its round, and the
/// next due date.
StudyHome studyHomeOf({
  required List<DeckTileRow> roots,
  required ResumableSession? resumable,
  required DateTime? nextDueAt,
}) => StudyHome(
  resumable: resumable,
  content: studyHomeContentOf([
    for (final row in roots) _deckOf(row),
  ], nextDueAt: nextDueAt),
);

/// The session Continue can take up, with the counts of the round it
/// serves (spec D3): the Study tab's Resume card and the Study Entry's
/// resume banner (FE-A6 D15).
ResumableSession resumableSessionOf(ResumableRow row, RoundCounts? round) =>
    ResumableSession(
      sessionId: row.session.id,
      deckName: row.deckName,
      kind: SessionKind.values.byName(row.session.sessionKind),
      mode: StudyMode.fromCode(row.session.currentMode),
      progress: round == null
          ? null
          : RoundProgress(completed: round.completed, total: round.total),
    );

StudyHomeDeck _deckOf(DeckTileRow row) => StudyHomeDeck(
  deckId: row.id,
  name: row.name,
  // A root always has its scheduler (the CHECK of `deck`).
  schedulerType: SchedulerType.fromCode(row.schedulerType!),
  cardCount: row.cardCount,
  overdueCount: row.overdueCount,
  dueTodayCount: row.dueTodayCount,
  newCount: row.newCount,
);
