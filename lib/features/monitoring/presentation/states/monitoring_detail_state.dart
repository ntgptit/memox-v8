import 'package:flutter/foundation.dart';
import 'package:memox/features/monitoring/domain/entities/log_record_entity.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_load_failure_state.dart';

/// What the detail page shows of its log.
sealed class MonitoringDetailContent {
  const MonitoringDetailContent();
}

final class MonitoringDetailLoading extends MonitoringDetailContent {
  const MonitoringDetailLoading();
}

final class MonitoringDetailLoaded extends MonitoringDetailContent {
  const MonitoringDetailLoaded(this.record);

  final LogRecordEntity record;
}

/// "This log is gone": cleaned up, or sent from the device since the list.
final class MonitoringDetailGone extends MonitoringDetailContent {
  const MonitoringDetailGone();
}

final class MonitoringDetailFailed extends MonitoringDetailContent {
  const MonitoringDetailFailed(this.failure);

  final MonitoringLoadFailure failure;
}

/// What the page says when a status change ends. Each is a new object, so a
/// listener sees two of the same kind in a row.
sealed class MonitoringDetailNotice {}

final class StatusChanged extends MonitoringDetailNotice {
  StatusChanged(this.status);

  final LogStatus status;
}

/// The change could not be made; [status] and [note] are what to try again.
final class StatusChangeFailed extends MonitoringDetailNotice {
  StatusChangeFailed(this.status, this.note);

  final LogStatus status;
  final String? note;
}

/// The detail page's own state: the log, the status being set (null when
/// none), and the last notice.
@immutable
final class MonitoringDetailState {
  const MonitoringDetailState({
    this.content = const MonitoringDetailLoading(),
    this.changing,
    this.notice,
  });

  final MonitoringDetailContent content;

  /// The status a change in flight sets; one change at a time.
  final LogStatus? changing;
  final MonitoringDetailNotice? notice;
}
