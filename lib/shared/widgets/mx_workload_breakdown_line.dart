import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_term_line.dart';

/// The "N overdue · N today · N new" statement, with one colour for each
/// term across the whole product, and an optional muted "N scheduled".
/// - A term at zero drops out together with its separator (Study home spec
///   H1: only the counts with work show).
/// - The order is urgency first, and it never changes.
/// - When nothing is due, [fallback] is the whole line.
///
/// It sets in the body role (13/400), as a row's metadata line does, below
/// the row title (type scale spec 2026-10-20), and paints no top margin: the
/// row that stacks it owns the 2 gap (S12).
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

  /// Leads each of the three terms with its own glyph in the term's ink, so
  /// colour is never the only signal (BR-STUDY-076). Each term and its glyph
  /// then wrap as one unit, and the line is read as its words alone: the
  /// glyphs are decorative.
  final bool hasIcons;

  static const String _separator = MxTermLine.separator;
  static const String _space = ' ';

  @override
  Widget build(BuildContext context) {
    final terms = [
      (
        overdueCount,
        overdueLabel,
        MxTermTone.warning,
        MxTermTone.warning,
        AppIcons.overdue,
      ),
      // The today glyph is an accent icon; its words stay primary.
      (
        todayCount,
        todayLabel,
        MxTermTone.primary,
        MxTermTone.accentMark,
        AppIcons.dueNow,
      ),
      (
        newCount,
        newLabel,
        MxTermTone.muted,
        MxTermTone.muted,
        AppIcons.newCards,
      ),
      if (scheduledLabel case final label?)
        (scheduledCount, label, MxTermTone.muted, MxTermTone.muted, null),
    ].where((term) => term.$1 > 0).toList();
    // Only the Scheduled term has no glyph. Without an overdue, today or new
    // term the fallback still says nothing is due, and Scheduled follows it
    // (critique 2026-09-30 part 3b review).
    final isFallbackShown = !terms.any((term) => term.$5 != null);
    if (!canWrap) return _oneLine(context, terms, isFallbackShown);
    // A wrapping line breaks only between whole terms, and no dot ends or
    // starts a line (The Wrap Rule, spec W1).
    if (hasIcons && terms.isEmpty) return MxTermLine.text(fallback);
    return MxTermLine(
      terms: [
        if (isFallbackShown && !hasIcons)
          for (final term in fallback.split(_separator)) MxTerm(term),
        for (final (count, label, tone, glyphTone, glyph) in terms)
          MxTerm(
            label(count),
            tone: tone,
            glyph: hasIcons ? glyph : null,
            glyphTone: glyphTone,
          ),
      ],
      trail: suffix,
    );
  }

  /// One line that ellipsizes: a row's metadata (S12, row 102).
  Widget _oneLine(
    BuildContext context,
    List<_Term> terms,
    bool isFallbackShown,
  ) => Text.rich(
    TextSpan(
      style: context.texts.body.copyWith(color: context.colors.mutedForeground),
      children: [
        if (isFallbackShown) TextSpan(text: fallback),
        for (final (index, (count, label, tone, _, _)) in terms.indexed) ...[
          if (index > 0 || isFallbackShown) const TextSpan(text: _separator),
          TextSpan(
            text: label(count),
            style: context.texts.body.copyWith(
              color: MxTermLine.inkOf(context, tone),
            ),
          ),
        ],
        if (suffix case final clause?) ...[
          const TextSpan(text: _space),
          TextSpan(text: clause),
        ],
      ],
    ),
    maxLines: 1,
    softWrap: false,
    overflow: TextOverflow.ellipsis,
  );
}

/// A term: its count, its words, the words' tone, the glyph's tone and the
/// glyph.
typedef _Term = (int, String Function(int), MxTermTone, MxTermTone, IconData?);
