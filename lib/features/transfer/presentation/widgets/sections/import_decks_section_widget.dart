import 'package:flutter/material.dart';
import 'package:memox/features/transfer/domain/models/import_plan_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/presentation/widgets/items/import_deck_row_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_section.dart';

/// The destinations of a sectioned import, before its rows (spec
/// 2026-10-08 U2): this block is the confirmation of what Import will
/// create and fill.
class ImportDecksSectionWidget extends StatelessWidget {
  const ImportDecksSectionWidget({
    super.key,
    required this.preview,
    required this.isIncludingDuplicates,
    required this.onChoose,
    required this.onRename,
  });

  final ImportPreview preview;
  final bool isIncludingDuplicates;
  final void Function(int index, ImportSectionChoice choice) onChoose;
  final ValueChanged<String> onRename;

  @override
  Widget build(BuildContext context) => MxSection(
    title: context.l10n.importDecksHeader,
    children: [
      for (final (index, group) in preview.groups.indexed)
        ImportDeckRowWidget(
          key: ValueKey(('import-deck', index)),
          group: group,
          willWrite: group.willWrite(includeDuplicates: isIncludingDuplicates),
          onChoose: (choice) => onChoose(index, choice),
          onRename: onRename,
        ),
    ],
  );
}
