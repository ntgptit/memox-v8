import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/transfer/presentation/controllers/card_import_controller.dart';
import 'package:memox/features/transfer/presentation/states/card_import_state.dart';
import 'package:memox/features/transfer/presentation/widgets/sections/import_commit_bar_widget.dart';
import 'package:memox/features/transfer/presentation/widgets/sections/import_mapping_section_widget.dart';
import 'package:memox/features/transfer/presentation/widgets/sections/import_preview_section_widget.dart';
import 'package:memox/features/transfer/presentation/widgets/sections/import_result_widget.dart';
import 'package:memox/features/transfer/presentation/widgets/sections/import_source_section_widget.dart';
import 'package:memox/features/transfer/presentation/widgets/sections/import_step_tracker_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';
import 'package:memox/shared/widgets/mx_action_pair.dart';

/// Imports cards from a file or pasted text into [deckId] (UC-TRANSFER-001,
/// kit 11): a full-screen task above the shell (IT-NAV-012). [deckContext]
/// is the deck's path and name that `app/` passes in, as for the card
/// editor; [onClose] leaves the import, [onViewCards] leaves it for the
/// deck's cards.
class CardImportScreen extends ConsumerStatefulWidget {
  const CardImportScreen({
    super.key,
    required this.deckId,
    required this.deckContext,
    required this.onClose,
    required this.onViewCards,
  });

  final String deckId;
  final Widget Function(String deckId, String currentLabel) deckContext;
  final VoidCallback onClose;
  final VoidCallback onViewCards;

  @override
  ConsumerState<CardImportScreen> createState() => _CardImportScreenState();
}

class _CardImportScreenState extends ConsumerState<CardImportScreen> {
  CardImportController get _wizard =>
      ref.read(cardImportControllerProvider(widget.deckId).notifier);

  /// Android Back steps back one step (IT-NAV-012 step 4); at step 1 and on
  /// a result it closes; while writing it does nothing (step 5).
  void _onBack() {
    if (_wizard.stepBack()) return;
    widget.onClose();
  }

  void _close() {
    final state = ref.read(cardImportControllerProvider(widget.deckId));
    if (state case CardImportDraft(step: CardImportStep.importing)) return;
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cardImportControllerProvider(widget.deckId));
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: switch (state) {
        final CardImportDraft draft => _wizardShell(context, draft),
        _ => _resultShell(context, state),
      },
    );
  }

  Widget _appBar(BuildContext context, String title) => MxAppBar(
    title: title,
    density: MxAppBarDensity.content,
    leading: MxIconButton(
      icon: AppIcons.close,
      semanticLabel: context.l10n.importClose,
      onPressed: _close,
    ),
  );

  Widget _wizardShell(BuildContext context, CardImportDraft draft) {
    final l10n = context.l10n;
    final step = draft.step;
    return MxAppShell(
      appBar: _appBar(context, l10n.importTitle),
      // The deck and the step stay above the scroll, as on the card editor.
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          widget.deckContext(widget.deckId, l10n.importBreadcrumb),
          ImportStepTrackerWidget(current: step),
          Expanded(child: _wizardScroll(draft)),
        ],
      ),
      footer: ImportCommitBarWidget(
        draft: draft,
        onCancel: _close,
        onRead: () => unawaited(_wizard.readSource()),
        onPreview: () => unawaited(_wizard.previewRows()),
        onCommit: () => unawaited(_wizard.commit()),
      ),
    );
  }

  Widget _wizardScroll(CardImportDraft draft) {
    final step = draft.step;
    return MxScreenScroll(
      children: [
        const SizedBox(height: AppSpacing.micro),
        ImportSourceSectionWidget(
          // A new source or a fresh start rebuilds the pasted text field.
          key: ValueKey(draft.sourceKind),
          draft: draft,
          onChooseKind: _wizard.chooseSourceKind,
          onChooseFile: () => unawaited(_wizard.chooseFile()),
          onPaste: _wizard.pasteText,
          onClear: _wizard.clearSource,
          onChooseSheet: (index) =>
              unawaited(_wizard.readSource(sheetIndex: index)),
        ),
        const SizedBox(height: AppSpacing.gutter),
        if (step == CardImportStep.columns)
          ImportMappingSectionWidget(
            draft: draft,
            onHeaderRow: (isOn) => _wizard.setHasHeaderRow(hasHeaderRow: isOn),
            onAssign: _wizard.assignColumn,
          ),
        if (step == CardImportStep.preview)
          ImportPreviewSectionWidget(
            draft: draft,
            onIncludeDuplicates: (isOn) =>
                _wizard.setIncludingDuplicates(isIncluding: isOn),
          ),
        if (step == CardImportStep.importing)
          _ImportingCard(count: draft.willWrite),
      ],
    );
  }

  Widget _resultShell(BuildContext context, CardImportState state) {
    final l10n = context.l10n;
    final (secondary, primary) = switch (state) {
      CardImportDone(summary: final summary) when summary.written == 0 => (
        (l10n.importAnother, _wizard.startOver),
        (l10n.importBackToDeck, widget.onClose, AppIcons.back),
      ),
      CardImportDone() => (
        (l10n.importAnother, _wizard.startOver),
        (l10n.importViewCards, widget.onViewCards, AppIcons.cardDeck),
      ),
      CardImportFailed(isTargetRejected: true) => (
        null,
        (l10n.importCloseAction, widget.onClose, AppIcons.close),
      ),
      _ => (
        (l10n.importCloseAction, widget.onClose),
        (l10n.importTryAgain, () => unawaited(_wizard.retry()), AppIcons.retry),
      ),
    };
    return MxAppShell(
      appBar: _appBar(context, l10n.importResultsTitle),
      body: MxScreenScroll(children: [ImportResultWidget(state: state)]),
      footer: MxFooterBar(
        child: MxActionPair(
          leading: switch (secondary) {
            (final label, final onPressed) => MxButton(
              label: label,
              tone: MxButtonTone.outline,
              isBlock: true,
              isSingleLine: true,
              onPressed: onPressed,
            ),
            null => null,
          },
          trailing: MxButton(
            label: primary.$1,
            icon: primary.$3,
            isBlock: true,
            isSingleLine: true,
            onPressed: primary.$2,
          ),
        ),
      ),
    );
  }
}

/// Step 4 while the commit runs (kit 11 importing): all or nothing
/// (BR-TRANSFER-004).
class _ImportingCard extends StatelessWidget {
  const _ImportingCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final title = l10n.importImportingTitle(count);
    return MxCard(
      child: Column(
        spacing: AppSpacing.grouped,
        children: [
          MxSpinner(size: MxSpinnerSize.large, semanticLabel: title),
          Text(
            title,
            textAlign: TextAlign.center,
            style: styles.emptyTitleCompact,
          ),
          Text(
            l10n.importImportingBody,
            textAlign: TextAlign.center,
            style: styles.emptyBody,
          ),
        ],
      ),
    );
  }
}
