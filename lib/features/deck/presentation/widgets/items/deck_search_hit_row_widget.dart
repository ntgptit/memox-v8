import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_search_hit_model.dart';
import 'package:memox/core/text/path_label.dart';
import 'package:memox/core/text/search_match.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

/// One deck found by the search (screen 04): its tile, its name with the
/// match marked (owner decision C-O7), where it sits and what it holds.
class DeckSearchHitRowWidget extends StatelessWidget {
  const DeckSearchHitRowWidget({
    super.key,
    required this.hit,
    required this.term,
    required this.onTap,
    required this.hasDivider,
  });

  final DeckSearchHit hit;
  final String term;
  final VoidCallback onTap;
  final bool hasDivider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final path = hit.path.isEmpty
        ? l10n.navLibrary
        : pathLabel([for (final entry in hit.path) entry.name]);
    return MxListRow(
      title: hit.name,
      titleMatch: searchMatchRange(hit.name, term),
      subtitle: switch (hit.contentType) {
        DeckContentType.card => l10n.searchHoldsCards(path),
        DeckContentType.deck => l10n.searchHoldsDecks(path),
        DeckContentType.unset => l10n.searchHoldsNothing(path),
      },
      leading: MxIconTile(
        icon: switch (hit.contentType) {
          DeckContentType.card => AppIcons.cardDeck,
          DeckContentType.deck => AppIcons.library,
          DeckContentType.unset => AppIcons.folder,
        },
      ),
      hasChevron: true,
      onTap: onTap,
      hasDivider: hasDivider,
    );
  }
}
