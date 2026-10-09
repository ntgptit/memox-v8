import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/speech/speech_language.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';

/// The order in which a learning session takes new cards (BR-STUDY-057).
/// The names are the codes `app_settings` and `deck.study_config` store.
enum NewCardOrder { created, random }

/// The study options of BR-STUDY-056 and BR-SETTINGS-009: the app-wide
/// defaults, or the override of a root deck. This is the one definition of
/// their bounds and defaults (BR-SETTINGS-002); the study feature reuses it.
final class StudyOptions {
  const StudyOptions({
    required this.cardLimit,
    required this.newCardOrder,
    this.speechLanguage = SpeechLanguage.defaultLanguage,
  });

  /// BR-STUDY-003: the fewest and the most distinct cards a session takes.
  static const minCardLimit = 1;
  static const maxCardLimit = 200;

  static const defaultCardLimit = 20;

  /// The options a fresh install starts with (BR-STUDY-003, BR-STUDY-057).
  static const defaults = StudyOptions(
    cardLimit: defaultCardLimit,
    newCardOrder: NewCardOrder.created,
  );

  final int cardLimit;
  final NewCardOrder newCardOrder;

  /// The language the term is read in (BR-SETTINGS-009, study speech spec
  /// D3). Defaulted (D15): most callers set the two options a session opens
  /// with; the sites that write a root's override or the defaults pass it.
  final SpeechLanguage speechLanguage;

  Outcome<void, SettingsRejection> check() => checkCardLimit(cardLimit);

  /// BR-STUDY-003 on one limit: the check every save and every form uses,
  /// so the bounds are compared in one place (DEV-217).
  static Outcome<void, SettingsRejection> checkCardLimit(int cardLimit) {
    if (cardLimit < minCardLimit || cardLimit > maxCardLimit) {
      return const Rejected(SettingsRejection.cardLimitOutOfRange);
    }
    return const Ok(null);
  }

  /// Whether a typed limit may be saved: parsed, and within the bounds.
  static bool isValidCardLimit(int? cardLimit) =>
      cardLimit != null && checkCardLimit(cardLimit) is Ok;
}
