import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/features/card/presentation/states/card_selection_state.dart';

/// A deck of cards' breadcrumb: [child], gone while cards are selected, when
/// the app bar is the selection header (screen 07, A14).
class CardDeckBreadcrumbWidget extends ConsumerWidget {
  const CardDeckBreadcrumbWidget({
    super.key,
    required this.deckId,
    required this.child,
  });

  final String deckId;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelecting = ref.watch(cardSelectionProvider(deckId)).isNotEmpty;
    if (isSelecting) return const SizedBox.shrink();
    return child;
  }
}
