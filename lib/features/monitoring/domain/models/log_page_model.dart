import 'package:memox/features/monitoring/domain/entities/log_summary_entity.dart';
import 'package:memox/features/monitoring/domain/models/log_cursor_model.dart';

/// One page of the server's logs, newest first.
final class LogPage {
  const LogPage({required this.items});

  /// The most a page holds; the server never sends more.
  static const int size = 100;

  final List<LogSummaryEntity> items;

  /// Where the next page starts, or null when this page was not full and so
  /// the last one.
  LogCursor? get next {
    if (items.length < size) return null;
    final last = items.last;
    return LogCursor(occurredAt: last.occurredAt, id: last.id);
  }
}
