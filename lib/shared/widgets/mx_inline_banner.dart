import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/shared/widgets/mx_tint_base.dart';

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
    final (ground, edge, ink, titleInk) = switch (tone) {
      MxBannerTone.warning => (
        context.mxColors.warning.tintOver(MxTintBase.of(context)),
        context.mxColors.warning,
        // The kit's amber glyph is 1.87:1 on the soft ground (FE-C1).
        context.mxColors.warning,
        context.mxColors.warning,
      ),
      // The glyph needs 3:1 and keeps error; the title is text and reads in
      // the danger ink, 4.5:1 even inside a sheet (tone pass, final review).
      MxBannerTone.danger => (
        context.colors.error.tintOver(MxTintBase.of(context)),
        context.colors.error,
        colors.error,
        context.colors.error,
      ),
    };
    final messageStyle = context.texts.labelMedium!.copyWith(
      color: title == null
          ? context.colors.onSurface
          : context.colors.onSurfaceVariant,
    );
    // The glyph centres on the first line at any text scale.
    final firstLine =
        MediaQuery.textScalerOf(context).scale(messageStyle.fontSize!) *
        messageStyle.height!;
    final glyphInset = math.max(
      0.0,
      (firstLine - context.dimens.sizeIconInline) / 2,
    );
    // A DecoratedBox border does not inset its child: the padding starts
    // after the hairline, as in the kit's CSS box (and MxNote).
    final padding = isInCommitBar
        ? EdgeInsets.symmetric(
            horizontal: context.dimens.space12 + context.dimens.strokeHairline,
            vertical: context.dimens.space8 + context.dimens.strokeHairline,
          )
        : EdgeInsets.symmetric(
            horizontal: context.dimens.space16 + context.dimens.strokeHairline,
            vertical: context.dimens.space12 + context.dimens.strokeHairline,
          );
    return Padding(
      padding: isInCommitBar || !hasBottomMargin
          ? EdgeInsets.zero
          : EdgeInsets.only(bottom: context.dimens.space16),
      child: Semantics(
        liveRegion: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ground,
            borderRadius: BorderRadius.circular(context.dimens.radiusMd),
            border: Border.all(
              color: edge,
              width: context.dimens.strokeHairline,
            ),
          ),
          child: Padding(
            padding: padding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: context.dimens.space8,
              children: [
                // The title and the message share the 12 × 1.55 first line.
                Padding(
                  padding: EdgeInsets.only(top: glyphInset),
                  child: Icon(
                    AppIcons.alert,
                    size: context.dimens.sizeIconInline,
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
                          style: context.texts.labelMedium?.copyWith(
                            color: titleInk,
                          ),
                        ),
                        const SizedBox(height: _titleGap),
                      ],
                      Text(message, style: messageStyle),
                      if (actions.isNotEmpty) ...[
                        SizedBox(height: context.dimens.space8),
                        Wrap(
                          spacing: context.dimens.space8,
                          runSpacing: context.dimens.space8,
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
