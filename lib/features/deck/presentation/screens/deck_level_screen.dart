import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_create_option_model.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/features/deck/presentation/providers/deck_view_provider.dart';
import 'package:memox/features/deck/presentation/states/deck_reorder_mode_state.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_name_dialog_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_gone_state_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_level_body_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_library_root_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_unset_state_widget.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_actions_flow_widget.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_reorder_done_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

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
    required this.onOpenAlgorithm,
    required this.onOpenStudy,
    required this.cardContent,
    required this.cardAppBar,
    required this.cardBreadcrumb,
    required this.onAddCard,
    required this.cardFab,
  });

  final String? deckId;
  final ValueChanged<String> onOpenDeck;

  /// A breadcrumb tap: a deck above this one, or null for the Library root.
  final ValueChanged<String?> onOpenAncestor;
  final VoidCallback onSearch;

  /// A root's review algorithm: the router opens screen 02.
  final ValueChanged<String> onOpenAlgorithm;

  /// A deck's Study Entry (screen 14), from an action sheet or a summary.
  final ValueChanged<String> onOpenStudy;

  /// What a deck of cards shows. The router passes the card feature's list
  /// section; `deck` never imports `card` (spec D8).
  final Widget Function(DeckView view) cardContent;

  /// A deck of cards' app bar, given the deck screen's Back and the deck's
  /// actions button: the card feature's, which turns into the selection
  /// header while cards are selected (A14).
  final Widget Function(DeckView view, Widget back, Widget deckActions)
  cardAppBar;

  /// A deck of cards' breadcrumb, given the deck's: the card feature hides
  /// it while cards are selected.
  final Widget Function(String deckId, Widget breadcrumb) cardBreadcrumb;

  /// New card for [deckId]: the router opens the card editor.
  final ValueChanged<String> onAddCard;

  /// A deck of cards' FAB, from the card feature like [cardContent] (spec
  /// D8). It hides itself while cards are selected.
  final Widget Function(String deckId) cardFab;

  @override
  Widget build(BuildContext context) => switch (deckId) {
    null => DeckLibraryRootWidget(
      onOpenDeck: onOpenDeck,
      onSearch: onSearch,
      onOpenAlgorithm: onOpenAlgorithm,
      onOpenStudy: onOpenStudy,
    ),
    final id => _OpenDeck(
      deckId: id,
      onOpenDeck: onOpenDeck,
      onOpenAncestor: onOpenAncestor,
      onOpenAlgorithm: onOpenAlgorithm,
      onOpenStudy: onOpenStudy,
      cardContent: cardContent,
      cardAppBar: cardAppBar,
      cardBreadcrumb: cardBreadcrumb,
      onAddCard: onAddCard,
      cardFab: cardFab,
    ),
  };
}

/// An open deck while its stream loads, fails or is gone.
class _OpenDeck extends ConsumerWidget {
  const _OpenDeck({
    required this.deckId,
    required this.onOpenDeck,
    required this.onOpenAncestor,
    required this.onOpenAlgorithm,
    required this.onOpenStudy,
    required this.cardContent,
    required this.cardAppBar,
    required this.cardBreadcrumb,
    required this.onAddCard,
    required this.cardFab,
  });

  final String deckId;
  final ValueChanged<String> onOpenDeck;
  final ValueChanged<String?> onOpenAncestor;
  final ValueChanged<String> onOpenAlgorithm;

  /// A deck's Study Entry (screen 14), from an action sheet or a summary.
  final ValueChanged<String> onOpenStudy;
  final Widget Function(DeckView view) cardContent;
  final Widget Function(DeckView view, Widget back, Widget deckActions)
  cardAppBar;
  final Widget Function(String deckId, Widget breadcrumb) cardBreadcrumb;
  final ValueChanged<String> onAddCard;
  final Widget Function(String deckId) cardFab;

  static const int _skeletonRows = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = deckViewProvider(deckId);
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
        onOpenAlgorithm: onOpenAlgorithm,
        onOpenStudy: onOpenStudy,
        cardContent: cardContent,
        cardAppBar: cardAppBar,
        cardBreadcrumb: cardBreadcrumb,
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
      // Spec A8: deleted while open. Say so; the way back is the Library.
      AsyncData(value: Rejected()) => MxAppShell(
        appBar: bar,
        body: DeckGoneStateWidget(onBackToLibrary: () => onOpenAncestor(null)),
      ),
      _ => MxAppShell(
        appBar: bar,
        body: MxScreenScroll(
          children: [
            MxSkeletonList(
              semanticLabel: context.l10n.commonLoading,
              rows: _skeletonRows,
            ),
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
    required this.onOpenAlgorithm,
    required this.onOpenStudy,
    required this.cardContent,
    required this.cardAppBar,
    required this.cardBreadcrumb,
    required this.onAddCard,
    required this.cardFab,
  });

  final DeckView view;
  final ValueChanged<String> onOpenDeck;
  final ValueChanged<String?> onOpenAncestor;
  final ValueChanged<String> onOpenAlgorithm;

  /// A deck's Study Entry (screen 14), from an action sheet or a summary.
  final ValueChanged<String> onOpenStudy;
  final Widget Function(DeckView view) cardContent;
  final Widget Function(DeckView view, Widget back, Widget deckActions)
  cardAppBar;
  final Widget Function(String deckId, Widget breadcrumb) cardBreadcrumb;
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
    final deckActions = MxIconButton(
      icon: AppIcons.more,
      semanticLabel: l10n.deckActions,
      onPressed: () => unawaited(
        openDeckActions(
          context,
          ref,
          deckId: deck.id,
          parentId: deck.parentId,
          onOpenDeck: onOpenDeck,
          onOpenAlgorithm: onOpenAlgorithm,
          onOpenStudy: onOpenStudy,
          isOpenDeck: true,
        ),
      ),
    );
    // Ruling P2-L4: Library > ancestors > this deck.
    final breadcrumb = MxBreadcrumb(
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
    );
    final isCardDeck = deck.contentType == DeckContentType.card;
    return MxAppShell(
      appBar: isCardDeck
          ? cardAppBar(view, const _BackButton(), deckActions)
          : MxAppBar(
              title: deck.name,
              density: MxAppBarDensity.content,
              leading: const _BackButton(),
              actions: isReordering
                  ? [DeckReorderDoneWidget(parentId: deck.id)]
                  : [deckActions],
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
          if (isCardDeck) cardBreadcrumb(deck.id, breadcrumb) else breadcrumb,
          Expanded(
            child: switch (deck.contentType) {
              DeckContentType.card => cardContent(view),
              DeckContentType.deck ||
              DeckContentType.unset => DeckLevelBodyWidget(
                parentId: deck.id,
                onOpenDeck: onOpenDeck,
                onOpenAlgorithm: onOpenAlgorithm,
                onOpenStudy: onOpenStudy,
                schedulerType: view.schedulerType,
                // Owner decision C-O6: its sub-decks are at level 10.
                hasDeepestSubDecks: deck.depth == DeckEntity.maxDepth - 1,
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
