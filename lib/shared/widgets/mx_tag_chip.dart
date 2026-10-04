import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/mark_style.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// A tag as read-only metadata (DESIGN.md, MxTagChip): a pill at least 24
/// tall on its own line, or 20 ([isDense]) inside a row. It hugs its name up
/// to half the width it is given, so a tag never dominates its row; a longer
/// name ends in an ellipsis and stays whole for TalkBack.
class MxTagChip extends StatelessWidget {
  const MxTagChip({required this.label, this.isDense = false, super.key});

  final String label;
  final bool isDense;

  @override
  Widget build(BuildContext context) {
    final ToneColors pair = mxTagColors(context.colors);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, row) => ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: isDense ? AppSize.tagChipDense : AppSize.tagChip,
            maxWidth: row.maxWidth / 2,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: pair.ground,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.control,
              ),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.labelSmall?.apply(color: pair.content),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
