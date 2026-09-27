import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/study/data/datasources/resumable_session_data_source.dart';
import 'package:memox/features/study/data/datasources/study_queue_dao.dart';
import 'package:memox/features/study/data/datasources/study_view_dao.dart';
import 'package:memox/features/study/data/mappers/study_home_mapper.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study/domain/repositories/study_home_repository.dart';

/// Reads the Study tab (UC-STUDY-002; Study Home spec §6): four reads in one
/// transaction, once when listened to and again after every write the tab
/// can see.
final class StudyHomeRepositoryImpl implements StudyHomeRepository {
  factory StudyHomeRepositoryImpl(AppDatabase db) {
    final views = StudyViewDao(db);
    return StudyHomeRepositoryImpl._(
      db,
      views,
      ResumableSessionDataSource(views, StudyQueueDao(db)),
    );
  }

  StudyHomeRepositoryImpl._(this._db, this._views, this._resumable);

  final AppDatabase _db;
  final StudyViewDao _views;
  final ResumableSessionDataSource _resumable;

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
    return studyHomeOf(
      roots: roots,
      resumable: await _resumable.read(startOfToday: startOfToday),
      nextDueAt: await _views.nextDueAt(now: now),
    );
  }
}
