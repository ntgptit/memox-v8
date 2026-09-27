import 'dart:ui';

import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// The day's notification text, from the digest alone (BR-REMINDER-005): the
/// most urgent root's name, its due count and how many other roots have
/// cards due, in the kit's sentence (screen 24, reminders spec D9). [locale]
/// is one the app supports.
String reminderNotificationBody(ReminderDigest digest, Locale locale) {
  final l10n = lookupAppLocalizations(locale);
  final due = l10n.reminderDueCards(digest.dueCount);
  if (digest.otherDeckCount == 0) {
    return l10n.reminderBody(due, digest.deckName);
  }
  return l10n.reminderBodyWithOthers(
    due,
    digest.deckName,
    l10n.reminderOtherDecks(digest.otherDeckCount),
  );
}
