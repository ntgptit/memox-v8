import 'package:memox/features/topik/di/topik_attempt_repository_provider.dart';
import 'package:memox/features/topik/di/topik_content_repository_provider.dart';
import 'package:memox/features/topik/domain/usecases/start_topik_attempt_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'start_topik_attempt_use_case_provider.g.dart';

@riverpod
StartTopikAttemptUseCase startTopikAttemptUseCase(Ref ref) =>
    StartTopikAttemptUseCase(
      ref.watch(topikContentRepositoryProvider),
      ref.watch(topikAttemptRepositoryProvider),
    );
