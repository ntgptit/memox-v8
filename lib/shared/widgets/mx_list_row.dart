import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';

/// A content row: decks, search results, tags, move targets and cards. The
/// title and the sub are one line each with an ellipsis, so every row in a
/// list is one height. It is not a SettingsRow: this is a piece of content.
class MxListRow extends StatelessWidget {
  const MxListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.meta,
    this.leading,
    this.trailing,
    this.hasChevron = false,
    this.onTap,
    this.isEnabled = true,
    this.isBusy = false,
    this.hasDivider = true,
  }) : assert(subtitle == null || meta == null, 'a subtitle or meta'),
       assert(trailing == null || !hasChevron, 'a trailing or the chevron');

  final String title;

  /// The one-line metadata. For a disabled move target, it is the reason
  /// the row cannot take the payload.
  final String? subtitle;

  /// A widget in the sub-line position (MxWorkloadBreakdownLine, tag chips).
  /// The row keeps the 2 gap above it (ruling S12).
  final Widget? meta;

  /// Usually an MxIconTile at the small step; any widget may replace it.
  final Widget? leading;

  /// An overflow button or another control. It keeps its own tap and node.
  final Widget? trailing;

  /// The navigation affordance.
  final bool hasChevron;
  final VoidCallback? onTap;
  final bool isEnabled;

  /// A spinner takes the trailing slot while the row's action runs.
  final bool isBusy;

  /// The ghost rule under the row. The caller turns it off on the last row
  /// and inside an MxSection, which draws its own.
  final bool hasDivider;

  static const double _subtitleGap = 2;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final end = switch ((isBusy, hasChevron)) {
      (true, _) => SizedBox.square(
        dimension: AppIconSize.inline,
        child: CircularProgressIndicator(
          strokeWidth: AppStroke.indicator,
          color: colors.primary,
        ),
      ),
      (false, true) => Icon(
        AppIcons.chevronRight,
        size: AppIconSize.compact,
        color: colors.onSurfaceVariant,
      ),
      (false, false) => trailing,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        border: hasDivider
            ? Border(
                bottom: BorderSide(
                  color: context.derivedColors.ghostBorder,
                  width: AppStroke.hairline,
                ),
              )
            : null,
      ),
      child: MxRowInk(
        onTap: onTap,
        isEnabled: isEnabled,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.listRowMin),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Row(
              spacing: AppSpacing.grouped,
              children: [
                ?leading,
                // Only the text carries the 12/12 inset, so a 48 trailing
                // control sits inside the text height instead of growing the
                // row: every row in a list stays one height.
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.grouped,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: styles.listRowTitle,
                        ),
                        if (subtitle case final text?) ...[
                          const SizedBox(height: _subtitleGap),
                          Text(
                            text,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: styles.rowSubtitle,
                          ),
                        ],
                        if (meta case final slot?) ...[
                          const SizedBox(height: _subtitleGap),
                          slot,
                        ],
                      ],
                    ),
                  ),
                ),
                ?end,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
