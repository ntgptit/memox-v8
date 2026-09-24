import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/features/deck/presentation/states/deck_level_query_state.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_level_query_label_widget.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_unavailable_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

/// One sheet for the level's order and its due-only filter (screen 01). A
/// sort applies at once; Done closes the sheet.
Future<void> showDeckSortFilterSheet(
  BuildContext context, {
  required String? parentId,
}) => showMxBottomSheet<void>(
  context,
  builder: (_) => DeckSortFilterSheetWidget(parentId: parentId),
);

class DeckSortFilterSheetWidget extends ConsumerWidget {
  const DeckSortFilterSheetWidget({super.key, required this.parentId});

  final String? parentId;

  /// The handoff's order: manual, date added, name, most due.
  static const _sorts = [
    DeckLevelSort.manual,
    DeckLevelSort.recent,
    DeckLevelSort.name,
    DeckLevelSort.due,
  ];

  DeckLevelQuery _query(WidgetRef ref) =>
      ref.read(deckLevelQueryProvider(parentId).notifier);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final query = ref.watch(deckLevelQueryProvider(parentId));
    return MxBottomSheet(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.card,
          AppSpacing.micro,
          AppSpacing.card,
          AppSpacing.control,
        ),
        child: Text(l10n.deckSortFilterTitle, style: styles.compactTitle),
      ),
      footer: Padding(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: MxButton(
          label: l10n.commonDone,
          isBlock: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.card),
            child: Text(l10n.deckSortByHeader, style: styles.overline),
          ),
          for (final sort in _sorts)
            MxOptionRow(
              title: l10n.deckSort(sort),
              description: _hint(l10n, sort),
              isSelected: sort == query.sort,
              onSelected: () => _query(ref).sortBy(sort),
            ),
          // Progress needs a mastery read model (BE-A7): shown, not usable.
          DeckUnavailableWidget(
            child: MxOptionRow(
              title: l10n.deckSortProgress,
              description: l10n.deckSortProgressHint,
              isSelected: false,
              onSelected: null,
              hasDivider: false,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.card,
              vertical: AppSpacing.grouped,
            ),
            child: Row(
              spacing: AppSpacing.grouped,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.deckFilterDueOnlyTitle, style: styles.rowTitle),
                      Text(
                        l10n.deckFilterDueOnlyBody,
                        style: styles.rowDescription,
                      ),
                    ],
                  ),
                ),
                MxToggle(
                  isOn: query.filter == DeckLevelFilter.due,
                  semanticLabel: l10n.deckFilterDueOnlyTitle,
                  onChanged: (isOn) => _query(ref)
                      .show(isOn ? DeckLevelFilter.due : DeckLevelFilter.all),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String? _hint(AppLocalizations l10n, DeckLevelSort sort) =>
      switch (sort) {
        DeckLevelSort.manual => l10n.deckSortManualHint,
        DeckLevelSort.recent => l10n.deckSortRecentHint,
        DeckLevelSort.name => l10n.deckSortNameHint,
        DeckLevelSort.due => null,
      };
}
