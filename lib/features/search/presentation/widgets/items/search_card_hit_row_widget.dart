import 'package:flutter/widgets.dart';
import 'package:memox/core/text/path_label.dart';
import 'package:memox/core/text/search_match.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/search/domain/models/search_hit_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';

/// A card found by the search (screen 04): "front · back" with the match
/// marked in the face that holds it, the tag that found it when neither
/// face does, and its deck path (UC-SEARCH-001 step 5; spec D12, D20–D22).
class SearchCardHitRowWidget extends StatelessWidget {
  const SearchCardHitRowWidget({
    super.key,
    required this.hit,
    required this.term,
    required this.onTap,
    required this.hasDivider,
  });

  final SearchCardHit hit;
  final String term;
  final VoidCallback onTap;
  final bool hasDivider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final path = pathLabel([for (final entry in hit.deckPath) entry.name]);
    final tag = hit.matchedTag;
    // The title can clip a back-face match on a long front (spec D22), so
    // one node says the whole card and why it was found.
    return Semantics(
      label: tag == null
          ? l10n.searchCardRowLabel(hit.front, hit.back, path)
          : l10n.searchCardRowTagLabel(hit.front, hit.back, tag, path),
      button: true,
      excludeSemantics: true,
      onTap: onTap,
      child: MxListRow(
        title: searchPairTitle(hit.front, hit.back),
        titleMatch: searchPairMatch(hit.front, hit.back, term),
        // Always the meta slot, so tag rows and plain rows are one style
        // and one height (spec D21).
        meta: Row(
          spacing: AppSpacing.micro,
          children: [
            if (tag != null) MxTagChip(label: tag, isDense: true),
            Flexible(
              child: Text(
                path,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.rowSubtitle,
              ),
            ),
          ],
        ),
        leading: const MxIconTile(icon: AppIcons.cardDeck),
        hasChevron: true,
        onTap: onTap,
        hasDivider: hasDivider,
      ),
    );
  }
}
