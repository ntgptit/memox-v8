import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/reminders/data/datasources/reminder_workload_dao.dart';
import 'package:memox/features/reminders/data/mappers/reminder_workload_mapper.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_workload_repository.dart';

final class ReminderWorkloadRepositoryImpl
    implements ReminderWorkloadRepository {
  ReminderWorkloadRepositoryImpl(AppDatabase db)
    : _dao = ReminderWorkloadDao(db);

  final ReminderWorkloadDao _dao;

  @override
  Future<List<ReminderDeckWorkload>> rootWorkloads({
    required DateTime now,
    required DateTime startOfToday,
  }) async {
    try {
      final rows = await _dao.rootDeckRows(
        now: now,
        startOfToday: startOfToday,
      );
      return [
        for (final row in rows) reminderDeckWorkloadOf(row, startOfToday),
      ];
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
  }
}
