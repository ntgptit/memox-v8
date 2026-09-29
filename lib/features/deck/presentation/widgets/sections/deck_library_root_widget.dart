import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/deck/presentation/providers/deck_level_provider.dart';
import 'package:memox/features/deck/presentation/states/deck_level_query_state.dart';
import 'package:memox/features/deck/presentation/states/deck_reorder_mode_state.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/create_root_deck_dialog_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_level_body_widget.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_reorder_done_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

/// The roots with today's work first (UC-DECK-003).
class DeckLibraryRootWidget extends ConsumerWidget {
  const DeckLibraryRootWidget({
    super.key,
    required this.onOpenDeck,
    required this.onSearch,
    required this.onOpenAlgorithm,
    required this.onOpenStudy,
    required this.onOpenStudyOptions,
    required this.onOpenTrash,
    this.onOpenStudyHome,
    required this.onOpenStarterDecks,
    required this.onOpenTags,
  });

  final ValueChanged<String> onOpenDeck;
  final VoidCallback onSearch;
  final ValueChanged<String> onOpenAlgorithm;

  /// A deck's Study Entry (screen 14), from an action sheet or a summary.
  final ValueChanged<String> onOpenStudy;

  /// Screen 15 for a deck (FE-A3 D3).
  final ValueChanged<String> onOpenStudyOptions;

  /// Opens the Trash (screen 06) from the app bar (FE-B1 D1).
  final VoidCallback onOpenTrash;

  /// The due strip's tap: Study home.
  final VoidCallback? onOpenStudyHome;

  /// Opens Starter decks (screen 03) from the app bar and the empty
  /// Library (FE-B4 spec D2, §5.4).
  final VoidCallback onOpenStarterDecks;

  /// Opens Tags (screen 05) from the app bar (FE-B2 spec D2).
  final VoidCallback onOpenTags;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isReordering = ref.watch(deckReorderModeProvider(null));
    final query = ref.watch(deckLevelQueryProvider(null));
    // Kit 01: no FAB while the Library loads, fails or is empty; the body
    // then offers its own action.
    final hasDecks =
        (ref
                .watch(
                  deckLevelProvider(
                    parentId: null,
                    sort: query.sort,
                    filter: query.filter,
                  ),
                )
                .value
                ?.deckCount ??
            0) >
        0;
    void createDeck() => unawaited(showCreateRootDeckDialog(context));
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.navLibrary,
        actions: isReordering
            ? const [DeckReorderDoneWidget(parentId: null)]
            // Kit 01: Starter decks, Tags, Trash (spec D2).
            : [
                MxIconButton(
                  icon: AppIcons.starterDecks,
                  semanticLabel: l10n.libraryStarterDecks,
                  onPressed: onOpenStarterDecks,
                ),
                MxIconButton(
                  icon: AppIcons.tag,
                  semanticLabel: l10n.libraryTags,
                  onPressed: onOpenTags,
                ),
                MxIconButton(
                  icon: AppIcons.delete,
                  semanticLabel: l10n.libraryTrash,
                  onPressed: onOpenTrash,
                ),
              ],
      ),
      fab: isReordering || !hasDecks
          ? null
          : MxFab(
              icon: AppIcons.add,
              semanticLabel: l10n.libraryCreateDeck,
              onPressed: createDeck,
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.micro,
              AppSpacing.gutter,
              AppSpacing.control,
            ),
            child: MxSearchField.trigger(
              hintText: l10n.searchFieldHint,
              onTap: onSearch,
            ),
          ),
          Expanded(
            child: DeckLevelBodyWidget(
              parentId: null,
              onOpenDeck: onOpenDeck,
              onOpenAlgorithm: onOpenAlgorithm,
              onOpenStudy: onOpenStudy,
              onOpenStudyOptions: onOpenStudyOptions,
              onOpenTrash: onOpenTrash,
              onOpenStudyHome: onOpenStudyHome,
              schedulerType: null,
              hasDeepestSubDecks: false,
              emptyState: MxEmptyState(
                icon: AppIcons.library,
                title: l10n.libraryEmptyTitle,
                body: l10n.libraryEmptyBody,
                actionLabel: l10n.libraryCreateDeck,
                onAction: createDeck,
                secondaryActionLabel: l10n.libraryBrowseStarterDecks,
                onSecondaryAction: onOpenStarterDecks,
                footnote: l10n.libraryEmptyFootnote,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
