import 'package:memox/features/monitoring/domain/entities/log_summary_entity.dart';

/// The device buffer as the Not sent tab shows it: the newest rows of the
/// chosen levels, and how many rows wait in all, whatever the level.
final class PendingLogs {
  const PendingLogs({required this.items, required this.total});

  final List<LogSummaryEntity> items;
  final int total;
}
