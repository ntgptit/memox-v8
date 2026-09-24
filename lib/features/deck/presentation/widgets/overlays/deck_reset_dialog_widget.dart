import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/features/deck/presentation/controllers/deck_actions_controller.dart';
import 'package:memox/features/deck/presentation/providers/reset_learning_summary_provider.dart';
import 'package:memox/features/deck/presentation/widgets/support/scheduler_type_label_widget.dart';
import 'package:memox/features/deck/presentation/widgets/support/srs_rejection_message_widget.dart';
import 'package:memox/features/srs/domain/models/reset_learning_summary_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_outcome_tile.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Asks before a root's learning progress is reset (UC-SRS-001).
Future<void> showResetLearningDialog(
  BuildContext context, {
  required DeckView view,
}) => showMxDialog<void>(
  context,
  builder: (_) => DeckResetDialogWidget(view: view),
);

/// What a reset keeps and loses (BR-SRS-030), or that nothing is lost
/// (A2), and the algorithm for the new cycle (step 3). It runs in one
/// transaction; a failure leaves everything as it was (E1).
class DeckResetDialogWidget extends ConsumerStatefulWidget {
  const DeckResetDialogWidget({super.key, required this.view});

  final DeckView view;

  @override
  ConsumerState<DeckResetDialogWidget> createState() =>
      _DeckResetDialogWidgetState();
}

class _DeckResetDialogWidgetState extends ConsumerState<DeckResetDialogWidget> {
  late SchedulerType _choice = widget.view.schedulerType;
  var _isResetting = false;

  /// The cycle the reset opens.
  int get _nextCycle => widget.view.deck.generation! + 1;

  Future<void> _reset(ResetLearningSummary summary) async {
    setState(() => _isResetting = true);
    final view = widget.view;
    final cycle = _nextCycle;
    try {
      final outcome = await ref
          .read(deckActionsControllerProvider.notifier)
          .resetLearning(
            rootDeckId: view.deck.id,
            schedulerType: _choice == view.schedulerType ? null : _choice,
          );
      if (!mounted) return;
      final l10n = context.l10n;
      showMxSnackbar(
        context,
        message: switch (outcome) {
          Ok() => l10n.resetDoneToast(cycle, summary.cardCount),
          Rejected(:final reason) => l10n.srsRejection(reason),
        },
      );
      Navigator.of(context).pop();
    } on Failure catch (failure) {
      if (!mounted) return;
      // E1: rolled back; the dialog stays for another try.
      setState(() => _isResetting = false);
      showMxSnackbar(context, message: context.l10n.failure(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final view = widget.view;
    final value = ref.watch(resetLearningSummaryProvider(view.deck.id));
    final summary = switch (value) {
      AsyncData(value: Ok(:final value)) => value,
      _ => null,
    };
    final body = switch (value) {
      AsyncData(value: Ok(:final value)) when !value.hasProgressToLose =>
        l10n.resetNothingToLose,
      AsyncData(value: Ok(:final value)) => l10n.resetDialogIntro(
        _nextCycle,
        view.deck.name,
        value.cardCount,
      ),
      AsyncData(value: Rejected(:final reason)) => l10n.srsRejection(reason),
      AsyncError(:final error) =>
        error is Failure ? l10n.failure(error) : l10n.failureUnknown,
      _ => null,
    };
    return MxDialog(
      title: l10n.resetDialogTitle,
      body: body,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (value.isLoading) const MxSkeletonRow(),
          if (summary != null && summary.hasProgressToLose)
            _Consequences(summary: summary, cycle: view.deck.generation!),
          MxListSectionHeader(label: l10n.resetAlgorithmHeader),
          _AlgorithmChoice(
            current: view.schedulerType,
            choice: _choice,
            onChosen: _isResetting
                ? null
                : (type) => setState(() => _choice = type),
          ),
        ],
      ),
      actions: MxSheetActions(
        cancelLabel: l10n.commonCancel,
        onCancel: _isResetting ? () {} : () => Navigator.of(context).pop(),
        confirmLabel: _isResetting
            ? l10n.resetRunning
            : l10n.resetConfirm(_nextCycle),
        confirmIcon: AppIcons.resetProgress,
        onConfirm: summary != null && !_isResetting
            ? () => unawaited(_reset(summary))
            : null,
      ),
    );
  }
}

/// Kept and Lost side by side (BR-SRS-030, spec A10).
class _Consequences extends StatelessWidget {
  const _Consequences({required this.summary, required this.cycle});

  final ResetLearningSummary summary;

  /// The cycle that ends: past answers stay labelled with it.
  final int cycle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cards = summary.cardCount;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.control,
        children: [
          Expanded(
            child: MxOutcomeTile(
              label: l10n.resetKeptLabel,
              body: l10n.resetKeptBody(cycle),
              tone: MxOutcomeTone.kept,
            ),
          ),
          Expanded(
            child: MxOutcomeTile(
              label: l10n.resetLostLabel,
              body: summary.openSessionCount > 0
                  ? l10n.resetLostBodyWithSession(cards)
                  : l10n.resetLostBody(cards),
              tone: MxOutcomeTone.lost,
            ),
          ),
        ],
      ),
    );
  }
}

/// Keep the current algorithm (selected first) or switch (step 3).
class _AlgorithmChoice extends StatelessWidget {
  const _AlgorithmChoice({
    required this.current,
    required this.choice,
    required this.onChosen,
  });

  final SchedulerType current;
  final SchedulerType choice;

  /// Null while the reset runs.
  final ValueChanged<SchedulerType>? onChosen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final other = SchedulerType.values.firstWhere((type) => type != current);
    final onChosen = this.onChosen;
    return MxCard(
      isFullBleed: true,
      child: Column(
        children: [
          MxOptionRow(
            title: l10n.resetKeep(l10n.schedulerType(current)),
            isSelected: choice == current,
            onSelected: onChosen == null ? null : () => onChosen(current),
          ),
          MxOptionRow(
            title: l10n.resetSwitchTo(l10n.schedulerType(other)),
            isSelected: choice == other,
            onSelected: onChosen == null ? null : () => onChosen(other),
            hasDivider: false,
          ),
        ],
      ),
    );
  }
}
