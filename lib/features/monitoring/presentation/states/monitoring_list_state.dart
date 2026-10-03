import 'package:flutter/foundation.dart';
import 'package:memox/features/monitoring/domain/entities/log_summary_entity.dart';
import 'package:memox/features/monitoring/domain/models/log_cursor_model.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_load_failure_state.dart';

/// Where the next page stands (monitoring spec §3.2).
enum MonitoringMore { idle, loading, failed }

/// What the Server tab's rows are.
sealed class MonitoringListContent {
  const MonitoringListContent();
}

/// The first page is on its way; no row is shown.
final class MonitoringListLoading extends MonitoringListContent {
  const MonitoringListLoading();
}

/// The pages read so far. Empty is a state the screen words (default
/// filter, or another); [next] is null at the last page.
final class MonitoringListLoaded extends MonitoringListContent {
  const MonitoringListLoaded({
    required this.items,
    required this.next,
    this.more = MonitoringMore.idle,
    this.refreshFailure,
  });

  final List<LogSummaryEntity> items;
  final LogCursor? next;
  final MonitoringMore more;

  /// The last pull to refresh failed and [items] are from the load before
  /// it (SP2b 2.38); null when the rows are current.
  final MonitoringLoadFailure? refreshFailure;

  MonitoringListLoaded withMore(MonitoringMore value) => MonitoringListLoaded(
    items: items,
    next: next,
    more: value,
    refreshFailure: refreshFailure,
  );

  MonitoringListLoaded withItems(List<LogSummaryEntity> value) =>
      MonitoringListLoaded(
        items: value,
        next: next,
        more: more,
        refreshFailure: refreshFailure,
      );

  MonitoringListLoaded withRefreshFailure(MonitoringLoadFailure? value) =>
      MonitoringListLoaded(
        items: items,
        next: next,
        more: more,
        refreshFailure: value,
      );
}

/// The first page failed, or a refresh found the admin role gone; no stale
/// row is shown.
final class MonitoringListFailed extends MonitoringListContent {
  const MonitoringListFailed(this.failure);

  final MonitoringLoadFailure failure;
}

/// The Server tab: the filter asked and what it returned. The filter is
/// always the one the content answers.
@immutable
final class MonitoringListState {
  const MonitoringListState({
    this.filter = const LogFilter(),
    this.content = const MonitoringListLoading(),
  });

  final LogFilter filter;
  final MonitoringListContent content;
}
