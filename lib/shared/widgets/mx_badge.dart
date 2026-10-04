import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/mark_style.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

export 'package:memox/core/theme/components/mark_style.dart' show MxBadgeTone;

/// A short label in a semantic tone (DESIGN.md, MxBadge): a pill at least
/// 24 tall, its label centred, that grows with text; the tone's container under its `on-…-container`. The unit
/// belongs inside the label ("23 due").
class MxBadge extends StatelessWidget {
  const MxBadge({
    required this.label,
    this.tone = MxBadgeTone.neutral,
    this.icon,
    super.key,
  });

  final String label;
  final MxBadgeTone tone;

  /// A glyph before the label, for a counted status.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ToneColors pair = mxBadgeColors(
      context.colors,
      context.semanticColors,
      tone,
    );
    final IconData? glyph = icon;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.badge),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: pair.ground,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.control),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.micro,
            children: [
              if (glyph != null)
                Icon(glyph, size: AppIconSize.small, color: pair.content),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.labelSmall?.apply(color: pair.content),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
