import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/speech/plugin_speech_synthesizer.dart';
import 'package:memox/core/speech/speech_language.dart';

import '../../support/recording_log_sink.dart';

// The one door to the engine (study speech spec §7, BR-STUDY-081): the
// language is set before every reading, a language the device lacks is
// logged and not read in another voice, a failing engine never throws.

/// The plugin with its platform calls recorded instead of sent.
class _FakeTts extends FlutterTts {
  final calls = <String>[];

  /// What `setLanguage` answers: 1 is available on Android, 0 is not.
  int languageResult = 1;
  bool throwOnSpeak = false;

  @override
  Future<dynamic> setLanguage(String language) async {
    calls.add('setLanguage:$language');
    return languageResult;
  }

  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    calls.add('speak:$text');
    if (throwOnSpeak) throw PlatformException(code: 'engine');
    return 1;
  }

  @override
  Future<dynamic> stop() async {
    calls.add('stop');
    return 1;
  }

  @override
  Future<dynamic> get getLanguages async => ['en-US', 'ko-KR'];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakeTts tts;
  late PluginSpeechSynthesizer door;
  late RecordingLogSink log;
  late AppLogger previous;

  setUp(() {
    tts = _FakeTts();
    door = PluginSpeechSynthesizer(tts: tts);
    log = RecordingLogSink();
    previous = appLogger;
    AppLogger.install(AppLogger(sinks: [log]));
  });
  tearDown(() => AppLogger.install(previous));

  test('a reading stops the last one and sets the language first, every '
      'time (BR-STUDY-082, spec §7)', () async {
    await door.speak('abandon', language: SpeechLanguage.enUs);
    await door.speak('abandon', language: SpeechLanguage.enUs);

    expect(tts.calls, [
      'stop',
      'setLanguage:en-US',
      'speak:abandon',
      'stop',
      'setLanguage:en-US',
      'speak:abandon',
    ]);
    expect(log.events, isEmpty);
  });

  test('a language the device lacks is logged and not read in another '
      'voice (BR-STUDY-081, D5)', () async {
    tts.languageResult = 0;

    await door.speak('먹다', language: SpeechLanguage.koKr);

    expect(tts.calls, ['stop', 'setLanguage:ko-KR']);
    expect(log.events, ['speech.language_unavailable']);
    expect(log.entries.single.context['language'], 'ko-KR');
  });

  test('a failing engine is a warning, never a throw (BR-STUDY-081)', () async {
    tts.throwOnSpeak = true;

    await door.speak('abandon', language: SpeechLanguage.enUs);

    expect(log.events, ['speech.speak_failed']);
    expect(log.entries.single.message, isNot(contains('abandon')));
  });

  test('a blank term asks the engine for nothing', () async {
    await door.speak('   ', language: SpeechLanguage.enUs);

    expect(tts.calls, isEmpty);
  });

  test('the languages the engine reports come back as a set of tags', () async {
    expect(await door.availableLanguageTags(), {'en-US', 'ko-KR'});
  });
}
