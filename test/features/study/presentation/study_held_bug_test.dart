import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/di/study_entry_repository_provider.dart';
import 'package:memox/features/study/di/study_session_repository_provider.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study/domain/repositories/study_entry_repository.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';
import 'package:memox/features/study/presentation/controllers/study_entry_controller.dart';
import 'package:memox/features/study/presentation/controllers/study_home_controller.dart';
import 'package:memox/features/study/presentation/controllers/study_session_controller.dart';
import 'package:memox/features/study/presentation/states/study_home_resume_state.dart';
import 'package:memox/features/study/presentation/states/study_start_state.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';

import '../../../support/held_bug.dart';
import '../../../support/held_bug_capture.dart';

/// A session store whose every write dies on a bug, not a Failure
/// (ADR-016).
final class _BuggySessions implements StudySessionRepository {
  @override
  Future<Outcome<TurnResult, StudyRejection>> answerTurn({
    required String sessionId,
    required String cardId,
    required StudyAnswer answer,
    DateTime? now,
  }) async => throw heldBug();

  @override
  Future<Outcome<void, StudyRejection>> revealRecallAnswer({
    required String sessionId,
    required String cardId,
    required int remainingMs,
    DateTime? now,
  }) async => throw heldBug();

  @override
  Future<Outcome<void, StudyRejection>> showFillHint({
    required String sessionId,
    required String cardId,
    DateTime? now,
  }) async => throw heldBug();

  @override
  Future<Outcome<void, StudyRejection>> resumeSession({
    required String sessionId,
    DateTime? now,
  }) async => throw heldBug();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// An entry store whose open dies on a bug.
final class _BuggyEntries implements StudyEntryRepository {
  @override
  Future<Outcome<String, StudyRejection>> openLearningSession({
    required String deckId,
    DateTime? now,
  }) async => throw heldBug();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _item = StudyItem(
  cardId: 'c1',
  front: 'abandon',
  back: 'từ bỏ',
  example: null,
  hint: null,
  pronunciation: null,
  round: 1,
  answersInSession: 0,
  direction: null,
  remainingMs: null,
  isRevealed: false,
);

// LIB-6: a held write that meets a bug releases its flow and reports the
// bug (runHeld). Study's flows end as they do for a Failure.
void main() {
  ProviderContainer buggy() {
    final container = ProviderContainer(
      overrides: [
        studySessionRepositoryProvider.overrideWithValue(_BuggySessions()),
        studyEntryRepositoryProvider.overrideWithValue(_BuggyEntries()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  StudySessionController session(ProviderContainer container) {
    final provider = studySessionControllerProvider('s1');
    container.listen(provider, (_, _) {});
    return container.read(provider.notifier);
  }

  test('an answer that dies on a bug is no longer busy and keeps nothing '
      'held (_answer)', () async {
    final container = buggy();
    final reported = captureReportedBugs();

    await session(container).answer(_item, const AdvanceAnswer());

    expectOneBugReported(reported);
    final state = container.read(studySessionControllerProvider('s1'));
    expect(state.isBusy, isFalse);
    expect(state.isLocked, isFalse);
    expect(state.held, isNull);
  });

  test(
    'a recall reveal that dies on a bug is no longer busy (_write)',
    () async {
      final container = buggy();
      final reported = captureReportedBugs();

      await session(container).revealRecall(_item, 5000);

      expectOneBugReported(reported);
      expect(
        container.read(studySessionControllerProvider('s1')).isBusy,
        isFalse,
      );
    },
  );

  test('a fill hint that dies on a bug is no longer busy (_write)', () async {
    final container = buggy();
    final reported = captureReportedBugs();

    await session(container).showFillHint(_item);

    expectOneBugReported(reported);
    expect(
      container.read(studySessionControllerProvider('s1')).isBusy,
      isFalse,
    );
  });

  test('a settle that dies on a bug is no longer busy, so the stalled '
      'round can settle again (settle)', () async {
    final container = buggy();
    final reported = captureReportedBugs();
    final controller = session(container);

    await controller.settle();

    expectOneBugReported(reported);
    expect(
      container.read(studySessionControllerProvider('s1')).isBusy,
      isFalse,
    );
    await controller.settle();
    expect(reported, hasLength(2));
  });

  test('a start that dies on a bug ends failed with Try again, as a '
      'Failure does (start)', () async {
    final container = buggy();
    final provider = studyEntryControllerProvider('d1');
    container.listen(provider, (_, _) {});
    final reported = captureReportedBugs();

    final id = await container
        .read(provider.notifier)
        .start(const LearnStart());

    expect(id, isNull);
    expectOneBugReported(reported);
    final state = container.read(provider);
    expect(state.status, StudyStartStatus.failed);
    expect(state.isStarting, isFalse);
    expect(state.lastStart, isA<LearnStart>());
  });

  test('a Resume that dies on a bug is no longer running and answers '
      'ResumeFailed, as a Failure does (resume)', () async {
    final container = buggy();
    container.listen(studyHomeControllerProvider, (_, _) {});
    final reported = captureReportedBugs();

    final result = await container
        .read(studyHomeControllerProvider.notifier)
        .resume('s1');

    expect(result, isA<ResumeFailed>());
    expectOneBugReported(reported);
    expect(container.read(studyHomeControllerProvider), isFalse);
  });
}
