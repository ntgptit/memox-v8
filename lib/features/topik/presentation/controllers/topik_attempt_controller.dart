import 'dart:math';

import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/logging/app_logger.dart';
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
/// Time is not ticked. The clock runs only while a question is on screen
/// ([showQuestion]) and the app is in the foreground ([resume]): the moment
/// the current question became current is kept, and the time since is added
/// to that question on the next answer, move, pause or exit. Loading, a read
/// error and the gone states show no question, so they add nothing
/// (BR-TOPIK-015).
///
/// A lap whose write fails or is refused is kept and goes with the next
/// write, so a failed write never loses time; a crash loses only the time
/// since the last successful write (spec §5.4).
///
/// The state is whether a submit runs or has run: a second tap, and every
/// command after it, is ignored (BR-TOPIK-014). A database `Failure` of a
/// command is thrown through; the screen says so. A `Failure` of the pause
/// or exit write, which has no screen to speak on, is logged and its time
/// kept.
@riverpod
class TopikAttemptController extends _$TopikAttemptController {
  /// When the current question's time started; null while the clock is
  /// stopped (no question on screen, or the app in the background).
  DateTime? _since;

  /// Time measured but not yet written: the lap of a write that failed or
  /// was refused, carried into the next write.
  var _carryMs = 0;

  var _isQuestionShown = false;
  var _isForeground = true;

  @override
  bool build(String attemptId) => false;

  /// A question is on screen: the clock runs while the app is in the
  /// foreground. Idempotent, so the screen may say it on every build.
  void showQuestion() {
    _isQuestionShown = true;
    _start();
  }

  /// No question is on screen (loading, an error, a gone state): the time so
  /// far is written and none accrues until [showQuestion].
  Future<void> hideQuestion() {
    _isQuestionShown = false;
    return _stop();
  }

  /// The app is back: the current question's time runs again.
  void resume() {
    _isForeground = true;
    _start();
  }

  /// The app went to the background: the time so far is written, and none
  /// accrues until [resume].
  Future<void> pause() {
    _isForeground = false;
    return _stop();
  }

  /// The screen goes (Close, Back, another route): the time so far is
  /// written.
  Future<void> leave() => _stop();

  /// Saves [selectedIdx] for [questionNo], which becomes current. Null
  /// once a submit runs.
  Future<Outcome<void, TopikRejection>?> answer({
    required int questionNo,
    required int selectedIdx,
  }) async {
    if (state) return null;
    final elapsedMs = _lap();
    return _written(
      elapsedMs,
      () => ref.read(answerTopikQuestionUseCaseProvider)(
        attemptId: attemptId,
        questionNo: questionNo,
        selectedIdx: selectedIdx,
        elapsedMs: elapsedMs,
      ),
    );
  }

  /// Makes [toQuestionNo] current. Null once a submit runs.
  Future<Outcome<void, TopikRejection>?> move(int toQuestionNo) async {
    if (state) return null;
    final elapsedMs = _lap();
    return _written(
      elapsedMs,
      () => ref.read(moveTopikQuestionUseCaseProvider)(
        attemptId: attemptId,
        toQuestionNo: toQuestionNo,
        elapsedMs: elapsedMs,
      ),
    );
  }

  /// Scores and closes the attempt (BR-TOPIK-013). Null when a submit
  /// already runs or ran; a refusal or a failure lets the person go on, the
  /// clock running again only where it ran before.
  Future<Outcome<TopikAttempt, TopikRejection>?> submit(String testId) async {
    if (state) return null;
    state = true;
    final elapsedMs = _lap();
    _since = null;
    var isDone = false;
    try {
      final outcome = await _written(
        elapsedMs,
        () => ref.read(submitTopikAttemptUseCaseProvider)(
          attemptId: attemptId,
          testId: testId,
          elapsedMs: elapsedMs,
        ),
      );
      isDone = outcome is Ok;
      return outcome;
    } finally {
      if (!isDone && ref.mounted) {
        state = false;
        _start();
      }
    }
  }

  /// Deletes the attempt whose content is gone (BR-TOPIK-019).
  Future<Outcome<void, TopikRejection>?> delete() async {
    if (state) return null;
    return ref.read(deleteTopikAttemptUseCaseProvider)(attemptId);
  }

  void _start() {
    if (state || !_isQuestionShown || !_isForeground) return;
    _since ??= ref.read(dayClockProvider).now();
  }

  /// Writes the time so far, if any, and stops the clock.
  Future<void> _stop() async {
    if (state) return;
    final elapsedMs = _lap();
    _since = null;
    if (elapsedMs == 0) return;
    try {
      await _written(
        elapsedMs,
        () => ref.read(recordTopikTimeUseCaseProvider)(
          attemptId: attemptId,
          elapsedMs: elapsedMs,
        ),
      );
    } on Failure catch (failure) {
      // No screen to tell: the time is kept for the next write.
      appLogger.warning(
        'topik.time_not_written',
        category: LogCategory.state,
        context: {'attemptId': attemptId, 'failure': '${failure.runtimeType}'},
      );
    }
  }

  /// Runs [write] with [elapsedMs]; a refusal or a failure keeps the lap for
  /// the next write.
  Future<Outcome<T, TopikRejection>> _written<T>(
    int elapsedMs,
    Future<Outcome<T, TopikRejection>> Function() write,
  ) async {
    try {
      final outcome = await write();
      if (outcome is Rejected) _carryMs += elapsedMs;
      return outcome;
    } on Object {
      _carryMs += elapsedMs;
      rethrow;
    }
  }

  /// The time since the last event plus what earlier writes left unwritten,
  /// and a new start from now while the clock runs.
  int _lap() {
    final carry = _carryMs;
    _carryMs = 0;
    final since = _since;
    if (since == null) return carry;
    final now = ref.read(dayClockProvider).now();
    _since = now;
    return carry + max(0, now.difference(since).inMilliseconds);
  }
}
