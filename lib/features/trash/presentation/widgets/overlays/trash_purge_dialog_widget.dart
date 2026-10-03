import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/domain/models/purge_report_model.dart';
import 'package:memox/features/trash/presentation/controllers/trash_controller.dart';
import 'package:memox/l10n/bulk_message.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';
import 'package:memox/shared/widgets/mx_action_pair.dart';

/// Asks before [entries], all of one kind, are deleted for good
/// (UC-TRASH-001 A3). Completes true once the purge ran; the batches the
/// store skipped are the screen's to name (spec D6).
Future<bool> showTrashPurgeDialog(
  BuildContext context, {
  required List<TrashEntry> entries,
}) async =>
    await showMxDialog<bool>(
      context,
      builder: (_) => TrashPurgeDialogWidget(entries: entries),
    ) ??
    false;

/// The strong confirmation of BR-TRASH-011: the exact count, the lost
/// history, the focus on Keep in Trash, the destructive tone on Delete only.
/// Delete spins while the batches go (spec D15).
class TrashPurgeDialogWidget extends ConsumerStatefulWidget {
  const TrashPurgeDialogWidget({super.key, required this.entries});

  final List<TrashEntry> entries;

  @override
  ConsumerState<TrashPurgeDialogWidget> createState() =>
      _TrashPurgeDialogWidgetState();
}

class _TrashPurgeDialogWidgetState
    extends ConsumerState<TrashPurgeDialogWidget> {
  /// Kit 06: Keep in Trash 1.2, Delete 1.
  static const int _keepShare = 12;
  static const int _deleteShare = 10;

  var _isPurging = false;

  /// The last purge's failure, shown in the dialog until the next try; Delete
  /// is the retry (SP2b 2.27).
  Failure? _failure;

  bool get _isCards => widget.entries.first is TrashCardEntry;

  Future<void> _purge() async {
    // A second tap in the same frame reaches here before the busy confirm
    // is drawn.
    if (_isPurging) return;
    setState(() {
      _isPurging = true;
      _failure = null;
    });
    try {
      final report = await ref.read(trashControllerProvider.notifier).purge({
        for (final entry in widget.entries) entry.batchId,
      });
      if (!mounted) return;
      final message = _toast(context.l10n, report);
      if (message != null) {
        showMxSnackbar(
          context,
          message: message,
          // What was kept is news the person reads past a first sentence.
          duration: bulkToastDuration(hasNews: report.blocked.isNotEmpty),
        );
      }
      Navigator.of(context).pop(true);
    } on Object catch (error, stack) {
      final failure = failureOfThrown(error, stack, library: 'trash purge');
      if (!mounted) return;
      setState(() {
        _isPurging = false;
        _failure = failure;
      });
    }
  }

  /// What goes: a deck is named with its sub-decks and cards, several decks
  /// by their totals, cards by the count (SP2b 2.32, BR-TRASH-011).
  String _body(AppLocalizations l10n) {
    final entries = widget.entries;
    int sum(int Function(TrashDeckEntry deck) of) => entries
        .whereType<TrashDeckEntry>()
        .fold(0, (total, deck) => total + of(deck));
    return switch (entries) {
      [TrashDeckEntry(:final name, :final subDeckCount, :final cardCount)] =>
        l10n.trashPurgeDeckBody(name, subDeckCount, cardCount),
      _ when !_isCards => l10n.trashPurgeDecksTotalBody(
        entries.length,
        sum((deck) => deck.subDeckCount),
        sum((deck) => deck.cardCount),
      ),
      _ => l10n.trashPurgeBody(entries.length),
    };
  }

  /// What the purge did, in one toast: what went and what was kept (SP2b
  /// 2.31). Null when nothing went and nothing was kept: every chosen batch
  /// was already gone, and its row with it.
  String? _toast(AppLocalizations l10n, PurgeReport report) {
    final purged = report.purged.length;
    final went = switch (purged) {
      0 => null,
      _ when _isCards => l10n.trashPurgedCards(purged),
      _ => l10n.trashPurgedDecks(purged),
    };
    // The kept decks are only counted: the banner above the list names what
    // each one still holds (a note says a thing once).
    final kept = report.blocked.isEmpty
        ? null
        : l10n.trashPurgeKeptMany(report.blocked.length);
    return switch ((went, kept)) {
      (final a?, final b?) => l10n.trashPurgedWithKept(a, b),
      (final one?, null) || (null, final one?) => one,
      (null, null) => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final count = widget.entries.length;
    final failure = _failure;
    // Once Delete runs, nothing may look like a cancel: the batches go
    // whatever the dialog does (BR-TRASH-011).
    return PopScope(
      canPop: !_isPurging,
      child: MxDialog(
        title: _isCards
            ? l10n.trashPurgeCardsTitle(count)
            : l10n.trashPurgeDecksTitle(count),
        body: _body(l10n),
        content: failure == null
            ? null
            : MxInlineBanner(
                tone: MxBannerTone.warning,
                message: l10n.failure(failure),
              ),
        actions: MxSheetActions.custom(
          children: [
            Expanded(
              child: MxActionPair(
                leading: MxButton(
                  label: l10n.trashPurgeKeep,
                  onPressed: _isPurging
                      ? null
                      : () => Navigator.of(context).pop(false),
                  isBlock: true,
                  isSingleLine: true,
                  isAutofocused: true,
                ),
                trailing: MxButton(
                  label: l10n.trashPurgeConfirm(count),
                  icon: AppIcons.delete,
                  tone: MxButtonTone.destructive,
                  isBlock: true,
                  isSingleLine: true,
                  isLoading: _isPurging,
                  onPressed: _purge,
                ),
                leadingFlex: _keepShare,
                trailingFlex: _deleteShare,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
