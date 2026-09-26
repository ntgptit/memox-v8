import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/usecases/save_study_defaults_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'save_study_defaults_use_case_provider.g.dart';

@riverpod
SaveStudyDefaultsUseCase saveStudyDefaultsUseCase(Ref ref) =>
    SaveStudyDefaultsUseCase(ref.watch(settingsRepositoryProvider));
