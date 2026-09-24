import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';

/// A deck that holds nothing yet (UC-DECK-004). Ruling P2-L1: it offers a
/// sub-deck now, and a card once the editor arrives in phase 4.
class DeckUnsetStateWidget extends StatelessWidget {
  const DeckUnsetStateWidget({super.key, required this.onCreateSubDeck});

  /// Null at the deepest level, where no sub-deck fits (BR-DECK-001).
  final VoidCallback? onCreateSubDeck;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canNest = onCreateSubDeck != null;
    return MxEmptyState(
      icon: AppIcons.folder,
      title: l10n.deckUnsetTitle,
      body: canNest ? l10n.deckUnsetBody : l10n.deckUnsetDeepestBody,
      actionLabel: canNest ? l10n.deckCreateSub : null,
      onAction: onCreateSubDeck,
    );
  }
}
