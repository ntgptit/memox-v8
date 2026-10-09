import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// Warning is a refusal or a limit, and nothing was lost. Danger means an
/// operation failed.
enum MxBannerTone { warning, danger }

/// One in-place message about an operation or an object, with the compact
/// Buttons that resolve it. It is not a Note (info, no action) and not an
/// ErrorState (a whole-card load failure). It wraps and never truncates.
class MxInlineBanner extends StatelessWidget {
  const MxInlineBanner({
    super.key,
    required this.tone,
    required this.message,
    this.title,
    this.actions = const [],
    this.isInCommitBar = false,
    this.hasBottomMargin = true,
  });

  final MxBannerTone tone;
  final String message;

  /// The bold lead line of the two-line form.
  final String? title;

  /// Compact MxButtons, under the message (ruling O6).
  final List<Widget> actions;

  /// The commit-bar variant: 8 12 padding and no margin below.
  final bool isInCommitBar;

  /// The 16 below the banner, kept for a banner in a flow. A banner that
  /// ends a dialog's content drops it, so the actions sit at the dialog's
  /// usual gap (the sign-in confirms, 2026-10-05 L3).
  final bool hasBottomMargin;

  static const double _titleGap = 2;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final semantic = context.semanticColors;
    final styles = context.textStyles;
    // A container has no edge; the glyph is the role, the text its
    // on-container (spec 2026-10-08 §4.5).
    final (ground, glyphInk, textInk) = switch (tone) {
      MxBannerTone.warning => (
        semantic.warningContainer,
        semantic.warning,
        semantic.onWarningContainer,
      ),
      MxBannerTone.danger => (
        colors.errorContainer,
        colors.error,
        colors.onErrorContainer,
      ),
    };
    final messageStyle = styles
        .bannerMessage(isLead: title == null)
        .copyWith(color: textInk);
    // The glyph centres on the first line at any text scale.
    final firstLine =
        MediaQuery.textScalerOf(context).scale(messageStyle.fontSize!) *
        messageStyle.height!;
    final glyphInset = math.max(0.0, (firstLine - AppIconSize.inline) / 2);
    final padding = isInCommitBar
        ? const EdgeInsets.symmetric(
            horizontal: AppSpacing.grouped,
            vertical: AppSpacing.control,
          )
        : const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter,
            vertical: AppSpacing.grouped,
          );
    return Padding(
      padding: isInCommitBar || !hasBottomMargin
          ? EdgeInsets.zero
          : const EdgeInsets.only(bottom: AppSpacing.gutter),
      child: Semantics(
        liveRegion: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ground,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Padding(
            padding: padding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.control,
              children: [
                // The title and the message share the 12 × 1.55 first line.
                Padding(
                  padding: EdgeInsets.only(top: glyphInset),
                  child: Icon(
                    AppIcons.alert,
                    size: AppIconSize.inline,
                    color: glyphInk,
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // The title and the message read in the same
                      // on-container.
                      if (title case final lead?) ...[
                        Text(
                          lead,
                          style: styles.bannerTitle.copyWith(color: textInk),
                        ),
                        const SizedBox(height: _titleGap),
                      ],
                      Text(message, style: messageStyle),
                      if (actions.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.control),
                        Wrap(
                          spacing: AppSpacing.control,
                          runSpacing: AppSpacing.control,
                          children: actions,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
