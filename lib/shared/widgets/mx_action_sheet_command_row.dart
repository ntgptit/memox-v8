import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';

/// One command in a bottom-sheet action list: a 30 tile in a 32 lead column
/// and a 14/600 verb. It is neither a SettingsRow nor a ListRow. The sheet
/// supplies the outer gutter.
class MxActionSheetCommandRow extends StatelessWidget {
  const MxActionSheetCommandRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.isDestructive = false,
    this.hasChevron = false,
    this.isEnabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? subtitle;

  /// The error tile, glyph and verb: named in colour and in words.
  final bool isDestructive;

  /// The command opens a further surface.
  final bool hasChevron;

  /// A command that exists but cannot run yet: dimmed, announced disabled.
  final bool isEnabled;

  static const double _leadColumn = 32;
  static const double _tileSize = 30;

  /// Ruling S7: UNSPECIFIED; the ListRow gap.
  static const double _subtitleGap = 2;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final semantic = context.semanticColors;
    // The lead tile is a soft ground with its on-soft glyph.
    final (ground, foreground) = isDestructive
        ? (semantic.dangerSoft, semantic.onDangerSoft)
        : (semantic.primarySoft, semantic.onPrimarySoft);
    return MxRowInk(
      onTap: onTap,
      isEnabled: isEnabled,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSize.touchTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.control,
            vertical: AppSpacing.grouped,
          ),
          child: Row(
            spacing: AppSpacing.grouped,
            children: [
              SizedBox(
                width: _leadColumn,
                child: Center(
                  heightFactor: 1,
                  child: SizedBox.square(
                    dimension: _tileSize,
                    child: DecoratedBox(
                      key: const ValueKey('mx-command-tile'),
                      decoration: BoxDecoration(
                        color: ground,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      // Ruling S7: the glyph size is UNSPECIFIED; the small
                      // IconTile step.
                      child: Center(
                        child: Icon(
                          icon,
                          size: AppIconSize.inline,
                          color: foreground,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: styles.commandLabel(isDestructive: isDestructive),
                    ),
                    if (subtitle case final text?) ...[
                      const SizedBox(height: _subtitleGap),
                      // Two lines: a consequence (a merge, a loss) must not be
                      // cut (audit 2026-09-29, screen 05).
                      Text(
                        text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: styles.rowSubtitle,
                      ),
                    ],
                  ],
                ),
              ),
              if (hasChevron)
                Icon(
                  AppIcons.chevronRight,
                  size: AppIconSize.compact,
                  color: colors.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
