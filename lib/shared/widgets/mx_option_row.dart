import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/primitives/mx_row_ink.dart';

/// One choice of a single-choice list: a radio, a title and an optional
/// description (DESIGN.md, Inputs). A row that cannot be picked dims only its
/// radio and title, never the description that says why; the selected row is
/// never dimmed, so a locked current choice still reads.
class MxOptionRow extends StatelessWidget {
  const MxOptionRow({
    required this.title,
    required this.isSelected,
    required this.onSelected,
    this.description,
    super.key,
  });

  final String title;
  final String? description;
  final bool isSelected;

  /// `null` when the choice cannot be made now.
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? select = onSelected;
    final bool isDimmed = select == null && !isSelected;
    final double emphasis = isDimmed ? AppOpacity.disabled : 1;
    final String? why = description;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: isSelected,
      enabled: select != null,
      child: MxRowInk(
        onTap: select,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.tapTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.gutter,
              vertical: AppSpacing.grouped,
            ),
            child: Row(
              children: [
                Opacity(
                  opacity: emphasis,
                  child: _Radio(isSelected: isSelected),
                ),
                const SizedBox(width: AppSpacing.grouped),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: emphasis,
                        child: Text(title, style: context.texts.bodyLarge),
                      ),
                      if (why != null)
                        Text(
                          why,
                          style: context.texts.bodyMedium?.apply(
                            color: context.colors.onSurfaceVariant,
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
    );
  }
}

/// A 20 ring, 2dp `outline` when idle; selected, the ring thickens to 6 in
/// `primary` without moving (DESIGN.md, Shapes).
class _Radio extends StatelessWidget {
  const _Radio({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.toggle,
      width: AppSize.radio,
      height: AppSize.radio,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? context.colors.primary : context.colors.outline,
          width: isSelected ? AppStroke.indicator : AppStroke.control,
        ),
      ),
    );
  }
}
