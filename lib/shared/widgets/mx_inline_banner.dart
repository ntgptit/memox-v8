import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/feedback_style.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';

export 'package:memox/core/theme/components/feedback_style.dart'
    show MxInlineBannerTone;

/// One action of a banner; the primary one is drawn last.
class MxInlineBannerAction {
  const MxInlineBannerAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  final String label;
  final VoidCallback onPressed;

  /// The banner's main action, filled; a screen that already shows a
  /// primary for this decision passes `false` (The One Indigo Rule).
  final bool isPrimary;
}

/// A warning or danger owned by its screen (DESIGN.md, MxInlineBanner): the
/// container ground with a hairline in the tone's role; glyph, bold title and
/// message in the container's `on-` role; actions at the end, primary last.
class MxInlineBanner extends StatelessWidget {
  const MxInlineBanner({
    required this.tone,
    required this.message,
    this.title,
    this.actions = const <MxInlineBannerAction>[],
    super.key,
  });

  final MxInlineBannerTone tone;
  final String message;
  final String? title;
  final List<MxInlineBannerAction> actions;

  @override
  Widget build(BuildContext context) {
    final paint = mxBannerColors(context.colors, context.semanticColors, tone);
    final String? heading = title;
    final List<MxInlineBannerAction> ordered = [
      for (final action in actions)
        if (!action.isPrimary) action,
      for (final action in actions)
        if (action.isPrimary) action,
    ];
    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: paint.ground,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: paint.edge, width: AppStroke.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.grouped),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.control,
            children: [
              Row(
                spacing: AppSpacing.control,
                children: [
                  Icon(
                    tone == MxInlineBannerTone.danger
                        ? Icons.error_outline
                        : Icons.warning_amber_outlined,
                    size: AppIconSize.medium,
                    color: paint.content,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (heading != null)
                          Text(
                            heading,
                            style: mxBannerTitleStyle(
                              context.texts,
                              paint.content,
                            ),
                          ),
                        Text(
                          message,
                          style: context.texts.bodyMedium?.apply(
                            color: paint.content,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (ordered.isNotEmpty)
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppSpacing.control,
                  children: [
                    for (final action in ordered)
                      MxButton(
                        label: action.label,
                        onPressed: action.onPressed,
                        size: MxButtonSize.small,
                        tone: action.isPrimary
                            ? MxButtonTone.primary
                            : MxButtonTone.text,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
