import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';

/// A deck that holds nothing yet (UC-DECK-004, kit 01 `deckEmpty`): what it
/// can take next, as the empty state's block actions (ruling M3-D5), and
/// while both fit, the note on what the first one decides (ruling P4a-L9).
class DeckUnsetStateWidget extends StatelessWidget {
  const DeckUnsetStateWidget({
    super.key,
    required this.onAddCard,
    required this.onCreateSubDeck,
    this.onImportCards,
  });

  /// Null for a top-level deck, which holds sub-decks only (BR-DECK-005).
  final VoidCallback? onAddCard;

  /// Null at the deepest level, where no sub-deck fits (BR-DECK-001).
  final VoidCallback? onCreateSubDeck;

  /// The third way to fill the deck: cards from a file (UC-TRANSFER-001).
  /// Null where no card fits.
  final VoidCallback? onImportCards;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final onAddCard = this.onAddCard;
    final onCreateSubDeck = this.onCreateSubDeck;
    final isOpen = onAddCard != null && onCreateSubDeck != null;
    // The first way in leads; a sub-deck is second only when a card also
    // fits (ruling P4a-L9).
    final (String? leadLabel, VoidCallback? onLead) = switch (onAddCard) {
      final onAdd? => (l10n.deckNewCard, onAdd),
      null => (
        onCreateSubDeck == null ? null : l10n.deckNewSubDeck,
        onCreateSubDeck,
      ),
    };
    return MxEmptyState(
      icon: AppIcons.folder,
      title: onAddCard == null ? l10n.deckRootEmptyTitle : l10n.deckUnsetTitle,
      body: switch ((onAddCard, onCreateSubDeck)) {
        (null, _) => l10n.deckRootEmptyBody,
        (_, null) => l10n.deckUnsetDeepestBody,
        _ => l10n.deckUnsetBody,
      },
      actionLabel: leadLabel,
      onAction: onLead,
      secondaryActionLabel: isOpen ? l10n.deckNewSubDeck : null,
      onSecondaryAction: isOpen ? onCreateSubDeck : null,
      tertiaryActionLabel: onImportCards == null ? null : l10n.deckUnsetImport,
      onTertiaryAction: onImportCards,
      footnote: isOpen ? l10n.deckUnsetNote : null,
    );
  }
}
