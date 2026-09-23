import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'schedule_repository_provider.g.dart';

@riverpod
ScheduleRepository scheduleRepository(Ref ref) =>
    ScheduleRepositoryImpl(ref.watch(databaseProvider));
