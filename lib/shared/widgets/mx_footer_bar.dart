import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_breakpoints.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The in-flow commit bar under a screen's body (DESIGN.md, MxFooterBar):
/// the page ground under a 1dp `outline-variant` hairline (no shadow), 16
/// across and 12 down, an optional caption in `on-surface-variant` 8 above
/// the actions. It clears the system bar and rides above the keyboard with
/// the screen. The actions are a slot: `MxSheetActions` today, the footer
/// pair (`MxActionPair`) once it is built.
class MxFooterBar extends StatelessWidget {
  const MxFooterBar({this.caption, this.actions, super.key})
    : assert(caption != null || actions != null, 'An empty footer.');

  final String? caption;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final String? words = caption;
    final Widget? commit = actions;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(
            color: colors.outlineVariant,
            width: AppStroke.hairline,
          ),
        ),
      ),
      child: Padding(
        // The system bar below and any cutout at the sides.
        padding: MediaQuery.paddingOf(context).copyWith(top: 0),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.contentMax,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
                vertical: AppSpacing.grouped,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.control,
                children: [
                  if (words != null)
                    Text(
                      words,
                      style: context.texts.bodySmall?.apply(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ?commit,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
