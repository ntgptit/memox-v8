import 'package:memox/features/settings/domain/models/speech_settings_model.dart';
import 'package:memox/features/study/presentation/providers/watch_speech_settings_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'speech_settings_provider.g.dart';

/// The switch and the language the session of [deckId] reads with, live
/// (BR-STUDY-080).
@riverpod
Stream<SpeechSettings?> speechSettings(Ref ref, String deckId) =>
    ref.watch(watchSpeechSettingsUseCaseProvider)(deckId: deckId);
