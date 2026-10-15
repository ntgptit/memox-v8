import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';

/// A single-choice row (algorithm, study mode, direction). The radio is the
/// Material 3 one: an `onSurfaceVariant` ring, and in the accent colour a ring
/// with a dot when selected. The whole row is the target. Dividers are the
/// list's (`MxDividedColumn`, DEV-305). Its height is the Material 3 list
/// item: 56 with a title alone, 72 with a description. Focus draws the
/// shared row ring (`MxRowInk`).
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
  static const double _descriptionGap = 2;

  @override
  Widget build(BuildContext context) {
    final isDim = isDimmed ?? (onSelected == null && !isSelected);
    return MergeSemantics(
      child: Semantics(
        checked: isSelected,
        inMutuallyExclusiveGroup: true,
        // A row that cannot be picked says so (SW-REV-006).
        enabled: onSelected != null,
        child: MxRowInk(
          onTap: onSelected,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: description == null
                  ? context.dimens.sizeListRow
                  : context.dimens.sizeListRowTwoLine,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.dimens.space16,
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
                        child: _Radio(isSelected: isSelected),
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
    );
  }

  static Widget _dim(BuildContext context, bool isDim, Widget child) => isDim
      ? Opacity(opacity: context.dimens.opacityDisabledContent, child: child)
      : child;
}

/// The Material 3 radio, drawn rather than built from `Radio` (whose 40 box
/// would grow every row): a ring stroked `strokeControl`, and a dot when
/// selected. A stroke glyph, so the selected colour is the accent (it reads 3:1
/// on a sheet where dark `primary` does not).
class _Radio extends StatelessWidget {
  const _Radio({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    final color = isSelected
        ? context.accentColor
        : context.colors.onSurfaceVariant;
    return DecoratedBox(
      key: const ValueKey('mx-option-radio'),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: dimens.strokeControl),
      ),
      child: SizedBox.square(
        dimension: dimens.sizeSelectionControl,
        child: isSelected
            ? Center(
                child: DecoratedBox(
                  key: const ValueKey('mx-option-radio-dot'),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                  child: SizedBox.square(dimension: dimens.sizeRadioDot),
                ),
              )
            : null,
      ),
    );
  }
}
