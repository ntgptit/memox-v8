import 'dart:async';

import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/models/pending_logs_model.dart';
import 'package:memox/features/monitoring/domain/usecases/watch_pending_logs_use_case.dart';
import 'package:memox/features/monitoring/presentation/providers/watch_pending_logs_use_case_provider.dart';
import 'package:memox/features/monitoring/presentation/states/pending_logs_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_logs_controller.g.dart';

/// The Not sent tab (monitoring spec §3.2): the device buffer, watched, for
/// the levels chosen. It lives as long as the screen, so the tab's count is
/// always the buffer's.
@riverpod
class PendingLogsController extends _$PendingLogsController {
  StreamSubscription<PendingLogs>? _watch;
  late WatchPendingLogsUseCase _watchLogs;

  @override
  PendingLogsState build() {
    _watchLogs = ref.watch(watchPendingLogsUseCaseProvider);
    ref.onDispose(() => unawaited(_watch?.cancel()));
    const initial = PendingLogsState();
    _listen(initial.levels);
    return initial;
  }

  /// Another set of levels; the rows stay until the buffer answers for it.
  void setLevels(Set<LogLevel> levels) {
    state = PendingLogsState(levels: levels, logs: state.logs);
    _listen(levels);
  }

  void _listen(Set<LogLevel> levels) {
    unawaited(_watch?.cancel());
    _watch = _watchLogs(levels).listen(
      (logs) => _show(levels, AsyncData(logs)),
      onError: (Object error, StackTrace stackTrace) =>
          _show(levels, AsyncError(error, stackTrace)),
    );
  }

  void _show(Set<LogLevel> levels, AsyncValue<PendingLogs> logs) {
    if (!ref.mounted) return;
    state = PendingLogsState(levels: levels, logs: logs);
  }
}
