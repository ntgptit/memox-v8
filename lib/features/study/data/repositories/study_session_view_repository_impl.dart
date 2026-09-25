import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/data/datasources/study_queue_dao.dart';
import 'package:memox/features/study/data/datasources/study_view_dao.dart';
import 'package:memox/features/study/data/mappers/study_session_view_mapper.dart';
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/domain/repositories/study_session_view_repository.dart';

/// Reads the session screen (UC-STUDY-001 steps 6–13): one Drift `watch()` on
/// the session row, and the rest of the screen read in the same emission.
final class StudySessionViewRepositoryImpl
    implements StudySessionViewRepository {
  StudySessionViewRepositoryImpl(AppDatabase db)
    : _queue = StudyQueueDao(db),
      _views = StudyViewDao(db);

  final StudyQueueDao _queue;
  final StudyViewDao _views;

  @override
  Stream<StudySessionView?> watchSession(String sessionId) => _views
      .watchSessionRow(sessionId)
      .asyncMap((row) async => row == null ? null : _viewOf(row))
      .mapDatabaseErrors();

  /// The rest of [row]'s screen, read in the same emission (spec §8.2): an
  /// open session shows the card it serves, an ended one its summary,
  /// whatever rows it left.
  Future<StudySessionView> _viewOf(SessionViewRow row) async {
    final session = row.session;
    final modes = await _views.modesOf(session.id);
    if (session.status == SessionStatus.inProgress.code) {
      return studySessionViewOf(
        row,
        modes: modes,
        served: await _servedOf(session),
        counts: null,
      );
    }
    return studySessionViewOf(
      row,
      modes: modes,
      served: null,
      counts: await _views.summaryCounts(
        session.id,
        lapseActions: lapseActionsOf(SchedulerType.fromCode(row.schedulerType)),
      ),
    );
  }

  /// The row [session] serves, with its card and the counts of its round;
  /// null while nothing is left to serve (spec D12).
  Future<ServedRow?> _servedOf(StudySession session) async {
    final head = await _queue.headRow(
      session.id,
      session.currentMode,
      session.cursor,
    );
    if (head == null) return null;
    final card = await _views.cardRow(head.cardId);
    if (card == null) return null;
    return (
      row: head,
      card: card,
      round: await _views.roundCounts(session.id, head.mode, head.round),
    );
  }
}
