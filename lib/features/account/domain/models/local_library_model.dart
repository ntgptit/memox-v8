/// What this phone holds of its own library, for the merge choice (account
/// UI spec §5.3, R6): live decks and cards, the Trash left out.
final class LocalLibrary {
  const LocalLibrary({required this.decks, required this.cards});

  final int decks;
  final int cards;

  /// Nothing to merge or to lose: the switch asks nothing (auth spec #17).
  bool get isEmpty => decks == 0;
}
