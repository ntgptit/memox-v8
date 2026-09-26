import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/transfer/domain/models/import_summary_model.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_section.dart';

/// How an import ended (kit 11 results; UC-TRANSFER-001 step 8, E4, E5):
/// the design system's empty state in the result's tone (kit deviation K4),
/// then what was added and skipped.
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
          if (summary.kind == ImportSummaryKind.partial)
            MxNote(text: l10n.importSkipNote),
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
