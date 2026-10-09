import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

/// A content row: decks, search results, tags, move targets and cards. The
/// title is one line by default and the sub one line, each with an
/// ellipsis, so every row in a list is one height. It is not a SettingsRow: this is a piece of content.
///
/// A disabled row dims its leading, title and end (chevron, trailing or
/// spinner), never the subtitle or meta that says why, as MxSettingsRow and
/// MxOptionRow do (critique 2026-09-30 part 3a, DEV-230). Dividers are the
/// list's (`MxDividedColumn`, DEV-305).
class MxListRow extends StatelessWidget {
  const MxListRow({
    super.key,
    required this.title,
    this.titleMatch,
    this.subtitle,
    this.meta,
    this.leading,
    this.trailing,
    this.hasChevron = false,
    this.onTap,
    this.isEnabled = true,
    this.isBusy = false,
    this.titleMaxLines = 1,
  }) : assert(subtitle == null || meta == null, 'a subtitle or meta'),
       assert(trailing == null || !hasChevron, 'a trailing or the chevron');

  final String title;

  /// A half-open range of [title] drawn in the match role, such as the part
  /// of a deck name a search term found (screen 04).
  final (int, int)? titleMatch;

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

  /// 2 for a name the person chose (tag, deck), which must stay
  /// recognisable; content lists keep 1 so rows are one height (audit
  /// 2026-09-29, pattern 2).
  final int titleMaxLines;

  static const double _subtitleGap = 2;

  TextSpan _titleSpan(TextStyle matchStyle) {
    final match = titleMatch;
    if (match == null) return TextSpan(text: title);
    final (start, end) = match;
    assert(
      0 <= start && start <= end && end <= title.length,
      'titleMatch lies inside the title',
    );
    return TextSpan(
      children: [
        TextSpan(text: title.substring(0, start)),
        TextSpan(text: title.substring(start, end), style: matchStyle),
        TextSpan(text: title.substring(end)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final end = switch ((isBusy, hasChevron)) {
      (true, _) => const MxSpinner(),
      (false, true) => Icon(
        AppIcons.chevronRight,
        size: AppIconSize.compact,
        color: colors.onSurfaceVariant,
      ),
      (false, false) => trailing,
    };
    return MxRowInk(
      onTap: onTap,
      isEnabled: isEnabled,
      shouldDimWhenDisabled: false,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSize.listRowMin),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
          child: Row(
            spacing: AppSpacing.grouped,
            children: [
              if (leading case final lead?) _dim(lead),
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
                      _dim(
                        Text.rich(
                          _titleSpan(styles.rowTitleMatch),
                          maxLines: titleMaxLines,
                          softWrap: titleMaxLines > 1,
                          overflow: TextOverflow.ellipsis,
                          style: styles.listRowTitle,
                        ),
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
              if (end case final slot?) _dim(slot),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dim(Widget child) =>
      isEnabled ? child : Opacity(opacity: AppOpacity.disabled, child: child);
}
