import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:memox/core/speech/plugin_speech_synthesizer.dart';
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
