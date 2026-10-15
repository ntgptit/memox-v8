import 'package:memox/features/topik/di/topik_attempt_repository_provider.dart';
import 'package:memox/features/topik/di/topik_content_repository_provider.dart';
import 'package:memox/features/topik/domain/usecases/submit_topik_attempt_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'submit_topik_attempt_use_case_provider.g.dart';

@riverpod
SubmitTopikAttemptUseCase submitTopikAttemptUseCase(Ref ref) =>
    SubmitTopikAttemptUseCase(
      ref.watch(topikContentRepositoryProvider),
      ref.watch(topikAttemptRepositoryProvider),
    );
