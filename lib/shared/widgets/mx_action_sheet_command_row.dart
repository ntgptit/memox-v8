import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/shared/widgets/mx_tint_base.dart';

/// One command in a bottom-sheet action list: a 30 tile in a 32 lead column
/// and an item-title verb. It is neither a SettingsRow nor a ListRow. The sheet
/// supplies the outer gutter. Its height is the list item's: 56 with
/// a verb alone, 72 with a subtitle.
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
    final ink = isDestructive ? colors.error : context.status.primaryInk;
    return MxRowInk(
      onTap: onTap,
      isEnabled: isEnabled,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: subtitle == null
              ? context.dimens.sizeListRow
              : context.dimens.sizeListRowTwoLine,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.dimens.space8,
            vertical: context.dimens.space12,
          ),
          child: Row(
            spacing: context.dimens.space12,
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
                        color: isDestructive
                            ? context.colors.error.tintOver(
                                MxTintBase.of(context),
                              )
                            : context.colors.primary.tintOver(
                                MxTintBase.of(context),
                              ),
                        borderRadius: context.radii.sm,
                      ),
                      // Ruling S7: the glyph size is UNSPECIFIED; the small
                      // IconTile step.
                      child: Center(
                        child: Icon(
                          icon,
                          size: context.dimens.sizeIconInline,
                          color: ink,
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
                      style: context.texts.itemTitle.copyWith(
                        color: isDestructive
                            ? context.colors.error
                            : context.colors.foreground,
                      ),
                    ),
                    if (subtitle case final text?) ...[
                      const SizedBox(height: _subtitleGap),
                      // Two lines: a consequence (a merge, a loss) must not be
                      // cut (audit 2026-09-29, screen 05).
                      Text(
                        text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.body.copyWith(
                          color: context.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (hasChevron)
                Icon(
                  AppIcons.chevronRight,
                  size: context.dimens.sizeIconCompact,
                  color: colors.mutedForeground,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
