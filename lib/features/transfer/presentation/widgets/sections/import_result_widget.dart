import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_summary_model.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';
import 'package:memox/features/transfer/presentation/widgets/items/import_preview_row_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_section.dart';

/// How an import ended (kit 11 results; UC-TRANSFER-001 step 8, E4, E5):
/// the design system's empty state in the result's tone (kit deviation K4),
/// then what was added and skipped, and each skipped row with why (critique
/// 2026-10-02, F4).
class ImportResultWidget extends StatelessWidget {
  const ImportResultWidget({super.key, required this.state});

  /// A [CardImportDone] or a [CardImportFailed].
  final CardImportState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return switch (state) {
      CardImportDone(:final summary) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          switch (summary.kind) {
            ImportSummaryKind.success => MxEmptyState(
              icon: AppIcons.learned,
              tone: MxEmptyStateTone.success,
              title: l10n.importDoneTitle,
              body: l10n.importDoneBody(summary.written),
            ),
            ImportSummaryKind.partial => MxEmptyState(
              icon: AppIcons.learned,
              tone: MxEmptyStateTone.success,
              title: l10n.importPartialTitle,
              body: l10n.importPartialBody,
            ),
            ImportSummaryKind.none => MxEmptyState(
              icon: AppIcons.cardDeck,
              tone: MxEmptyStateTone.neutral,
              title: l10n.importNoneTitle,
              body: l10n.importNoneBody,
            ),
          },
          if (summary.kind != ImportSummaryKind.none) ...[
            const SizedBox(height: AppSpacing.gutter),
            _Counts(summary: summary),
          ],
          if (summary.decks.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.gutter),
            _Decks(decks: summary.decks),
          ],
          if (summary.skipped.isNotEmpty) _SkippedRows(rows: summary.skipped),
          // The rule explains the duplicate rows only (final review).
          if (summary.duplicatesSkipped > 0) MxNote(text: l10n.importSkipNote),
        ],
      ),
      CardImportFailed(isTargetRejected: true) => MxEmptyState(
        icon: AppIcons.library,
        tone: MxEmptyStateTone.warning,
        title: l10n.importRejectsTitle,
        body: l10n.importRejectsBody,
      ),
      _ => MxEmptyState(
        icon: AppIcons.alert,
        tone: MxEmptyStateTone.danger,
        title: l10n.importFailedTitle,
        body: l10n.importFailedBody,
      ),
    };
  }
}

class _Counts extends StatelessWidget {
  const _Counts({required this.summary});

  final ImportSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final count = context.textStyles.counter;
    MxListRow row(IconData icon, String label, int value) => MxListRow(
      title: label,
      leading: MxIconTile(icon: icon),
      trailing: Text(l10n.importResultCount(value), style: count),
    );
    return MxSection(
      children: [
        row(AppIcons.check, l10n.importCountAdded, summary.written),
        if (summary.duplicatesSkipped > 0)
          row(
            AppIcons.cardDeck,
            l10n.importCountDuplicates,
            summary.duplicatesSkipped,
          ),
        if (summary.invalid > 0)
          row(AppIcons.alert, l10n.importCountInvalid, summary.invalid),
      ],
    );
  }
}

/// The decks a sectioned import wrote to, New or Existing, with the cards
/// each received (spec 2026-10-08 U8).
class _Decks extends StatelessWidget {
  const _Decks({required this.decks});

  final List<ImportDeckResult> decks;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxSection(
      title: l10n.importDecksHeader,
      children: [
        for (final deck in decks)
          MxListRow(
            title: deck.name,
            subtitle: l10n.importDeckCards(deck.written),
            trailing: MxBadge(
              label: deck.isNew ? l10n.importDeckNew : l10n.importDeckExisting,
              tone: deck.isNew ? MxBadgeTone.primary : MxBadgeTone.neutral,
            ),
          ),
      ],
    );
  }
}

/// The rows the import skipped, each as the preview drew it: number, term,
/// meaning, why, and its mark (critique 2026-10-02, F4). The first
/// [shownRows] show; "Show all" opens the rest in place.
class _SkippedRows extends StatefulWidget {
  const _SkippedRows({required this.rows});

  final List<ImportRow> rows;

  static const int shownRows = 5;

  @override
  State<_SkippedRows> createState() => _SkippedRowsState();
}

class _SkippedRowsState extends State<_SkippedRows> {
  var _isShowingAll = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = widget.rows;
    final shown = _isShowingAll
        ? rows
        : rows.take(_SkippedRows.shownRows).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxSection(
          title: l10n.importSkippedHeader,
          children: [for (final row in shown) ImportPreviewRowWidget(row: row)],
        ),
        if (shown.length < rows.length)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: MxButton(
              label: l10n.importSkippedShowAll(rows.length),
              tone: MxButtonTone.text,
              size: MxButtonSize.compact,
              onPressed: () => setState(() => _isShowingAll = true),
            ),
          ),
      ],
    );
  }
}
