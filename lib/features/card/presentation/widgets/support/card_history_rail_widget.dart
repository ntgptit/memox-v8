import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
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
    this.foreground,
    this.isFirst = false,
    this.isLast = false,
    this.gap = AppSpacing.grouped,
  });

  final Widget child;

  /// Where the dot sits, so it centres on the line it marks.
  final double dotTop;

  /// An answer's outcome foreground; null draws the hollow marker of a cycle or of
  /// the beginning.
  final Color? foreground;

  /// The rail starts at the first node's dot and ends at the last node's.
  final bool isFirst;
  final bool isLast;

  /// The space under this node, which the rail crosses.
  final double gap;

  /// The rail sits on the centre of the leading 24.
  static const double _railStart =
      (AppSpacing.section - AppStroke.indicator) / 2;
  static const double _dotStart =
      (AppSpacing.section - AppSize.timelineDot) / 2;

  /// The dot's top that centres it on [lines] lines of text in [style].
  static double dotTopOn(
    BuildContext context,
    TextStyle style, {
    int lines = 1,
  }) {
    final line = MediaQuery.textScalerOf(context)
        .scale(style.fontSize! * (style.height ?? 1));
    final top = (line * lines - AppSize.timelineDot) / 2;
    return top < 0 ? 0 : top;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dotCentre = dotTop + AppSize.timelineDot / 2;
    final foreground = this.foreground;
    return Stack(
      children: [
        PositionedDirectional(
          start: _railStart,
          width: AppStroke.indicator,
          top: isFirst ? dotCentre : 0,
          bottom: isLast ? null : 0,
          height: isLast ? dotCentre : null,
          child: ColoredBox(color: colors.surfaceContainerHigh),
        ),
        PositionedDirectional(
          start: _dotStart,
          top: dotTop,
          child: Container(
            width: AppSize.timelineDot,
            height: AppSize.timelineDot,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: foreground == null
                  ? colors.surfaceContainerHigh
                  : colors.surface,
              // Non-text, so the edge holds 3:1 on the page (DESIGN.md, The
              // Contrast Floor Rule): the outcome's foreground, or the outline.
              border: Border.all(
                color: foreground ?? colors.outline,
                width: AppStroke.control,
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.only(
            start: AppSpacing.section,
            bottom: gap,
          ),
          child: child,
        ),
      ],
    );
  }
}
