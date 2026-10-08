import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/domain/models/deck_level_query_model.dart';
import 'package:memox/features/deck/presentation/providers/deck_level_provider.dart';
import 'package:memox/features/deck/presentation/providers/delete_deck_use_case_provider.dart';
import 'package:memox/features/deck/presentation/screens/deck_level_screen.dart';
import 'package:memox/features/deck/presentation/states/deck_level_query_state.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_reorder_done_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));
final _vi = lookupAppLocalizations(const Locale('vi'));

final _root = deckLevelProvider(
  parentId: null,
  sort: DeckLevelSort.manual,
  filter: DeckLevelFilter.all,
);

/// The app bar's action labels, in order.
List<String> _actions(WidgetTester tester) => [
  for (final button in tester.widgetList<MxIconButton>(
    find.descendant(
      of: find.byType(MxAppBar),
      matching: find.byType(MxIconButton),
    ),
  ))
    button.semanticLabel,
];

/// Two roots, enough for reorder mode.
Future<void> _seed(LibraryEnv env) async {
  await env.decks.root('Korean');
  await env.decks.root('Kanji');
}

/// The empty Library and its chrome (screen 01, The Content Gate Rule,
/// DEV-309): what a first run offers, what the first deck brings in, and
/// what losing the last deck takes away.
void main() {
  libraryTest('first run: an empty Library offers to create a deck', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, deckScreen());

    expect(find.text(_en.libraryEmptyTitle), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(MxEmptyState),
        matching: find.text(_en.libraryCreateDeck),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsOneWidget);
  });

  libraryTest('rootEmpty offers a starter deck beside Create deck (spec '
      '§5.4)', (tester, env) async {
    var starters = 0;
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(onOpenStarterDecks: () => starters++),
    );

    expect(find.text(_en.libraryEmptyBody), findsOneWidget);
    expect(
      [
        for (final button in tester.widgetList<MxButton>(find.byType(MxButton)))
          (button.label, button.tone),
      ],
      [
        (_en.libraryCreateDeck, MxButtonTone.primary),
        (_en.libraryBrowseStarterDecks, MxButtonTone.secondary),
      ],
    );
    expect(find.text(_en.libraryEmptyFootnote), findsOneWidget);
    await tester.tap(find.text(_en.libraryBrowseStarterDecks));
    expect(starters, 1);
  });

  libraryTest('the FAB waits for a first deck; the empty state offers it', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, deckScreen());
    expect(find.byType(MxFab), findsNothing);

    await env.decks.root('Korean');
    await tester.pumpAndSettle();
    expect(find.byType(MxFab), findsOneWidget);
  });

  libraryTest('scenario A: a first run shows Starter decks and the Trash, '
      'no Tags, no search, no FAB (The Content Gate)', (tester, env) async {
    await pumpLibraryScreen(tester, env, deckScreen());

    expect(
      [
        for (final button in tester.widgetList<MxIconButton>(
          find.descendant(
            of: find.byType(MxAppBar),
            matching: find.byType(MxIconButton),
          ),
        ))
          button.semanticLabel,
      ],
      [_en.libraryStarterDecks, _en.libraryTrash],
    );
    expect(find.text(_en.searchFieldHint), findsNothing);
    expect(find.byType(MxFab), findsNothing);
    expect(find.text(_en.libraryEmptyTitle), findsOneWidget);
  });

  libraryTest('scenario C: the first deck brings the search field, Tags and '
      'the FAB in the same frame as its row', (tester, env) async {
    await pumpLibraryScreen(tester, env, deckScreen());
    expect(find.byTooltip(_en.libraryTags), findsNothing);

    await env.decks.root('Korean');
    await tester.pumpAndSettle();

    expect(find.text('Korean'), findsOneWidget);
    expect(find.text(_en.searchFieldHint), findsOneWidget);
    expect(find.byTooltip(_en.libraryTags), findsOneWidget);
    expect(find.byType(MxFab), findsOneWidget);
  });

  libraryTest('reorder keeps its chrome: Done replaces the actions, no search '
      'field, no FAB (critique 2026-09-30 part 3d-2)', (tester, env) async {
    await _seed(env);
    await pumpLibraryScreen(tester, env, deckScreen());
    await tester.tap(find.byTooltip(_en.deckMoreActions('Korean')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.deckReorder));
    await tester.pumpAndSettle();

    expect(find.byType(DeckReorderDoneWidget), findsOneWidget);
    expect(find.byTooltip(_en.libraryTags), findsNothing);
    expect(find.text(_en.searchFieldHint), findsNothing);
    expect(find.byType(MxFab), findsNothing);
  });

  libraryTest(
    'scenario B: the last deck goes to the Trash; the same frame drops the '
    'search field, Tags and the FAB and keeps the Trash and Undo',
    (tester, env) async {
      await env.decks.root('Korean');
      await pumpLibraryScreen(tester, env, deckScreen());
      expect(find.byTooltip(_en.libraryTags), findsOneWidget);

      await tester.tap(find.byTooltip(_en.deckMoreActions('Korean')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_en.deckDelete));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_en.trashMoveConfirm));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(_en.libraryEmptyTitle), findsOneWidget);
      expect(find.text(_en.searchFieldHint), findsNothing);
      expect(find.byTooltip(_en.libraryTags), findsNothing);
      expect(find.byType(MxFab), findsNothing);
      expect(find.byTooltip(_en.libraryTrash), findsOneWidget);
      expect(find.text(_en.commonUndo), findsOneWidget);
    },
  );

  libraryTest('the empty state reads as an action, in both languages (R4)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, deckScreen());
    expect(
      find.text(
        'Organize your cards into decks. Create your own or start with a '
        'ready-made collection.',
      ),
      findsOneWidget,
    );
    expect(
      _vi.libraryEmptyBody,
      'Sắp xếp thẻ thành bộ thẻ. Tạo bộ của riêng bạn hoặc bắt đầu với một '
      'bộ mẫu có sẵn.',
    );
  });

  libraryTest('the last deck under "Due only" leaves the first-run empty '
      'state, not "Nothing due" (Review Focus 1)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, deckScreen());
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DeckLevelScreen)),
    );
    container
        .read(deckLevelQueryProvider(null).notifier)
        .show(DeckLevelFilter.due);
    await tester.pumpAndSettle();
    expect(find.text(_en.libraryNothingDueTitle), findsOneWidget);

    await container.read(deleteDeckUseCaseProvider)(deckId: korean.id);
    await tester.pumpAndSettle();

    expect(find.text(_en.libraryEmptyTitle), findsOneWidget);
    expect(find.text(_en.libraryNothingDueTitle), findsNothing);
    expect(find.text(_en.searchFieldHint), findsNothing);
    expect(find.byTooltip(_en.libraryTags), findsNothing);
    expect(find.byType(MxFab), findsNothing);
  });

  libraryTest('a failed root keeps only Starter decks and the Trash over '
      'Retry (Review Focus 3)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(),
      overrides: [
        _root.overrideWith(
          (ref) => Stream<DeckLevel>.error(
            UnknownDatabaseFailure(cause: StateError('read failed')),
          ),
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(_actions(tester), [_en.libraryStarterDecks, _en.libraryTrash]);
    expect(find.text(_en.searchFieldHint), findsNothing);
    expect(find.byType(MxFab), findsNothing);
  });

  libraryTest('a loading root keeps only Starter decks and the Trash over '
      'the skeleton', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(),
      overrides: [_root.overrideWith((ref) => const Stream<DeckLevel>.empty())],
    );
    await tester.pump();

    expect(find.byType(MxSkeletonList), findsOneWidget);
    expect(_actions(tester), [_en.libraryStarterDecks, _en.libraryTrash]);
    expect(find.text(_en.searchFieldHint), findsNothing);
    expect(find.byType(MxFab), findsNothing);
  });
}
