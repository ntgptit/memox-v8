/// One deck on the way down from a root: enough to show a path and to open
/// that deck.
final class DeckPathEntry {
  const DeckPathEntry({required this.id, required this.name});

  final String id;
  final String name;
}
