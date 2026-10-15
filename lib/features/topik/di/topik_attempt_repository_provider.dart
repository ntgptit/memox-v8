import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'topik_attempt_repository_provider.g.dart';

@riverpod
TopikAttemptRepository topikAttemptRepository(Ref ref) =>
    TopikAttemptRepositoryImpl(
      ref.watch(databaseProvider),
      now: ref.watch(dayClockProvider).now,
    );
