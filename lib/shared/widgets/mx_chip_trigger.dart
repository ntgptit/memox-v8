import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';

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
        focusColor: context.accentColor,
        height: context.dimens.sizeChip,
        radius: AppRadius.full,
        padding: context.dimens.space8,
        label: context.texts.labelLarge,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: context.dimens.space4,
        children: [
          Text(label, maxLines: 1, softWrap: false),
          Icon(icon, size: context.dimens.sizeIconInline),
        ],
      ),
    );
  }
}
