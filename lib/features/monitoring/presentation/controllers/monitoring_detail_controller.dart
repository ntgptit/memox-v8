import 'dart:async';

import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/monitoring/domain/entities/log_record_entity.dart';
import 'package:memox/features/monitoring/domain/failures/monitoring_failure.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/presentation/controllers/monitoring_list_controller.dart';
import 'package:memox/features/monitoring/presentation/providers/get_pending_log_use_case_provider.dart';
import 'package:memox/features/monitoring/presentation/providers/get_server_log_use_case_provider.dart';
import 'package:memox/features/monitoring/presentation/providers/set_log_status_use_case_provider.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_detail_state.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_load_failure_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'monitoring_detail_controller.g.dart';

/// The detail page of one log (monitoring spec §3.3): read from the server,
/// or from the device buffer when [isLocal]; and, for a warning or an error
/// of the server, marked fixed or reopened. One change at a time.
@riverpod
class MonitoringDetailController extends _$MonitoringDetailController {
  @override
  MonitoringDetailState build(String id, bool isLocal) {
    Future.microtask(_load);
    return const MonitoringDetailState();
  }

  /// After a failure: read it again.
  Future<void> retry() {
    state = const MonitoringDetailState();
    return _load();
  }

  /// Marks the log [status], with an optional [note]. The row shows the
  /// server's answer, and the list drops or updates its row; a failure
  /// leaves everything as it was and offers the same change again.
  Future<void> setStatus(LogStatus status, {String? note}) async {
    final current = state.content;
    if (current is! MonitoringDetailLoaded ||
        !current.record.canTriage ||
        state.changing != null) {
      return;
    }
    state = MonitoringDetailState(content: current, changing: status);
    // The page may close before the server answers; the answer still
    // reaches the list (final review I1).
    final alive = ref.keepAlive();
    try {
      final outcome = await ref.read(setLogStatusUseCaseProvider)(
        id,
        status,
        note: note,
      );
      if (!ref.mounted) return;
      switch (outcome) {
        case Ok(:final value):
          _changed(value, status);
        case Rejected(reason: MonitoringRejection.notFound):
          state = const MonitoringDetailState(content: MonitoringDetailGone());
      }
    } on Object {
      if (!ref.mounted) return;
      state = MonitoringDetailState(
        content: current,
        notice: StatusChangeFailed(status, note),
      );
    } finally {
      alive.close();
    }
  }

  void _changed(LogRecordEntity record, LogStatus status) {
    state = MonitoringDetailState(
      content: MonitoringDetailLoaded(record),
      notice: StatusChanged(status),
    );
    if (ref.exists(monitoringListControllerProvider)) {
      ref
          .read(monitoringListControllerProvider.notifier)
          .statusChanged(id, status);
    }
  }

  Future<void> _load() async {
    try {
      final outcome = isLocal
          ? await ref.read(getPendingLogUseCaseProvider)(id)
          : await ref.read(getServerLogUseCaseProvider)(id);
      if (!ref.mounted) return;
      state = MonitoringDetailState(
        content: switch (outcome) {
          Ok(:final value) => MonitoringDetailLoaded(value),
          Rejected() => const MonitoringDetailGone(),
        },
      );
    } on Object catch (error) {
      if (!ref.mounted) return;
      state = MonitoringDetailState(
        content: MonitoringDetailFailed(MonitoringLoadFailure.of(error)),
      );
    }
  }
}
