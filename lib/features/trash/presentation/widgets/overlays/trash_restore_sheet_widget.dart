import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/deck/domain/models/deck_path_model.dart';
import 'package:memox/features/deck/domain/models/deck_restore_targets_model.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/presentation/controllers/trash_controller.dart';
import 'package:memox/features/trash/presentation/providers/trash_restore_targets_provider.dart';
import 'package:memox/features/trash/presentation/states/trash_state.dart';
import 'package:memox/features/trash/presentation/widgets/support/trash_labels_widget.dart';
import 'package:memox/features/trash/presentation/widgets/support/trash_rejection_message_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_deck_picker_sheet.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Asks where [entries], all of one kind, go back to, then restores them
/// there (UC-TRASH-001 steps 5-7). Nothing is written before a target is
/// chosen (BR-TRASH-006). Completes true once they are back.
Future<bool> showTrashRestoreSheet(
  BuildContext context, {
  required List<TrashEntry> entries,
}) async =>
    await showMxBottomSheet<bool>(
      context,
      builder: (_) => TrashRestoreSheetWidget(entries: entries),
    ) ??
    false;

/// A place the entries can go: a deck, or the top level (null).
typedef _Target = ({String? id, String name, String label});

class TrashRestoreSheetWidget extends ConsumerStatefulWidget {
  const TrashRestoreSheetWidget({super.key, required this.entries});

  final List<TrashEntry> entries;

  @override
  ConsumerState<TrashRestoreSheetWidget> createState() =>
      _TrashRestoreSheetWidgetState();
}

class _TrashRestoreSheetWidgetState
    extends ConsumerState<TrashRestoreSheetWidget> {
  static const int _skeletonRows = 3;

  /// One restore at a time: a second tap before the first lands does
  /// nothing.
  var _isRestoring = false;

  late final _batchIds = TrashBatchIds({
    for (final entry in widget.entries) entry.batchId,
  });

  bool get _isCards => widget.entries.first is TrashCardEntry;

  Future<void> _restore(_Target target) async {
    if (_isRestoring) return;
    setState(() => _isRestoring = true);
    final trash = ref.read(trashControllerProvider.notifier);
    try {
      final String? refusal;
      if (_isCards) {
        final outcome = await trash.restoreCards(
          batchIds: _batchIds.ids,
          deckId: target.id!,
        );
        if (!mounted) return;
        refusal = switch (outcome) {
          Ok() => null,
          Rejected(:final reason) => context.l10n.trashCardRejection(reason),
        };
      } else {
        final outcome = await trash.restoreDecks(
          batchIds: _batchIds.ids,
          parentId: target.id,
        );
        if (!mounted) return;
        refusal = switch (outcome) {
          Ok() => null,
          Rejected(:final reason) => context.l10n.trashDeckRejection(reason),
        };
      }
      final l10n = context.l10n;
      showMxSnackbar(
        context,
        message:
            refusal ??
            switch (widget.entries) {
              [final entry] => l10n.trashRestoredOne(
                trashEntryName(entry),
                target.name,
              ),
              final entries => l10n.trashRestoredMany(
                entries.length,
                target.name,
              ),
            },
      );
      Navigator.of(context).pop(refusal == null);
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() => _isRestoring = false);
      showMxSnackbar(context, message: context.l10n.failure(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final targets = _isCards
        ? ref
              .watch(cardRestoreTargetsProvider(_batchIds))
              .whenData(
                (targets) => [
                  for (final target in targets)
                    _deck(target.id, target.name, target.path),
                ],
              )
        : ref
              .watch(deckRestoreTargetsProvider(_batchIds))
              .whenData(
                (targets) => switch (targets) {
                  DeckRestoreTopLevel() => [
                    (
                      id: null,
                      name: l10n.trashTopLevel,
                      label: l10n.trashTopLevel,
                    ),
                  ],
                  DeckRestoreUnder(:final decks) => [
                    for (final target in decks)
                      _deck(target.id, target.name, target.path),
                  ],
                },
              );
    return switch (targets) {
      AsyncData(:final value) => MxDeckPickerSheet(
        title: _title(l10n),
        rule: _rule(l10n, value),
        candidates: [
          for (final target in value)
            MxPickerCandidate(
              label: target.label,
              icon: target.id == null ? AppIcons.library : AppIcons.folder,
              isEnabled: !_isRestoring,
              onTap: () => unawaited(_restore(target)),
            ),
        ],
        dismissLabel: value.isEmpty ? l10n.commonOk : l10n.commonCancel,
        onDismiss: () => Navigator.of(context).pop(false),
        emptyTitle: l10n.trashRestoreEmptyTitle,
        emptyBody: _emptyBody(l10n),
      ),
      AsyncError() => MxBottomSheet(
        child: MxErrorState(
          title: l10n.trashLoadErrorTitle,
          body: l10n.libraryLoadErrorBody,
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.invalidate(
            _isCards
                ? cardRestoreTargetsProvider(_batchIds)
                : deckRestoreTargetsProvider(_batchIds),
          ),
        ),
      ),
      _ => MxBottomSheet(
        child: Column(
          children: [
            MxSkeletonList(
              semanticLabel: l10n.commonLoading,
              rows: _skeletonRows,
            ),
          ],
        ),
      ),
    };
  }

  static _Target _deck(String id, String name, List<DeckPathEntry> path) => (
    id: id,
    name: name,
    label: [
      for (final entry in path) entry.name,
      name,
    ].join(trashPathSeparator),
  );

  String _title(AppLocalizations l10n) => switch (widget.entries) {
    [final entry] => l10n.trashRestoreOneTitle(trashEntryName(entry)),
    final entries when _isCards => l10n.trashRestoreCardsTitle(entries.length),
    final entries => l10n.trashRestoreDecksTitle(entries.length),
  };

  String _rule(AppLocalizations l10n, List<_Target> targets) {
    if (_isCards) return l10n.trashRestoreCardsRule;
    final isTopLevel = targets.length == 1 && targets.single.id == null;
    return isTopLevel ? l10n.trashRestoreRootsRule : l10n.trashRestoreDecksRule;
  }

  /// A card names its top-level deck, where an empty sub-deck would take it
  /// (kit 06 noTarget).
  String _emptyBody(AppLocalizations l10n) {
    final origin = widget.entries.first.origin;
    if (!_isCards || origin.isEmpty) return l10n.trashRestoreNoDeckTargetBody;
    return l10n.trashRestoreNoCardTargetBody(origin.first.name);
  }
}
