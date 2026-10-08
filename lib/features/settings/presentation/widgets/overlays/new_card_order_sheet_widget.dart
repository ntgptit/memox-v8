import 'package:flutter/material.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

/// The new-card order picker of screen 23a (owner 2026-10-07): one row per
/// order, the current one selected, as the speech language sheet is.
/// Returns the pick, or null when dismissed.
Future<NewCardOrder?> showNewCardOrderSheet(
  BuildContext context, {
  required NewCardOrder selected,
}) => showMxBottomSheet<NewCardOrder>(
  context,
  builder: (_) => NewCardOrderSheetWidget(selected: selected),
);

/// The display name of [order], shared by the row and the sheet.
String newCardOrderLabel(BuildContext context, NewCardOrder order) =>
    switch (order) {
      NewCardOrder.created => context.l10n.settingsOrderCreated,
      NewCardOrder.random => context.l10n.settingsOrderRandom,
    };

class NewCardOrderSheetWidget extends StatelessWidget {
  const NewCardOrderSheetWidget({super.key, required this.selected});

  final NewCardOrder selected;

  @override
  Widget build(BuildContext context) => MxBottomSheet(
    // The head of the speech language sheet: the title in the card inset.
    title: context.l10n.settingsNewCardOrder,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, order) in NewCardOrder.values.indexed)
          MxOptionRow(
            title: newCardOrderLabel(context, order),
            isSelected: order == selected,
            isDimmed: false,
            hasDivider: index < NewCardOrder.values.length - 1,
            onSelected: () => Navigator.of(context).pop(order),
          ),
      ],
    ),
  );
}
