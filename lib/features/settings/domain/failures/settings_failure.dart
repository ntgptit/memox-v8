/// Why the settings feature refuses a write (ADR-011 D6).
enum SettingsRejection {
  /// BR-STUDY-003: the card limit is outside 1 to 200.
  cardLimitOutOfRange,

  /// The deck does not exist or is in the Trash.
  deckNotFound,

  /// The deck is a sub-deck: study options live on its root (BR-STUDY-056).
  notARootDeck,

  /// BR-REMINDER-002: the reminder's minute is outside 0 to 1439.
  reminderMinuteOutOfRange,
}
