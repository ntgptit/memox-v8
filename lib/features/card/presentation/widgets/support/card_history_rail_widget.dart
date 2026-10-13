import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';

/// One node of the card history's timeline (DEV-170, kit "Flashcard
/// history"): a rail down the leading 24, a dot on it, and [child] beside
/// it. Each node draws its own stretch of rail, so the nodes join into one
/// line however the scroll builds them.
class CardHistoryRailWidget extends StatelessWidget {
  const CardHistoryRailWidget({
    super.key,
    required this.child,
    required this.dotTop,
    this.ink,
    this.isFirst = false,
    this.isLast = false,
    this.gap,
  });

  final Widget child;

  /// Where the dot sits, so it centres on the line it marks.
  final double dotTop;

  /// An answer's outcome ink; null draws the hollow marker of a cycle or of
  /// the beginning.
  final Color? ink;

  /// The rail starts at the first node's dot and ends at the last node's.
  final bool isFirst;
  final bool isLast;

  /// The space under this node, which the rail crosses; `space12` when null.
  final double? gap;

  /// A node on the rail: the card history's answers and markers (DEV-170).
  static const double _dotSize = 14;

  /// The dot's top that centres it on [lines] lines of text in [style].
  static double dotTopOn(
    BuildContext context,
    TextStyle style, {
    int lines = 1,
  }) {
    final line = MediaQuery.textScalerOf(context)
        .scale(style.fontSize! * (style.height ?? 1));
    final top = (line * lines - _dotSize) / 2;
    return top < 0 ? 0 : top;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;
    // The rail sits on the centre of the leading 24.
    final railStart = (dimens.space24 - dimens.strokeIndicator) / 2;
    final dotStart = (dimens.space24 - _dotSize) / 2;
    final dotCentre = dotTop + _dotSize / 2;
    final ink = this.ink;
    return Stack(
      children: [
        PositionedDirectional(
          start: railStart,
          width: context.dimens.strokeIndicator,
          top: isFirst ? dotCentre : 0,
          bottom: isLast ? null : 0,
          height: isLast ? dotCentre : null,
          child: ColoredBox(color: colors.surfaceContainerHigh),
        ),
        PositionedDirectional(
          start: dotStart,
          top: dotTop,
          child: Container(
            width: _dotSize,
            height: _dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ink == null ? colors.surfaceContainerHigh : colors.surface,
              // Non-text, so the edge holds 3:1 on the page (DESIGN.md, The
              // Contrast Floor Rule): the outcome's ink, or the outline.
              border: Border.all(
                color: ink ?? colors.outline,
                width: context.dimens.strokeControl,
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.only(
            start: context.dimens.space24,
            bottom: gap ?? dimens.space12,
          ),
          child: child,
        ),
      ],
    );
  }
}
