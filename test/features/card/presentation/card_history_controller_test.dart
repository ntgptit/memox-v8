import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/models/review_history_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/card/domain/usecases/load_card_history_page_use_case.dart';
import 'package:memox/features/card/presentation/controllers/card_history_controller.dart';
import 'package:memox/features/card/presentation/providers/load_card_history_page_use_case_provider.dart';
import 'package:memox/features/card/presentation/widgets/support/card_history_labels_widget.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/library_harness.dart';
import '../../../support/test_database.dart';

/// Fails the first request for an older page, then answers as [_cards]
/// does; records every cursor it was asked from.
final class _FlakyHistory implements CardRepository {
  _FlakyHistory(this._cards);

  final CardRepository _cards;
  final afters = <ReviewHistoryCursor?>[];
  var _hasFailed = false;

  @override
  Future<ReviewHistoryPage?> historyPage({
    required String cardId,
    ReviewHistoryCursor? after,
  }) async {
    afters.add(after);
    if (after != null && !_hasFailed) {
      _hasFailed = true;
      throw const UnknownDatabaseFailure(cause: '/data/memox.sqlite');
    }
    return _cards.historyPage(cardId: cardId, after: after);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  ProviderContainer container([List<Override> overrides = const []]) {
    final created = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        dayClockProvider.overrideWithValue(FakeDayClock(libraryToday)),
        ...overrides,
      ],
    );
    addTearDown(created.dispose);
    return created;
  }

  /// Korean › Words holding card `c`, with [answers] logged a minute apart.
  Future<void> seed(int answers) async {
    final decks = DeckRepositoryImpl(db);
    final words = await decks.sub((await decks.root('Korean')).id, 'Words');
    await insertCard(db, id: 'c', deckId: words.id);
    for (var i = 0; i < answers; i++) {
      await logReview(
        db,
        id: 'r$i',
        cardId: 'c',
        at: DateTime(2026, 9, 1, 8).add(Duration(minutes: i)),
      );
    }
  }

  Future<CardHistoryView> open(ProviderContainer c) {
    c.listen(cardHistoryControllerProvider('c'), (_, _) {});
    return c.read(cardHistoryControllerProvider('c').future);
  }

  CardHistoryController history(ProviderContainer c) =>
      c.read(cardHistoryControllerProvider('c').notifier);

  CardHistoryView shown(ProviderContainer c) =>
      c.read(cardHistoryControllerProvider('c')).requireValue;

  test(
    'the newest 50 first; older answers append once (BR-CARD-015)',
    () async {
      await seed(ReviewHistoryPage.size + 1);
      final c = container();
      final first = await open(c);

      expect(first.entries, hasLength(ReviewHistoryPage.size));
      expect(first.entries.first.id, 'r50');
      expect(first.next, isNotNull);

      // A double tap asks once (E5).
      await Future.wait([history(c).loadMore(), history(c).loadMore()]);
      expect(shown(c).entries, hasLength(ReviewHistoryPage.size + 1));
      expect(shown(c).entries.last.id, 'r0');
      expect(shown(c).next, isNull);
    },
  );

  test(
    'a failed older page keeps the rows; Retry resumes at the cursor (E4)',
    () async {
      await seed(ReviewHistoryPage.size + 1);
      final flaky = _FlakyHistory(
        CardRepositoryImpl(
          db,
          ScheduleRepositoryImpl(db),
          TagRepositoryImpl(db),
        ),
      );
      final c = container([
        loadCardHistoryPageUseCaseProvider.overrideWithValue(
          LoadCardHistoryPageUseCase(flaky),
        ),
      ]);
      await open(c);
      await history(c).loadMore();

      expect(shown(c).hasMoreFailed, isTrue);
      expect(shown(c).isLoadingMore, isFalse);
      expect(shown(c).entries, hasLength(ReviewHistoryPage.size));

      await history(c).loadMore();
      expect(shown(c).hasMoreFailed, isFalse);
      expect(shown(c).entries, hasLength(ReviewHistoryPage.size + 1));
      expect(flaky.afters[2], same(flaky.afters[1]));
    },
  );

  test('a card never studied has an empty history (BR-CARD-018)', () async {
    await seed(0);
    final view = await open(container());

    expect(view.entries, isEmpty);
    expect(view.next, isNull);
  });

  test(
    'a card that is gone has an empty history; its detail says why',
    () async {
      final view = await open(container());

      expect(view.entries, isEmpty);
      expect(view.next, isNull);
    },
  );

  test(
    'the labels name each kind, action and mode; an unknown mode as stored',
    () {
      final en = lookupAppLocalizations(const Locale('en'));

      expect(
        en.cardHistoryKind(ReviewKind.relearning),
        en.cardHistoryKindRelearning,
      );
      expect(
        en.cardHistoryAction(EightBoxAction.forgotten),
        en.cardActionForgotten,
      );
      expect(en.cardHistoryAction(Sm2Action.easy), en.cardActionEasy);
      expect(en.cardHistoryMode('self_assess'), en.cardModeSelfAssess);
      expect(en.cardHistoryMode('dictation'), 'dictation');
    },
  );
}
