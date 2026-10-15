import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';

/// Screen 35's header: the section, how many tests, what they are, and the
/// sort. Shown only with tests (The Content Gate Rule, critique F4).
class TopikTestListHeaderWidget extends StatelessWidget {
  const TopikTestListHeaderWidget({
    super.key,
    required this.section,
    required this.testCount,
    required this.order,
    required this.onSort,
  });

  final TopikSection section;
  final int testCount;
  final TopikTestOrder order;
  final VoidCallback onSort;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // The count and the sort share the first line; what the tests are reads
    // full width under them, so the sort never squeezes it.
    return MxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: context.dimens.space12,
        children: [
          Row(
            spacing: context.dimens.space16,
            children: [
              MxIconTile(
                icon: section == TopikSection.reading
                    ? AppIcons.fileText
                    : AppIcons.speak,
              ),
              Expanded(
                child: Text(
                  l10n.topikTestCount(testCount),
                  style: context.texts.titleMedium,
                ),
              ),
              MxChipTrigger(
                label: l10n.topikOrderName(order),
                onPressed: onSort,
              ),
            ],
          ),
          Text(
            l10n.topikTestsHeaderBody,
            style: context.texts.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
