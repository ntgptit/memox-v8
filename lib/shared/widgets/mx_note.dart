import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// One calm line stating a product rule. Info tone only: never a warning,
/// never an action.
class MxNote extends StatelessWidget {
  const MxNote({super.key, required this.text, this.icon = AppIcons.info});

  final String text;

  /// The info glyph, or a clock or shield where the rule is about time or
  /// safety.
  final IconData icon;

  static const double _verticalPadding = 10;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = context.textStyles.noteText;
    // The glyph centres on the first line at any text scale.
    final firstLine =
        MediaQuery.textScalerOf(context).scale(style.fontSize!) * style.height!;
    final glyphInset = math.max(0.0, (firstLine - AppIconSize.inline) / 2);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: context.derivedColors.ghostBorder,
          width: AppStroke.hairline,
        ),
      ),
      child: Padding(
        // A DecoratedBox border does not inset its child, so the padding
        // starts after the hairline, as in the kit's CSS box.
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.grouped + AppStroke.hairline,
          vertical: _verticalPadding + AppStroke.hairline,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.control,
          children: [
            Padding(
              padding: EdgeInsets.only(top: glyphInset),
              child: Icon(
                icon,
                size: AppIconSize.inline,
                color: colors.onSurfaceVariant,
              ),
            ),
            Expanded(child: Text(text, style: style)),
          ],
        ),
      ),
    );
  }
}
