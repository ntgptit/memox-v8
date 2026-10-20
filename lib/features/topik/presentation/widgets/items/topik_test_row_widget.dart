import 'package:flutter/widgets.dart';
import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_term_line.dart';

/// A test on screen 35: its round, its Korean title (content, so it may end
/// in an ellipsis, critique F7), its content tags (BR-TOPIK-009) and the
/// person's status (BR-TOPIK-022) as the row's meta.
class TopikTestRowWidget extends StatelessWidget {
  const TopikTestRowWidget({
    super.key,
    required this.entry,
    required this.onOpen,
  });

  final TopikCatalogEntry entry;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final test = entry.test;
    final tags = [
      for (final tag in TopikContentTagOrder.ordered(test.contentTags))
        l10n.topikTagName(tag),
    ];
    return MxListRow(
      title: test.titleKo,
      // The round number is 1 to 3 digits: the title stays in one column.
      hasStableLeading: true,
      leading: MxBadge(
        label: l10n.topikRoundNumber(test.round),
        tone: MxBadgeTone.neutral,
      ),
      meta: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tags.isNotEmpty) MxTermLine.of(tags),
          MxTermLine.text(l10n.topikTestStatusLine(entry.status)),
        ],
      ),
      hasChevron: true,
      onTap: onOpen,
    );
  }
}

/// Tags in the order the enum declares, so every row reads alike.
abstract final class TopikContentTagOrder {
  static List<TopikContentTag> ordered(Set<TopikContentTag> tags) => [
    for (final tag in TopikContentTag.values)
      if (tags.contains(tag)) tag,
  ];
}
