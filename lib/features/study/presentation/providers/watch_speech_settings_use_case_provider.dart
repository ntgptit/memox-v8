import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/study/domain/usecases/watch_speech_settings_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_speech_settings_use_case_provider.g.dart';

@riverpod
WatchSpeechSettingsUseCase watchSpeechSettingsUseCase(Ref ref) =>
    WatchSpeechSettingsUseCase(ref.watch(settingsRepositoryProvider));
