import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/surface_style.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';

/// The overline over a list (DESIGN.md, MxListSectionHeader): the Section
/// Label in `on-surface-variant`, upper-cased by the widget (pass the app's
/// own words, never user data), read as a header. 16 across; 8 down when it
/// stands alone, at least 48 tall when it carries a trailing chip trigger
/// (sort or filter). `MxSection` heads a card; this heads a list.
class MxListSectionHeader extends StatelessWidget {
  const MxListSectionHeader({required this.title, this.trigger, super.key});

  final String title;
  final MxChipTrigger? trigger;

  @override
  Widget build(BuildContext context) {
    final MxChipTrigger? end = trigger;
    // TalkBack reads the words as written, not spelled out in capitals.
    final Widget label = Semantics(
      header: true,
      label: title,
      excludeSemantics: true,
      child: Text(
        title.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: mxSectionLabelStyle(context.texts, context.colors),
      ),
    );
    if (end == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gutter,
          vertical: AppSpacing.control,
        ),
        child: label,
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.tapTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: Row(
          spacing: AppSpacing.grouped,
          children: [
            Expanded(child: label),
            end,
          ],
        ),
      ),
    );
  }
}
