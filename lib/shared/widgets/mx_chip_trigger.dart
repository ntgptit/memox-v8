import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/app_button_style.dart';

/// A ghost chip that opens a menu (sort, filters). No fill and no border,
/// which sets it apart from MxFilterChip; it never reads as selected. The
/// menu is the caller's.
class MxChipTrigger extends StatelessWidget {
  const MxChipTrigger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = AppIcons.chevronDown,
  });

  final String label;
  final VoidCallback? onPressed;

  /// The trailing glyph at 16: chevron-down by default.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextButton(
      onPressed: onPressed,
      style: appButtonStyle(
        fill: null,
        ink: colors.onSurfaceVariant,
        edge: BorderSide.none,
        focusColor: colors.primary,
        height: AppSize.chip,
        radius: AppRadius.full,
        padding: AppSpacing.control,
        label: context.textStyles.buttonLabelSmall,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.micro,
        children: [
          Text(label, maxLines: 1, softWrap: false),
          Icon(icon, size: AppIconSize.inline),
        ],
      ),
    );
  }
}
