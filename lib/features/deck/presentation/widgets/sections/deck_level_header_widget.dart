import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/features/deck/presentation/states/deck_level_query_state.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_level_query_sheets_widget.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_level_query_label_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';

/// The level's count, or "Decks with due cards" under the filter, and one
/// pill naming the order (screen 01) that opens the sort & filter sheet.
class DeckLevelHeaderWidget extends ConsumerWidget {
  const DeckLevelHeaderWidget({
    super.key,
    required this.parentId,
    required this.label,
  });

  final String? parentId;

  /// "6 decks", "4 sub-decks", or the filter's heading.
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final query = ref.watch(deckLevelQueryProvider(parentId));
    final sort = l10n.deckSort(query.sort);
    return MxListSectionHeader(
      label: label,
      trailing: MxChipTrigger(
        label: query.filter == DeckLevelFilter.due
            ? l10n.deckSortPillDueOnly(sort)
            : sort,
        icon: AppIcons.sort,
        onPressed: () => showDeckSortFilterSheet(context, parentId: parentId),
      ),
    );
  }
}
