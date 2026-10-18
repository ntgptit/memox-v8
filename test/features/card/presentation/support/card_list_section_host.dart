import 'package:flutter/material.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_section_widget.dart';

/// The card list section of [deckId], wired without the Export command.
Widget cardListSection(String deckId) => Scaffold(
  body: CardListSectionWidget(
    deckId: deckId,
    algorithm: 'Eight boxes',
    onAddCard: () {},
    onOpenCard: (_) {},
  ),
);

/// The card list section of [deckId] as the router wires it: the bulk bar
/// holds its five commands.
Widget cardListSectionWithExport(String deckId) => Scaffold(
  body: CardListSectionWidget(
    deckId: deckId,
    algorithm: 'Eight boxes',
    onAddCard: () {},
    onOpenCard: (_) {},
    onExport: (_) {},
  ),
);
