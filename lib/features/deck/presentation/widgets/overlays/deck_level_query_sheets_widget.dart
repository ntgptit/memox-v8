import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_level_query_label_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

/// Picks the level's order. The chosen option closes the sheet.
Future<void> showDeckSortSheet(
  BuildContext context, {
  required DeckLevelSort selected,
  required ValueChanged<DeckLevelSort> onSelected,
}) => showMxBottomSheet<void>(
  context,
  builder: (sheetContext) => _OptionSheet<DeckLevelSort>(
    title: sheetContext.l10n.deckSortTitle,
    options: DeckLevelSort.values,
    labelOf: sheetContext.l10n.deckSort,
    selected: selected,
    onSelected: (sort) {
      onSelected(sort);
      Navigator.of(sheetContext).pop();
    },
  ),
);

/// Picks which decks of the level show.
Future<void> showDeckFilterSheet(
  BuildContext context, {
  required DeckLevelFilter selected,
  required ValueChanged<DeckLevelFilter> onSelected,
}) => showMxBottomSheet<void>(
  context,
  builder: (sheetContext) => _OptionSheet<DeckLevelFilter>(
    title: sheetContext.l10n.deckFilterTitle,
    options: DeckLevelFilter.values,
    labelOf: sheetContext.l10n.deckFilter,
    selected: selected,
    onSelected: (filter) {
      onSelected(filter);
      Navigator.of(sheetContext).pop();
    },
  ),
);

class _OptionSheet<T> extends StatelessWidget {
  const _OptionSheet({
    required this.title,
    required this.options,
    required this.labelOf,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final List<T> options;
  final String Function(T option) labelOf;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => MxBottomSheet(
    header: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.card,
        AppSpacing.micro,
        AppSpacing.card,
        AppSpacing.grouped,
      ),
      child: Text(title, style: context.textStyles.compactTitle),
    ),
    child: Column(
      children: [
        for (final (index, option) in options.indexed)
          MxOptionRow(
            title: labelOf(option),
            isSelected: option == selected,
            onSelected: () => onSelected(option),
            hasDivider: index < options.length - 1,
          ),
      ],
    ),
  );
}
