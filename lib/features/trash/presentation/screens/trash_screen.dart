import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/presentation/controllers/trash_controller.dart';
import 'package:memox/features/trash/presentation/providers/trash_entries_provider.dart';
import 'package:memox/features/trash/presentation/states/trash_state.dart';
import 'package:memox/features/trash/presentation/widgets/items/trash_entry_row_widget.dart';
import 'package:memox/features/trash/presentation/widgets/overlays/trash_entry_actions_sheet_widget.dart';
import 'package:memox/features/trash/presentation/widgets/overlays/trash_restore_sheet_widget.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/features/trash/presentation/widgets/support/trash_labels_widget.dart';
import 'package:memox/features/trash/presentation/widgets/sections/trash_selection_bar_widget.dart';
import 'package:memox/features/trash/presentation/widgets/overlays/trash_purge_dialog_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// Screen 06, the Trash (UC-TRASH-001): what was deleted, newest first,
/// filtered by kind, each entry with its time left.
class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> {
  static const int _skeletonRows = 3;

  TrashController _trash() => ref.read(trashControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    unawaited(_purgeExpired());
  }

  /// Opening the Trash purges what expired (UC-TRASH-001 A4); the stream
  /// drops those rows in place. A failure keeps them for the next try.
  Future<void> _purgeExpired() async {
    try {
      await _trash().purgeExpired();
    } on Failure {
      // The list still shows; the next start, resume or visit retries.
    }
  }

  Future<void> _openActions(TrashEntry entry) async {
    final action = await showTrashEntryActionsSheet(
      context,
      entry: entry,
      now: ref.read(dayClockProvider).now(),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case TrashEntryAction.restore:
        await showTrashRestoreSheet(context, entries: [entry]);
      case TrashEntryAction.purge:
        await showTrashPurgeDialog(context, entries: [entry]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entries = ref.watch(trashEntriesProvider);
    final state = ref.watch(trashControllerProvider);
    final loaded = entries.value ?? const <TrashEntry>[];
    final selected = [
      for (final entry in loaded)
        if (state.selected.contains(entry.batchId)) entry,
    ];
    // Back leaves selection before it leaves the Trash.
    return PopScope(
      canPop: !state.isSelecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _trash().stopSelecting();
      },
      child: MxAppShell(
        appBar: _appBar(l10n, state, loaded),
        footer: state.isSelecting
            ? TrashSelectionBarWidget(
                count: selected.length,
                onRestore: () => unawaited(
                  showTrashRestoreSheet(context, entries: selected),
                ),
                onPurge: () =>
                    unawaited(showTrashPurgeDialog(context, entries: selected)),
              )
            : null,
        body: switch (entries) {
          AsyncData(:final value) when value.isEmpty => MxScreenScroll(
            children: [
              MxEmptyState(
                icon: AppIcons.delete,
                title: l10n.trashEmptyTitle,
                body: l10n.trashEmptyBody,
              ),
            ],
          ),
          AsyncData(:final value) => MxScreenScroll(
            children: _list(l10n, value),
          ),
          AsyncError() => MxScreenScroll(
            children: [
              MxErrorState(
                title: l10n.trashLoadErrorTitle,
                body: l10n.libraryLoadErrorBody,
                retryLabel: l10n.commonRetry,
                onRetry: () => ref.invalidate(trashEntriesProvider),
              ),
            ],
          ),
          _ => MxScreenScroll(
            children: [
              MxSkeletonList(
                semanticLabel: l10n.commonLoading,
                rows: _skeletonRows,
              ),
            ],
          ),
        },
      ),
    );
  }

  /// Back, "Trash" and Select; while selecting, close and the count of the
  /// kind picked (kit 06 selection).
  MxAppBar _appBar(
    AppLocalizations l10n,
    TrashState state,
    List<TrashEntry> entries,
  ) {
    if (!state.isSelecting) {
      return MxAppBar(
        title: l10n.libraryTrash,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
        actions: [
          if (entries.isNotEmpty)
            MxButton(
              label: l10n.trashSelect,
              size: MxButtonSize.compact,
              tone: MxButtonTone.secondary,
              onPressed: _trash().startSelecting,
            ),
        ],
      );
    }
    final count = state.countIn(entries);
    return MxAppBar(
      title: switch (state.kindIn(entries)) {
        null => l10n.trashSelectTitle,
        TrashKind.card => l10n.trashCardsSelected(count),
        TrashKind.deck => l10n.trashDecksSelected(count),
      },
      density: MxAppBarDensity.content,
      leading: MxIconButton(
        icon: AppIcons.close,
        semanticLabel: l10n.trashSelectionClose,
        onPressed: _trash().stopSelecting,
      ),
    );
  }

  /// The note, the filters with their counts (A6, none while selecting),
  /// the header, the rows, then why the other kind waits and what a purge
  /// skipped (spec D6).
  List<Widget> _list(AppLocalizations l10n, List<TrashEntry> entries) {
    final state = ref.watch(trashControllerProvider);
    final now = ref.watch(dayClockProvider).now();
    final shown = entries.where(state.filter.accepts).toList();
    final kind = state.kindIn(entries);
    return [
      const SizedBox(height: AppSpacing.control),
      // Read before selecting; the selection gives the list the room.
      if (!state.isSelecting) ...[
        MxNote(icon: AppIcons.history, text: l10n.trashNote),
        const SizedBox(height: AppSpacing.grouped),
      ],
      if (!state.isSelecting)
        _Filters(
          selected: state.filter,
          entries: entries,
          onSelected: _trash().chooseFilter,
        ),
      MxListSectionHeader(
        label: _header(l10n, state, shown, kind),
        isAfterFilterBand: !state.isSelecting,
      ),
      for (final entry in shown)
        TrashEntryRowWidget(
          key: ValueKey(entry.batchId),
          entry: entry,
          now: now,
          isSelecting: state.isSelecting,
          isSelected: state.selected.contains(entry.batchId),
          onTap: switch (state.isSelecting) {
            false => () => unawaited(_openActions(entry)),
            // The other kind cannot be picked (BR-TRASH-011).
            true when kind != null && kind != TrashKind.of(entry) => null,
            true => () => _trash().toggle(entry, entries),
          },
          onLongPress: state.isSelecting
              ? null
              : () => _trash().toggle(entry, entries),
          onActions: () => unawaited(_openActions(entry)),
        ),
      if (kind != null) MxNote(text: l10n.trashKindLock),
      for (final note in _blockedNotes(l10n, state, entries))
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.control),
          child: MxInlineBanner(tone: MxBannerTone.warning, message: note),
        ),
    ];
  }

  String _header(
    AppLocalizations l10n,
    TrashState state,
    List<TrashEntry> shown,
    TrashKind? kind,
  ) {
    int total(TrashKind of) =>
        shown.where((entry) => TrashKind.of(entry) == of).length;
    final count = state.countIn(shown);
    return switch (kind) {
      TrashKind.card => l10n.trashSelectedOfCards(count, total(TrashKind.card)),
      TrashKind.deck => l10n.trashSelectedOfDecks(count, total(TrashKind.deck)),
      null => l10n.trashEntriesHeader(shown.length),
    };
  }

  /// One sentence per batch the last purge skipped and still in the Trash,
  /// naming what it still holds (spec D6).
  Iterable<String> _blockedNotes(
    AppLocalizations l10n,
    TrashState state,
    List<TrashEntry> entries,
  ) sync* {
    final byBatch = {for (final entry in entries) entry.batchId: entry};
    for (final MapEntry(key: batchId, value: inner) in state.blocked.entries) {
      final blocked = byBatch[batchId];
      final names = [
        for (final id in inner)
          if (byBatch[id] case final entry?) trashEntryName(entry),
      ];
      if (blocked == null || names.isEmpty) continue;
      yield l10n.trashPurgeBlocked(
        trashEntryName(blocked),
        names.join(trashNamesSeparator),
      );
    }
  }
}

/// All · Cards · Decks, each with its count (kit 06).
class _Filters extends StatelessWidget {
  const _Filters({
    required this.selected,
    required this.entries,
    required this.onSelected,
  });

  final TrashFilter selected;
  final List<TrashEntry> entries;
  final ValueChanged<TrashFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.control),
      // The chips never shrink or wrap, so their row scrolls.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: AppSpacing.micro,
          children: [
            for (final filter in TrashFilter.values)
              MxFilterChip(
                label: switch (filter) {
                  TrashFilter.all => l10n.trashFilterAll,
                  TrashFilter.cards => l10n.trashFilterCards,
                  TrashFilter.decks => l10n.trashFilterDecks,
                },
                count: entries.where(filter.accepts).length,
                isSelected: filter == selected,
                onSelected: (_) => onSelected(filter),
              ),
          ],
        ),
      ),
    );
  }
}
