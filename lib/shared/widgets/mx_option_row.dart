import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';

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

  /// The ghost rule under the row; the caller turns it off on the last row.
  final bool hasDivider;

  static const double _radioColumn = 22;

  /// The selected radio's ring: it thickens, nothing moves.
  static const double _selectedRing = 6;
  static const double _radioSize = 20;
  static const double _descriptionGap = 2;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDim = isDimmed ?? (onSelected == null && !isSelected);
    return MergeSemantics(
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
                        color: context.colors.outlineVariant,
                        width: context.dimens.strokeHairline,
                      ),
                    )
                  : null,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: context.dimens.sizeControl,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.screenMargin,
                  vertical: context.dimens.space12,
                ),
                child: Row(
                  spacing: context.dimens.space12,
                  children: [
                    _dim(
                      context,
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
                                // 2026-09-27): it reads 3:1 on a sheet.
                                color: isSelected
                                    ? context.accentColor
                                    : colors.outline,
                                width: isSelected
                                    ? _selectedRing
                                    : context.dimens.strokeControl,
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
                          _dim(
                            context,
                            isDim,
                            Text(title, style: context.texts.titleSmall),
                          ),
                          if (description case final text?) ...[
                            const SizedBox(height: _descriptionGap),
                            Text(
                              text,
                              style: context.texts.bodyMedium?.copyWith(
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
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
  }

  static Widget _dim(BuildContext context, bool isDim, Widget child) => isDim
      ? Opacity(opacity: context.dimens.opacityDisabledContent, child: child)
      : child;
}
