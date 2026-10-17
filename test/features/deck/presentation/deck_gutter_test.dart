import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/theme_rules.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/features/deck/presentation/providers/deck_view_provider.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/deck_screen_harness.dart';

// M3F-19: the Library's search field and the card pages' loading header sit
// on the screen margin, as the app bar and the breadcrumb they stand beside.

void main() {
  for (final (width, margin) in [(360.0, 16.0), (700.0, 24.0)]) {
    libraryTest('the Library search field starts and ends on the $margin '
        'screen margin at ${width.toInt()} wide', (tester, env) async {
      await env.decks.root('Korean');
      await pumpLibraryScreen(
        tester,
        env,
        WindowWidthScope(width: width, child: deckScreen()),
      );

      final field = tester.getRect(find.byType(MxSearchField));
      expect(field.left, margin);
      expect(360 - field.right, margin);
    });

    libraryTest('the loading header starts on the $margin screen margin at '
        '${width.toInt()} wide', (tester, env) async {
      final pending = StreamController<Outcome<DeckView, DeckRejection>>();
      addTearDown(pending.close);
      await pumpLibraryScreen(
        tester,
        env,
        WindowWidthScope(
          width: width,
          child: const Scaffold(
            body: DeckContextHeaderWidget(deckId: 'words', currentLabel: 'New'),
          ),
        ),
        overrides: [
          deckViewProvider('words').overrideWith((ref) => pending.stream),
        ],
      );

      expect(tester.getTopLeft(find.byType(MxSkeleton)).dx, margin);
    });
  }
}
