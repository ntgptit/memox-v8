import 'package:flutter/material.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_add_fab_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_deck_app_bar_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_deck_breadcrumb_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_section_widget.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_algorithm_screen.dart';
import 'package:memox/features/deck/presentation/screens/deck_level_screen.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';

// The Library's own screens, built for a test with navigation that goes
// nowhere. Apart from library_harness.dart so that a test which only needs
// the backend does not depend on these screens: diff-based test selection
// follows imports (build_verification_plan.py).

/// A deck level whose navigation goes nowhere, for screen tests: the Library
/// root when [deckId] is null.
DeckLevelScreen deckScreen({
  String? deckId,
  ValueChanged<String>? onOpenDeck,
  ValueChanged<String?>? onOpenAncestor,
  ValueChanged<String>? onAddCard,
  Widget Function(DeckView view)? cardContent,
  Widget Function(DeckView view, Widget back, Widget deckActions)? cardAppBar,
  Widget Function(String deckId, Widget breadcrumb)? cardBreadcrumb,
  Widget Function(String deckId)? cardFab,
  VoidCallback? onSearch,
  ValueChanged<String>? onOpenAlgorithm,
  ValueChanged<String>? onImportCards,
  ValueChanged<DeckEntity>? onExportCards,
  ValueChanged<String>? onSelectCards,
  ValueChanged<String>? onOpenStudy,
  ValueChanged<String>? onOpenStudyOptions,
  VoidCallback? onOpenTrash,
  VoidCallback? onOpenStarterDecks,
  VoidCallback? onOpenTags,
  VoidCallback? onOpenStudyHome,
}) => DeckLevelScreen(
  deckId: deckId,
  onOpenDeck: onOpenDeck ?? (_) {},
  onOpenAncestor: onOpenAncestor ?? (_) {},
  onSearch: onSearch ?? () {},
  onOpenAlgorithm: onOpenAlgorithm ?? (_) {},
  onOpenStudy: onOpenStudy ?? (_) {},
  onOpenStudyOptions: onOpenStudyOptions ?? (_) {},
  onAddCard: onAddCard ?? (_) {},
  onImportCards: onImportCards ?? (_) {},
  onExportCards: onExportCards ?? (_) {},
  onSelectCards: onSelectCards ?? (_) {},
  onOpenTrash: onOpenTrash ?? () {},
  onOpenStarterDecks: onOpenStarterDecks ?? () {},
  onOpenTags: onOpenTags ?? () {},
  onOpenStudyHome: onOpenStudyHome,
  cardContent: cardContent ?? (_) => const SizedBox.shrink(),
  cardAppBar:
      cardAppBar ??
      (view, back, actions) =>
          MxAppBar(title: view.deck.name, leading: back, actions: [actions]),
  cardBreadcrumb: cardBreadcrumb ?? (_, breadcrumb) => breadcrumb,
  cardFab: cardFab ?? (_) => const SizedBox.shrink(),
);

/// Screen 07: the open deck as `app/` composes it (A14). [onSelectCards]
/// is the router's: the test reaches the scope's container (DEV-307).
DeckLevelScreen cardDeckScreen(
  String deckId, {
  ValueChanged<String>? onSelectCards,
}) => deckScreen(
  deckId: deckId,
  onSelectCards: onSelectCards,
  cardContent: (view) => CardListSectionWidget(
    deckId: view.deck.id,
    algorithm: 'Eight boxes',
    onAddCard: () {},
    onOpenCard: (_) {},
    onExport: (_) {},
    onStudy: () {},
    onOpenTrash: () {},
  ),
  cardAppBar: (view, back, actions) =>
      CardDeckAppBarWidget(view: view, back: back, deckActions: actions),
  cardBreadcrumb: (id, child) =>
      CardDeckBreadcrumbWidget(deckId: id, child: child),
  cardFab: (id) => CardAddFabWidget(deckId: id, onAddCard: () {}),
);

/// Screen 02 for [deckId], with its breadcrumb callback.
DeckAlgorithmScreen deckAlgorithmScreen({
  required String deckId,
  ValueChanged<String?>? onOpenAncestor,
  VoidCallback? onOpenTrash,
}) => DeckAlgorithmScreen(
  deckId: deckId,
  onOpenAncestor: onOpenAncestor ?? (_) {},
  onOpenTrash: onOpenTrash ?? () {},
);
