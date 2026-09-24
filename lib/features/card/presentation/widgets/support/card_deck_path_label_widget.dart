/// Between two decks of a path. The deck feature has its own join; the card
/// feature may not import `deck/presentation` (ruling P3-L8).
const String cardDeckPathSeparator = ' › ';

/// A deck path read root first.
String cardDeckPathLabel(Iterable<String> names) =>
    names.join(cardDeckPathSeparator);
