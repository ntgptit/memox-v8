@Tags(['golden'])
library;

import 'dart:async';

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
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

LibrarySearchScreen _screen() =>
    LibrarySearchScreen(onOpenDeck: (_) {}, onOpenCard: (_) {});

/// The kit's library, shortened and without Hangul (the test fonts have
/// none): one deck and four cards on "học", one of them found by a tag,
/// and [extraCards] more for a second page.
Future<void> _seed(LibraryEnv env, {int extraCards = 0}) async {
  final english = await env.decks.root('Tiếng Anh giao tiếp hằng ngày');
  await env.decks.sub(english.id, 'Học qua phim');
  final korean = await env.decks.root('TOPIK I');
  final nouns = await env.decks.sub(korean.id, 'Danh từ');
  await insertCard(
    env.db,
    id: 'hw',
    deckId: nouns.id,
    front: 'homework',
    back: 'bài tập về nhà',
  );
  await TagRepositoryImpl(env.db).attachByName(cardIds: {'hw'}, name: 'Học');
  await insertCard(
    env.db,
    id: 'hs',
    deckId: nouns.id,
    front: 'student',
    back: 'học sinh',
  );
  await insertCard(
    env.db,
    id: 'ht',
    deckId: nouns.id,
    front: 'to study',
    back: 'học, học tập',
  );
  await insertCard(
    env.db,
    id: 'dh',
    deckId: nouns.id,
    front: 'university',
    back: 'trường đại học',
  );
  for (var i = 0; i < extraCards; i++) {
    await insertCard(env.db, id: 'x$i', deckId: nouns.id, front: 'học $i');
  }
}

Future<void> _search(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(EditableText), text);
  await tester.pump(searchDebounce);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// A read that never answers: the loading state stays.
final class _PendingSearch implements SearchRepository {
  final _pending = StreamController<LibrarySearchResults>();

  @override
  Stream<LibrarySearchResults> watchSearch({
    required String foldedTerm,
    SearchCursor? through,
  }) => _pending.stream;
}

/// The first page from the database; every later page fails.
final class _LaterPagesFail implements SearchRepository {
  _LaterPagesFail(this._inner);

  final SearchRepository _inner;

  @override
  Stream<LibrarySearchResults> watchSearch({
    required String foldedTerm,
    SearchCursor? through,
  }) => through == null
      ? _inner.watchSearch(foldedTerm: foldedTerm)
      : Stream.error(const UnknownDatabaseFailure(cause: '/data/memox.sqlite'));
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    libraryTest('search, empty query, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(), brightness);
        await tester.pump(const Duration(milliseconds: 400));
        await expectBoundaryGolden(
          tester,
          'goldens/search_empty_query_$theme.png',
        );
      });
    });

    libraryTest('search, loading, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          _screen(),
          brightness,
          overrides: [
            searchRepositoryProvider.overrideWithValue(_PendingSearch()),
          ],
        );
        await _search(tester, 'học');
        await expectBoundaryGolden(tester, 'goldens/search_loading_$theme.png');
      });
    });

    libraryTest('search, results, $theme', (tester, env) async {
      await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(), brightness);
        await _search(tester, 'học');
        await expectBoundaryGolden(tester, 'goldens/search_results_$theme.png');
      });
    });

    libraryTest('search, no results, $theme', (tester, env) async {
      await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(), brightness);
        await _search(tester, 'hoc');
        await expectBoundaryGolden(
          tester,
          'goldens/search_no_results_$theme.png',
        );
      });
    });

    libraryTest('search, error, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          _screen(),
          brightness,
          overrides: [searchRepositoryProvider.overrideWithValue(_FailFirst())],
        );
        await _search(tester, 'học');
        await expectBoundaryGolden(tester, 'goldens/search_error_$theme.png');
      });
    });

    libraryTest('search, load more failed, $theme', (tester, env) async {
      await _seed(env, extraCards: 50);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          _screen(),
          brightness,
          overrides: [
            searchRepositoryProvider.overrideWithValue(
              _LaterPagesFail(SearchRepositoryImpl(env.db)),
            ),
          ],
        );
        await _search(tester, 'học');
        await tester.scrollUntilVisible(
          find.text(_en.searchLoadMore),
          400,
          scrollable: find
              .descendant(
                of: find.byType(MxScreenScroll),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.tap(find.text(_en.searchLoadMore));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await expectBoundaryGolden(
          tester,
          'goldens/search_load_more_failed_$theme.png',
        );
      });
    });
  }
}

/// Fails every read, the first page included.
final class _FailFirst implements SearchRepository {
  @override
  Stream<LibrarySearchResults> watchSearch({
    required String foldedTerm,
    SearchCursor? through,
  }) => Stream.error(const UnknownDatabaseFailure(cause: '/data/memox.sqlite'));
}
