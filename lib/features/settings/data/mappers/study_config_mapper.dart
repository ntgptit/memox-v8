import 'dart:convert';

import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/speech/speech_language.dart';
import 'package:memox/features/settings/data/mappers/app_settings_mapper.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';

// The keys of `deck.study_config` (spec D5; study speech spec §4).
const _cardLimitKey = 'card_limit';
const _newCardOrderKey = 'new_card_order';
const _speechLanguageKey = 'tts_language';

/// The JSON a root keeps [options] in (spec D5).
String studyConfigOf(StudyOptions options) => jsonEncode({
  _cardLimitKey: options.cardLimit,
  _newCardOrderKey: options.newCardOrder.name,
  _speechLanguageKey: options.speechLanguage.tag,
});

/// The options [studyConfig] holds, or null when it cannot be read: not a
/// JSON object, a key missing, a value of the wrong type, an unknown order,
/// a card limit out of bounds or an unknown speech language (D5). A key the
/// app does not know is ignored; a missing `tts_language` is the default
/// (study speech spec D6).
StudyOptions? studyOptionsOf(String studyConfig) {
  final Object? decoded;
  try {
    decoded = jsonDecode(studyConfig);
  } on FormatException {
    return null;
  }
  if (decoded is! Map<String, Object?>) return null;
  final cardLimit = decoded[_cardLimitKey];
  final newCardOrder = NewCardOrder.values
      .asNameMap()[decoded[_newCardOrderKey]];
  final speechLanguage = _speechLanguageOf(decoded[_speechLanguageKey]);
  if (cardLimit is! int || newCardOrder == null || speechLanguage == null) {
    return null;
  }
  final options = StudyOptions(
    cardLimit: cardLimit,
    newCardOrder: newCardOrder,
    speechLanguage: speechLanguage,
  );
  if (options.check() case Rejected()) return null;
  return options;
}

/// The options in force under [root]: its override when it can be read, the
/// app-wide defaults of [settings] otherwise (BR-STUDY-056). An unreadable
/// override is reported, never repaired here (IT-STUDY-013).
EffectiveStudyOptions effectiveStudyOptionsOf(Deck root, AppSetting settings) {
  final appDefaults = _checkedAppDefaults(settings);
  final studyConfig = root.studyConfig;
  if (studyConfig == null) {
    return EffectiveStudyOptions(
      rootDeckId: root.id,
      rootDeckName: root.name,
      options: appDefaults,
      source: StudyOptionsSource.appDefaults,
    );
  }
  final override = studyOptionsOf(studyConfig);
  if (override == null) {
    return EffectiveStudyOptions(
      rootDeckId: root.id,
      rootDeckName: root.name,
      options: appDefaults,
      source: StudyOptionsSource.unreadableRootOverride,
    );
  }
  return EffectiveStudyOptions(
    rootDeckId: root.id,
    rootDeckName: root.name,
    options: override,
    source: StudyOptionsSource.rootOverride,
  );
}

/// The app-wide defaults of [settings], held to the same rule as an override
/// (BR-STUDY-003): a row outside it, which no write path of a released build
/// makes, studies with the fresh-install defaults (DEV-214).
StudyOptions _checkedAppDefaults(AppSetting settings) {
  final appDefaults = appSettingsOf(settings).studyDefaults;
  if (appDefaults.check() case Ok()) return appDefaults;
  appLogger.warning(
    'settings.app_defaults_out_of_range',
    message:
        'app_settings holds a card limit no session can open with; '
        'studying with the defaults',
    context: {'cardLimit': appDefaults.cardLimit},
  );
  return StudyOptions.defaults;
}

/// Study speech spec D6: an override written before speech has no key and
/// reads in the default language; a key of another type or a tag the app
/// does not know makes the override unreadable, as the other keys do.
SpeechLanguage? _speechLanguageOf(Object? value) {
  if (value == null) return SpeechLanguage.defaultLanguage;
  if (value is! String) return null;
  return SpeechLanguage.fromTag(value);
}
