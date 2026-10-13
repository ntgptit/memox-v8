import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// The SQL log switch, saved on the tap (SQL log switch spec §4.4).
final class SetLogSqlStatementsUseCase {
  const SetLogSqlStatementsUseCase(this._settings);

  final SettingsRepository _settings;

  Future<Outcome<void, SettingsRejection>> call({required bool enabled}) =>
      _settings.setLogSqlStatements(enabled: enabled);
}
