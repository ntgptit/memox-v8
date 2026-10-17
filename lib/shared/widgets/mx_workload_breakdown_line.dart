import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/meta_line.dart';

/// The "N overdue · N today · N new" statement, with one colour for each
/// term across the whole product, and an optional muted "N scheduled".
/// - A term at zero drops out together with its separator, unless
///   [shouldKeepZeroTerms] is set.
/// - The order is urgency first, and it never changes.
/// - When nothing is due, [fallback] is the whole line.
///
/// It paints no top margin: the row that stacks it owns the 2 gap (S12).
class MxWorkloadBreakdownLine extends StatelessWidget {
  const MxWorkloadBreakdownLine({
    super.key,
    required this.overdueCount,
    required this.todayCount,
    required this.newCount,
    required this.overdueLabel,
    required this.todayLabel,
    required this.newLabel,
    required this.fallback,
    this.suffix,
    this.scheduledCount = 0,
    this.scheduledLabel,
    this.canWrap = false,
    this.shouldKeepZeroTerms = false,
    this.hasIcons = false,
  }) : assert(
         overdueCount >= 0 &&
             todayCount >= 0 &&
             newCount >= 0 &&
             scheduledCount >= 0,
         'counts are never negative',
       ),
       assert(
         !hasIcons || (canWrap && suffix == null),
         'a statement with glyphs wraps and takes no suffix',
       );

  final int overdueCount;
  final int todayCount;
  final int newCount;

  /// Builds a term from its count, typically a plural ARB message.
  final String Function(int count) overdueLabel;
  final String Function(int count) todayLabel;
  final String Function(int count) newLabel;

  /// The calm line when all three counts are zero: "12 cards · nothing due",
  /// "Nothing due" or "No cards yet". The caller knows which one applies.
  final String fallback;

  /// A trailing clause ("across 4 decks"), after a space.
  final String? suffix;

  /// Learned cards resting until they fall due (BR-STUDY-068): a fourth,
  /// muted term after New, drawn only with [scheduledLabel]. It is the
  /// schedule running, so it takes no warning ink and no headline.
  final int scheduledCount;
  final String Function(int count)? scheduledLabel;

  /// A row keeps one line and ellipsizes (S12, row 102); a hero statement,
  /// or a Study Home deck row that must show all three counts
  /// (BR-STUDY-076), wraps so no part is cut.
  final bool canWrap;

  /// Study Home's deck rows state all three counts even at zero
  /// (BR-STUDY-076); a zero term is muted, since a count at rest is the
  /// schedule running, not a warning (BR-STUDY-008). [fallback] then never
  /// shows.
  final bool shouldKeepZeroTerms;

  /// Leads each of the three terms with its own glyph in the term's ink, so
  /// colour is never the only signal (BR-STUDY-076). Each term, its glyph
  /// and its dot then wrap as one unit, and the line is read as its words
  /// alone: the glyphs are decorative.
  final bool hasIcons;

  static const String _separator = ' · ';
  static const String _space = ' ';

  // A wrapping line breaks only between terms (The Wrap Rule, meta_line).

  String _termText(String label) => canWrap ? wholeTerm(label) : label;

  @override
  Widget build(BuildContext context) {
    final muted = context.colors.mutedForeground;
    final terms = [
      (
        overdueCount,
        overdueLabel,
        context.status.warning,
        context.status.warning,
        AppIcons.overdue,
      ),
      // The today glyph is an accent icon; its words stay primary.
      (
        todayCount,
        todayLabel,
        context.colors.primary,
        context.status.accentMark,
        AppIcons.dueNow,
      ),
      (newCount, newLabel, muted, muted, AppIcons.newCards),
      if (scheduledLabel case final label?)
        (scheduledCount, label, muted, muted, null),
    ].where((term) => shouldKeepZeroTerms || term.$1 > 0).toList();
    if (hasIcons) return _GlyphStatement(terms: terms, fallback: fallback);
    // Only the Scheduled term has no glyph. Without an overdue, today or new
    // term the fallback still says nothing is due, and Scheduled follows it
    // (critique 2026-09-30 part 3b review).
    final isFallbackShown = !terms.any((term) => term.$5 != null);
    return Text.rich(
      TextSpan(
        style: context.texts.label.copyWith(
          color: context.colors.mutedForeground,
        ),
        children: [
          // "1,248 cards · nothing due" is a line of terms too.
          if (isFallbackShown)
            TextSpan(text: canWrap ? metaLine(fallback) : fallback),
          for (final (index, (count, label, ink, _, _)) in terms.indexed) ...[
            if (index > 0 || isFallbackShown)
              TextSpan(text: canWrap ? metaTermSeparator : _separator),
            TextSpan(
              text: _termText(label(count)),
              style: count > 0
                  ? context.texts.label.copyWith(color: ink)
                  : context.texts.label.copyWith(
                      color: context.colors.mutedForeground,
                    ),
            ),
          ],
          if (suffix case final clause?) ...[
            const TextSpan(text: _space),
            TextSpan(text: clause),
          ],
        ],
      ),
      maxLines: canWrap ? null : 1,
      softWrap: canWrap,
      overflow: canWrap ? TextOverflow.visible : TextOverflow.ellipsis,
    );
  }
}

/// A term: its count, its words, the words' colour, the glyph's colour and
/// the glyph.
typedef _Term = (int, String Function(int), Color, Color, IconData?);

/// The terms as units in a [Wrap]: a centred glyph, then the words and the
/// dot that follows them. A unit wider than the line wraps its own words.
class _GlyphStatement extends StatelessWidget {
  const _GlyphStatement({required this.terms, required this.fallback});

  final List<_Term> terms;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final muted = context.colors.mutedForeground;
    if (terms.isEmpty) {
      return Text(
        fallback,
        style: context.texts.label.copyWith(
          color: context.colors.mutedForeground,
        ),
      );
    }
    final statement = [
      for (final (count, label, _, _, _) in terms) label(count),
    ].join(MxWorkloadBreakdownLine._separator);
    return Semantics(
      label: statement,
      excludeSemantics: true,
      child: Wrap(
        spacing: context.dimens.space4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final (index, (count, label, ink, glyphInk, glyph))
              in terms.indexed)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (glyph case final icon?) ...[
                  Icon(
                    icon,
                    size: context.dimens.sizeIconInline,
                    color: count > 0 ? glyphInk : muted,
                  ),
                  SizedBox(width: context.dimens.space4),
                ],
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      style: context.texts.label.copyWith(
                        color: context.colors.mutedForeground,
                      ),
                      children: [
                        TextSpan(
                          text: label(count),
                          style: count > 0
                              ? context.texts.label.copyWith(color: ink)
                              : null,
                        ),
                        if (index < terms.length - 1)
                          const TextSpan(text: metaTermDot),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
