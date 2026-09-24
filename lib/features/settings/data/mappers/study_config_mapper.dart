import 'dart:convert';

import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/data/mappers/app_settings_mapper.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';

// The keys of `deck.study_config` (spec D5).
const _cardLimitKey = 'card_limit';
const _newCardOrderKey = 'new_card_order';

/// The JSON a root keeps [options] in (spec D5).
String studyConfigOf(StudyOptions options) => jsonEncode({
  _cardLimitKey: options.cardLimit,
  _newCardOrderKey: options.newCardOrder.name,
});

/// The options [studyConfig] holds, or null when it cannot be read: not a
/// JSON object, a key missing, a value of the wrong type, an unknown order or
/// a card limit out of bounds (D5). A key the app does not know is ignored.
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
  if (cardLimit is! int || newCardOrder == null) return null;
  final options = StudyOptions(
    cardLimit: cardLimit,
    newCardOrder: newCardOrder,
  );
  if (options.check() case Rejected()) return null;
  return options;
}

/// The options in force under [root]: its override when it can be read, the
/// app-wide defaults of [settings] otherwise (BR-STUDY-056). An unreadable
/// override is reported, never repaired here (IT-STUDY-013).
EffectiveStudyOptions effectiveStudyOptionsOf(Deck root, AppSetting settings) {
  final appDefaults = appSettingsOf(settings).studyDefaults;
  final studyConfig = root.studyConfig;
  if (studyConfig == null) {
    return EffectiveStudyOptions(
      rootDeckId: root.id,
      options: appDefaults,
      source: StudyOptionsSource.appDefaults,
    );
  }
  final override = studyOptionsOf(studyConfig);
  if (override == null) {
    return EffectiveStudyOptions(
      rootDeckId: root.id,
      options: appDefaults,
      source: StudyOptionsSource.unreadableRootOverride,
    );
  }
  return EffectiveStudyOptions(
    rootDeckId: root.id,
    options: override,
    source: StudyOptionsSource.rootOverride,
  );
}
