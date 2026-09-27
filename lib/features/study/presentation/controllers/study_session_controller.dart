import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study/presentation/providers/abandon_study_session_use_case_provider.dart';
import 'package:memox/features/study/presentation/providers/answer_study_turn_use_case_provider.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_session_controller.g.dart';

/// The session screen's one write path (spec D4): answer and abandon, both
/// behind a single in-flight flag, so a second tap while a write runs is
/// dropped instead of racing it (BR-STUDY-004). Reveal, recall time and
/// fill hint join once P4 builds the modes that use them. Mode widgets never
/// call a use case directly.
@riverpod
class StudySessionController extends _$StudySessionController {
  bool _isInFlight = false;

  @override
  void build(String sessionId) {}

  /// Null when a write is already in flight: the tap is dropped, not queued.
  Future<Outcome<TurnResult, StudyRejection>?> answer({
    required String cardId,
    required StudyAnswer answer,
  }) => _guarded(
    () => ref.read(answerStudyTurnUseCaseProvider)(
      sessionId: sessionId,
      cardId: cardId,
      answer: answer,
    ),
  );

  /// UC-STUDY-001 A3: Stop in the exit dialog calls this, from the ✕ and the
  /// system back gesture alike (spec D8, owner ruling 2026-09-27).
  Future<Outcome<void, StudyRejection>?> abandon() => _guarded(
    () => ref.read(abandonStudySessionUseCaseProvider)(sessionId: sessionId),
  );

  Future<T?> _guarded<T>(Future<T> Function() action) async {
    if (_isInFlight) return null;
    _isInFlight = true;
    try {
      return await action();
    } finally {
      _isInFlight = false;
    }
  }
}
