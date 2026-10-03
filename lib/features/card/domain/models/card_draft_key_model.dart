/// The key a card being written is kept under (SP2a R9): one per deck for a
/// new card, one per card for an edit.
abstract final class CardDraftKey {
  static String create(String deckId) => 'create:$deckId';

  static String edit(String cardId) => 'edit:$cardId';
}
