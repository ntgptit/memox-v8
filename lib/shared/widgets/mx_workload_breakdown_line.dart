import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The "N overdue · N today · N new" statement, with one colour for each
/// term across the whole product, and an optional muted "N scheduled".
/// - A term at zero drops out together with its separator.
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
  }) : assert(
         overdueCount >= 0 &&
             todayCount >= 0 &&
             newCount >= 0 &&
             scheduledCount >= 0,
         'counts are never negative',
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

  /// A row keeps one line and ellipsizes (S12, row 102); a hero statement
  /// wraps so its suffix is never cut (kit Study Home hero).
  final bool canWrap;

  static const String _separator = ' · ';
  static const String _space = ' ';

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final terms = [
      (overdueCount, overdueLabel, context.derivedColors.warningInk),
      (todayCount, todayLabel, context.colors.primary),
      (newCount, newLabel, context.derivedColors.statusNewInk),
      if (scheduledLabel case final label?)
        (scheduledCount, label, context.colors.onSurfaceVariant),
    ].where((term) => term.$1 > 0).toList();
    return Text.rich(
      TextSpan(
        style: styles.workloadText,
        children: [
          for (final (index, (count, label, ink)) in terms.indexed) ...[
            if (index > 0) const TextSpan(text: _separator),
            TextSpan(text: label(count), style: styles.workloadTerm(ink)),
          ],
          if (terms.isEmpty) TextSpan(text: fallback),
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
