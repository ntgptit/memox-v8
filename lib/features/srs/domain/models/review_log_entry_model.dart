import 'package:memox/features/srs/domain/models/review_kind_model.dart';

/// What one answer adds to `review_log` beyond the session's columns: the
/// turn's kind and the scheduler's values before and after (schema.md). The
/// other scheduler's columns stay null.
final class ReviewLogEntry {
  const ReviewLogEntry({
    required this.kind,
    this.previousBox,
    this.nextBox,
    this.previousEaseFactor,
    this.nextEaseFactor,
    this.previousIntervalDays,
    this.nextIntervalDays,
    this.nextDueAt,
  });

  final ReviewKind kind;
  final int? previousBox;
  final int? nextBox;
  final double? previousEaseFactor;
  final double? nextEaseFactor;
  final int? previousIntervalDays;
  final int? nextIntervalDays;
  final DateTime? nextDueAt;
}
