import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_note.dart';

/// A deck that holds nothing yet (UC-DECK-004, kit 01 `deckEmpty`): what it
/// can take next, as buttons, and while both fit, the note on what the first
/// one decides (ruling P4a-L9).
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
    final onImportCards = this.onImportCards;
    final isOpen = onAddCard != null && onCreateSubDeck != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.gutter,
      children: [
        MxEmptyState(
          icon: AppIcons.folder,
          title: onAddCard == null
              ? l10n.deckRootEmptyTitle
              : l10n.deckUnsetTitle,
          body: switch ((onAddCard, onCreateSubDeck)) {
            (null, _) => l10n.deckRootEmptyBody,
            (_, null) => l10n.deckUnsetDeepestBody,
            _ => l10n.deckUnsetBody,
          },
        ),
        OverflowBar(
          alignment: MainAxisAlignment.center,
          spacing: AppSpacing.control,
          overflowSpacing: AppSpacing.control,
          overflowAlignment: OverflowBarAlignment.center,
          children: [
            if (onAddCard != null)
              MxButton(
                label: l10n.deckNewCard,
                icon: AppIcons.add,
                onPressed: onAddCard,
              ),
            if (onCreateSubDeck != null)
              MxButton(
                label: l10n.deckNewSubDeck,
                icon: AppIcons.library,
                tone: isOpen ? MxButtonTone.secondary : MxButtonTone.primary,
                onPressed: onCreateSubDeck,
              ),
            if (onImportCards != null)
              MxButton(
                label: l10n.deckUnsetImport,
                icon: AppIcons.fileUp,
                tone: MxButtonTone.outline,
                onPressed: onImportCards,
              ),
          ],
        ),
        if (isOpen) MxNote(text: l10n.deckUnsetNote),
      ],
    );
  }
}
