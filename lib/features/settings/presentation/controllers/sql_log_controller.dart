import 'package:memox/features/settings/presentation/providers/set_log_sql_statements_use_case_provider.dart';
import 'package:memox/features/settings/presentation/states/sql_log_state.dart';
import 'package:memox/shared/support/held_run.dart';
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
    final outcome = await runHeld(
      () => ref.read(setLogSqlStatementsUseCaseProvider)(enabled: enabled),
      // A bug takes the Failure's way out: the switch is reported once.
      onFailed: (_) {},
    );
    if (ref.mounted) state = SqlLogState(hasFailure: outcome == null);
  }

  void dismissFailure() => state = const SqlLogState();
}
