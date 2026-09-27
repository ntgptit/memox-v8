import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/presentation/providers/watch_app_settings_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_settings_provider.g.dart';

/// The one `app_settings` row, as every surface reads it (BR-SETTINGS-001).
/// Kept alive: the app follows its theme and language for its whole life.
@Riverpod(keepAlive: true)
Stream<AppSettingsEntity> appSettings(Ref ref) =>
    ref.watch(watchAppSettingsUseCaseProvider)();
