import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/app_button_style.dart';
import 'package:memox/shared/widgets/mx_focus_ring.dart';

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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final ink = isSelected ? colors.onPrimary : colors.onSurface;
    final select = onSelected;
    final chip = MergeSemantics(
      child: Semantics(
        selected: isSelected,
        child: MxFocusRing(
          radius: BorderRadius.circular(AppRadius.full),
          child: TextButton(
            onPressed: select == null ? null : () => select(!isSelected),
            style: appButtonStyle(
              fill: isSelected ? colors.primary : colors.surfaceContainerLowest,
              ink: ink,
              edge: isSelected
                  ? BorderSide.none
                  : BorderSide(
                      color: colors.outline,
                      width: AppStroke.hairline,
                    ),
              pressedLayer: ink,
              height: AppSize.chip,
              radius: AppRadius.full,
              padding: AppSpacing.control,
              label: styles.buttonLabelSmall,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.micro,
              children: [
                if (icon case final glyph?)
                  Icon(glyph, size: AppIconSize.inline),
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
                    // On the primary fill even full white is only 4.77:1, so
                    // the selected count keeps the label's ink (SW-REV-001).
                    style: styles.chipCount(
                      isSelected ? ink : colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (select != null) return chip;
    return Opacity(opacity: AppOpacity.disabled, child: chip);
  }
}
