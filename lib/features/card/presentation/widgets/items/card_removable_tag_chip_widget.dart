import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/core/theme/theme_rules.dart';

/// A tag on the card being edited (kit `RemovableTagChip`): a primary-tinted
/// pill with an ✕. Its whole 48 area removes the tag (ruling P4a-L8); the
/// read-only `MxTagChip` is a different control.
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
    final colors = context.colors;
    // Its own node, or the tag editor's row merges every chip into one.
    return Semantics(
      container: true,
      button: true,
      label: context.l10n.cardTagRemove(name),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onRemove,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: context.dimens.sizeControl),
          child: Center(
            widthFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.accentColor.tintOver(colors.surface),
                borderRadius: BorderRadius.circular(
                  context.dimens.sizeChip / 2,
                ),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: context.dimens.sizeChip),
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: context.dimens.space12,
                    end: context.dimens.space8,
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(
                      color: context.accentColor,
                      size: context.dimens.sizeIconInline,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: context.dimens.space4,
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.texts.labelSmall?.copyWith(
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
