/// A meta line that wraps does so only between whole terms (DESIGN.md, The
/// Wrap Rule; owner, Q-P6-4): a term's own spaces and range dashes ("Levels
/// 3–6") do not break, and each dot stays with the term before it. Use it
/// for a line of short terms, such as "4 sub-decks · 1,248 cards"; a line of
/// sentences or of names keeps its spaces ([metaDots]), or a sentence would
/// never break.
library;

const String _space = ' ';
const String _nonBreakingSpace = '\u00A0';
const String _wordJoiner = '\u2060';
const String _rangeDash = '\u2013';

/// What a line of terms is split at, as the ARB messages write it.
const String _termSeparator = ' · ';

/// The separator of a line that wraps only between terms: the dot is glued
/// to the term before it.
const String metaTermSeparator = '$_nonBreakingSpace· ';

/// The dot alone, glued to the term before it, for a line built of spans.
const String metaTermDot = '$_nonBreakingSpace·';

/// [term] with no break inside it.
String wholeTerm(String term) => term
    .replaceAll(_space, _nonBreakingSpace)
    .replaceAll(_rangeDash, '$_wordJoiner$_rangeDash$_wordJoiner');

/// [terms] as one line that breaks only between them.
String metaTerms(Iterable<String> terms) =>
    terms.map(wholeTerm).join(metaTermSeparator);

/// A localized line already joined with " · " ([line]), glued the same way.
String metaLine(String line) => metaTerms(line.split(_termSeparator));

/// A localized line of phrases joined with " · " ([line]): each dot stays
/// with the phrase before it, and the phrases still wrap as words (a hint).
String metaDots(String line) =>
    line.split(_termSeparator).join(metaTermSeparator);
