import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/app_component_themes.dart';
import 'package:memox/core/theme/theme_context.dart';

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
      style:
          buttonStyle(
            ThemeTokens.of(context),
            fill: null,
            foreground: colors.onSurfaceVariant,
            edge: null,
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
          Icon(icon, size: context.dimens.sizeIconInline),
        ],
      ),
    );
  }
}
