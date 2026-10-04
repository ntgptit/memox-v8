import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';

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

  static const double _tint = 0.10;

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
          constraints: const BoxConstraints(minHeight: AppSize.touchTarget),
          child: Center(
            widthFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: _tint),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: AppSize.chip),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.grouped,
                    end: AppSpacing.control,
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(
                      color: context.derivedColors.primaryInk,
                      size: AppIconSize.inline,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: AppSpacing.micro,
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.removableTagLabel,
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
