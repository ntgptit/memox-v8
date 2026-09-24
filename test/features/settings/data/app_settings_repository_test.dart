import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';

import '../../../support/test_database.dart';

// UC-SETTINGS-001 over the one `app_settings` row: every save is its own
// transaction and every watcher sees it (BR-SETTINGS-001, BR-SETTINGS-007).

DateTime _t0() => DateTime(2026, 9, 24, 9);

const _sevenRandom = StudyOptions(
  cardLimit: 7,
  newCardOrder: NewCardOrder.random,
);

const _rootOverride = '{"card_limit":30,"new_card_order":"created"}';

/// A root deck `r` holding [_rootOverride], written as SQL: the import map
/// keeps settings away from the deck feature.
Future<void> _insertRootWithOverride(AppDatabase db) => db.customStatement(
  'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
  'scheduler_type, scheduler_version, generation, sibling_position, '
  'study_config, created_at, updated_at) '
  "VALUES ('r', 'r', NULL, 'r', 1, 'deck', 'eight_box', 1, 1, 0, ?, 0, 0)",
  [_rootOverride],
);

Future<String?> _rootStudyConfig(AppDatabase db) async =>
    (await db
            .customSelect("SELECT study_config FROM deck WHERE id = 'r'")
            .getSingle())
        .read<String?>('study_config');

void main() {
  late AppDatabase db;
  late SettingsRepositoryImpl settings;
  setUp(() {
    db = openTestDatabase();
    settings = SettingsRepositoryImpl(db, now: _t0);
  });
  tearDown(() => db.close());

  Future<Map<String, Object?>> settingsRow(AppDatabase db) async =>
      (await db
              .customSelect('SELECT * FROM app_settings WHERE id = 1')
              .getSingle())
          .data;

  test('a fresh install reads the defaults (UC-SETTINGS-001 step 1)', () async {
    final current = await settings.watchAppSettings().first;

    expect(current.studyDefaults.cardLimit, StudyOptions.defaultCardLimit);
    expect(current.studyDefaults.newCardOrder, NewCardOrder.created);
    expect(current.theme, ThemeChoice.system);
    expect(current.language, LanguageChoice.system);
  });

  test('saving the study defaults writes both values and every watcher sees '
      'them (UC-SETTINGS-001 step 2, BR-SETTINGS-001)', () async {
    final seen = <(int, NewCardOrder)>[];
    final subscription = settings.watchAppSettings().listen(
      (current) => seen.add((
        current.studyDefaults.cardLimit,
        current.studyDefaults.newCardOrder,
      )),
    );
    await pumpEventQueue();

    final result = await settings.saveStudyDefaults(options: _sevenRandom);
    await pumpEventQueue();
    await subscription.cancel();

    expect(result, isA<Ok<void, SettingsRejection>>());
    expect(seen, [(20, NewCardOrder.created), (7, NewCardOrder.random)]);
    expect((await settingsRow(db))['updated_at'], isNotNull);
  });

  test('a card limit out of bounds is refused and writes nothing '
      '(UC-SETTINGS-001 E1, BR-SETTINGS-002)', () async {
    await settings.watchAppSettings().first;
    final before = await totalChanges(db);

    final result = await settings.saveStudyDefaults(
      options: const StudyOptions(
        cardLimit: 201,
        newCardOrder: NewCardOrder.random,
      ),
    );

    expect(
      result,
      isA<Rejected<void, SettingsRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        SettingsRejection.cardLimitOutOfRange,
      ),
    );
    expect(await totalChanges(db), before);
  });

  test('each save changes only its own value (BR-SETTINGS-007)', () async {
    await settings.setTheme(theme: ThemeChoice.dark);
    await settings.setLanguage(language: LanguageChoice.vi);

    final current = await settings.watchAppSettings().first;
    expect(current.theme, ThemeChoice.dark);
    expect(current.language, LanguageChoice.vi);
    expect(current.studyDefaults.cardLimit, StudyOptions.defaultCardLimit);
    expect(current.studyDefaults.newCardOrder, NewCardOrder.created);
  });

  test('saving the study defaults leaves open sessions and root overrides '
      'alone (BR-SETTINGS-002, BR-SETTINGS-004)', () async {
    await _insertRootWithOverride(db);
    await db.customStatement(
      'INSERT INTO study_session (id, deck_id, root_id, generation, session_kind, current_mode, '
      "status, cursor, card_limit, started_at) VALUES ('s', 'r', 'r', 1, 'learning', 'browse', "
      "'in_progress', 0, 20, 0)",
    );

    await settings.saveStudyDefaults(options: _sevenRandom);

    final session = await db
        .customSelect("SELECT card_limit FROM study_session WHERE id = 's'")
        .getSingle();
    expect(session.read<int>('card_limit'), 20);
    expect(await _rootStudyConfig(db), _rootOverride);
  });

  test('reset to defaults returns the four values and writes nothing else: '
      'not the reminder columns, not a root override '
      '(UC-SETTINGS-001 A3, BR-SETTINGS-008)', () async {
    await _insertRootWithOverride(db);
    await settings.saveStudyDefaults(options: _sevenRandom);
    await settings.setTheme(theme: ThemeChoice.light);
    await settings.setLanguage(language: LanguageChoice.en);
    await db.customStatement(
      'UPDATE app_settings SET reminder_enabled = 1, reminder_minute_of_day = 480 '
      'WHERE id = 1',
    );

    final before = await totalChanges(db);

    final result = await settings.resetToDefaults();

    expect(result, isA<Ok<void, SettingsRejection>>());
    expect(await totalChanges(db), before + 1);
    expect(await _rootStudyConfig(db), _rootOverride);
    final current = await settings.watchAppSettings().first;
    expect(
      current.studyDefaults.cardLimit,
      AppSettingsEntity.defaults.studyDefaults.cardLimit,
    );
    expect(current.studyDefaults.newCardOrder, NewCardOrder.created);
    expect(current.theme, ThemeChoice.system);
    expect(current.language, LanguageChoice.system);
    final row = await settingsRow(db);
    expect(row['reminder_enabled'], 1);
    expect(row['reminder_minute_of_day'], 480);
  });

  test('a settings row that is gone is a read failure, never made-up values '
      '(UC-SETTINGS-001 E3)', () async {
    await db.customStatement('DELETE FROM app_settings');

    await expectLater(
      settings.watchAppSettings().first,
      throwsA(isA<UnknownDatabaseFailure>()),
    );
  });

  test('a failed save leaves as a typed Failure and the persisted values stay '
      '(UC-SETTINGS-001 E2, BR-SETTINGS-007)', () async {
    final failing = openTestDatabase(interceptor: FailingUpdates());
    addTearDown(failing.close);
    final broken = SettingsRepositoryImpl(failing, now: _t0);

    await expectLater(
      broken.setTheme(theme: ThemeChoice.dark),
      throwsA(isA<ConstraintFailure>()),
    );
    expect((await broken.watchAppSettings().first).theme, ThemeChoice.system);
  });

  test('saved values survive closing and reopening the database '
      '(IT-STUDY-008, host half)', () async {
    final folder = await Directory.systemTemp.createTemp('memox_settings');
    addTearDown(() => folder.delete(recursive: true));
    final file = File('${folder.path}/memox.sqlite');
    final first = AppDatabase(NativeDatabase(file));
    await SettingsRepositoryImpl(
      first,
      now: _t0,
    ).saveStudyDefaults(options: _sevenRandom);
    await first.close();

    final second = AppDatabase(NativeDatabase(file));
    addTearDown(second.close);
    final current = await SettingsRepositoryImpl(
      second,
      now: _t0,
    ).watchAppSettings().first;

    expect(current.studyDefaults.cardLimit, 7);
    expect(current.studyDefaults.newCardOrder, NewCardOrder.random);
  });
}
