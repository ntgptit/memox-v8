import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/progress/presentation/providers/deck_progress_provider.dart';
import 'package:memox/features/progress/presentation/screens/deck_progress_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/progress_screen_fixtures.dart';

// Screen 22 at a deck's level: UC-PROGRESS-002 (steps 1, 5; A1; E1; E2),
// FE-A9 D2, D5.

final _en = lookupAppLocalizations(const Locale('en'));

final class _Taps {
  final decks = <String>[];
  final ancestors = <String?>[];
}

DeckProgressScreen _screen(String deckId, _Taps taps) => DeckProgressScreen(
  deckId: deckId,
  onOpenDeck: taps.decks.add,
  onOpenAncestor: taps.ancestors.add,
);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  libraryTest("the deck's path, its whole-deck total and a row per child; a "
      'row opens the child, a segment its level (steps 1, 5; D2)', (
    tester,
    env,
  ) async {
    final taps = _Taps();
    final korean = await studiedDeck(
      env,
      'Korean',
      days: [(daysAgo: 0, learning: 1, reviewing: 2)],
    );
    final grammar = await env.decks.sub(korean, 'Grammar');
    await pumpLibraryScreen(tester, env, _screen(korean, taps));
    await _settle(tester);

    expect(find.text(_en.progressToday.toUpperCase()), findsNothing);
    final whole = find.widgetWithText(MxListRow, _en.progressWholeDeck);
    expect(
      find.descendant(
        of: whole,
        matching: find.text(_en.progressRowCardsDays(3, 1)),
      ),
      findsOneWidget,
    );
    // A child opens its level; the total does not (critique 2026-09-30 part
    // 3d-1, D3; Review Focus 4).
    expect(
      find.descendant(of: whole, matching: find.byIcon(AppIcons.chevronRight)),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.widgetWithText(MxListRow, 'Grammar'),
        matching: find.byIcon(AppIcons.chevronRight),
      ),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(MxListRow, 'Grammar'));
    await tester.tap(
      find.descendant(
        of: find.byType(MxBreadcrumb),
        matching: find.text(_en.progressTitle),
      ),
    );

    expect(taps.decks, [grammar.id]);
    expect(taps.ancestors, [null]);
  });

  libraryTest('a deck with no children keeps its total and says it is all of '
      'it (A1)', (tester, env) async {
    final root = await env.decks.root('Korean');
    final words = await env.decks.sub(root.id, 'Words');
    await pumpLibraryScreen(tester, env, _screen(words.id, _Taps()));
    await _settle(tester);

    expect(find.text(_en.progressWholeDeck), findsOneWidget);
    expect(find.text(_en.progressLeafNote), findsOneWidget);
  });

  libraryTest('a deck gone to the Trash offers Back only, no Retry (E2)', (
    tester,
    env,
  ) async {
    final root = await env.decks.root('Korean');
    await env.decks.deleteDeck(deckId: root.id);
    await pumpLibraryScreen(tester, env, _screen(root.id, _Taps()));
    await _settle(tester);

    expect(
      find.widgetWithText(MxEmptyState, _en.deckGoneTitle),
      findsOneWidget,
    );
    expect(find.text(_en.commonBack), findsOneWidget);
    expect(find.text(_en.commonRetry), findsNothing);
  });

  libraryTest('a deck moved to the Trash while its level is open turns into '
      'the gone state, with no error in between (E2, BR-PROGRESS-008)', (
    tester,
    env,
  ) async {
    final korean = await studiedDeck(
      env,
      'Korean',
      days: [(daysAgo: 0, learning: 0, reviewing: 2)],
    );
    await pumpLibraryScreen(tester, env, _screen(korean, _Taps()));
    await _settle(tester);
    expect(find.text(_en.progressWholeDeck), findsOneWidget);

    await env.decks.deleteDeck(deckId: korean);
    await tester.pump();
    expect(find.text(_en.progressErrorTitle), findsNothing);
    await _settle(tester);

    expect(
      find.widgetWithText(MxEmptyState, _en.deckGoneTitle),
      findsOneWidget,
    );
    expect(find.text(_en.progressWholeDeck), findsNothing);
    expect(find.text(_en.commonRetry), findsNothing);
  });

  libraryTest('a failed read shows the error with Retry (E1)', (
    tester,
    env,
  ) async {
    var reads = 0;
    await pumpLibraryScreen(
      tester,
      env,
      _screen('any', _Taps()),
      overrides: [
        deckProgressProvider('any').overrideWith((ref) {
          reads++;
          return Stream<DeckProgress>.error(StateError('read failed'));
        }),
      ],
    );
    await _settle(tester);
    await tester.tap(find.text(_en.commonRetry));
    await _settle(tester);

    expect(find.text(_en.progressErrorTitle), findsOneWidget);
    expect(reads, 2);
  });

  libraryTest('while a Retry reloads, the error stays and its Retry spins', (
    tester,
    env,
  ) async {
    var reads = 0;
    final pending = StreamController<DeckProgress>();
    addTearDown(pending.close);
    await pumpLibraryScreen(
      tester,
      env,
      _screen('any', _Taps()),
      overrides: [
        deckProgressProvider('any').overrideWith((ref) {
          reads++;
          return reads == 1
              ? Stream<DeckProgress>.error(StateError('read failed'))
              : pending.stream;
        }),
      ],
    );
    await _settle(tester);
    await tester.tap(find.text(_en.commonRetry));
    await _settle(tester);

    expect(find.text(_en.progressErrorTitle), findsOneWidget);
    expect(tester.widget<MxButton>(find.byType(MxButton)).isLoading, isTrue);
  });

  libraryTest('a failed read says what failed, by the kind of failure, '
      'without its cause (UC-PROGRESS-002 E1, BR-CORE-005)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      _screen('any', _Taps()),
      overrides: [
        deckProgressProvider('any').overrideWith(
          (ref) => Stream<DeckProgress>.error(
            const DatabaseLockedFailure(cause: '/data/memox.sqlite'),
          ),
        ),
      ],
    );
    await _settle(tester);

    expect(find.text(_en.progressErrorTitle), findsOneWidget);
    expect(find.text(_en.failureBusy), findsOneWidget);
    expect(find.textContaining('/data/'), findsNothing);
  });
}
