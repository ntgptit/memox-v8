import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// A single-choice row (algorithm, study mode, direction). The radio is a ring
/// that thickens when selected, so nothing moves between states. The whole
/// row is the target.
class MxOptionRow extends StatelessWidget {
  const MxOptionRow({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onSelected,
    this.description,
    this.trailing,
    this.hasDivider = true,
  });

  final String title;
  final bool isSelected;

  /// Null disables the row.
  final VoidCallback? onSelected;

  /// Wraps to as many lines as it needs; the row grows.
  final String? description;
  final Widget? trailing;

  /// The ghost rule under the row; the caller turns it off on the last row.
  final bool hasDivider;

  static const double _radioColumn = 22;
  static const double _radioSize = 20;
  static const double _descriptionGap = 2;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final row = MergeSemantics(
      child: Semantics(
        checked: isSelected,
        inMutuallyExclusiveGroup: true,
        child: InkWell(
          onTap: onSelected,
          child: DecoratedBox(
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSize.listRowMin),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                  vertical: AppSpacing.grouped,
                ),
                child: Row(
                  spacing: AppSpacing.grouped,
                  children: [
                    SizedBox(
                      width: _radioColumn,
                      child: Center(
                        heightFactor: 1,
                        child: DecoratedBox(
                          key: const ValueKey('mx-option-radio'),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? colors.primary
                                  : colors.outline,
                              width: isSelected
                                  ? AppStroke.selectedRing
                                  : AppStroke.control,
                            ),
                          ),
                          child: const SizedBox.square(dimension: _radioSize),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: styles.rowTitle),
                          if (description case final text?) ...[
                            const SizedBox(height: _descriptionGap),
                            Text(text, style: styles.rowDescription),
                          ],
                        ],
                      ),
                    ),
                    ?trailing,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (onSelected != null) return row;
    return Opacity(opacity: AppOpacity.disabled, child: row);
  }
}
