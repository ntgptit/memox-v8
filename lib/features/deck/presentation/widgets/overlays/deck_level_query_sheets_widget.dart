import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/features/deck/presentation/states/deck_level_query_state.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_level_query_label_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_divided_column.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
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

  /// The handoff's order: manual, date added, name, most due, progress.
  /// "Sort by" starts on the rows' edge, 16 from the sheet like the option
  /// rows' radios (DESIGN.md gutter): the header carries 4 of its own, so the
  /// sheet gives it the rest (DEV-232).
  static const double _sectionHeaderInset =
      AppSpacing.gutter - AppSpacing.micro;

  static const _sorts = [
    DeckLevelSort.manual,
    DeckLevelSort.recent,
    DeckLevelSort.name,
    DeckLevelSort.due,
    DeckLevelSort.progress,
  ];

  DeckLevelQuery _query(WidgetRef ref) =>
      ref.read(deckLevelQueryProvider(parentId).notifier);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final query = ref.watch(deckLevelQueryProvider(parentId));
    return MxBottomSheet(
      title: l10n.deckSortFilterTitle,
      footer: MxSheetActions.single(
        isInSheet: true,
        label: l10n.commonDone,
        onPressed: () => Navigator.of(context).pop(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding:
                const EdgeInsets.only(top: AppSpacing.micro) +
                const EdgeInsets.symmetric(horizontal: _sectionHeaderInset),
            child: MxListSectionHeader(label: l10n.deckSortByHeader),
          ),
          MxDividedColumn(
            children: [
              for (final sort in _sorts)
                MxOptionRow(
                  title: l10n.deckSort(sort),
                  description: _hint(l10n, sort),
                  isSelected: sort == query.sort,
                  onSelected: () => _query(ref).sortBy(sort),
                ),
            ],
          ),
          MxSettingsRow(
            label: l10n.deckFilterDueOnlyTitle,
            subtitle: l10n.deckFilterDueOnlyBody,
            trailing: MxToggle(
              isOn: query.filter == DeckLevelFilter.due,
              semanticLabel: l10n.deckFilterDueOnlyTitle,
              onChanged: (isOn) =>
                  _query(ref)
                      .show(isOn ? DeckLevelFilter.due : DeckLevelFilter.all),
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
        DeckLevelSort.progress => l10n.deckSortProgressHint,
      };
}
