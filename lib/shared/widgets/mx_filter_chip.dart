import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_component_themes.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_chip_style.dart';

/// A selectable filter (All · Cards · Decks), the Material 3 flat filter chip:
/// an outlined 32 chip at rest, `secondaryContainer` with a leading check when
/// selected, all read from `chipTheme`. Its selection is exposed as state, not
/// only as a look, so screen readers announce it. It never shrinks or wraps:
/// the caller's row scrolls.
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

  /// Optional leading glyph at 18; a selected chip shows the check instead.
  final IconData? icon;

  static const double _countOpacityResting = 0.6;

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    final chip = Theme.of(context).chipTheme;
    final foreground = chipPaint(chip, isSelected: isSelected).foreground;
    final leading = isSelected ? AppIcons.check : icon;
    final select = onSelected;
    return MergeSemantics(
      child: Semantics(
        selected: isSelected,
        child: TextButton(
          onPressed: select == null ? null : () => select(!isSelected),
          style: chipButtonStyle(
            tokens,
            chip,
            isSelected: isSelected,
            hasLeading: leading != null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: chipGap(chip),
            children: [
              if (leading case final glyph?) Icon(glyph),
              // A label wider than the column ends in an ellipsis, as
              // MxTagChip's does (SW-REV-010).
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (count case final value?)
                Text(
                  value.toString(),
                  // On the container fill a dimmed count loses its contrast,
                  // so the selected count keeps the label's foreground
                  // (SW-REV-001).
                  style: context.texts.labelSmall?.copyWith(
                    color: isSelected
                        ? foreground
                        : foreground.withValues(alpha: _countOpacityResting),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
