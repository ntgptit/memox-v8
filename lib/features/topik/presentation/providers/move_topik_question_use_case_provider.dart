import 'package:memox/features/topik/di/topik_attempt_repository_provider.dart';
import 'package:memox/features/topik/domain/usecases/move_topik_question_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'move_topik_question_use_case_provider.g.dart';

@riverpod
MoveTopikQuestionUseCase moveTopikQuestionUseCase(Ref ref) =>
    MoveTopikQuestionUseCase(ref.watch(topikAttemptRepositoryProvider));
