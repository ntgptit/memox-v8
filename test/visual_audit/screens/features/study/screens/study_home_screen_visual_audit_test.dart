import 'package:flutter/material.dart';
import 'package:memox/features/study/presentation/screens/study_home_screen.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

import '../../../../../support/card_fixtures.dart';
import '../../../../../support/deck_fixtures.dart';
import '../../../../../support/library_harness.dart';
import '../../../../../support/study_entry_fixtures.dart';
import '../../../../screen_audit.dart';

StudyHomeScreen _screen() => StudyHomeScreen(
  onOpenSession: (_) {},
  onOpenDeck: (_) {},
  onOpenLibrary: () {},
);

void main() {
  libraryTest('screen 13, Study Home loaded, with a deck that has no card', (
    tester,
    env,
  ) async {
    await openFiveDueReview(env.db, env.decks, libraryToday, StudyMode.recall);
    final spanish = await env.decks.root('Spanish');
    final leaf = await env.decks.sub(spanish.id, 'Leaf');
    await insertCard(env.db, id: 'es-1', deckId: leaf.id, back: 'uno');
    await env.decks.root('Empty');
    await auditProductionScreen(
      tester,
      screen: StudyHomeScreen,
      pump: (brightness, scale) async {
        await tester.pumpWidget(const SizedBox());
        await pumpLibraryScreen(
          tester,
          env,
          _screen(),
          brightness: brightness,
          textScale: scale,
        );
      },
    );
  });
}
