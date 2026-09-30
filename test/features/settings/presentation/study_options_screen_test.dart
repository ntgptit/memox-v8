import 'dart:async';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_stepper.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/presentation/providers/study_options_provider.dart';
import 'package:memox/features/settings/presentation/screens/study_options_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/settings_fakes.dart';

final _en = lookupAppLocalizations(const Locale('en'));

const _valueKey = ValueKey('mx-stepper-value');

/// The screen with a stand-in path: `app/` composes the real one (C6).
StudyOptionsScreen _screen(String deckId) =>
    StudyOptionsScreen(deckId: deckId, breadcrumb: const SizedBox.shrink());

/// Korean › Words; the screen opens on Words. [rootConfig] is Korean's
/// stored override.
Future<({String rootId, String subId})> _seed(
  LibraryEnv env, {
  String? rootConfig,
}) async {
  final root = await env.decks.root('Korean');
  final sub = await env.decks.sub(root.id, 'Words');
  if (rootConfig != null) {
    await env.db.customUpdate(
      'UPDATE deck SET study_config = ? WHERE id = ?',
      variables: [Variable(rootConfig), Variable(root.id)],
    );
  }
  return (rootId: root.id, subId: sub.id);
}

MxButton _save(WidgetTester tester) =>
    tester.widget<MxButton>(find.byType(MxButton).last);

Future<EffectiveStudyOptions> _stored(LibraryEnv env, String deckId) async =>
    (await SettingsRepositoryImpl(env.db).studyOptionsOf(deckId: deckId))!;

void main() {
  libraryTest('a sub-deck shows its root\'s options, following Settings, '
      'with nothing to save (kit defaults, D9)', (tester, env) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _screen(ids.subId));

    expect(find.text(_en.studyOptionsBelongTo('Korean')), findsOneWidget);
    // Audit P1: the note keeps a section's gap above the first section.
    expect(
      tester.getTopLeft(find.byType(MxSection).first).dy -
          tester.getBottomLeft(find.byType(MxNote).first).dy,
      AppSpacing.gutter,
    );
    expect(
      find.text(
        _en.studyOptionsFollowing(20, _en.studyOptionsOrderCreatedShort),
      ),
      findsOneWidget,
    );
    expect(
      find.text(_en.studyOptionsAppDefaultsHeader.toUpperCase()),
      findsOneWidget,
    );
    expect(find.text(_en.studyOptionsLocalOnly), findsOneWidget);
    expect(_save(tester).onPressed, isNull);
    // Critique 2026-09-30: one note, and the values read at full contrast
    // as plain text instead of dimmed controls.
    expect(find.byType(MxNote), findsOneWidget);
    expect(find.byType(MxStepper), findsNothing);
    expect(find.byType(MxSegmentedTray<NewCardOrder>), findsNothing);
    expect(find.text('20'), findsOneWidget);
    expect(find.text(_en.settingsOrderCreated), findsOneWidget);
    // Full contrast: the value reads like the row's label, not a muted count.
    final styles = tester.element(find.text('20')).textStyles;
    for (final value in ['20', _en.settingsOrderCreated]) {
      expect(
        tester.widget<Text>(find.text(value)).style,
        styles.settingsLabel,
        reason: value,
      );
    }
  });

  libraryTest('turning app defaults off, stepping and saving writes the '
      'root\'s options and says so (A1)', (tester, env) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _screen(ids.subId));

    await tester.tap(find.byType(MxToggle));
    await tester.pump();
    expect(find.text(_en.studyOptionsThisDeck.toUpperCase()), findsOneWidget);
    await tester.tap(find.byTooltip(_en.settingsMoreCards));
    await tester.pump();
    await tester.tap(find.text(_en.settingsOrderRandom));
    await tester.pump();
    await tester.tap(find.text(_en.cardSave));
    await tester.pumpAndSettle();

    expect(find.text(_en.studyOptionsSaved), findsOneWidget);
    final stored = await tester.runAsync(() => _stored(env, ids.rootId));
    expect(stored!.source, StudyOptionsSource.rootOverride);
    expect(stored.options.cardLimit, 21);
    expect(stored.options.newCardOrder, NewCardOrder.random);
  });

  libraryTest('while app defaults are on the values are read-only text; '
      'turning them off brings the controls back with the same values (E1; '
      'critique 2026-09-30)', (tester, env) async {
    final ids = await _seed(env);
    await pumpLibraryScreen(tester, env, _screen(ids.subId));

    expect(find.byType(MxSegmentedTray<NewCardOrder>), findsNothing);
    expect(find.byType(MxOptionRow), findsNothing);

    await tester.tap(find.byType(MxToggle));
    await tester.pump();
    expect(tester.widget<MxStepper>(find.byType(MxStepper)).value, 20);
    final tray = tester.widget<MxSegmentedTray<NewCardOrder>>(
      find.byType(MxSegmentedTray<NewCardOrder>),
    );
    expect(tray.selected, NewCardOrder.created);
    expect(tray.onSelected, isNotNull);
  });

  libraryTest('a typed 250 is refused under the stepper and Save waits '
      '(E1)', (tester, env) async {
    final ids = await _seed(
      env,
      rootConfig: '{"card_limit":50,"new_card_order":"random"}',
    );
    await pumpLibraryScreen(tester, env, _screen(ids.subId));

    await tester.tap(find.byKey(_valueKey));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '250');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text(_en.settingsCardLimitInvalid(1, 200)), findsOneWidget);
    expect(find.text(_en.studyOptionsFixLimit), findsOneWidget);
    expect(_save(tester).onPressed, isNull);
  });

  libraryTest('a failed save names what the deck still uses; Retry save '
      'writes it (E4)', (tester, env) async {
    final ids = await _seed(env);
    final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db))
      ..isFailing = true;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(ids.subId),
      overrides: [settingsRepositoryProvider.overrideWithValue(store)],
    );
    await tester.tap(find.byType(MxToggle));
    await tester.pump();
    await tester.tap(find.byTooltip(_en.settingsMoreCards));
    await tester.pump();
    await tester.tap(find.text(_en.cardSave));
    await tester.pumpAndSettle();

    expect(
      find.text(
        _en.studyOptionsSaveFailed(20, _en.studyOptionsOrderCreatedShort),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('memox.sqlite'), findsNothing);

    store.isFailing = false;
    await tester.tap(find.text(_en.cardRetrySave));
    await tester.pumpAndSettle();
    expect(find.text(_en.studyOptionsSaved), findsOneWidget);
  });

  libraryTest('an override that cannot be read is named, and Save replaces '
      'it', (tester, env) async {
    final ids = await _seed(env, rootConfig: '{not json');
    await pumpLibraryScreen(tester, env, _screen(ids.subId));

    expect(find.byType(MxInlineBanner), findsOneWidget);
    expect(_save(tester).onPressed, isNotNull);
  });

  libraryTest('a deck gone to the Trash shows the gone state with Back '
      '(spec §6)', (tester, env) async {
    final ids = await _seed(env);
    await env.decks.deleteDeck(deckId: ids.subId);
    await pumpLibraryScreen(tester, env, _screen(ids.subId));

    expect(find.text(_en.deckGoneTitle), findsOneWidget);
    expect(find.text(_en.commonBack), findsOneWidget);
  });

  libraryTest('a failed read shows the error with Retry and no invented '
      'value', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _screen('any'),
      overrides: [
        studyOptionsProvider(
          'any',
        ).overrideWith((ref) => Stream.error(FlakySettingsRepository.failure)),
      ],
    );

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.byKey(_valueKey), findsNothing);
  });

  libraryTest('before the first read the screen shows skeleton rows and no '
      'Save (loading)', (tester, env) async {
    final never = StreamController<Never>();
    addTearDown(never.close);
    await pumpLibraryScreen(
      tester,
      env,
      _screen('any'),
      overrides: [
        studyOptionsProvider('any').overrideWith((ref) => never.stream),
      ],
    );

    expect(find.byType(MxSkeletonList), findsOneWidget);
    expect(find.text(_en.cardSave), findsNothing);
  });
}
