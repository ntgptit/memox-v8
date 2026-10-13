import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/usecases/set_speech_auto_play_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'set_speech_auto_play_use_case_provider.g.dart';

@riverpod
SetSpeechAutoPlayUseCase setSpeechAutoPlayUseCase(Ref ref) =>
    SetSpeechAutoPlayUseCase(ref.watch(settingsRepositoryProvider));
