import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/usecases/set_log_sql_statements_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'set_log_sql_statements_use_case_provider.g.dart';

@riverpod
SetLogSqlStatementsUseCase setLogSqlStatementsUseCase(Ref ref) =>
    SetLogSqlStatementsUseCase(ref.watch(settingsRepositoryProvider));
