import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/usecases/reset_app_settings_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reset_app_settings_use_case_provider.g.dart';

@riverpod
ResetAppSettingsUseCase resetAppSettingsUseCase(Ref ref) =>
    ResetAppSettingsUseCase(ref.watch(settingsRepositoryProvider));
