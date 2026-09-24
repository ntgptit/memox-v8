/// Between two decks of a path, as in "Korean › Words".
const String deckPathSeparator = ' › ';

/// A deck path read root first.
String deckPathLabel(Iterable<String> names) => names.join(deckPathSeparator);
