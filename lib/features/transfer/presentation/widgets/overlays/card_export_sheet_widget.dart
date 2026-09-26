import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:memox/features/transfer/presentation/controllers/card_export_controller.dart';
import 'package:memox/features/transfer/presentation/providers/count_export_cards_use_case_provider.dart';
import 'package:memox/features/transfer/presentation/states/card_export_state.dart';
import 'package:memox/features/transfer/presentation/widgets/support/export_labels_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Opens the export sheet over [scope] (kit 12, UC-TRANSFER-002) and, once
/// the share sheet took the file, says so without naming where it went
/// (BR-TRANSFER-014, ruling E2).
Future<void> showCardExportSheet(
  BuildContext context,
  CardExportScope scope,
) async {
  final isHandedOver =
      await showMxBottomSheet<bool>(
        context,
        builder: (_) => CardExportSheetWidget(scope: scope),
      ) ??
      false;
  if (!isHandedOver || !context.mounted) return;
  showMxSnackbar(
    context,
    message: context.l10n.exportHandedOver(scope.cardCount),
  );
}

/// The whole-deck entry (the deck's ⋮): counts the deck's cards first, so
/// the sheet opens knowing its scope and never loads (UC-TRANSFER-002 UI).
Future<void> showDeckExportSheet(
  BuildContext context, {
  required String deckId,
  required String deckName,
}) async {
  final count = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(countExportCardsUseCaseProvider);
  final int cardCount;
  try {
    cardCount = await count(deckId);
  } on Failure catch (failure) {
    if (!context.mounted) return;
    showMxSnackbar(context, message: context.l10n.failure(failure));
    return;
  }
  if (!context.mounted) return;
  await showCardExportSheet(
    context,
    CardExportScope.deck(
      deckId: deckId,
      deckName: deckName,
      cardCount: cardCount,
    ),
  );
}

/// Kit 12: the fixed scope, the three formats, what the file holds, and one
/// action. It closes itself once the file is handed over.
class CardExportSheetWidget extends ConsumerWidget {
  const CardExportSheetWidget({super.key, required this.scope});

  final CardExportScope scope;

  CardExportController _sheet(WidgetRef ref) =>
      ref.read(cardExportControllerProvider(scope).notifier);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = cardExportControllerProvider(scope);
    ref.listen(provider, (_, next) {
      if (next.isHandedOver) Navigator.of(context).pop(true);
    });
    final state = ref.watch(provider);
    final problem = state.problem;
    final sheet = MxBottomSheet(
      header: _Header(scope: scope),
      footer: _Actions(
        scope: scope,
        state: state,
        onExport: () => _sheet(ref).export(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.control),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (problem != null) _Problem(problem: problem),
            // The overline, the banner and the note line up with the title.
            Padding(
              padding:
                  const EdgeInsets.only(top: AppSpacing.micro) +
                  const EdgeInsets.symmetric(horizontal: AppSpacing.control),
              child: MxListSectionHeader(
                label: context.l10n.exportFormatSection,
              ),
            ),
            for (final (index, format) in TransferFormat.values.indexed)
              _FormatRow(
                format: format,
                isSelected: state.format == format,
                isLast: index == TransferFormat.values.length - 1,
                onSelected: state.isPreparing
                    ? null
                    : () => _sheet(ref).chooseFormat(format),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.grouped,
                AppSpacing.grouped,
                AppSpacing.grouped,
                AppSpacing.control,
              ),
              child: MxNote(
                text: context.l10n.exportContentNote,
                icon: AppIcons.fileText,
              ),
            ),
          ],
        ),
      ),
    );
    // Every way out pops this route: the file in progress is never shared.
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _sheet(ref).close();
      },
      child: sheet,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.scope});

  final CardExportScope scope;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final deckName = scope.deckName;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.card,
        AppSpacing.micro,
        AppSpacing.card,
        AppSpacing.grouped,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.micro,
        children: [
          Text(
            deckName == null
                ? l10n.exportTitleSelection(scope.cardCount)
                : l10n.exportTitleDeck(scope.cardCount),
            style: styles.compactTitle,
          ),
          Text(
            deckName == null
                ? l10n.exportBodySelection
                : l10n.exportBodyDeck(deckName),
            style: styles.dialogBody,
          ),
        ],
      ),
    );
  }
}

class _Problem extends StatelessWidget {
  const _Problem({required this.problem});

  final CardExportProblem problem;

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n.exportProblem(problem);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.grouped,
        0,
        AppSpacing.grouped,
        AppSpacing.grouped,
      ),
      child: MxInlineBanner(
        tone: problem == CardExportProblem.prepareFailed
            ? MxBannerTone.danger
            : MxBannerTone.warning,
        title: copy.title,
        message: copy.body,
      ),
    );
  }
}

class _FormatRow extends StatelessWidget {
  const _FormatRow({
    required this.format,
    required this.isSelected,
    required this.isLast,
    required this.onSelected,
  });

  final TransferFormat format;
  final bool isSelected;
  final bool isLast;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (name, body) = l10n.exportFormat(format);
    return MxOptionRow(
      title: name,
      description: body,
      isSelected: isSelected,
      onSelected: onSelected,
      hasDivider: !isLast,
      trailing: format == TransferFormat.csv
          ? MxBadge(label: l10n.exportRecommended, tone: MxBadgeTone.primary)
          : null,
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.scope,
    required this.state,
    required this.onExport,
  });

  final CardExportScope scope;
  final CardExportState state;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    void close() => Navigator.of(context).pop(false);
    final problem = state.problem;
    if (problem != null && problem.isFinal) {
      return MxSheetActions.custom(
        isInSheet: true,
        children: [
          Expanded(
            child: MxButton(
              label: l10n.exportClose,
              onPressed: close,
              tone: MxButtonTone.outline,
              isBlock: true,
            ),
          ),
        ],
      );
    }
    final isRetry = problem != null;
    return MxSheetActions(
      isInSheet: true,
      cancelLabel: l10n.commonCancel,
      onCancel: close,
      confirmLabel: state.isPreparing
          ? l10n.exportPreparing
          : isRetry
          ? l10n.exportTryAgain
          : l10n.exportAction(scope.cardCount),
      confirmIcon: isRetry ? AppIcons.retry : AppIcons.share,
      isConfirmLoading: state.isPreparing,
      onConfirm: onExport,
    );
  }
}
