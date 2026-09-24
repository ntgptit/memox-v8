import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_create_option_model.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/features/deck/presentation/providers/deck_view_provider.dart';
import 'package:memox/features/deck/presentation/states/deck_reorder_mode_state.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/create_root_deck_dialog_widget.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_name_dialog_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_level_body_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_unset_state_widget.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// One level of the deck tree (spec §6.1): the Library root when [deckId] is
/// null, otherwise an open deck under its breadcrumb. Navigation arrives as
/// callbacks; the screen never builds a path (spec §4).
class DeckLevelScreen extends StatelessWidget {
  const DeckLevelScreen({
    super.key,
    this.deckId,
    required this.onOpenDeck,
    required this.onOpenAncestor,
    required this.onSearch,
    required this.cardContent,
    required this.onAddCard,
    required this.cardFab,
  });

  final String? deckId;
  final ValueChanged<String> onOpenDeck;

  /// A breadcrumb tap: a deck above this one, or null for the Library root.
  final ValueChanged<String?> onOpenAncestor;
  final VoidCallback onSearch;

  /// What a deck of cards shows. The router passes the card feature's list
  /// section; `deck` never imports `card` (spec D8).
  final Widget Function(String deckId) cardContent;

  /// New card for [deckId]: the router opens the card editor.
  final ValueChanged<String> onAddCard;

  /// A deck of cards' FAB, from the card feature like [cardContent] (spec
  /// D8). It hides itself while cards are selected.
  final Widget Function(String deckId) cardFab;

  @override
  Widget build(BuildContext context) => switch (deckId) {
    null => _LibraryRoot(onOpenDeck: onOpenDeck, onSearch: onSearch),
    final id => _OpenDeck(
      deckId: id,
      onOpenDeck: onOpenDeck,
      onOpenAncestor: onOpenAncestor,
      cardContent: cardContent,
      onAddCard: onAddCard,
      cardFab: cardFab,
    ),
  };
}

/// The roots with today's work first (UC-DECK-003).
class _LibraryRoot extends ConsumerWidget {
  const _LibraryRoot({required this.onOpenDeck, required this.onSearch});

  final ValueChanged<String> onOpenDeck;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isReordering = ref.watch(deckReorderModeProvider(null));
    void createDeck() => unawaited(showCreateRootDeckDialog(context));
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.navLibrary,
        actions: isReordering
            ? const [_ReorderDone(parentId: null)]
            // Starter decks, tags and trash have no screen yet (spec A6).
            : [
                MxIconButton(
                  icon: AppIcons.starterDecks,
                  semanticLabel: l10n.libraryStarterDecks,
                  onPressed: null,
                ),
                MxIconButton(
                  icon: AppIcons.tag,
                  semanticLabel: l10n.libraryTags,
                  onPressed: null,
                ),
                MxIconButton(
                  icon: AppIcons.delete,
                  semanticLabel: l10n.libraryTrash,
                  onPressed: null,
                ),
              ],
      ),
      fab: isReordering
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
              hintText: l10n.deckSearchHint,
              onTap: onSearch,
            ),
          ),
          Expanded(
            child: DeckLevelBodyWidget(
              parentId: null,
              onOpenDeck: onOpenDeck,
              emptyState: MxEmptyState(
                icon: AppIcons.library,
                title: l10n.libraryEmptyTitle,
                body: l10n.libraryEmptyBody,
                actionLabel: l10n.libraryCreateDeck,
                onAction: createDeck,
                // Starter decks have no screen yet (spec A6).
                secondaryActionLabel: l10n.libraryBrowseStarter,
                footnote: l10n.libraryEmptyFootnote,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// An open deck while its stream loads, fails or is gone.
class _OpenDeck extends ConsumerWidget {
  const _OpenDeck({
    required this.deckId,
    required this.onOpenDeck,
    required this.onOpenAncestor,
    required this.cardContent,
    required this.onAddCard,
    required this.cardFab,
  });

  final String deckId;
  final ValueChanged<String> onOpenDeck;
  final ValueChanged<String?> onOpenAncestor;
  final Widget Function(String deckId) cardContent;
  final ValueChanged<String> onAddCard;
  final Widget Function(String deckId) cardFab;

  static const int _skeletonRows = 4;

  /// Ruling P2-L7: the deck is gone. Say so once and step back.
  void _leaveWhenGone(
    BuildContext context,
    AsyncValue<Outcome<DeckView, DeckRejection>>? previous,
    AsyncValue<Outcome<DeckView, DeckRejection>> next,
  ) {
    if (previous?.value case Rejected()) return;
    if (next.value case Rejected(reason: DeckRejection.notFound)) {
      showMxSnackbar(context, message: context.l10n.deckDeletedToast);
      unawaited(Navigator.of(context).maybePop());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = deckViewProvider(deckId);
    ref.listen(
      provider,
      (previous, next) => _leaveWhenGone(context, previous, next),
    );
    final bar = MxAppBar(
      title: l10n.navLibrary,
      density: MxAppBarDensity.content,
      leading: const _BackButton(),
    );
    return switch (ref.watch(provider)) {
      AsyncData(value: Ok(:final value)) => _OpenDeckContent(
        view: value,
        onOpenDeck: onOpenDeck,
        onOpenAncestor: onOpenAncestor,
        cardContent: cardContent,
        onAddCard: onAddCard,
        cardFab: cardFab,
      ),
      AsyncError() => MxAppShell(
        appBar: bar,
        body: MxScreenScroll(
          children: [
            MxErrorState(
              title: l10n.deckLoadErrorTitle,
              body: l10n.libraryLoadErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(provider),
            ),
          ],
        ),
      ),
      // Loading, or gone and about to pop.
      _ => MxAppShell(
        appBar: bar,
        body: MxScreenScroll(
          children: [
            for (var i = 0; i < _skeletonRows; i++) const MxSkeletonRow(),
          ],
        ),
      ),
    };
  }
}

/// An open deck: its name, its path, and what it holds (spec §6.1).
class _OpenDeckContent extends ConsumerWidget {
  const _OpenDeckContent({
    required this.view,
    required this.onOpenDeck,
    required this.onOpenAncestor,
    required this.cardContent,
    required this.onAddCard,
    required this.cardFab,
  });

  final DeckView view;
  final ValueChanged<String> onOpenDeck;
  final ValueChanged<String?> onOpenAncestor;
  final Widget Function(String deckId) cardContent;
  final ValueChanged<String> onAddCard;
  final Widget Function(String deckId) cardFab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final deck = view.deck;
    final isReordering = ref.watch(deckReorderModeProvider(deck.id));
    final canCreateDeck = view.createOptions.contains(DeckCreateOption.deck);
    final canCreateCard = view.createOptions.contains(DeckCreateOption.card);
    void createSubDeck() =>
        unawaited(showCreateSubDeckDialog(context, parentId: deck.id));
    return MxAppShell(
      appBar: MxAppBar(
        title: deck.name,
        density: MxAppBarDensity.content,
        leading: const _BackButton(),
        actions: isReordering
            ? [_ReorderDone(parentId: deck.id)]
            : [
                MxIconButton(
                  icon: AppIcons.more,
                  semanticLabel: l10n.deckActions,
                  onPressed: () => unawaited(
                    openDeckActions(
                      context,
                      ref,
                      deckId: deck.id,
                      parentId: deck.parentId,
                      onOpenDeck: onOpenDeck,
                      isOpenDeck: true,
                    ),
                  ),
                ),
              ],
      ),
      // Ruling P4a-L9: a sub-deck where one fits, a card on a deck of cards.
      fab: switch (deck.contentType) {
        DeckContentType.card => cardFab(deck.id),
        _ when canCreateDeck && !isReordering => MxFab(
          icon: AppIcons.add,
          semanticLabel: l10n.deckCreateSub,
          onPressed: createSubDeck,
        ),
        _ => null,
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ruling P2-L4: Library › ancestors › this deck.
          MxBreadcrumb(
            segments: [
              MxBreadcrumbSegment(
                label: l10n.navLibrary,
                onTap: () => onOpenAncestor(null),
              ),
              for (final entry in view.breadcrumb)
                MxBreadcrumbSegment(
                  label: entry.name,
                  onTap: () => onOpenAncestor(entry.id),
                ),
              MxBreadcrumbSegment(label: deck.name),
            ],
          ),
          Expanded(
            child: switch (deck.contentType) {
              DeckContentType.card => cardContent(deck.id),
              DeckContentType.deck ||
              DeckContentType.unset => DeckLevelBodyWidget(
                parentId: deck.id,
                onOpenDeck: onOpenDeck,
                emptyState: DeckUnsetStateWidget(
                  onAddCard: canCreateCard ? () => onAddCard(deck.id) : null,
                  onCreateSubDeck: canCreateDeck ? createSubDeck : null,
                ),
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) => MxIconButton(
    icon: AppIcons.back,
    semanticLabel: context.l10n.commonBack,
    onPressed: () => unawaited(Navigator.of(context).maybePop()),
  );
}

/// Ends reorder mode for its level (ruling P2-L3).
class _ReorderDone extends ConsumerWidget {
  const _ReorderDone({required this.parentId});

  final String? parentId;

  void _finish(WidgetRef ref) =>
      ref.read(deckReorderModeProvider(parentId).notifier).finish();

  @override
  Widget build(BuildContext context, WidgetRef ref) => MxButton(
    label: context.l10n.libraryReorderDone,
    size: MxButtonSize.compact,
    onPressed: () => _finish(ref),
  );
}
