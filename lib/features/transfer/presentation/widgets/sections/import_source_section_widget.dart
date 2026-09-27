import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_source_model.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';
import 'package:memox/features/transfer/presentation/widgets/items/import_source_option_widget.dart';
import 'package:memox/features/transfer/presentation/widgets/overlays/import_option_sheet_widget.dart';
import 'package:memox/features/transfer/presentation/widgets/support/import_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// Step 1 of the import (kit 11). While choosing: the two sources, then the
/// file picker, the pasted text, the problem or the reading card. Once the
/// source is read, only its chip stays (kit deviation K1).
class ImportSourceSectionWidget extends StatefulWidget {
  const ImportSourceSectionWidget({
    super.key,
    required this.draft,
    required this.onChooseKind,
    required this.onChooseFile,
    required this.onPaste,
    required this.onClear,
    required this.onChooseSheet,
  });

  final CardImportDraft draft;
  final ValueChanged<CardImportSourceKind> onChooseKind;
  final VoidCallback onChooseFile;
  final ValueChanged<String> onPaste;
  final VoidCallback onClear;
  final ValueChanged<int> onChooseSheet;

  @override
  State<ImportSourceSectionWidget> createState() =>
      _ImportSourceSectionWidgetState();
}

class _ImportSourceSectionWidgetState extends State<ImportSourceSectionWidget> {
  late final _pasted = TextEditingController(
    text: switch (widget.draft.source) {
      PastedSource(:final text) => text,
      _ => '',
    },
  );

  @override
  void dispose() {
    _pasted.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final draft = widget.draft;
    final isChoosing = draft.step == CardImportStep.source;
    final isPaste = draft.sourceKind == CardImportSourceKind.paste;
    final canChange = !draft.isBusy;
    final children = <Widget>[
      if (isChoosing) ...[
        MxListSectionHeader(label: l10n.importSectionSource),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.control,
            children: [
              Expanded(
                child: ImportSourceOptionWidget(
                  icon: AppIcons.fileUp,
                  label: l10n.importSourceFile,
                  hint: l10n.importSourceFileHint,
                  isSelected: !isPaste,
                  onSelected: canChange
                      ? () => widget.onChooseKind(CardImportSourceKind.file)
                      : null,
                ),
              ),
              Expanded(
                child: ImportSourceOptionWidget(
                  icon: AppIcons.clipboard,
                  label: l10n.importSourcePaste,
                  hint: l10n.importSourcePasteHint,
                  isSelected: isPaste,
                  onSelected: canChange
                      ? () => widget.onChooseKind(CardImportSourceKind.paste)
                      : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.gutter),
      ],
      ..._body(context),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  List<Widget> _body(BuildContext context) {
    final l10n = context.l10n;
    final draft = widget.draft;
    final isChoosing = draft.step == CardImportStep.source;
    if (isChoosing && draft.isBusy) {
      return [_ReadingCard(label: l10n.importReading)];
    }
    final problem = draft.problem;
    if (isChoosing && problem != null) {
      final copy = l10n.importProblem(problem);
      return [
        MxInlineBanner(
          tone: MxBannerTone.warning,
          title: copy.title,
          message: copy.body,
          actions: [
            if (draft.sourceKind == CardImportSourceKind.file)
              MxButton(
                label: l10n.importChooseAnother,
                icon: AppIcons.folderOpen,
                tone: MxButtonTone.outline,
                size: MxButtonSize.small,
                onPressed: widget.onChooseFile,
              ),
          ],
        ),
        if (draft.sourceKind == CardImportSourceKind.paste) ...[
          const SizedBox(height: AppSpacing.grouped),
          _pasteField(context),
        ],
      ];
    }
    if (draft.sourceKind == CardImportSourceKind.paste && isChoosing) {
      return [
        _pasteField(context),
        const SizedBox(height: AppSpacing.grouped),
        MxNote(text: l10n.importHelperBody),
      ];
    }
    if (draft.source == null) {
      return [
        MxCard(
          child: MxEmptyState(
            icon: AppIcons.fileUp,
            title: l10n.importPickTitle,
            body: l10n.importPickBody,
            isCompact: true,
            actionLabel: l10n.importPickAction,
            onAction: widget.onChooseFile,
          ),
        ),
        const SizedBox(height: AppSpacing.grouped),
        MxNote(text: l10n.importHelperBody),
      ];
    }
    return [
      _SourceChip(
        draft: draft,
        onClear: draft.isBusy ? null : widget.onClear,
        onChooseSheet: widget.onChooseSheet,
      ),
      if (isChoosing) ...[
        const SizedBox(height: AppSpacing.grouped),
        MxNote(text: l10n.importHelperBody),
      ],
    ];
  }

  Widget _pasteField(BuildContext context) {
    final l10n = context.l10n;
    final lines = _pasted.text.trim().isEmpty
        ? 0
        : _pasted.text.trim().split('\n').length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.micro,
      children: [
        MxTextField(
          controller: _pasted,
          label: l10n.importSourcePaste,
          hintText: l10n.importPasteHint,
          variant: MxTextFieldVariant.detail,
          onChanged: (text) {
            widget.onPaste(text);
            setState(() {});
          },
        ),
        if (lines > 0)
          Text(
            l10n.importPastedLines(lines),
            style: context.textStyles.rowDescription,
          ),
      ],
    );
  }
}

/// The source once chosen (kit 11 file chip): its name and what was read,
/// the sheet of a workbook with several (spec §8.1 ruling 2), and a remove
/// button that returns to an empty step 1.
class _SourceChip extends StatelessWidget {
  const _SourceChip({
    required this.draft,
    required this.onClear,
    required this.onChooseSheet,
  });

  final CardImportDraft draft;
  final VoidCallback? onClear;
  final ValueChanged<int> onChooseSheet;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final source = draft.source;
    final table = draft.table;
    final format = switch (source) {
      FileSource(:final format) => format.extension.toUpperCase(),
      _ => l10n.importPastedFormat,
    };
    final isFile = source is FileSource;
    final meta = table == null
        ? l10n.importFileReady(format)
        : l10n.importFileRead(format, table.rows.length, table.columnCount);
    return MxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.control,
        children: [
          Row(
            spacing: AppSpacing.grouped,
            children: [
              MxIconTile(icon: isFile ? AppIcons.fileText : AppIcons.clipboard),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.micro,
                  children: [
                    Text(
                      isFile ? draft.fileName ?? '' : l10n.importSourcePaste,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: styles.contentTitle,
                    ),
                    Text(meta, style: styles.rowDescription),
                  ],
                ),
              ),
              MxIconButton(
                icon: AppIcons.close,
                semanticLabel: l10n.importRemoveSource,
                onPressed: onClear,
              ),
            ],
          ),
          if (table != null && table.sheetNames.length > 1)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: _SheetTrigger(table: table, onChooseSheet: onChooseSheet),
            ),
        ],
      ),
    );
  }
}

class _SheetTrigger extends StatelessWidget {
  const _SheetTrigger({required this.table, required this.onChooseSheet});

  final SourceTable table;
  final ValueChanged<int> onChooseSheet;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final names = table.sheetNames;
    return MxChipTrigger(
      label: l10n.importSheet(
        names[table.sheetIndex],
        table.sheetIndex + 1,
        names.length,
      ),
      onPressed: () => showImportOptionSheet<int>(
        context,
        title: l10n.importSheetPickerTitle,
        options: [for (var index = 0; index < names.length; index++) index],
        selected: table.sheetIndex,
        label: (index) => names[index],
        onSelected: onChooseSheet,
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => MxCard(
    child: Column(
      spacing: AppSpacing.grouped,
      children: [
        MxSpinner(size: MxSpinnerSize.large, semanticLabel: label),
        Text(label, style: context.textStyles.emptyBody),
      ],
    ),
  );
}
