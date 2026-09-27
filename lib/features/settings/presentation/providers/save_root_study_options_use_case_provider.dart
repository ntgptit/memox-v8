import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/usecases/save_root_study_options_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'save_root_study_options_use_case_provider.g.dart';

@riverpod
SaveRootStudyOptionsUseCase saveRootStudyOptionsUseCase(Ref ref) =>
    SaveRootStudyOptionsUseCase(ref.watch(settingsRepositoryProvider));
