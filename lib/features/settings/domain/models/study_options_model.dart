import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';

/// The order in which a learning session takes new cards (BR-STUDY-057).
/// The names are the codes `app_settings` and `deck.study_config` store.
enum NewCardOrder { created, random }

/// The study options of BR-STUDY-056: the app-wide defaults, or the override
/// of a root deck. This is the one definition of their bounds and defaults
/// (BR-SETTINGS-002); the study feature reuses it.
final class StudyOptions {
  const StudyOptions({required this.cardLimit, required this.newCardOrder});

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

  Outcome<void, SettingsRejection> check() {
    if (cardLimit < minCardLimit || cardLimit > maxCardLimit) {
      return const Rejected(SettingsRejection.cardLimitOutOfRange);
    }
    return const Ok(null);
  }
}
