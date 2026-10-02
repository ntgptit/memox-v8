import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
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
  });

  final MxBannerTone tone;
  final String message;

  /// The bold lead line of the two-line form.
  final String? title;

  /// Compact MxButtons, under the message (ruling O6).
  final List<Widget> actions;

  /// The commit-bar variant: 8 12 padding and no margin below.
  final bool isInCommitBar;

  static const double _titleGap = 2;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final derived = context.derivedColors;
    final styles = context.textStyles;
    final (ground, edge, ink, titleInk) = switch (tone) {
      MxBannerTone.warning => (
        derived.warningSoft,
        derived.warningBorder,
        // The kit's amber glyph is 1.87:1 on the soft ground (FE-C1).
        derived.warningInk,
        derived.warningInk,
      ),
      // The glyph needs 3:1 and keeps error; the title is text and reads in
      // the danger ink, 4.5:1 even inside a sheet (tone pass, final review).
      MxBannerTone.danger => (
        derived.dangerSoft,
        derived.dangerBorder,
        colors.error,
        derived.dangerInk,
      ),
    };
    final messageStyle = styles.bannerMessage(isLead: title == null);
    // The glyph centres on the first line at any text scale.
    final firstLine =
        MediaQuery.textScalerOf(context).scale(messageStyle.fontSize!) *
        messageStyle.height!;
    final glyphInset = math.max(0.0, (firstLine - AppIconSize.inline) / 2);
    // A DecoratedBox border does not inset its child: the padding starts
    // after the hairline, as in the kit's CSS box (and MxNote).
    final padding = isInCommitBar
        ? const EdgeInsets.symmetric(
            horizontal: AppSpacing.grouped + AppStroke.hairline,
            vertical: AppSpacing.control + AppStroke.hairline,
          )
        : const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter + AppStroke.hairline,
            vertical: AppSpacing.grouped + AppStroke.hairline,
          );
    return Padding(
      padding: isInCommitBar
          ? EdgeInsets.zero
          : const EdgeInsets.only(bottom: AppSpacing.gutter),
      child: Semantics(
        liveRegion: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ground,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: edge, width: AppStroke.hairline),
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
                    color: ink,
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // The title carries the tone, as the glyph does; the
                      // message stays neutral (critique 2026-09-30 tone
                      // pass, T2).
                      if (title case final lead?) ...[
                        Text(
                          lead,
                          style: styles.bannerTitle.copyWith(color: titleInk),
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
