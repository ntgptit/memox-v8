import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/chrome_style.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/primitives/mx_focus_ring.dart';
import 'package:memox/shared/widgets/primitives/mx_row_ink.dart';

/// One command in an action sheet (DESIGN.md, MxActionSheetCommandRow): a 24
/// glyph in `on-surface-variant` (Material 3's menu leading icon, not a
/// tile) 12 from the label in Body Large, an optional subtitle; a destructive
/// command paints its glyph and label in `error` (4.5:1 on the sheet ground)
/// and its words say so too. 48 minimum, 16 across and 12 down; a button.
class MxActionSheetCommandRow extends StatelessWidget {
  const MxActionSheetCommandRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.isDestructive = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final paint = mxCommandRowColors(colors, isDestructive: isDestructive);
    final String? detail = subtitle;
    // One TalkBack node, a button, carrying the ripple's tap and focus.
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: MxFocusRing(
          borderRadius: BorderRadius.zero,
          child: MxRowInk(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSize.tapTarget),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                  vertical: AppSpacing.grouped,
                ),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        icon,
                        size: AppIconSize.large,
                        color: paint.glyph,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.grouped),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: mxRowTitleStyle(
                              context.texts,
                              colors,
                            )?.apply(color: paint.label),
                          ),
                          if (detail != null)
                            Text(
                              detail,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.texts.bodyMedium?.apply(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
