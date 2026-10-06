/// Which of two schedules of one card has progressed further: library and
/// study sync spec §3.4, ADR-017. Pure, so the order is tested rule by rule.
library;

/// What spec §3.4 compares; the rest of a schedule row does not take part.
typedef ScheduleProgress = ({
  int generation,
  String schedulerType,
  DateTime? lastAnsweredAt,
  DateTime? learnedAt,
  int answerCount,
});

/// Positive when [local] has progressed further than [pulled] (spec §3.4):
/// generation, then matching the root's scheduler, then the later answer
/// (none first), then learned over not, then more answers. Zero on a tie.
int compareScheduleProgress(
  ScheduleProgress local,
  ScheduleProgress pulled, {
  required String? rootSchedulerType,
}) {
  final generation = local.generation.compareTo(pulled.generation);
  if (generation != 0) return generation;
  if (rootSchedulerType != null) {
    final localMatches = local.schedulerType == rootSchedulerType;
    final pulledMatches = pulled.schedulerType == rootSchedulerType;
    if (localMatches != pulledMatches) return localMatches ? 1 : -1;
  }
  final answered = _compareNullsFirst(
    local.lastAnsweredAt,
    pulled.lastAnsweredAt,
  );
  if (answered != 0) return answered;
  final learned =
      (local.learnedAt != null ? 1 : 0) - (pulled.learnedAt != null ? 1 : 0);
  if (learned != 0) return learned;
  return local.answerCount.compareTo(pulled.answerCount);
}

int _compareNullsFirst(DateTime? a, DateTime? b) {
  if (a == null || b == null) return (a == null ? 0 : 1) - (b == null ? 0 : 1);
  return a.compareTo(b);
}
