import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/usecases/watch_app_settings_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_app_settings_use_case_provider.g.dart';

@riverpod
WatchAppSettingsUseCase watchAppSettingsUseCase(Ref ref) =>
    WatchAppSettingsUseCase(ref.watch(settingsRepositoryProvider));
