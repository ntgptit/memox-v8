import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/speech/speech_language.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';
import 'package:memox/features/settings/domain/models/reminder_snapshot_model.dart';
import 'package:memox/features/settings/domain/models/speech_settings_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';

/// The one implementation is `SettingsRepositoryImpl` (data layer). The
/// contract exists for ADR-010's reason: domain stays framework-free and tests
/// substitute a fake.
abstract interface class SettingsRepository {
  /// The one `app_settings` row, again after every save (BR-SETTINGS-001).
  Stream<AppSettingsEntity> watchAppSettings();

  /// The app-wide study defaults: only the columns given are written, so a
  /// save of one never carries a stale copy of the other over a change that
  /// arrived meanwhile (BR-SETTINGS-007, DEV-217); at least one is given. It
  /// never writes a root's override (BR-SETTINGS-002), and a session already
  /// open keeps its limit (BR-SETTINGS-004).
  Future<Outcome<void, SettingsRejection>> saveStudyDefaults({
    int? cardLimit,
    NewCardOrder? newCardOrder,
    SpeechLanguage? speechLanguage,
  });

  /// Whether a learning session reads a new card aloud (BR-SETTINGS-010);
  /// one column, device-only.
  Future<Outcome<void, SettingsRejection>> setSpeechAutoPlay({
    required bool isOn,
  });

  Future<Outcome<void, SettingsRejection>> setTheme({
    required ThemeChoice theme,
  });

  Future<Outcome<void, SettingsRejection>> setLanguage({
    required LanguageChoice language,
  });

  /// The SQL log switch (SQL log switch spec §4.4): an admin's tool, synced
  /// with the account like the theme, never touched by [resetToDefaults].
  Future<Outcome<void, SettingsRejection>> setLogSqlStatements({
    required bool enabled,
  });

  /// The six values a person can set back to their defaults, in one
  /// The eight values a person can set back to their defaults, in one
  /// transaction, and nothing else: not the last delivery of the reminder,
  /// which is bookkeeping (BR-SETTINGS-008; reminders spec D3).
  Future<Outcome<void, SettingsRejection>> resetToDefaults();

  /// The daily reminder's switch and time (UC-REMINDER-001 steps 2-3, A1,
  /// A2). A minute out of range is refused before anything is written
  /// (BR-REMINDER-002).
  Future<Outcome<void, SettingsRejection>> saveReminder({
    required ReminderSettings reminder,
  });

  /// The reminder, its last delivery and the language, read in one
  /// statement: the moment a schedule or a delivery is decided from.
  Future<ReminderSnapshot> reminderSnapshot();

  /// Records that the digest was shown at [at]. It writes that one column and
  /// nothing else, not even `updated_at`: the background delivery must never
  /// overwrite a choice the person just changed (`schema.md`).
  Future<void> recordReminderDelivered({required DateTime at});

  /// The options [deckId] studies with: its root's override, or the app-wide
  /// defaults when there is none or it cannot be read (BR-STUDY-056,
  /// IT-STUDY-013). Again when either changes; null when the deck does not
  /// exist or is in the Trash.
  Stream<EffectiveStudyOptions?> watchStudyOptions({required String deckId});

  /// [watchStudyOptions] read once, for the study session that opens with
  /// them (BR-STUDY-024). Joins the caller's transaction.
  Future<EffectiveStudyOptions?> studyOptionsOf({required String deckId});

  /// Gives the root [rootDeckId] options of its own, for the sessions opened
  /// after it (BR-SETTINGS-003). A sub-deck has none (BR-STUDY-056).
  Future<Outcome<void, SettingsRejection>> saveRootStudyOptions({
    required String rootDeckId,
    required StudyOptions options,
  });

  /// The switch and the language [deckId]'s root reads in, in one
  /// statement, again when either changes (BR-STUDY-080); null when the
  /// deck does not exist or is in the Trash.
  Stream<SpeechSettings?> watchSpeechSettings({required String deckId});

  /// Removes the root's override, readable or not, so the app-wide defaults
  /// apply again (UC-SETTINGS-001 A1). A root without one is `Ok` and
  /// nothing is written.
  Future<Outcome<void, SettingsRejection>> clearRootStudyOptions({
    required String rootDeckId,
  });
}
