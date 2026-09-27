import 'package:memox/features/study/di/study_session_repository_provider.dart';
import 'package:memox/features/study/domain/usecases/reveal_recall_answer_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reveal_recall_answer_use_case_provider.g.dart';

@riverpod
RevealRecallAnswerUseCase revealRecallAnswerUseCase(Ref ref) =>
    RevealRecallAnswerUseCase(ref.watch(studySessionRepositoryProvider));
