import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

/// The study state of one card under its root's scheduler: the shape of a
/// `card_schedule` row (schema.md). Each variant carries exactly one
/// scheduler's fields; the other scheduler's fields read as null, as the
/// row's columns do.
sealed class CardScheduleState {
  const CardScheduleState({
    required this.generation,
    required this.learnedAt,
    required this.dueAt,
    required this.lastAnsweredAt,
    required this.answerCount,
    required this.lapseCount,
  });

  const factory CardScheduleState.eightBox({
    required int generation,
    required DateTime? learnedAt,
    required DateTime? dueAt,
    required DateTime? lastAnsweredAt,
    required int answerCount,
    required int lapseCount,
    required int currentBox,
  }) = _EightBoxState;

  const factory CardScheduleState.sm2({
    required int generation,
    required DateTime? learnedAt,
    required DateTime? dueAt,
    required DateTime? lastAnsweredAt,
    required int answerCount,
    required int lapseCount,
    required double easeFactor,
    required int intervalDays,
    required int repetitions,
  }) = _Sm2State;

  /// The row a card starts with (BR-CARD-004), and the row the scheduler
  /// change (BR-SRS-004) and the reset (BR-SRS-020) write again: nothing
  /// learned, nothing scheduled, the lowest level of [type], at [generation].
  factory CardScheduleState.initial(
    SchedulerType type, {
    required int generation,
  }) => switch (type) {
    SchedulerType.eightBox => CardScheduleState.eightBox(
      generation: generation,
      learnedAt: null,
      dueAt: null,
      lastAnsweredAt: null,
      answerCount: 0,
      lapseCount: 0,
      currentBox: 1,
    ),
    SchedulerType.sm2 => CardScheduleState.sm2(
      generation: generation,
      learnedAt: null,
      dueAt: null,
      lastAnsweredAt: null,
      answerCount: 0,
      lapseCount: 0,
      easeFactor: 2.5,
      intervalDays: 0,
      repetitions: 0,
    ),
  };

  /// The state a `card_schedule` row holds, column by column (schema.md):
  /// the columns of the scheduler [type] names are set, the other
  /// scheduler's are null, as the row's CHECK constraints keep them.
  factory CardScheduleState.fromColumns({
    required SchedulerType type,
    required int generation,
    required DateTime? learnedAt,
    required DateTime? dueAt,
    required DateTime? lastAnsweredAt,
    required int answerCount,
    required int lapseCount,
    required int? currentBox,
    required double? easeFactor,
    required int? intervalDays,
    required int? repetitions,
  }) => switch (type) {
    SchedulerType.eightBox => CardScheduleState.eightBox(
      generation: generation,
      learnedAt: learnedAt,
      dueAt: dueAt,
      lastAnsweredAt: lastAnsweredAt,
      answerCount: answerCount,
      lapseCount: lapseCount,
      currentBox: currentBox!,
    ),
    SchedulerType.sm2 => CardScheduleState.sm2(
      generation: generation,
      learnedAt: learnedAt,
      dueAt: dueAt,
      lastAnsweredAt: lastAnsweredAt,
      answerCount: answerCount,
      lapseCount: lapseCount,
      easeFactor: easeFactor!,
      intervalDays: intervalDays!,
      repetitions: repetitions!,
    ),
  };

  final int generation;
  final DateTime? learnedAt;
  final DateTime? dueAt;
  final DateTime? lastAnsweredAt;
  final int answerCount;
  final int lapseCount;

  /// `eight_box` only: the box, 1..8.
  int? get currentBox;

  /// `sm2` only.
  double? get easeFactor;

  /// `sm2` only.
  int? get intervalDays;

  /// `sm2` only.
  int? get repetitions;

  /// A copy with the given fields replaced. Passing a field of the other
  /// scheduler is a programming error and throws [ArgumentError].
  CardScheduleState copyWith({
    DateTime? learnedAt,
    DateTime? dueAt,
    DateTime? lastAnsweredAt,
    int? answerCount,
    int? lapseCount,
    int? currentBox,
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
  });
}

final class _EightBoxState extends CardScheduleState {
  const _EightBoxState({
    required super.generation,
    required super.learnedAt,
    required super.dueAt,
    required super.lastAnsweredAt,
    required super.answerCount,
    required super.lapseCount,
    required this.currentBox,
  });

  @override
  final int currentBox;

  @override
  double? get easeFactor => null;

  @override
  int? get intervalDays => null;

  @override
  int? get repetitions => null;

  @override
  CardScheduleState copyWith({
    DateTime? learnedAt,
    DateTime? dueAt,
    DateTime? lastAnsweredAt,
    int? answerCount,
    int? lapseCount,
    int? currentBox,
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
  }) {
    if (easeFactor != null || intervalDays != null || repetitions != null) {
      throw ArgumentError('an eight_box state has no sm2 fields');
    }
    return _EightBoxState(
      generation: generation,
      learnedAt: learnedAt ?? this.learnedAt,
      dueAt: dueAt ?? this.dueAt,
      lastAnsweredAt: lastAnsweredAt ?? this.lastAnsweredAt,
      answerCount: answerCount ?? this.answerCount,
      lapseCount: lapseCount ?? this.lapseCount,
      currentBox: currentBox ?? this.currentBox,
    );
  }
}

final class _Sm2State extends CardScheduleState {
  const _Sm2State({
    required super.generation,
    required super.learnedAt,
    required super.dueAt,
    required super.lastAnsweredAt,
    required super.answerCount,
    required super.lapseCount,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
  });

  @override
  int? get currentBox => null;

  @override
  final double easeFactor;

  @override
  final int intervalDays;

  @override
  final int repetitions;

  @override
  CardScheduleState copyWith({
    DateTime? learnedAt,
    DateTime? dueAt,
    DateTime? lastAnsweredAt,
    int? answerCount,
    int? lapseCount,
    int? currentBox,
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
  }) {
    if (currentBox != null) {
      throw ArgumentError('an sm2 state has no box');
    }
    return _Sm2State(
      generation: generation,
      learnedAt: learnedAt ?? this.learnedAt,
      dueAt: dueAt ?? this.dueAt,
      lastAnsweredAt: lastAnsweredAt ?? this.lastAnsweredAt,
      answerCount: answerCount ?? this.answerCount,
      lapseCount: lapseCount ?? this.lapseCount,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
    );
  }
}
