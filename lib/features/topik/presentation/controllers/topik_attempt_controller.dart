import 'dart:math';

import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/presentation/providers/answer_topik_question_use_case_provider.dart';
import 'package:memox/features/topik/presentation/providers/delete_topik_attempt_use_case_provider.dart';
import 'package:memox/features/topik/presentation/providers/move_topik_question_use_case_provider.dart';
import 'package:memox/features/topik/presentation/providers/record_topik_time_use_case_provider.dart';
import 'package:memox/features/topik/presentation/providers/submit_topik_attempt_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'topik_attempt_controller.g.dart';

/// Screen 37's commands and its question clock (spec §5.4, §13.6).
///
/// Time is not ticked. The moment the current question became current is
/// kept, and the time since is added to that question on the next answer,
/// move, pause or exit. While paused (the app in the background) none
/// accrues.
///
/// The state is whether a submit runs or has run: a second tap, and every
/// command after it, is ignored (BR-TOPIK-014). A database `Failure` is
/// thrown through; the screen says so.
@riverpod
class TopikAttemptController extends _$TopikAttemptController {
  /// When the current question's time started; null while paused.
  DateTime? _since;

  @override
  bool build(String attemptId) {
    _since = ref.watch(dayClockProvider).now();
    return false;
  }

  /// Saves [selectedIdx] for [questionNo], which becomes current. Null
  /// once a submit runs.
  Future<Outcome<void, TopikRejection>?> answer({
    required int questionNo,
    required int selectedIdx,
  }) async {
    if (state) return null;
    return ref.read(answerTopikQuestionUseCaseProvider)(
      attemptId: attemptId,
      questionNo: questionNo,
      selectedIdx: selectedIdx,
      elapsedMs: _lap(),
    );
  }

  /// Makes [toQuestionNo] current. Null once a submit runs.
  Future<Outcome<void, TopikRejection>?> move(int toQuestionNo) async {
    if (state) return null;
    return ref.read(moveTopikQuestionUseCaseProvider)(
      attemptId: attemptId,
      toQuestionNo: toQuestionNo,
      elapsedMs: _lap(),
    );
  }

  /// The app went to the background, or the screen goes: the time so far
  /// is written, and none accrues until [resume].
  Future<void> pause() async {
    if (state || _since == null) return;
    final elapsedMs = _lap();
    _since = null;
    await ref.read(recordTopikTimeUseCaseProvider)(
      attemptId: attemptId,
      elapsedMs: elapsedMs,
    );
  }

  /// The app is back: the current question's time runs again.
  void resume() {
    if (state) return;
    _since ??= ref.read(dayClockProvider).now();
  }

  /// The screen goes (Close, Back, another route): as [pause].
  Future<void> leave() => pause();

  /// Scores and closes the attempt (BR-TOPIK-013). Null when a submit
  /// already runs or ran; a refusal or a failure lets the person go on.
  Future<Outcome<TopikAttempt, TopikRejection>?> submit(String testId) async {
    if (state) return null;
    state = true;
    final elapsedMs = _lap();
    _since = null;
    var isDone = false;
    try {
      final outcome = await ref.read(submitTopikAttemptUseCaseProvider)(
        attemptId: attemptId,
        testId: testId,
        elapsedMs: elapsedMs,
      );
      isDone = outcome is Ok;
      return outcome;
    } finally {
      if (!isDone && ref.mounted) {
        state = false;
        _since = ref.read(dayClockProvider).now();
      }
    }
  }

  /// Deletes the attempt whose content is gone (BR-TOPIK-019).
  Future<Outcome<void, TopikRejection>?> delete() async {
    if (state) return null;
    return ref.read(deleteTopikAttemptUseCaseProvider)(attemptId);
  }

  /// The time since the last event, and a new start from now.
  int _lap() {
    final since = _since;
    if (since == null) return 0;
    final now = ref.read(dayClockProvider).now();
    _since = now;
    return max(0, now.difference(since).inMilliseconds);
  }
}
