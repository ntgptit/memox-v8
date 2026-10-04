import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/features/settings/presentation/controllers/settings_controller.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/settings/presentation/providers/watch_app_settings_use_case_provider.dart';
import 'package:memox/features/settings/presentation/states/settings_state.dart';

import '../../../support/fake_day_clock.dart';
import '../../../support/library_harness.dart';
import '../../../support/settings_fakes.dart';
import '../../../support/test_database.dart';

typedef _Rig = ({ProviderContainer container, FlakySettingsRepository store});

/// A container over [env] whose settings store counts and can fail, with
/// the controller kept alive and the first row read.
Future<_Rig> _rig(LibraryEnv env) async {
  final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db));
  final container = libraryContainer(
    env,
    overrides: [settingsRepositoryProvider.overrideWithValue(store)],
  );
  container.listen(settingsControllerProvider, (_, _) {});
  await container.read(appSettingsProvider.future);
  return (container: container, store: store);
}

SettingsController _controller(_Rig rig) =>
    rig.container.read(settingsControllerProvider.notifier);

SettingsState _state(_Rig rig) =>
    rig.container.read(settingsControllerProvider);

/// What the store holds now.
Future<AppSettingsEntity> _stored(_Rig rig) =>
    rig.container.read(watchAppSettingsUseCaseProvider)().first;

/// Past the settle, with the write and the stream's echo done.
Future<void> _settled() =>
    Future<void>.delayed(cardLimitSettle + const Duration(milliseconds: 150));

/// A plain test over a fresh [LibraryEnv]: drift's streams need the real
/// event loop, which a widget test's fake clock does not run.
void _settingsTest(String description, Future<void> Function(_Rig rig) body) {
  test(description, () async {
    final env = LibraryEnv(openTestDatabase(), FakeDayClock(libraryToday));
    try {
      await body(await _rig(env));
    } finally {
      await env.db.close();
    }
  });
}

void main() {
  _settingsTest('steps settle into one write of the last value (D1, D6)', (
    rig,
  ) async {
    _controller(rig)
      ..stepCardLimit(1)
      ..stepCardLimit(1)
      ..stepCardLimit(1);
    expect(_state(rig).cardLimitDraft, 23);
    expect((await _stored(rig)).studyDefaults.cardLimit, 20);

    await _settled();
    expect((await _stored(rig)).studyDefaults.cardLimit, 23);
    expect(rig.store.writes, 1);
    expect(_state(rig).cardLimitDraft, isNull);
    expect(_state(rig).notice, isA<SettingsSaved>());
  });

  _settingsTest('a step stops at the bounds', (rig) async {
    _controller(rig).stepCardLimit(-50);
    expect(_state(rig).cardLimitDraft, StudyOptions.minCardLimit);
    _controller(rig).stepCardLimit(500);
    expect(_state(rig).cardLimitDraft, StudyOptions.maxCardLimit);
  });

  _settingsTest('a typed limit outside 1–200 is shown as invalid and not '
      'written; a valid one is written at once (E1)', (rig) async {
    _controller(rig).typeCardLimit('250');
    expect(_state(rig).isCardLimitInvalid, isTrue);
    expect(_state(rig).cardLimitDraft, 250);
    await _settled();
    expect(rig.store.writes, 0);

    _controller(rig).typeCardLimit('');
    expect(_state(rig).isCardLimitInvalid, isTrue);

    _controller(rig).typeCardLimit('150');
    await pumpEventQueue();
    expect((await _stored(rig)).studyDefaults.cardLimit, 150);
    expect(_state(rig).isCardLimitInvalid, isFalse);
  });

  _settingsTest('a second submit of a kind in flight is ignored (A4)', (
    rig,
  ) async {
    _controller(rig)
      ..chooseNewCardOrder(NewCardOrder.random)
      ..chooseNewCardOrder(NewCardOrder.random)
      ..chooseTheme(ThemeChoice.dark)
      ..chooseTheme(ThemeChoice.dark);
    await pumpEventQueue();

    expect(rig.store.writes, 2);
    final stored = await _stored(rig);
    expect(stored.studyDefaults.newCardOrder, NewCardOrder.random);
    expect(stored.theme, ThemeChoice.dark);
  });

  _settingsTest('a limit changed while its group writes is written once '
      'that write ends, not dropped', (rig) async {
    _controller(rig)
      ..chooseNewCardOrder(NewCardOrder.random)
      ..typeCardLimit('30');
    await _settled();

    final stored = await _stored(rig);
    expect(stored.studyDefaults.newCardOrder, NewCardOrder.random);
    expect(stored.studyDefaults.cardLimit, 30);
    expect(_state(rig).cardLimitDraft, isNull);
  });

  _settingsTest('a step while its own write runs is written after it', (
    rig,
  ) async {
    final gate = rig.store.hold = Completer<void>();
    _controller(rig).typeCardLimit('30');
    _controller(rig).stepCardLimit(1);
    // The step settles while the first write still runs.
    await _settled();
    rig.store.hold = null;
    gate.complete();
    await _settled();

    expect((await _stored(rig)).studyDefaults.cardLimit, 31);
    expect(rig.store.writes, 2);
  });

  _settingsTest('a failed write keeps the persisted value, says so, and '
      'Retry writes the same change (E2)', (rig) async {
    rig.store.isFailing = true;
    _controller(rig).stepCardLimit(5);
    await _settled();

    expect(_state(rig).notice, isA<SettingsSaveFailed>());
    expect(_state(rig).notice!.kind, SettingsSubmit.cardLimit);
    expect(_state(rig).cardLimitDraft, isNull);
    expect((await _stored(rig)).studyDefaults.cardLimit, 20);

    rig.store.isFailing = false;
    await _controller(rig).retry(SettingsSubmit.cardLimit);
    await pumpEventQueue();
    expect((await _stored(rig)).studyDefaults.cardLimit, 25);
    expect(_state(rig).notice, isA<SettingsSaved>());
  });

  _settingsTest('theme and language are each one write; choosing the '
      'persisted value writes nothing', (rig) async {
    _controller(rig)
      ..chooseTheme(ThemeChoice.system)
      ..chooseLanguage(LanguageChoice.system);
    await pumpEventQueue();
    expect(rig.store.writes, 0);

    _controller(rig).chooseLanguage(LanguageChoice.vi);
    await pumpEventQueue();
    expect((await _stored(rig)).language, LanguageChoice.vi);
    expect(_state(rig).notice!.kind, SettingsSubmit.language);
  });

  _settingsTest('reset returns every option to its default in one write '
      '(A3)', (rig) async {
    _controller(rig)
      ..chooseTheme(ThemeChoice.dark)
      ..chooseLanguage(LanguageChoice.vi)
      ..typeCardLimit('50');
    await pumpEventQueue();
    rig.store.writes = 0;

    expect(await _controller(rig).reset(), isTrue);
    final stored = await _stored(rig);
    expect(stored.theme, AppSettingsEntity.defaults.theme);
    expect(stored.language, AppSettingsEntity.defaults.language);
    expect(stored.studyDefaults.cardLimit, StudyOptions.defaultCardLimit);
    expect(rig.store.writes, 1);
    expect(_state(rig).notice!.kind, SettingsSubmit.reset);
  });

  _settingsTest('a failed reset changes nothing and says so', (rig) async {
    _controller(rig).chooseTheme(ThemeChoice.dark);
    await pumpEventQueue();
    rig.store.isFailing = true;

    expect(await _controller(rig).reset(), isFalse);
    expect((await _stored(rig)).theme, ThemeChoice.dark);
    expect(_state(rig).notice, isA<SettingsSaveFailed>());
  });
}
