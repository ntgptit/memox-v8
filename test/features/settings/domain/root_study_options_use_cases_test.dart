import 'package:drift/drift.dart' show UpdateKind;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/usecases/save_root_study_options_use_case.dart';
import 'package:memox/features/settings/domain/usecases/use_app_defaults_use_case.dart';
import 'package:memox/features/settings/domain/usecases/watch_study_options_use_case.dart';

import '../../../support/test_database.dart';

// The study options screen of a root deck (UC-SETTINGS-001 A1) through its
// three use cases.

void main() {
  late AppDatabase db;
  late SettingsRepositoryImpl settings;
  setUp(() async {
    db = openTestDatabase();
    settings = SettingsRepositoryImpl(db, now: () => DateTime(2026, 9, 24));
    await db.customStatement(
      'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
      'scheduler_type, scheduler_version, generation, sibling_position, '
      'created_at, updated_at) '
      "VALUES ('r', 'r', NULL, 'r', 1, 'deck', 'eight_box', 1, 1, 0, 0, 0)",
    );
  });
  tearDown(() => db.close());

  test('saving the options of a root, then Use app defaults, shows the '
      'override and then the app defaults (UC-SETTINGS-001 A1)', () async {
    final seen = <Outcome<EffectiveStudyOptions, SettingsRejection>>[];
    final subscription = WatchStudyOptionsUseCase(settings)(deckId: 'r')
        .listen(seen.add);
    await pumpEventQueue();

    final saved = await SaveRootStudyOptionsUseCase(settings)(
      rootDeckId: 'r',
      options: const StudyOptions(
        cardLimit: 50,
        newCardOrder: NewCardOrder.random,
      ),
    );
    await pumpEventQueue();
    final overridden = seen.last;
    final cleared = await UseAppDefaultsUseCase(settings)(rootDeckId: 'r');
    await pumpEventQueue();
    await subscription.cancel();

    expect(saved, isA<Ok<void, SettingsRejection>>());
    expect(cleared, isA<Ok<void, SettingsRejection>>());
    expect(
      overridden,
      isA<Ok<EffectiveStudyOptions, SettingsRejection>>().having(
        (ok) => (ok.value.options.cardLimit, ok.value.hasRootOverride),
        'options',
        (50, true),
      ),
    );
    expect(
      seen.last,
      isA<Ok<EffectiveStudyOptions, SettingsRejection>>().having(
        (ok) => (ok.value.options.cardLimit, ok.value.hasRootOverride),
        'options',
        (StudyOptions.defaultCardLimit, false),
      ),
    );
  });

  test('a deck that does not exist is deckNotFound', () async {
    final first = await WatchStudyOptionsUseCase(settings)(deckId: 'missing')
        .first;

    expect(
      first,
      isA<Rejected<EffectiveStudyOptions, SettingsRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        SettingsRejection.deckNotFound,
      ),
    );
  });

  test('deleting the deck while its options are open turns them into '
      'deckNotFound', () async {
    final seen = <Outcome<EffectiveStudyOptions, SettingsRejection>>[];
    final subscription = WatchStudyOptionsUseCase(settings)(deckId: 'r')
        .listen(seen.add);
    await pumpEventQueue();

    await db.customUpdate(
      "DELETE FROM deck WHERE id = 'r'",
      updates: {db.deck},
      updateKind: UpdateKind.delete,
    );
    await pumpEventQueue();
    await subscription.cancel();

    expect(seen.first, isA<Ok<EffectiveStudyOptions, SettingsRejection>>());
    expect(
      seen.last,
      isA<Rejected<EffectiveStudyOptions, SettingsRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        SettingsRejection.deckNotFound,
      ),
    );
  });
}
