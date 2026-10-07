import 'package:drift/drift.dart' show Value;
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/speech/speech_language.dart';
import 'package:memox/features/settings/data/mappers/study_config_mapper.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';
import 'package:memox/features/settings/domain/models/reminder_snapshot_model.dart';
import 'package:memox/features/settings/domain/models/speech_settings_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';

/// The stored codes are the enum names, and the table's `CHECK` constraints
/// keep them valid: an unknown code is corrupt data and throws.
AppSettingsEntity appSettingsOf(AppSetting row) => AppSettingsEntity(
  studyDefaults: StudyOptions(
    cardLimit: row.cardLimit,
    newCardOrder: NewCardOrder.values.byName(row.newCardOrder),
    speechLanguage: _speechLanguageOf(row.ttsLanguage),
  ),
  theme: ThemeChoice.values.byName(row.themeMode),
  language: LanguageChoice.values.byName(row.language),
  reminder: _reminderOf(row),
  isSpeechAutoPlay: row.ttsAutoPlay == 1,
);

/// The table's CHECK keeps the tag in the list: an unknown one is corrupt
/// data and throws, as the other codes do.
SpeechLanguage _speechLanguageOf(String tag) =>
    SpeechLanguage.fromTag(tag) ??
    (throw ArgumentError.value(tag, 'tts_language', 'unknown speech language'));

/// Study speech spec §4: the switch and the root's language from the one
/// statement that reads both rows (BR-STUDY-080).
SpeechSettings speechSettingsOf(Deck root, AppSetting settings) =>
    SpeechSettings(
      isAutoPlay: settings.ttsAutoPlay == 1,
      language: effectiveStudyOptionsOf(root, settings).options.speechLanguage,
    );

ReminderSnapshot reminderSnapshotOf(AppSetting row) => ReminderSnapshot(
  reminder: _reminderOf(row),
  lastDeliveredAt: row.reminderLastDeliveredAt,
  language: LanguageChoice.values.byName(row.language),
);

/// The two reminder columns of [reminder]. `reminder_enabled` stores the
/// switch as 0 or 1.
AppSettingsCompanion reminderColumnsOf(ReminderSettings reminder) =>
    AppSettingsCompanion(
      reminderEnabled: Value(reminder.isEnabled ? 1 : 0),
      reminderMinuteOfDay: Value(reminder.minuteOfDay),
    );

ReminderSettings _reminderOf(AppSetting row) => ReminderSettings(
  isEnabled: row.reminderEnabled == 1,
  minuteOfDay: row.reminderMinuteOfDay,
);
