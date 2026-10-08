import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// A single-choice row (algorithm, study mode, direction). The radio is a ring
/// that thickens when selected, so nothing moves between states. The whole
/// row is the target. Dividers are the list's (`MxDividedColumn`, DEV-305).
class MxOptionRow extends StatelessWidget {
  const MxOptionRow({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onSelected,
    this.description,
    this.trailing,
    this.isDimmed,
  });

  final String title;
  final bool isSelected;

  /// Null disables the row.
  final VoidCallback? onSelected;

  /// Whether the radio and the title draw at the disabled opacity; null dims
  /// exactly the rows that cannot be selected and are not selected. False
  /// keeps a row that cannot be picked yet at full contrast, such as a study
  /// mode not built yet (FE-A6 spec §3): the kit dims only a choice that is
  /// blocked. The description is never dimmed, so a blocked row's reason and
  /// a locked current choice stay readable (critique 2026-09-30).
  final bool? isDimmed;

  /// Wraps to as many lines as it needs; the row grows.
  final String? description;
  final Widget? trailing;

  static const double _radioColumn = 22;
  static const double _radioSize = 20;
  static const double _descriptionGap = 2;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final isDim = isDimmed ?? (onSelected == null && !isSelected);
    return MergeSemantics(
      child: Semantics(
        checked: isSelected,
        inMutuallyExclusiveGroup: true,
        // A row that cannot be picked says so (SW-REV-006).
        enabled: onSelected != null,
        child: InkWell(
          onTap: onSelected,
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
                  _dim(
                    isDim,
                    SizedBox(
                      width: _radioColumn,
                      child: Center(
                        heightFactor: 1,
                        child: DecoratedBox(
                          key: const ValueKey('mx-option-radio'),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              // A stroke glyph, so primaryInk (spec
                              // 2026-09-27): it reads 3:1 on a sheet. The
                              // empty ring is a control edge: Outline Edge,
                              // 3:1 on every ground (SW-REV-001).
                              color: isSelected
                                  ? context.derivedColors.primaryInk
                                  : context.derivedColors.outlineEdge,
                              width: isSelected
                                  ? AppStroke.selectedRing
                                  : AppStroke.control,
                            ),
                          ),
                          child: const SizedBox.square(dimension: _radioSize),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _dim(isDim, Text(title, style: styles.rowTitle)),
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
    );
  }

  static Widget _dim(bool isDim, Widget child) =>
      isDim ? Opacity(opacity: AppOpacity.disabled, child: child) : child;
}
