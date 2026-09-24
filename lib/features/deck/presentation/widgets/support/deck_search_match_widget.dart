import 'package:memox/core/text/folded_text.dart';

/// Where [term] sits in [name] under the search's own folding
/// (BR-SEARCH-002), as a half-open range in [name]; null when it does not.
/// The name is lower-cased but not trimmed, so a range in it is the same
/// range in [name]. Where lower-casing changes a name's length (on the web
/// 'İ' becomes two code units), the name is left unmarked rather than
/// marked in the wrong place.
(int, int)? deckSearchMatch(String name, String term) {
  final folded = foldText(term);
  if (folded.isEmpty) return null;
  final lowered = name.toLowerCase();
  if (lowered.length != name.length) return null;
  final start = lowered.indexOf(folded);
  if (start < 0) return null;
  return (start, start + folded.length);
}
