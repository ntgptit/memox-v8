import 'package:memox/core/error/failure.dart';
import 'package:memox/features/settings/presentation/providers/set_log_sql_statements_use_case_provider.dart';
import 'package:memox/features/settings/presentation/states/sql_log_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sql_log_controller.g.dart';

/// The SQL log switch's save (SQL log switch spec §5): one at a time, a
/// second tap while one runs is ignored, a failed write is reported once.
@riverpod
class SqlLogController extends _$SqlLogController {
  @override
  SqlLogState build() => const SqlLogState();

  Future<void> set({required bool enabled}) async {
    if (state.isSaving) return;
    state = const SqlLogState(isSaving: true);
    try {
      await ref.read(setLogSqlStatementsUseCaseProvider)(enabled: enabled);
      state = const SqlLogState();
    } on Failure {
      state = const SqlLogState(hasFailure: true);
    }
  }

  void dismissFailure() => state = const SqlLogState();
}
