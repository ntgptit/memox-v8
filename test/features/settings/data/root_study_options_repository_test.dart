import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';

import '../../../support/test_database.dart';

// The study options of a root deck (UC-SETTINGS-001 A1, BR-STUDY-056): its
// override, or the app-wide defaults when it has none or cannot be read.

DateTime _t0() => DateTime(2026, 9, 24, 9);

const _thirtyRandom = StudyOptions(
  cardLimit: 30,
  newCardOrder: NewCardOrder.random,
);

/// The root `r` and its sub-deck `s`, written as SQL: the import map keeps
/// settings away from the deck feature. [studyConfig] is the root's override.
Future<void> _insertTree(AppDatabase db, {String? studyConfig}) async {
  await db.customStatement(
    'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
    'scheduler_type, scheduler_version, generation, sibling_position, '
    'study_config, created_at, updated_at) '
    "VALUES ('r', 'r', NULL, 'r', 1, 'deck', 'eight_box', 1, 1, 0, ?, 0, 0)",
    [studyConfig],
  );
  await db.customStatement(
    'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
    'sibling_position, created_at, updated_at) '
    "VALUES ('s', 's', 'r', 'r', 2, 'unset', 0, 0, 0)",
  );
}

Future<void> _moveTreeToTrash(AppDatabase db) => db.customStatement(
  "UPDATE deck SET delete_batch_id = 'b' WHERE root_id = 'r'",
);

Future<({String? studyConfig, DateTime updatedAt})> _root(
  AppDatabase db,
) async {
  final row = await db
      .customSelect("SELECT study_config, updated_at FROM deck WHERE id = 'r'")
      .getSingle();
  return (
    studyConfig: row.read<String?>('study_config'),
    updatedAt: row.read<DateTime>('updated_at'),
  );
}

Matcher _rejectedWith(SettingsRejection reason) =>
    isA<Rejected<void, SettingsRejection>>().having(
      (rejected) => rejected.reason,
      'reason',
      reason,
    );

void main() {
  late AppDatabase db;
  late SettingsRepositoryImpl settings;
  setUp(() {
    db = openTestDatabase();
    settings = SettingsRepositoryImpl(db, now: _t0);
  });
  tearDown(() => db.close());

  test('a root with no override studies with the app defaults '
      '(BR-STUDY-056)', () async {
    await _insertTree(db);
    await settings.saveStudyDefaults(
      options: const StudyOptions(
        cardLimit: 7,
        newCardOrder: NewCardOrder.random,
      ),
    );

    final effective = await settings.watchStudyOptions(deckId: 'r').first;

    expect(effective?.rootDeckId, 'r');
    expect(effective?.options.cardLimit, 7);
    expect(effective?.options.newCardOrder, NewCardOrder.random);
    expect(effective?.source, StudyOptionsSource.appDefaults);
    expect(effective?.hasRootOverride, isFalse);
  });

  test("a sub-deck studies with its root's override (BR-STUDY-056)", () async {
    await _insertTree(
      db,
      studyConfig: '{"card_limit":30,"new_card_order":"random"}',
    );

    final effective = await settings.watchStudyOptions(deckId: 's').first;

    expect(effective?.rootDeckId, 'r');
    expect(effective?.options.cardLimit, 30);
    expect(effective?.options.newCardOrder, NewCardOrder.random);
    expect(effective?.source, StudyOptionsSource.rootOverride);
    expect(effective?.hasRootOverride, isTrue);
  });

  test('a missing deck and a deck in the Trash have no options', () async {
    await _insertTree(db);
    expect(await settings.watchStudyOptions(deckId: 'missing').first, isNull);

    await _moveTreeToTrash(db);

    expect(await settings.watchStudyOptions(deckId: 'r').first, isNull);
    expect(await settings.watchStudyOptions(deckId: 's').first, isNull);
  });

  test('an unreadable override studies with the app defaults and stays '
      'stored as it was (IT-STUDY-013)', () async {
    const unreadable = '{"card_limit":500,"new_card_order":"created"}';
    await _insertTree(db, studyConfig: unreadable);
    final before = await totalChanges(db);

    final effective = await settings.watchStudyOptions(deckId: 's').first;

    expect(effective?.options.cardLimit, StudyOptions.defaultCardLimit);
    expect(effective?.options.newCardOrder, NewCardOrder.created);
    expect(effective?.source, StudyOptionsSource.unreadableRootOverride);
    expect(effective?.hasRootOverride, isTrue);
    expect((await _root(db)).studyConfig, unreadable);
    expect(await totalChanges(db), before);
  });

  test('the options in force follow the override and the app defaults '
      '(UC-SETTINGS-001 A1)', () async {
    await _insertTree(db);
    final seen = <EffectiveStudyOptions?>[];
    final subscription = settings
        .watchStudyOptions(deckId: 's')
        .listen(seen.add);
    await pumpEventQueue();

    await settings.saveRootStudyOptions(
      rootDeckId: 'r',
      options: _thirtyRandom,
    );
    await pumpEventQueue();
    final overridden = seen.last;
    await settings.saveStudyDefaults(
      options: const StudyOptions(
        cardLimit: 7,
        newCardOrder: NewCardOrder.created,
      ),
    );
    await pumpEventQueue();
    final overrideStillWins = seen.last;
    await settings.clearRootStudyOptions(rootDeckId: 'r');
    await pumpEventQueue();
    await subscription.cancel();

    expect(
      (overridden?.options.cardLimit, overridden?.source),
      (30, StudyOptionsSource.rootOverride),
    );
    expect(
      (overrideStillWins?.options.cardLimit, overrideStillWins?.source),
      (30, StudyOptionsSource.rootOverride),
    );
    expect(
      (seen.last?.options.cardLimit, seen.last?.source),
      (7, StudyOptionsSource.appDefaults),
    );
  });

  test("saving a root's options writes its override and nothing else "
      '(BR-SETTINGS-003)', () async {
    await _insertTree(db);
    final before = await totalChanges(db);

    final result = await settings.saveRootStudyOptions(
      rootDeckId: 'r',
      options: _thirtyRandom,
    );

    expect(result, isA<Ok<void, SettingsRejection>>());
    final root = await _root(db);
    expect(root.studyConfig, '{"card_limit":30,"new_card_order":"random"}');
    expect(root.updatedAt, _t0());
    expect(await totalChanges(db), before + 1);
  });

  test('a card limit out of bounds is refused for a root too '
      '(BR-STUDY-003)', () async {
    await _insertTree(db);
    final before = await totalChanges(db);

    final result = await settings.saveRootStudyOptions(
      rootDeckId: 'r',
      options: const StudyOptions(
        cardLimit: 0,
        newCardOrder: NewCardOrder.created,
      ),
    );

    expect(result, _rejectedWith(SettingsRejection.cardLimitOutOfRange));
    expect(await totalChanges(db), before);
  });

  test('a sub-deck, a missing deck and a deck in the Trash are refused and '
      'nothing is written (BR-STUDY-056)', () async {
    await _insertTree(db);
    final before = await totalChanges(db);

    expect(
      await settings.saveRootStudyOptions(
        rootDeckId: 's',
        options: _thirtyRandom,
      ),
      _rejectedWith(SettingsRejection.notARootDeck),
    );
    expect(
      await settings.clearRootStudyOptions(rootDeckId: 's'),
      _rejectedWith(SettingsRejection.notARootDeck),
    );
    expect(
      await settings.saveRootStudyOptions(
        rootDeckId: 'missing',
        options: _thirtyRandom,
      ),
      _rejectedWith(SettingsRejection.deckNotFound),
    );
    expect(await totalChanges(db), before);

    await _moveTreeToTrash(db);
    final trashed = await totalChanges(db);

    expect(
      await settings.saveRootStudyOptions(
        rootDeckId: 'r',
        options: _thirtyRandom,
      ),
      _rejectedWith(SettingsRejection.deckNotFound),
    );
    expect(
      await settings.clearRootStudyOptions(rootDeckId: 'r'),
      _rejectedWith(SettingsRejection.deckNotFound),
    );
    expect(await totalChanges(db), trashed);
  });

  test(
    'Use app defaults clears the override and writes only the root; '
    'again, it writes nothing (UC-SETTINGS-001 A1, E4, BR-SETTINGS-003)',
    () async {
      await _insertTree(
        db,
        studyConfig: '{"card_limit":30,"new_card_order":"random"}',
      );
      final before = await totalChanges(db);

      final cleared = await settings.clearRootStudyOptions(rootDeckId: 'r');
      final afterFirst = await totalChanges(db);
      final again = await settings.clearRootStudyOptions(rootDeckId: 'r');

      expect(cleared, isA<Ok<void, SettingsRejection>>());
      expect(afterFirst, before + 1);
      expect(again, isA<Ok<void, SettingsRejection>>());
      final root = await _root(db);
      expect(root.studyConfig, isNull);
      expect(root.updatedAt, _t0());
      expect(await totalChanges(db), afterFirst);
    },
  );

  test('a failed Use app defaults leaves the override as it was '
      '(UC-SETTINGS-001 E4)', () async {
    final failing = openTestDatabase(interceptor: FailingUpdates());
    addTearDown(failing.close);
    const override = '{"card_limit":30,"new_card_order":"random"}';
    await _insertTree(failing, studyConfig: override);

    await expectLater(
      SettingsRepositoryImpl(
        failing,
        now: _t0,
      ).clearRootStudyOptions(rootDeckId: 'r'),
      throwsA(isA<ConstraintFailure>()),
    );
    expect((await _root(failing)).studyConfig, override);
  });

  test('Use app defaults clears an unreadable override too (D5)', () async {
    await _insertTree(db, studyConfig: '{"card_limit":"many"}');

    final result = await settings.clearRootStudyOptions(rootDeckId: 'r');

    expect(result, isA<Ok<void, SettingsRejection>>());
    expect((await _root(db)).studyConfig, isNull);
  });

  test(
    'the options in force are one statement per emission (spec §5.3)',
    () async {
      final counter = SelectCounter();
      final counted = openTestDatabase(interceptor: counter);
      addTearDown(counted.close);
      await _insertTree(counted);
      counter.selects = 0;

      await SettingsRepositoryImpl(
        counted,
        now: _t0,
      ).watchStudyOptions(deckId: 's').first;

      expect(counter.selects, 1);
    },
  );

  test("a sub-deck moved to another tree studies with its new root's options "
      '(BR-STUDY-056)', () async {
    await _insertTree(
      db,
      studyConfig: '{"card_limit":30,"new_card_order":"random"}',
    );
    await db.customStatement(
      'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
      'scheduler_type, scheduler_version, generation, sibling_position, '
      'created_at, updated_at) '
      "VALUES ('other', 'other', NULL, 'other', 1, 'deck', 'eight_box', 1, 1, "
      '1, 0, 0)',
    );
    final seen = <EffectiveStudyOptions?>[];
    final subscription = settings
        .watchStudyOptions(deckId: 's')
        .listen(seen.add);
    await pumpEventQueue();

    await db.customUpdate(
      "UPDATE deck SET parent_id = 'other', root_id = 'other' WHERE id = 's'",
      updates: {db.deck},
    );
    await pumpEventQueue();
    await subscription.cancel();

    expect((seen.first?.rootDeckId, seen.first?.options.cardLimit), ('r', 30));
    expect(
      (seen.last?.rootDeckId, seen.last?.source),
      ('other', StudyOptionsSource.appDefaults),
    );
  });
}
