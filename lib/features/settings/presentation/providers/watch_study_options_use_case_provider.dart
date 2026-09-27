import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/usecases/watch_study_options_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_study_options_use_case_provider.g.dart';

@riverpod
WatchStudyOptionsUseCase watchStudyOptionsUseCase(Ref ref) =>
    WatchStudyOptionsUseCase(ref.watch(settingsRepositoryProvider));
