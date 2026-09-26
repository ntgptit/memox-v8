/// Between two decks of a path, as in "Korean › Words".
const String pathSeparator = ' › ';

/// A deck path read root first.
String pathLabel(Iterable<String> names) => names.join(pathSeparator);
