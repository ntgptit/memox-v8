import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/progress/data/datasources/progress_dao.dart';
import 'package:memox/features/progress/data/mappers/progress_mapper.dart';
import 'package:memox/features/progress/domain/models/progress_days_model.dart';
import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/progress/domain/models/progress_overview_model.dart';
import 'package:memox/features/progress/domain/repositories/progress_repository.dart';

/// Reads the Progress screen (UC-PROGRESS-001, UC-PROGRESS-002; Progress
/// spec §6): its statements in one transaction, once when listened to and
/// again after every write it can see.
final class ProgressRepositoryImpl implements ProgressRepository {
  ProgressRepositoryImpl(this._db) : _progress = ProgressDao(_db);

  final AppDatabase _db;
  final ProgressDao _progress;

  @override
  Stream<Progress> watchProgress(ProgressDays days) => _progress
      .changes()
      .asyncMap((_) => _db.transaction(() => _progressOf(days)))
      .mapDatabaseErrors();

  /// The history's days, the last seven with their split and the root
  /// level, read in the caller's transaction, so Today, the streak and the
  /// deck numbers see one state of the database (UC-PROGRESS-001 step 4).
  Future<Progress> _progressOf(ProgressDays days) async => Progress(
    overview: progressOverviewOf(
      activeDays: await _progress.activeDays(days),
      week: activeDaysOf(await _progress.weekActivity(days)),
      days: days,
    ),
    level: levelOf(await _progress.rootLevel(days)),
    validUntil: days.validUntil,
  );
}
