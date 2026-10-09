import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/transfer/domain/models/import_plan_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/presentation/widgets/items/import_deck_row_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';

/// The destinations of a sectioned import, before its rows (spec
/// 2026-10-08 U2): this block is the confirmation of what Import will
/// create and fill. Two or more taken names add a first row that decides
/// them all (C2).
class ImportDecksSectionWidget extends StatelessWidget {
  const ImportDecksSectionWidget({
    super.key,
    required this.preview,
    required this.isIncludingDuplicates,
    required this.onChoose,
    required this.onChooseAll,
    required this.onRename,
  });

  final ImportPreview preview;
  final bool isIncludingDuplicates;
  final void Function(int index, ImportSectionChoice choice) onChoose;
  final ValueChanged<ImportSectionChoice> onChooseAll;
  final ValueChanged<String> onRename;

  /// From this many taken names on, one choice can decide them all (C2).
  static const int _minForAll = 2;

  @override
  Widget build(BuildContext context) {
    final choosable = [
      for (final group in preview.groups)
        if (group.isChoosable) group,
    ];
    return MxSection(
      title: context.l10n.importDecksHeader,
      children: [
        if (choosable.length >= _minForAll)
          _ChooseAllRow(groups: choosable, onChooseAll: onChooseAll),
        for (final (index, group) in preview.groups.indexed)
          ImportDeckRowWidget(
            key: ValueKey(('import-deck', index)),
            group: group,
            willWrite: group.willWrite(
              includeDuplicates: isIncludingDuplicates,
            ),
            onChoose: (choice) => onChoose(index, choice),
            onRename: onRename,
          ),
      ],
    );
  }
}

/// "{n} decks with taken names" and one choice for all of them; nothing is
/// chosen until every one of them shares a choice (S2, C2).
class _ChooseAllRow extends StatelessWidget {
  const _ChooseAllRow({required this.groups, required this.onChooseAll});

  final List<ImportGroup> groups;
  final ValueChanged<ImportSectionChoice> onChooseAll;

  ImportSectionChoice? get _shared {
    if (groups.every((group) => group.destination is IntoExistingDeck)) {
      return ImportSectionChoice.addToExisting;
    }
    if (groups.every((group) => group.destination is IntoNewDeck)) {
      return ImportSectionChoice.createNew;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.grouped,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.control,
        children: [
          Text(
            l10n.importDecksTakenNames(groups.length),
            style: context.textStyles.contentTitle,
          ),
          MxSegmentedTray<ImportSectionChoice>(
            segments: [
              MxSegment(
                value: ImportSectionChoice.addToExisting,
                label: l10n.importDeckAddAll,
              ),
              MxSegment(
                value: ImportSectionChoice.createNew,
                label: l10n.importDeckCreateAll,
              ),
            ],
            selected: _shared,
            onSelected: onChooseAll,
          ),
        ],
      ),
    );
  }
}
