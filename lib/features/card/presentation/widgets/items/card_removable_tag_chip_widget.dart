import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_chip_style.dart';

/// A tag on the card being edited (kit `RemovableTagChip`): the shared chip
/// at rest (mxChipStyle), its label and a ✕ after it. Its whole 48 area
/// removes the tag (ruling P4a-L8); the read-only `MxTagChip` is a different
/// control.
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
              decoration: mxChipDecoration(context),
              child: Padding(
                padding: mxChipPadding(context),
                child: IconTheme.merge(
                  data: mxChipIconTheme(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: mxChipGap(context),
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: mxChipLabelStyle(context),
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
    );
  }
}
