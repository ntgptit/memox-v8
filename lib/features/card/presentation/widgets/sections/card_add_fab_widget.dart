import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/card/presentation/states/card_selection_state.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_fab.dart';

/// New card on a deck of cards (kit 07). It gives way to the bulk bar while
/// cards are selected (ruling P4a-L9).
class CardAddFabWidget extends ConsumerWidget {
  const CardAddFabWidget({
    super.key,
    required this.deckId,
    required this.onAddCard,
  });

  final String deckId;
  final VoidCallback onAddCard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(cardSelectionProvider(deckId)).isNotEmpty) {
      return const SizedBox.shrink();
    }
    return MxFab(
      icon: AppIcons.add,
      semanticLabel: context.l10n.cardNewCard,
      onPressed: onAddCard,
    );
  }
}
