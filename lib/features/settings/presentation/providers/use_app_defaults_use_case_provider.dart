import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/usecases/use_app_defaults_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'use_app_defaults_use_case_provider.g.dart';

@riverpod
UseAppDefaultsUseCase useAppDefaultsUseCase(Ref ref) =>
    UseAppDefaultsUseCase(ref.watch(settingsRepositoryProvider));
