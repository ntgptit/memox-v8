import 'package:memox/features/topik/di/topik_attempt_repository_provider.dart';
import 'package:memox/features/topik/domain/usecases/answer_topik_question_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'answer_topik_question_use_case_provider.g.dart';

@riverpod
AnswerTopikQuestionUseCase answerTopikQuestionUseCase(Ref ref) =>
    AnswerTopikQuestionUseCase(ref.watch(topikAttemptRepositoryProvider));
