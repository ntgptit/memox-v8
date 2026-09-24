import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// UC-SETTINGS-001 step 1: the values in force, again after every save
/// (BR-SETTINGS-001).
final class WatchAppSettingsUseCase {
  const WatchAppSettingsUseCase(this._settings);

  final SettingsRepository _settings;

  Stream<AppSettingsEntity> call() => _settings.watchAppSettings();
}
