import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:memox/core/speech/plugin_speech_synthesizer.dart';
import 'package:memox/core/speech/speech_language.dart';
import 'package:memox/core/speech/speech_synthesizer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'speech_providers.g.dart';

/// The device engine on Android; silent everywhere else, the host running
/// the tests included (study speech spec §7). Kept alive: one engine for the
/// app's life.
@Riverpod(keepAlive: true)
SpeechSynthesizer speechSynthesizer(Ref ref) {
  if (kIsWeb || !Platform.isAndroid) return const SilentSpeechSynthesizer();
  return PluginSpeechSynthesizer();
}

/// Whether the device can read [language]; true while the engine has not
/// answered, so nothing is marked missing on a guess. Kept alive, so the
/// speaker does not re-ask and re-flash on every card; a session asks
/// afresh when it opens (`invalidate`), which notices a voice installed
/// meanwhile (audit 2026-10-07).
@Riverpod(keepAlive: true)
Future<bool> speechVoiceAvailable(Ref ref, SpeechLanguage language) =>
    ref.watch(speechSynthesizerProvider).isLanguageAvailable(language);
