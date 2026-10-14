import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_component_themes.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/shared/widgets/mx_chip_style.dart';

/// A ghost chip that opens a menu (sort, filters). No fill and no border,
/// which sets it apart from MxFilterChip; it never reads as selected. It takes
/// the chip geometry of `chipTheme`. The menu is the caller's.
class MxChipTrigger extends StatelessWidget {
  const MxChipTrigger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = AppIcons.chevronDown,
  });

  final String label;
  final VoidCallback? onPressed;

  /// The trailing glyph at 18: chevron-down by default.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final chip = Theme.of(context).chipTheme;
    return TextButton(
      onPressed: onPressed,
      style: chipButtonStyle(
        ThemeTokens.of(context),
        chip,
        isGhost: true,
        hasTrailing: true,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: chipGap(chip),
        children: [
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
          Icon(icon),
        ],
      ),
    );
  }
}
