import 'dart:async';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/speech/speech_language.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/presentation/controllers/study_options_controller.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/settings/presentation/providers/study_options_provider.dart';
import 'package:memox/features/settings/presentation/states/study_options_state.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/library_harness.dart';
import '../../../support/settings_fakes.dart';
import '../../../support/test_database.dart';

typedef _Rig = ({
  ProviderContainer container,
  FlakySettingsRepository store,
  LibraryEnv env,
  String rootId,
  String subId,
});

/// Korean › Words, the screen open on the sub-deck, whose options are its
/// root's (BR-STUDY-056).
Future<_Rig> _rig(LibraryEnv env, {String? rootConfig}) async {
  final root = await env.decks.root('Korean');
  final sub = await env.decks.sub(root.id, 'Words');
  if (rootConfig != null) {
    await env.db.customUpdate(
      'UPDATE deck SET study_config = ? WHERE id = ?',
      variables: [Variable(rootConfig), Variable(root.id)],
    );
  }
  final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db));
  final container = libraryContainer(
    env,
    overrides: [settingsRepositoryProvider.overrideWithValue(store)],
  );
  container.listen(studyOptionsControllerProvider(sub.id), (_, _) {});
  await container.read(studyOptionsProvider(sub.id).future);
  await container.read(appSettingsProvider.future);
  return (
    container: container,
    store: store,
    env: env,
    rootId: root.id,
    subId: sub.id,
  );
}

StudyOptionsController _controller(_Rig rig) =>
    rig.container.read(studyOptionsControllerProvider(rig.subId).notifier);

StudyOptionsState _state(_Rig rig) =>
    rig.container.read(studyOptionsControllerProvider(rig.subId));

Future<EffectiveStudyOptions> _stored(_Rig rig) async =>
    (await SettingsRepositoryImpl(rig.env.db)
        .studyOptionsOf(deckId: rig.rootId))!;

Future<StudyOptionsForm> _form(_Rig rig) async => StudyOptionsForm.of(
  await _stored(rig),
  _state(rig),
  appDefaults: StudyOptions.defaults,
);

/// Past the write and the stream's echo.
Future<void> _settled() =>
    Future<void>.delayed(const Duration(milliseconds: 150));

const _override = '{"card_limit":50,"new_card_order":"random"}';

void _optionsTest(
  String description,
  Future<void> Function(_Rig rig) body, {
  String? rootConfig,
}) {
  test(description, () async {
    final env = LibraryEnv(openTestDatabase(), FakeDayClock(libraryToday));
    try {
      await body(await _rig(env, rootConfig: rootConfig));
    } finally {
      await env.db.close();
    }
  });
}

void main() {
  _optionsTest('a deck with no override follows the app defaults, and '
      'nothing is to save (D9)', (rig) async {
    final form = await _form(rig);

    expect(form.isUsingAppDefaults, isTrue);
    expect(form.options.cardLimit, StudyOptions.defaultCardLimit);
    expect(form.canSave, isFalse);
  });

  _optionsTest('turning app defaults off and stepping saves the root\'s own '
      'options, from a sub-deck (A1, BR-STUDY-056)', (rig) async {
    _controller(rig)
      ..useAppDefaults(isOn: false)
      ..stepCardLimit(5)
      ..chooseNewCardOrder(NewCardOrder.random);
    expect((await _form(rig)).canSave, isTrue);

    await _controller(rig).save();
    await _settled();

    final stored = await _stored(rig);
    expect(stored.source, StudyOptionsSource.rootOverride);
    expect(stored.options.cardLimit, 25);
    expect(stored.options.newCardOrder, NewCardOrder.random);
    expect(_state(rig).timesSaved, 1);
    expect(_state(rig).cardLimit, isNull);
  });

  _optionsTest('Use app defaults clears the root\'s override (A1)', (
    rig,
  ) async {
    expect((await _form(rig)).isUsingAppDefaults, isFalse);
    _controller(rig).useAppDefaults(isOn: true);
    await _controller(rig).save();
    await _settled();

    expect((await _stored(rig)).source, StudyOptionsSource.appDefaults);
  }, rootConfig: _override);

  _optionsTest('turning app defaults on shows the app\'s values, not the '
      'override it replaces', (rig) async {
    _controller(rig).useAppDefaults(isOn: true);

    final form = await _form(rig);
    expect(form.options.cardLimit, StudyOptions.defaultCardLimit);
    expect(form.options.newCardOrder, NewCardOrder.created);
  }, rootConfig: _override);

  _optionsTest('an override saved unchanged has nothing to save', (rig) async {
    expect((await _form(rig)).options.cardLimit, 50);
    expect((await _form(rig)).canSave, isFalse);
  }, rootConfig: _override);

  _optionsTest('an unreadable override can be replaced by Save', (rig) async {
    final form = await _form(rig);
    expect(form.isUsingAppDefaults, isFalse);
    expect(form.canSave, isTrue);

    await _controller(rig).save();
    await _settled();
    expect((await _stored(rig)).source, StudyOptionsSource.rootOverride);
  }, rootConfig: '{not json');

  _optionsTest('a typed 250 is invalid and Save writes nothing (E1)', (
    rig,
  ) async {
    _controller(rig)
      ..useAppDefaults(isOn: false)
      ..typeCardLimit('250');
    final form = await _form(rig);
    expect(form.isCardLimitInvalid, isTrue);
    expect(form.options.cardLimit, 250);
    expect(form.canSave, isFalse);

    await _controller(rig).save();
    expect(rig.store.writes, 0);
  });

  _optionsTest('a failed save keeps the draft, and Retry save writes it '
      '(E4)', (rig) async {
    rig.store.isFailing = true;
    _controller(rig)
      ..useAppDefaults(isOn: false)
      ..stepCardLimit(1);
    await _controller(rig).save();
    expect(_state(rig).save, StudyOptionsSave.failed);
    expect(_state(rig).cardLimit, 21);
    expect((await _stored(rig)).source, StudyOptionsSource.appDefaults);

    // An edit keeps the failure in view until a save lands (critique
    // 2026-09-30 part 3d-2, E13).
    _controller(rig).stepCardLimit(1);
    expect(_state(rig).save, StudyOptionsSave.failed);
    expect(_state(rig).cardLimit, 22);

    rig.store.isFailing = false;
    await _controller(rig).save();
    await _settled();
    expect((await _stored(rig)).options.cardLimit, 22);
    expect(_state(rig).save, StudyOptionsSave.idle);
  });

  _optionsTest('a second Save while one runs is ignored (A4)', (rig) async {
    final gate = rig.store.hold = Completer<void>();
    _controller(rig)
      ..useAppDefaults(isOn: false)
      ..stepCardLimit(1);
    final first = _controller(rig).save();
    await _controller(rig).save();
    expect(_state(rig).isSaving, isTrue);

    rig.store.hold = null;
    gate.complete();
    await first;
    expect(rig.store.writes, 1);
  });

  // Study speech spec §6; BR-SETTINGS-009, D6.

  _optionsTest('chooseSpeechLanguage changes the draft; Save writes it in the '
      'override (BR-SETTINGS-009)', (rig) async {
    _controller(rig).chooseSpeechLanguage(SpeechLanguage.koKr);
    final form = await _form(rig);
    expect(form.isChanged, isTrue);
    expect(form.options.speechLanguage, SpeechLanguage.koKr);

    await _controller(rig).save();
    await _settled();

    final stored = await _stored(rig);
    expect(stored.options.speechLanguage, SpeechLanguage.koKr);
    expect(stored.options.cardLimit, 50);
  }, rootConfig: _override);

  _optionsTest('an override from before speech shows the default language '
      'and is unchanged until edited (D6)', (rig) async {
    final form = await _form(rig);

    expect(form.options.speechLanguage, SpeechLanguage.enUs);
    expect(form.isChanged, isFalse);
  }, rootConfig: _override);
}
