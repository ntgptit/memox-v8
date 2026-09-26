import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/presentation/controllers/trash_controller.dart';
import 'package:memox/features/trash/presentation/providers/trash_entries_provider.dart';
import 'package:memox/features/trash/presentation/states/trash_state.dart';
import 'package:memox/features/trash/presentation/widgets/items/trash_entry_row_widget.dart';
import 'package:memox/features/trash/presentation/widgets/overlays/trash_entry_actions_sheet_widget.dart';
import 'package:memox/features/trash/presentation/widgets/overlays/trash_restore_sheet_widget.dart';
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
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entries = ref.watch(trashEntriesProvider);
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.libraryTrash,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
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
        AsyncData(:final value) => MxScreenScroll(children: _list(l10n, value)),
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
    );
  }

  /// The note, the filters with their counts (A6), the header, the rows.
  List<Widget> _list(AppLocalizations l10n, List<TrashEntry> entries) {
    final state = ref.watch(trashControllerProvider);
    final now = ref.watch(dayClockProvider).now();
    final shown = entries.where(state.filter.accepts).toList();
    return [
      const SizedBox(height: AppSpacing.control),
      MxNote(icon: AppIcons.history, text: l10n.trashNote),
      const SizedBox(height: AppSpacing.grouped),
      _Filters(
        selected: state.filter,
        entries: entries,
        onSelected: _trash().chooseFilter,
      ),
      MxListSectionHeader(
        label: l10n.trashEntriesHeader(shown.length),
        isAfterFilterBand: true,
      ),
      for (final entry in shown)
        TrashEntryRowWidget(
          key: ValueKey(entry.batchId),
          entry: entry,
          now: now,
          onTap: () => unawaited(_openActions(entry)),
          onActions: () => unawaited(_openActions(entry)),
        ),
    ];
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
