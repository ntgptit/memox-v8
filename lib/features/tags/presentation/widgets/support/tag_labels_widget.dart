/// Between a tag's name and its count on a chip (kit 05).
const String tagCountSeparator = ' · ';

/// "{tag} · {n}", the chip of a tag with its cards.
String tagWithCount(String name, int count) => '$name$tagCountSeparator$count';
