import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/reminders/data/repositories/reminder_workload_repository_impl.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_workload_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reminder_workload_repository_provider.g.dart';

@riverpod
ReminderWorkloadRepository reminderWorkloadRepository(Ref ref) =>
    ReminderWorkloadRepositoryImpl(ref.watch(databaseProvider));
