import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

/// One answer in a card's history with the values its `review_log` row
/// stored (BR-CARD-016): nothing is inferred from before and after.
final class ReviewHistoryEntry {
  const ReviewHistoryEntry({
    required this.id,
    required this.generation,
    required this.schedulerType,
    required this.kind,
    required this.mode,
    required this.action,
    required this.answeredAt,
    required this.isTimedOut,
    required this.usedHint,
    required this.nextDueAt,
    required this.previousBox,
    required this.nextBox,
    required this.previousEaseFactor,
    required this.nextEaseFactor,
    required this.previousIntervalDays,
    required this.nextIntervalDays,
  });

  final String id;

  /// The history groups by it (BR-CARD-017).
  final int generation;

  /// Which before and after values the entry holds.
  final SchedulerType schedulerType;
  final ReviewKind kind;

  /// The study mode code as stored (BR-MODE-008), such as `recall`. The
  /// study feature owns the modes and their labels.
  final String mode;

  /// An `EightBoxAction` or a `Sm2Action`, after [schedulerType].
  final Enum action;
  final DateTime answeredAt;

  /// The answer timed out (BR-STUDY-034).
  final bool isTimedOut;

  /// Set on a `fill` answer only (BR-STUDY-028).
  final bool? usedHint;

  /// Null on a turn that does not move the schedule (BR-STUDY-053).
  final DateTime? nextDueAt;
  final int? previousBox;
  final int? nextBox;
  final double? previousEaseFactor;
  final double? nextEaseFactor;
  final int? previousIntervalDays;
  final int? nextIntervalDays;
}

/// Where the next page starts: the last entry shown (BR-CARD-015).
final class ReviewHistoryCursor {
  const ReviewHistoryCursor({required this.answeredAt, required this.id});

  final DateTime answeredAt;
  final String id;
}

/// One page of a card's history, newest first. An empty page is a valid
/// answer (BR-CARD-018).
final class ReviewHistoryPage {
  const ReviewHistoryPage({required this.entries, required this.next});

  /// At most [size] entries.
  static const size = 50;

  final List<ReviewHistoryEntry> entries;

  /// Null on the last page.
  final ReviewHistoryCursor? next;
}
