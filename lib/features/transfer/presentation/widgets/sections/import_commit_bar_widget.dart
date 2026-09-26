import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';

/// The import's commit bar (kit 11): Cancel, the step's one action, and a
/// caption that says what happens next. Nothing is written before Import
/// (UC-TRANSFER-001 step 6); while it runs, only waiting is possible.
class ImportCommitBarWidget extends StatelessWidget {
  const ImportCommitBarWidget({
    super.key,
    required this.draft,
    required this.onCancel,
    required this.onRead,
    required this.onPreview,
    required this.onCommit,
  });

  final CardImportDraft draft;
  final VoidCallback onCancel;
  final VoidCallback onRead;
  final VoidCallback onPreview;
  final VoidCallback onCommit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isBusy = draft.isBusy;
    final (label, icon, action, caption) = switch (draft.step) {
      CardImportStep.source => (
        l10n.importReadAction,
        AppIcons.arrowRight,
        draft.source == null ? null : onRead,
        draft.source == null
            ? l10n.importCaptionSource
            : l10n.importCaptionPrivate,
      ),
      CardImportStep.columns => (
        l10n.importPreviewAction,
        AppIcons.preview,
        draft.mapping.isComplete ? onPreview : null,
        l10n.importCaptionColumns,
      ),
      CardImportStep.preview => (
        l10n.importCommitAction(draft.willWrite),
        AppIcons.download,
        draft.willWrite > 0 ? onCommit : null,
        l10n.importCaptionPreview(draft.willWrite),
      ),
      CardImportStep.importing => (
        l10n.importCommitting,
        AppIcons.download,
        null,
        l10n.importCaptionPrivate,
      ),
    };
    final isImporting = draft.step == CardImportStep.importing;
    return MxFooterBar(
      caption: caption,
      child: Row(
        spacing: AppSpacing.control,
        children: [
          MxButton(
            label: l10n.commonCancel,
            tone: MxButtonTone.outline,
            onPressed: isImporting ? null : onCancel,
          ),
          Expanded(
            child: MxButton(
              label: label,
              icon: icon,
              isBlock: true,
              isLoading: isBusy,
              onPressed: isBusy ? null : action,
            ),
          ),
        ],
      ),
    );
  }
}
