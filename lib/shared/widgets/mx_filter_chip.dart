import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/app_button_style.dart';

/// A selectable filter (All · Cards · Decks). Its selection is exposed as
/// state, not only as a look, so screen readers announce it. It never shrinks
/// or wraps: the caller's row scrolls.
class MxFilterChip extends StatelessWidget {
  const MxFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.count,
    this.icon,
  });

  final String label;
  final bool isSelected;

  /// Receives the flipped selection. Null disables the chip.
  final ValueChanged<bool>? onSelected;

  /// Shown after the label, lighter than it.
  final int? count;

  /// Optional leading glyph at 16.
  final IconData? icon;

  static const double _countOpacityResting = 0.6;
  static const double _countOpacitySelected = 0.75;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final ink = isSelected ? colors.onPrimary : colors.onSurface;
    final select = onSelected;
    final chip = MergeSemantics(
      child: Semantics(
        selected: isSelected,
        child: TextButton(
          onPressed: select == null ? null : () => select(!isSelected),
          style: appButtonStyle(
            fill: isSelected ? colors.primary : colors.surfaceContainerLowest,
            ink: ink,
            edge: isSelected
                ? BorderSide.none
                : BorderSide(
                    color: context.derivedColors.ghostBorder,
                    width: AppStroke.hairline,
                  ),
            focusColor: context.derivedColors.primaryInk,
            height: AppSize.chip,
            radius: AppRadius.full,
            padding: AppSpacing.control,
            label: styles.buttonLabelSmall,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.micro,
            children: [
              if (icon case final glyph?) Icon(glyph, size: AppIconSize.inline),
              Text(label, maxLines: 1, softWrap: false),
              if (count case final value?)
                Text(
                  value.toString(),
                  style: styles.chipCount(
                    ink.withValues(
                      alpha: isSelected
                          ? _countOpacitySelected
                          : _countOpacityResting,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (select != null) return chip;
    return Opacity(opacity: AppOpacity.disabled, child: chip);
  }
}
