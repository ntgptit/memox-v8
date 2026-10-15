import 'package:memox/features/topik/di/topik_attempt_repository_provider.dart';
import 'package:memox/features/topik/domain/usecases/record_topik_time_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'record_topik_time_use_case_provider.g.dart';

@riverpod
RecordTopikTimeUseCase recordTopikTimeUseCase(Ref ref) =>
    RecordTopikTimeUseCase(ref.watch(topikAttemptRepositoryProvider));
