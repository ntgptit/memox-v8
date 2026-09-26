import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/search/data/repositories/search_repository_impl.dart';
import 'package:memox/features/search/di/search_repository_provider.dart';
import 'package:memox/features/search/domain/models/library_search_model.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';
import 'package:memox/features/search/domain/repositories/search_repository.dart';
import 'package:memox/features/search/presentation/controllers/search_screen_controller.dart';
import 'package:memox/features/search/presentation/screens/library_search_screen.dart';
import 'package:memox/features/search/presentation/widgets/items/search_card_hit_row_widget.dart';
import 'package:memox/features/search/presentation/widgets/items/search_deck_hit_row_widget.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

// UC-SEARCH-001 on screen 04; IT-DISC-006, IT-DISC-007 in the whole-library
// sense (spec D17).

final _en = lookupAppLocalizations(const Locale('en'));

/// The results list, not the field's own scrollable.
final _results = find
    .descendant(
      of: find.byType(MxScreenScroll),
      matching: find.byType(Scrollable),
    )
    .first;

LibrarySearchScreen _screen({
  ValueChanged<String>? onOpenDeck,
  ValueChanged<String>? onOpenCard,
}) => LibrarySearchScreen(
  onOpenDeck: onOpenDeck ?? (_) {},
  onOpenCard: onOpenCard ?? (_) {},
);

/// Types [text] and lets the debounce pass and the read emit.
Future<void> _search(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(EditableText), text);
  await tester.pump(searchDebounce);
  await tester.pump();
  await tester.pump();
}

/// Fails every read from [failFrom] on (0 = the first page), else answers
/// as [_inner] does.
final class _FailingSearch implements SearchRepository {
  _FailingSearch(this._inner, {this.failLaterPagesOnly = false});

  final SearchRepository _inner;
  final bool failLaterPagesOnly;

  @override
  Stream<LibrarySearchResults> watchSearch({
    required String foldedTerm,
    SearchCursor? through,
  }) {
    if (!failLaterPagesOnly || through != null) {
      return Stream.error(
        const UnknownDatabaseFailure(cause: '/data/memox.sqlite'),
      );
    }
    return _inner.watchSearch(foldedTerm: foldedTerm, through: through);
  }
}

void main() {
  libraryTest('the field sits in the app bar and takes focus', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _screen());
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(MxAppBar),
        matching: find.byType(MxSearchField),
      ),
      findsOneWidget,
    );
    expect(find.text(_en.searchFieldHint), findsOneWidget);
    expect(tester.testTextInput.hasAnyClients, isTrue);
  });

  libraryTest('before a term it says what search finds (step 2)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _screen());

    expect(find.text(_en.searchFinds.toUpperCase()), findsOneWidget);
    expect(find.text(_en.searchHintDeckName), findsOneWidget);
    expect(find.text(_en.searchHintCardTerm), findsOneWidget);
    expect(find.text(_en.searchHintTagName), findsOneWidget);
    expect(find.text(_en.searchAccentNote), findsOneWidget);
  });

  libraryTest('decks first, then cards, each group counted (step 4)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean học');
    final lesson = await env.decks.sub(korean.id, 'Lesson');
    await insertCard(env.db, id: 'c', deckId: lesson.id, front: 'học sinh');
    await pumpLibraryScreen(tester, env, _screen());
    await _search(tester, 'học');

    expect(
      find.text(_en.searchResultsFor('học').toUpperCase()),
      findsOneWidget,
    );
    final decks = find.text(_en.searchDecksGroup.toUpperCase());
    final cards = find.text(_en.searchCardsGroup.toUpperCase());
    expect(decks, findsOneWidget);
    expect(cards, findsOneWidget);
    expect(tester.getTopLeft(decks).dy, lessThan(tester.getTopLeft(cards).dy));
    expect(find.widgetWithText(MxBadge, '1'), findsNWidgets(2));
    expect(find.byType(SearchDeckHitRowWidget), findsOneWidget);
    expect(find.byType(SearchCardHitRowWidget), findsOneWidget);
    expect(find.text(_en.searchFooter), findsOneWidget);
    expect(find.text(_en.searchLoadMore), findsNothing);
  });

  libraryTest('a group with no row draws no header (A2)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await insertCard(env.db, id: 'c', deckId: korean.id, front: 'học sinh');
    await pumpLibraryScreen(tester, env, _screen());
    await _search(tester, 'học');

    expect(find.text(_en.searchDecksGroup.toUpperCase()), findsNothing);
    expect(find.text(_en.searchCardsGroup.toUpperCase()), findsOneWidget);
  });

  libraryTest('a back-face match marks the back; a tag-only match marks '
      'nothing and shows the tag (step 5, spec D20)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await insertCard(
      env.db,
      id: 'back',
      deckId: korean.id,
      front: '학생',
      back: 'học sinh',
    );
    await insertCard(
      env.db,
      id: 'tagged',
      deckId: korean.id,
      front: 'homework',
      back: 'bài tập',
    );
    await TagRepositoryImpl(env.db)
        .attachByName(cardIds: {'tagged'}, name: 'Học');
    await pumpLibraryScreen(tester, env, _screen());
    await _search(tester, 'học');

    final rows = tester
        .widgetList<MxListRow>(
          find.descendant(
            of: find.byType(SearchCardHitRowWidget),
            matching: find.byType(MxListRow),
          ),
        )
        .toList();
    final back = rows.singleWhere((row) => row.title.startsWith('학생'));
    final tagged = rows.singleWhere((row) => row.title.startsWith('homework'));
    final offset = '학생 · '.length;
    expect(back.titleMatch, (offset, offset + 3));
    expect(tagged.titleMatch, isNull);
    expect(find.widgetWithText(MxTagChip, 'Học'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        _en.searchCardRowTagLabel('homework', 'bài tập', 'Học', 'Korean'),
      ),
      findsOneWidget,
    );
  });

  libraryTest('two decks of one name tell apart by path, and a tap opens the '
      'one chosen (IT-DISC-006)', (tester, env) async {
    final english = await env.decks.root('English');
    final vocab = await env.decks.sub(english.id, 'Vocabulary');
    final academic = await env.decks.sub(vocab.id, 'Academic words');
    final korean = await env.decks.root('Korean');
    await env.decks.sub(korean.id, 'Academic words');
    String? opened;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(onOpenDeck: (id) => opened = id),
    );
    await _search(tester, 'academic');

    expect(
      find.text(_en.searchHoldsNothing('English › Vocabulary')),
      findsOneWidget,
    );
    expect(find.text(_en.searchHoldsNothing('Korean')), findsOneWidget);
    await tester.tap(find.text(_en.searchHoldsNothing('English › Vocabulary')));
    expect(opened, academic.id);
  });

  libraryTest('no match names what is searched; clearing returns to the '
      'hints (IT-DISC-007, A4)', (tester, env) async {
    await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, _screen());
    await _search(tester, 'zzz');

    expect(find.byType(MxEmptyState), findsOneWidget);
    expect(find.text(_en.searchNoMatchesTitle('zzz')), findsOneWidget);
    expect(find.text(_en.searchNoMatchesBody), findsOneWidget);

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is MxIconButton && widget.semanticLabel == _en.searchClear,
      ),
    );
    await tester.pump();

    expect(find.byType(MxEmptyState), findsNothing);
    expect(find.text(_en.searchFinds.toUpperCase()), findsOneWidget);
  });

  libraryTest('a card row opens the card (step 6)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await insertCard(env.db, id: 'c', deckId: korean.id, front: 'học sinh');
    String? opened;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(onOpenCard: (id) => opened = id),
    );
    await _search(tester, 'học');
    await tester.tap(find.byType(SearchCardHitRowWidget));

    expect(opened, 'c');
  });

  libraryTest('a rename elsewhere updates the path in place (A3)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await insertCard(env.db, id: 'c', deckId: korean.id, front: 'học sinh');
    await pumpLibraryScreen(tester, env, _screen());
    await _search(tester, 'học');
    expect(find.text('Korean'), findsWidgets);

    await env.decks.renameDeck(deckId: korean.id, name: 'Tiếng Hàn');
    await tester.pump();
    await tester.pump();

    expect(find.text('Tiếng Hàn'), findsOneWidget);
  });

  libraryTest('51 hits: the count says more, Load more reads the rest (A1)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    for (var i = 0; i < 51; i++) {
      await insertCard(
        env.db,
        id: 'c${i.toString().padLeft(2, '0')}',
        deckId: korean.id,
        front: 'học ${i.toString().padLeft(2, '0')}',
      );
    }
    await pumpLibraryScreen(tester, env, _screen());
    await _search(tester, 'học');

    expect(find.widgetWithText(MxBadge, '50+'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(_en.searchLoadMore),
      400,
      scrollable: _results,
    );
    await tester.tap(find.text(_en.searchLoadMore));
    await tester.pump();
    await tester.pump();

    expect(find.text(_en.searchLoadMore), findsNothing);
    await tester.scrollUntilVisible(
      find.text(_en.searchCardsGroup.toUpperCase()),
      -400,
      scrollable: _results,
    );
    expect(find.widgetWithText(MxBadge, '51'), findsOneWidget);
  });

  libraryTest('a failed first page is the error state; retry reads again '
      '(E1)', (tester, env) async {
    await env.decks.root('Korean');
    await pumpLibraryScreen(
      tester,
      env,
      _screen(),
      overrides: [
        searchRepositoryProvider.overrideWithValue(_FailingSearch(_inner(env))),
      ],
    );
    await _search(tester, 'kor');

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.byType(SearchDeckHitRowWidget), findsNothing);
  });

  libraryTest('a failed later page keeps the rows and offers a retry (E2)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    for (var i = 0; i < 51; i++) {
      await insertCard(
        env.db,
        id: 'c${i.toString().padLeft(2, '0')}',
        deckId: korean.id,
        front: 'học ${i.toString().padLeft(2, '0')}',
      );
    }
    await pumpLibraryScreen(
      tester,
      env,
      _screen(),
      overrides: [
        searchRepositoryProvider.overrideWithValue(
          _FailingSearch(_inner(env), failLaterPagesOnly: true),
        ),
      ],
    );
    await _search(tester, 'học');
    await tester.scrollUntilVisible(
      find.text(_en.searchLoadMore),
      400,
      scrollable: _results,
    );
    await tester.tap(find.text(_en.searchLoadMore));
    await tester.pump();
    await tester.pump();

    expect(find.byType(MxInlineBanner), findsOneWidget);
    expect(find.text(_en.searchLoadMoreFailed), findsOneWidget);
    expect(find.byType(SearchCardHitRowWidget), findsWidgets);
  });
}

SearchRepository _inner(LibraryEnv env) => SearchRepositoryImpl(env.db);
