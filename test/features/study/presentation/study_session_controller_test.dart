import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';
import 'package:memox/features/study/domain/usecases/abandon_study_session_use_case.dart';
import 'package:memox/features/study/domain/usecases/answer_study_turn_use_case.dart';
import 'package:memox/features/study/presentation/controllers/study_session_controller.dart';
import 'package:memox/features/study/presentation/providers/abandon_study_session_use_case_provider.dart';
import 'package:memox/features/study/presentation/providers/answer_study_turn_use_case_provider.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';

/// Answers only after [release] is called, so two calls started together
/// race the lock instead of the database.
final class _SlowSessions implements StudySessionRepository {
  final calls = <String>[];
  final _gate = Completer<void>();

  void release() => _gate.complete();

  @override
  Future<Outcome<TurnResult, StudyRejection>> answerTurn({
    required String sessionId,
    required String cardId,
    required StudyAnswer answer,
    DateTime? now,
  }) async {
    calls.add(cardId);
    await _gate.future;
    return const Ok(TurnResult());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'a second answer while one is in flight is dropped (BR-STUDY-004)',
    () async {
      final sessions = _SlowSessions();
      final container = ProviderContainer(
        overrides: [
          answerStudyTurnUseCaseProvider.overrideWithValue(
            AnswerStudyTurnUseCase(sessions),
          ),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        studySessionControllerProvider('s').notifier,
      );

      final first = controller.answer(
        cardId: 'c1',
        answer: const AdvanceAnswer(),
      );
      final second = controller.answer(
        cardId: 'c2',
        answer: const AdvanceAnswer(),
      );
      sessions.release();

      expect(await second, isNull);
      expect(await first, isA<Ok<TurnResult, StudyRejection>>());
      expect(sessions.calls, ['c1']);
    },
  );

  test(
    'the lock releases: a later answer after the first completes runs',
    () async {
      final sessions = _SlowSessions()..release();
      final container = ProviderContainer(
        overrides: [
          answerStudyTurnUseCaseProvider.overrideWithValue(
            AnswerStudyTurnUseCase(sessions),
          ),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        studySessionControllerProvider('s').notifier,
      );

      await controller.answer(cardId: 'c1', answer: const AdvanceAnswer());
      await controller.answer(cardId: 'c2', answer: const AdvanceAnswer());

      expect(sessions.calls, ['c1', 'c2']);
    },
  );

  test(
    'abandon calls AbandonStudySessionUseCase exactly once per tap',
    () async {
      final calls = <String>[];
      final container = ProviderContainer(
        overrides: [
          abandonStudySessionUseCaseProvider.overrideWithValue(
            AbandonStudySessionUseCase(_AbandonSpy(calls)),
          ),
        ],
      );
      addTearDown(container.dispose);

      final outcome = await container
          .read(studySessionControllerProvider('s').notifier)
          .abandon();

      expect(outcome, isA<Ok<void, StudyRejection>>());
      expect(calls, ['s']);
    },
  );
}

final class _AbandonSpy implements StudySessionRepository {
  _AbandonSpy(this.calls);

  final List<String> calls;

  @override
  Future<Outcome<void, StudyRejection>> abandonSession({
    required String sessionId,
    DateTime? now,
  }) async {
    calls.add(sessionId);
    return const Ok(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
