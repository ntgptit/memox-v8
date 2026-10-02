import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/app_button_style.dart';

/// A chip that opens a menu (sort, filters). A ghost hairline marks it as a
/// control; while it holds a choice other than the default ([isActive]) it
/// fills with the primary container, so a filtered list says so
/// (critique 2026-10-02 screen 28, SP1 §5.3). The menu is the caller's.
class MxChipTrigger extends StatelessWidget {
  const MxChipTrigger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = AppIcons.chevronDown,
    this.isActive = false,
  });

  final String label;
  final VoidCallback? onPressed;

  /// The trailing glyph at 16: chevron-down by default.
  final IconData icon;

  /// The chip holds a non-default choice.
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextButton(
      onPressed: onPressed,
      style: appButtonStyle(
        fill: isActive ? colors.primaryContainer : null,
        ink: isActive ? colors.onPrimaryContainer : colors.onSurfaceVariant,
        edge: isActive
            ? BorderSide.none
            : BorderSide(
                color: context.derivedColors.ghostBorder,
                width: AppStroke.hairline,
              ),
        focusColor: context.derivedColors.primaryInk,
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
