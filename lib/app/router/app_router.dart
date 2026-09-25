import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/gallery/gallery_screen.dart';
import 'package:memox/app/placeholder_screen.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/card/presentation/screens/card_detail_screen.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_add_fab_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_deck_app_bar_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_deck_breadcrumb_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_section_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_history_labels_widget.dart';
import 'package:memox/features/deck/presentation/screens/deck_algorithm_screen.dart';
import 'package:memox/features/deck/presentation/screens/deck_level_screen.dart';
import 'package:memox/features/deck/presentation/screens/deck_search_screen.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';

/// The app's routes: four top-level branches in a stateful shell, each
/// keeping its own stack, plus the component gallery when [hasGallery]
/// (debug builds by default, so release builds never register it).
GoRouter buildAppRouter({bool hasGallery = kDebugMode}) => GoRouter(
  initialLocation: AppRoutes.decks,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _TabShell(navigationShell: navigationShell),
      branches: [
        // The Library (library spec §4): one page per deck level.
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.decks,
              builder: (context, state) => _deckLevel(context),
              routes: [
                GoRoute(
                  path: AppRoutes.deckChild,
                  builder: (context, state) => _deckLevel(
                    context,
                    deckId: state.pathParameters[AppRoutes.deckIdParam],
                  ),
                  routes: [
                    GoRoute(
                      path: AppRoutes.cardNewChild,
                      builder: (context, state) => CardEditorScreen.create(
                        deckId: state.pathParameters[AppRoutes.deckIdParam]!,
                        deckContext: _deckContext,
                      ),
                    ),
                    GoRoute(
                      path: AppRoutes.algorithmChild,
                      builder: (context, state) => DeckAlgorithmScreen(
                        deckId: state.pathParameters[AppRoutes.deckIdParam]!,
                        onOpenAncestor: (id) => _openAncestor(context, id),
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: AppRoutes.searchChild,
                  builder: (context, state) => DeckSearchScreen(
                    onOpenDeck: (id) => context.push(AppRoutes.deck(id)),
                  ),
                ),
                GoRoute(
                  path: AppRoutes.cardChild,
                  builder: (context, state) => CardDetailScreen(
                    cardId: state.pathParameters[AppRoutes.cardIdParam]!,
                    deckContext: _deckContext,
                    onEdit: (id) =>
                        unawaited(context.push(AppRoutes.editCard(id))),
                  ),
                  routes: [
                    GoRoute(
                      path: AppRoutes.cardEditChild,
                      builder: (context, state) => CardEditorScreen.edit(
                        cardId: state.pathParameters[AppRoutes.cardIdParam]!,
                        deckContext: _deckContext,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        _branch(AppRoutes.study, (context) => context.l10n.navStudy),
        _branch(AppRoutes.progress, (context) => context.l10n.navProgress),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) => PlaceholderScreen(
                title: context.l10n.navSettings,
                onOpenGallery: hasGallery
                    ? () => context.push(AppRoutes.gallery)
                    : null,
              ),
            ),
          ],
        ),
      ],
    ),
    if (hasGallery)
      GoRoute(
        path: AppRoutes.gallery,
        builder: (context, state) => const GalleryScreen(),
      ),
  ],
);

/// A Library level wired to the router: each deck opened is one more page,
/// so Back climbs one level (library spec §4).
DeckLevelScreen _deckLevel(BuildContext context, {String? deckId}) {
  void addCard(String id) => unawaited(context.push(AppRoutes.newCard(id)));
  return DeckLevelScreen(
    deckId: deckId,
    onOpenDeck: (id) => context.push(AppRoutes.deck(id)),
    onOpenAncestor: (id) => _openAncestor(context, id),
    onSearch: () => context.push(AppRoutes.deckSearch),
    onOpenAlgorithm: (id) =>
        unawaited(context.push(AppRoutes.deckAlgorithm(id))),
    onAddCard: addCard,
    cardAppBar: (view, back, actions) =>
        CardDeckAppBarWidget(view: view, back: back, deckActions: actions),
    cardBreadcrumb: (id, child) =>
        CardDeckBreadcrumbWidget(deckId: id, child: child),
    cardContent: (view) => CardListSectionWidget(
      deckId: view.deck.id,
      algorithm: context.l10n.cardScheduler(view.schedulerType),
      onAddCard: () => addCard(view.deck.id),
      onOpenCard: (cardId) => unawaited(context.push(AppRoutes.card(cardId))),
    ),
    cardFab: (id) => CardAddFabWidget(deckId: id, onAddCard: () => addCard(id)),
  );
}

/// The deck path over the card editor (ruling P4a-L7, spec D8).
Widget _deckContext(String deckId, String currentLabel) =>
    DeckContextHeaderWidget(deckId: deckId, currentLabel: currentLabel);

/// Ruling P2-L5: a breadcrumb tap pops the Library stack back to [deckId],
/// or to the root for null. A deck that is not on the stack (it was opened
/// from search) is pushed over the root instead.
void _openAncestor(BuildContext context, String? deckId) {
  final router = GoRouter.of(context);
  var isOnStack = false;
  Navigator.of(context).popUntil((route) {
    final arguments = route.settings.arguments;
    isOnStack =
        deckId != null &&
        arguments is Map &&
        arguments[AppRoutes.deckIdParam] == deckId;
    return isOnStack || route.isFirst;
  });
  if (deckId == null || isOnStack) return;
  unawaited(router.push(AppRoutes.deck(deckId)));
}

StatefulShellBranch _branch(String path, String Function(BuildContext) title) =>
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: path,
          builder: (context, state) => PlaceholderScreen(title: title(context)),
        ),
      ],
    );

/// The bottom nav around the current branch.
class _TabShell extends StatelessWidget {
  const _TabShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxAppShell(
      body: navigationShell,
      bottomBar: MxBottomNav(
        destinations: [
          MxNavDestination(
            icon: AppIcons.library,
            selectedIcon: AppIcons.librarySelected,
            label: l10n.navLibrary,
          ),
          MxNavDestination(
            icon: AppIcons.study,
            selectedIcon: AppIcons.studySelected,
            label: l10n.navStudy,
          ),
          MxNavDestination(
            icon: AppIcons.progress,
            selectedIcon: AppIcons.progressSelected,
            label: l10n.navProgress,
          ),
          MxNavDestination(
            icon: AppIcons.settings,
            selectedIcon: AppIcons.settingsSelected,
            label: l10n.navSettings,
          ),
        ],
        selectedIndex: navigationShell.currentIndex,
        // Re-tapping the current tab returns its branch to its root.
        onSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
