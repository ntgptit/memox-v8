import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/usecases/set_language_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'set_language_use_case_provider.g.dart';

@riverpod
SetLanguageUseCase setLanguageUseCase(Ref ref) =>
    SetLanguageUseCase(ref.watch(settingsRepositoryProvider));
