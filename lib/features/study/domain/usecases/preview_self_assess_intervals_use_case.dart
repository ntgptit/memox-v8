import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/features/srs/domain/models/interval_preview_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/srs/domain/models/schedulers_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';
import 'package:memox/features/study/domain/models/turn_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';

/// Screen 16a's interval preview (FE-A6 D11): on a `scheduled` turn, the
/// interval each grade would give the card; null on a learning or
/// relearning turn, whose answer moves no schedule (BR-SRS-016, BR-SRS-017),
/// and for a card gone meanwhile. Read-only.
final class PreviewSelfAssessIntervalsUseCase {
  const PreviewSelfAssessIntervalsUseCase(this._schedules, this._clock);

  final ScheduleRepository _schedules;
  final DayClock _clock;

  Future<Map<Object, int>?> call({
    required SessionKind kind,
    required String cardId,
    required int round,
    required int answersInSession,
  }) async {
    final turn = turnKindOf(
      kind,
      round: round,
      answersInSession: answersInSession,
    );
    if (turn != ReviewKind.scheduled) return null;
    final stored = await _schedules.scheduleOf(cardId: cardId);
    if (stored == null) return null;
    final (type, state) = stored;
    // A scheduled turn on a card still learning is a bug the write refuses
    // (BR-STUDY-058); the preview shows nothing rather than throw.
    if (state.learnedAt == null) return null;
    return nextIntervalsOf(schedulerFor(type), state, _clock.now());
  }
}
