import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/presentation/controllers/trash_controller.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

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

  bool get _isCards => widget.entries.first is TrashCardEntry;

  Future<void> _purge() async {
    // A second tap in the same frame reaches here before the busy confirm
    // is drawn.
    if (_isPurging) return;
    setState(() => _isPurging = true);
    try {
      final report = await ref.read(trashControllerProvider.notifier).purge({
        for (final entry in widget.entries) entry.batchId,
      });
      if (!mounted) return;
      final purged = report.purged.length;
      if (purged > 0) {
        final l10n = context.l10n;
        showMxSnackbar(
          context,
          message: _isCards
              ? l10n.trashPurgedCards(purged)
              : l10n.trashPurgedDecks(purged),
        );
      }
      Navigator.of(context).pop(true);
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() => _isPurging = false);
      showMxSnackbar(context, message: context.l10n.failure(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final count = widget.entries.length;
    return MxDialog(
      title: _isCards
          ? l10n.trashPurgeCardsTitle(count)
          : l10n.trashPurgeDecksTitle(count),
      body: l10n.trashPurgeBody(count),
      actions: MxSheetActions.custom(
        children: [
          Expanded(
            flex: _keepShare,
            child: MxButton(
              label: l10n.trashPurgeKeep,
              onPressed: () => Navigator.of(context).pop(false),
              isBlock: true,
              isAutofocused: true,
            ),
          ),
          Expanded(
            flex: _deleteShare,
            child: MxButton(
              label: l10n.trashPurgeConfirm(count),
              icon: AppIcons.delete,
              tone: MxButtonTone.destructive,
              isBlock: true,
              isLoading: _isPurging,
              onPressed: _purge,
            ),
          ),
        ],
      ),
    );
  }
}
