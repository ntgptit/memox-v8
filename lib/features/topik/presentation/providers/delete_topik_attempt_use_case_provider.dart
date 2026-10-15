import 'package:memox/features/topik/di/topik_attempt_repository_provider.dart';
import 'package:memox/features/topik/domain/usecases/delete_topik_attempt_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'delete_topik_attempt_use_case_provider.g.dart';

@riverpod
DeleteTopikAttemptUseCase deleteTopikAttemptUseCase(Ref ref) =>
    DeleteTopikAttemptUseCase(ref.watch(topikAttemptRepositoryProvider));
