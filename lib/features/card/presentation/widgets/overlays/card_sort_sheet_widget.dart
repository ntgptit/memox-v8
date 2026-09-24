import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/presentation/widgets/support/card_list_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

/// Picks the card list's order (IT-ORG-003). The chosen option closes the
/// sheet.
Future<void> showCardSortSheet(
  BuildContext context, {
  required CardListSort selected,
  required ValueChanged<CardListSort> onSelected,
}) => showMxBottomSheet<void>(
  context,
  builder: (sheetContext) => CardSortSheetWidget(
    selected: selected,
    onSelected: (sort) {
      onSelected(sort);
      Navigator.of(sheetContext).pop();
    },
  ),
);

class CardSortSheetWidget extends StatelessWidget {
  const CardSortSheetWidget({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final CardListSort selected;
  final ValueChanged<CardListSort> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const sorts = CardListSort.values;
    return MxBottomSheet(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.card,
          AppSpacing.micro,
          AppSpacing.card,
          AppSpacing.grouped,
        ),
        child: Text(l10n.cardSortTitle, style: context.textStyles.compactTitle),
      ),
      child: Column(
        children: [
          for (final (index, sort) in sorts.indexed)
            MxOptionRow(
              title: l10n.cardSort(sort),
              isSelected: sort == selected,
              onSelected: () => onSelected(sort),
              hasDivider: index < sorts.length - 1,
            ),
        ],
      ),
    );
  }
}
