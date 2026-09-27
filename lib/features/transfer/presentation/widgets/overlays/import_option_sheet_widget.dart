import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

/// A one-choice sheet of the import (kit 11): the field a column feeds, or
/// the sheet of a workbook (A2). The chosen option closes the sheet.
Future<void> showImportOptionSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required T selected,
  required String Function(T option) label,
  required ValueChanged<T> onSelected,
}) => showMxBottomSheet<void>(
  context,
  builder: (sheetContext) => ImportOptionSheetWidget<T>(
    title: title,
    options: options,
    selected: selected,
    label: label,
    onSelected: (option) {
      onSelected(option);
      Navigator.of(sheetContext).pop();
    },
  ),
);

class ImportOptionSheetWidget<T> extends StatelessWidget {
  const ImportOptionSheetWidget({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final String title;
  final List<T> options;
  final T selected;
  final String Function(T option) label;
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
            title: label(option),
            isSelected: option == selected,
            onSelected: () => onSelected(option),
            hasDivider: index < options.length - 1,
          ),
      ],
    ),
  );
}
