/// Where the card under edit stands while the form is open (SP2a 2.17): the
/// form never goes away with it, it only annotates itself.
enum CardEditorSource {
  /// The card is there.
  present,

  /// The card was deleted or trashed after the form opened.
  gone,

  /// Reading the card failed after the form opened; nothing says it is gone.
  unreadable,
}
