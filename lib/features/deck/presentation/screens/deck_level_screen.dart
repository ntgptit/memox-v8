import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/deck/presentation/providers/deck_level_provider.dart';
import 'package:memox/features/deck/presentation/states/deck_level_query_state.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/create_root_deck_dialog_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_level_list_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// The Library root: the roots with today's work first (UC-DECK-003). Phase
/// 2 turns it into the recursive deck screen (ruling L1).
class DeckLevelScreen extends ConsumerWidget {
  const DeckLevelScreen({super.key});

  static const int _skeletonRows = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final query = ref.watch(deckLevelQueryProvider(null));
    final provider = deckLevelProvider(sort: query.sort, filter: query.filter);
    void createDeck() => unawaited(showCreateRootDeckDialog(context));
    return MxAppShell(
      appBar: MxAppBar(title: l10n.navLibrary),
      fab: MxFab(
        icon: AppIcons.add,
        semanticLabel: l10n.libraryCreateDeck,
        onPressed: createDeck,
      ),
      body: ref
          .watch(provider)
          .when(
            data: (level) =>
                DeckLevelListWidget(level: level, onCreateDeck: createDeck),
            loading: () => MxScreenScroll(
              clearance: MxScrollClearance.fabAboveNav,
              children: [
                for (var i = 0; i < _skeletonRows; i++) const MxSkeletonRow(),
              ],
            ),
            error: (_, _) => MxScreenScroll(
              clearance: MxScrollClearance.fabAboveNav,
              children: [
                MxErrorState(
                  title: l10n.libraryLoadErrorTitle,
                  body: l10n.libraryLoadErrorBody,
                  retryLabel: l10n.commonRetry,
                  onRetry: () => ref.invalidate(provider),
                ),
              ],
            ),
          ),
    );
  }
}
