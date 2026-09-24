import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/deck/presentation/states/deck_level_query_state.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_level_query_sheets_widget.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_level_query_label_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';

/// "DECKS" and the two chips that name the level's order and filter (L5).
class DeckLevelHeaderWidget extends ConsumerWidget {
  const DeckLevelHeaderWidget({super.key});

  DeckLevelQuery _query(WidgetRef ref) =>
      ref.read(deckLevelQueryProvider(null).notifier);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final query = ref.watch(deckLevelQueryProvider(null));
    return MxListSectionHeader(
      label: l10n.libraryDecksHeader,
      trailing: Wrap(
        spacing: AppSpacing.control,
        runSpacing: AppSpacing.control,
        children: [
          MxChipTrigger(
            label: l10n.deckSortTrigger(l10n.deckSort(query.sort)),
            icon: AppIcons.sort,
            onPressed: () => showDeckSortSheet(
              context,
              selected: query.sort,
              onSelected: (sort) => _query(ref).sortBy(sort),
            ),
          ),
          MxChipTrigger(
            label: l10n.deckFilterTrigger(l10n.deckFilter(query.filter)),
            icon: AppIcons.filter,
            onPressed: () => showDeckFilterSheet(
              context,
              selected: query.filter,
              onSelected: (filter) => _query(ref).show(filter),
            ),
          ),
        ],
      ),
    );
  }
}
