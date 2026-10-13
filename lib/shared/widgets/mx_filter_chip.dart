import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_component_themes.dart';
import 'package:memox/core/theme/theme_context.dart';

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
    final ink = isSelected ? colors.onPrimary : colors.onSurface;
    final select = onSelected;
    final chip = MergeSemantics(
      child: Semantics(
        selected: isSelected,
        child: TextButton(
          onPressed: select == null ? null : () => select(!isSelected),
          style:
              buttonStyle(
                ThemeTokens.of(context),
                fill: isSelected
                    ? colors.primary
                    : colors.surfaceContainerLowest,
                ink: ink,
                edge: isSelected
                    ? null
                    : BorderSide(
                        color: colors.outlineVariant,
                        width: context.dimens.strokeHairline,
                      ),
              ).copyWith(
                minimumSize: WidgetStatePropertyAll(
                  Size(0, context.dimens.sizeChip),
                ),
                padding: WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: context.dimens.space8),
                ),
              ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: context.dimens.space4,
            children: [
              if (icon case final glyph?)
                Icon(glyph, size: context.dimens.sizeIconInline),
              Text(label, maxLines: 1, softWrap: false),
              if (count case final value?)
                Text(
                  value.toString(),
                  style: context.texts.labelSmall?.copyWith(
                    color: ink.withValues(
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
    return Opacity(opacity: context.dimens.opacityDisabledContent, child: chip);
  }
}
