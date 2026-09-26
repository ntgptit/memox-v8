import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/usecases/set_theme_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'set_theme_use_case_provider.g.dart';

@riverpod
SetThemeUseCase setThemeUseCase(Ref ref) =>
    SetThemeUseCase(ref.watch(settingsRepositoryProvider));
