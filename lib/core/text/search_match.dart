import 'package:memox/core/text/folded_text.dart';

/// Between a card's two faces when one line shows both (screen 04). Display
/// only: the search never matches it (spec D20).
const String searchFaceSeparator = ' · ';

/// Where [term] sits in [text] under the search's own folding
/// (BR-SEARCH-002), as a half-open range in [text]; null when it does not.
/// The text is lower-cased but not trimmed, so a range in it is the same
/// range in [text]. Where lower-casing changes a text's length (on the web
/// 'İ' becomes two code units), the text is left unmarked rather than
/// marked in the wrong place.
(int, int)? searchMatchRange(String text, String term) {
  final folded = foldText(term);
  if (folded.isEmpty) return null;
  final lowered = text.toLowerCase();
  if (lowered.length != text.length) return null;
  final start = lowered.indexOf(folded);
  if (start < 0) return null;
  return (start, start + folded.length);
}

/// A card's two faces on one line, as [searchPairMatch] counts them.
String searchPairTitle(String first, String second) =>
    '$first$searchFaceSeparator$second';

/// The match in "[first][searchFaceSeparator][second]": [first]'s own
/// range, else [second]'s shifted past [first] and the separator; null when
/// neither face holds [term], as for a card found by a tag only. Each face
/// is searched alone, as the backend matches `front_folded` and
/// `back_folded` (spec D20).
(int, int)? searchPairMatch(String first, String second, String term) {
  final inFirst = searchMatchRange(first, term);
  if (inFirst != null) return inFirst;
  final inSecond = searchMatchRange(second, term);
  if (inSecond == null) return null;
  final offset = first.length + searchFaceSeparator.length;
  final (start, end) = inSecond;
  return (start + offset, end + offset);
}
