import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/study/data/datasources/study_queue_dao.dart';
import 'package:memox/features/study/data/datasources/study_view_dao.dart';
import 'package:memox/features/study/data/mappers/study_home_mapper.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study/domain/repositories/study_home_repository.dart';

/// Reads the Study tab (UC-STUDY-002; Study Home spec §6): four reads in one
/// transaction, once when listened to and again after every write the tab
/// can see.
final class StudyHomeRepositoryImpl implements StudyHomeRepository {
  StudyHomeRepositoryImpl(this._db)
    : _queue = StudyQueueDao(_db),
      _views = StudyViewDao(_db);

  final AppDatabase _db;
  final StudyQueueDao _queue;
  final StudyViewDao _views;

  @override
  Stream<StudyHome> watchHome({
    required DateTime now,
    required DateTime startOfToday,
  }) => _views
      .homeChanges()
      .asyncMap(
        (_) => _db.transaction(
          () => _snapshot(now: now, startOfToday: startOfToday),
        ),
      )
      .mapDatabaseErrors();

  /// The root decks, the resumable session and its round, and the next due
  /// date, read in the caller's transaction so they see one state of the
  /// database (UC-STUDY-002 step 1).
  Future<StudyHome> _snapshot({
    required DateTime now,
    required DateTime startOfToday,
  }) async {
    final roots = await _views.rootDeckRows(
      now: now,
      startOfToday: startOfToday,
    );
    final resumable = await _views.resumableSessionRow(
      startOfToday: startOfToday,
    );
    return studyHomeOf(
      roots: roots,
      resumable: resumable,
      round: resumable == null ? null : await _roundOf(resumable.session),
      nextDueAt: await _views.nextDueAt(now: now),
    );
  }

  /// The counts of the round [session] serves, read as the session screen
  /// reads them (spec D3); null while it serves nothing.
  Future<RoundCounts?> _roundOf(StudySession session) async {
    final head = await _queue.headRow(
      session.id,
      session.currentMode,
      session.cursor,
    );
    if (head == null) return null;
    return _views.roundCounts(session.id, head.mode, head.round);
  }
}
