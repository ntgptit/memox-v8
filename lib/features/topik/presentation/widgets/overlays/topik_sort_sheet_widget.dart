import 'package:flutter/material.dart';
import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_divided_column.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

/// Screen 35's sort (BR-TOPIK-022): the three orders; the pick closes the
/// sheet. Null when dismissed.
Future<TopikTestOrder?> showTopikSortSheet(
  BuildContext context, {
  required TopikTestOrder selected,
}) => showMxBottomSheet<TopikTestOrder>(
  context,
  builder: (sheetContext) => TopikSortSheetWidget(selected: selected),
);

class TopikSortSheetWidget extends StatelessWidget {
  const TopikSortSheetWidget({super.key, required this.selected});

  final TopikTestOrder selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxBottomSheet(
      title: l10n.topikSortTitle,
      child: MxDividedColumn(
        children: [
          for (final order in TopikTestOrder.values)
            MxOptionRow(
              title: l10n.topikOrderName(order),
              isSelected: order == selected,
              onSelected: () => Navigator.of(context).pop(order),
            ),
        ],
      ),
    );
  }
}
