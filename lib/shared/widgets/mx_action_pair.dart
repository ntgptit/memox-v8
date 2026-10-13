import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_button.dart';

/// Two footer actions (spec 2026-09-26 D3): side by side when both labels
/// fit the row on one line, in their flex shares when each fits its own,
/// otherwise stacked full width, [leading] on top. Stacking is the last resort: a caller shortens its labels first
/// (DESIGN.md, The Short Label Rule). A paired label never wraps or ellipsizes, so its icon stays on the
/// line. Both buttons are built with `isBlock: true, isSingleLine: true`.
class MxActionPair extends StatelessWidget {
  const MxActionPair({
    super.key,
    this.leading,
    required this.trailing,
    this.leadingFlex = 1,
    this.trailingFlex = 1,
    this.canStack = false,
  });

  /// Optional; without it [trailing] stands alone at full width.
  final MxButton? leading;
  final MxButton trailing;

  /// The shares of the side-by-side layout.
  final int leadingFlex;
  final int trailingFlex;

  /// A recorded exception to The Short Label Rule: the pair may stack at
  /// the default text scale, as a count no shorter label can drop does.
  final bool canStack;

  static const double _gap = AppSpacing.control;

  /// The phone width The Short Label Rule measures at; a narrower window
  /// may stack.
  static const double _ruleWidth = 360;

  @override
  Widget build(BuildContext context) {
    final leading = this.leading;
    assert(
      [?leading, trailing].every((b) => b.isBlock && b.isSingleLine),
      'a paired button is block and single-line',
    );
    if (leading == null) return trailing;
    return LayoutBuilder(
      builder: (context, constraints) {
        final shared = constraints.maxWidth - _gap;
        final leadingWidth = leading.naturalWidth(context);
        final trailingWidth = trailing.naturalWidth(context);
        if (leadingWidth + trailingWidth > shared) {
          // Stacking answers a reader's larger text or a phone narrower
          // than 360, never a long label (DESIGN.md, The Short Label Rule).
          assert(
            canStack ||
                MediaQuery.textScalerOf(context).scale(1) != 1 ||
                MediaQuery.sizeOf(context).width < _ruleWidth,
            'A pair stacked at the default text scale: shorten '
            '"${leading.label}" or "${trailing.label}" so the two share the '
            'row (DESIGN.md, The Short Label Rule).',
          );
          return Column(
            mainAxisSize: MainAxisSize.min,
            spacing: _gap,
            children: [leading, trailing],
          );
        }
        final flexTotal = leadingFlex + trailingFlex;
        final leadingShare = shared * leadingFlex / flexTotal;
        final fitsShares =
            leadingWidth <= leadingShare &&
            trailingWidth <= shared - leadingShare;
        // The flex shares when both labels fit them; otherwise each button
        // takes its label's width and the rest is split by the flexes, so
        // the pair stays side by side whenever it fits at all.
        final leadingSlot = fitsShares
            ? leadingShare
            : leadingWidth +
                  (shared - leadingWidth - trailingWidth) *
                      leadingFlex /
                      flexTotal;
        return Row(
          spacing: _gap,
          children: [
            SizedBox(width: leadingSlot, child: leading),
            Expanded(child: trailing),
          ],
        );
      },
    );
  }
}
