import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/core/theme/theme_rules.dart';
import 'package:memox/shared/widgets/mx_chip_style.dart';
import 'package:memox/shared/widgets/mx_tint_base.dart';

/// A tag on the card being edited (kit `RemovableTagChip`): a Material 3 input
/// chip, 32 tall with the `chipTheme` corner, `outlineVariant` edge and insets,
/// tinted primary, with an 18 ✕ after the label. Its whole 48 area removes the
/// tag (ruling P4a-L8); the read-only `MxTagChip` is a different control.
class CardRemovableTagChipWidget extends StatelessWidget {
  const CardRemovableTagChipWidget({
    super.key,
    required this.name,
    required this.onRemove,
  });

  final String name;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final chip = Theme.of(context).chipTheme;
    // Its own node, or the tag editor's row merges every chip into one.
    return Semantics(
      container: true,
      button: true,
      label: context.l10n.cardTagRemove(name),
      excludeSemantics: true,
      // The excluded chip's tap, kept on this one node (SW-REV-005).
      onTap: onRemove,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onRemove,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: context.dimens.sizeControl),
          child: Center(
            widthFactor: 1,
            child: DecoratedBox(
              decoration: chipDecoration(
                chip,
                fill: context.accentColor.tintOver(MxTintBase.of(context)),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: context.dimens.sizeChip),
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: chipStartInset(chip, hasLeading: false),
                    end: chipEndInset(chip, hasTrailing: true),
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(
                      color: context.accentColor,
                      size: chip.iconTheme!.size,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: chipGap(chip),
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: chip.labelStyle?.copyWith(
                              color: context.accentColor,
                            ),
                          ),
                        ),
                        const Icon(AppIcons.close),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
