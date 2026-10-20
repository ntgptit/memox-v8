/// Glue for localized lines that a plain `Text` lays out (DESIGN.md, The
/// Wrap Rule). A line of short terms is not glued here: `MxTermLine` lays it
/// out, so no dot ends or starts a line (spec W1).
library;

const String _nonBreakingSpace = ' ';

/// What a localized line is split at, as the ARB messages write it.
const String _termSeparator = ' · ';

/// The separator of a phrase line: the dot is glued to the phrase before it.
const String _phraseSeparator = '$_nonBreakingSpace· ';

/// What a breadcrumb's levels are joined with, as the ARB messages write it.
const String _crumbSeparator = ' › ';

/// A localized line of phrases joined with " · " ([line]): each dot stays
/// with the phrase before it, and the phrases still wrap as words (a hint;
/// spec W2).
String metaDots(String line) =>
    line.split(_termSeparator).join(_phraseSeparator);

/// A localized breadcrumb ("Korean › Words", [line]): each "›" is glued to
/// the word after it, so a line never ends on one (spec B1).
String breadcrumbLine(String line) =>
    line.replaceAll(_crumbSeparator, ' ›$_nonBreakingSpace');
