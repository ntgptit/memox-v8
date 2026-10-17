import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';

/// A single-choice row (algorithm, study mode, direction). The radio is
/// ForUI's [FRadio], painted only: the whole row is the target, which keeps
/// a 48 touch target ForUI's radio alone does not have. Dividers are the
/// list's (`MxDividedColumn`, DEV-305). It is 56 tall with a title alone, 72
/// with a description. Focus draws ForUI's outline on the row (`MxRowInk`).
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
          // A row that cannot be picked is blocked, trailing included; it
          // dims only what `isDimmed` says.
          isEnabled: onSelected != null,
          shouldDimWhenDisabled: false,
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
                          Text(title, style: context.texts.itemTitle),
                        ),
                        if (description case final text?) ...[
                          const SizedBox(height: _descriptionGap),
                          Text(
                            text,
                            style: context.texts.body.copyWith(
                              color: context.colors.mutedForeground,
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
      ? Opacity(opacity: context.colors.disabledOpacity, child: child)
      : child;
}

/// ForUI's radio, drawn for the row that owns its tap and its semantics.
class _Radio extends StatelessWidget {
  const _Radio({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    key: const ValueKey('mx-option-radio'),
    child: IgnorePointer(
      child: FRadio(value: isSelected, onChange: (_) {}),
    ),
  );
}
