import 'package:memox/features/study/di/study_session_repository_provider.dart';
import 'package:memox/features/study/domain/usecases/answer_study_turn_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'answer_study_turn_use_case_provider.g.dart';

@riverpod
AnswerStudyTurnUseCase answerStudyTurnUseCase(Ref ref) =>
    AnswerStudyTurnUseCase(ref.watch(studySessionRepositoryProvider));
