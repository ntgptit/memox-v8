@Tags(['golden'])
library;

import 'dart:async';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/presentation/providers/study_options_provider.dart';
import 'package:memox/features/settings/presentation/screens/study_options_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/settings_fakes.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// The path kit 15 draws; `app/` composes it from the deck feature (C6).
StudyOptionsScreen _screen(String deckId) => StudyOptionsScreen(
  deckId: deckId,
  breadcrumb: MxBreadcrumb(
    segments: [
      MxBreadcrumbSegment(label: _en.navLibrary),
      const MxBreadcrumbSegment(label: 'Korean TOPIK I'),
      const MxBreadcrumbSegment(label: 'Từ vựng'),
      MxBreadcrumbSegment(label: _en.deckStudyOptions),
    ],
  ),
);

const _override = '{"card_limit":50,"new_card_order":"random"}';

/// 한국어 TOPIK I › Từ vựng, as the kit draws it; [rootConfig] is the
/// root's override.
Future<String> _seed(LibraryEnv env, {String? rootConfig}) async {
  final root = await env.decks.root('Korean TOPIK I');
  final sub = await env.decks.sub(root.id, 'Từ vựng');
  if (rootConfig != null) {
    await env.db.customUpdate(
      'UPDATE deck SET study_config = ? WHERE id = ?',
      variables: [Variable(rootConfig), Variable(root.id)],
    );
  }
  return sub.id;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> shot(WidgetTester tester, String name) => expectBoundaryGolden(
      tester,
      'goldens/study_options_${name}_$theme.png',
    );

    libraryTest('study options, override, $theme', (tester, env) async {
      final deckId = await _seed(env, rootConfig: _override);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(deckId), brightness);
        await shot(tester, 'override');
      });
    });

    libraryTest('study options, defaults, $theme', (tester, env) async {
      final deckId = await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(deckId), brightness);
        await shot(tester, 'defaults');
      });
    });

    libraryTest('study options, invalid, $theme', (tester, env) async {
      final deckId = await _seed(env, rootConfig: _override);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(deckId), brightness);
        await tester.tap(find.byKey(const ValueKey('mx-stepper-value')));
        await tester.pump();
        await tester.enterText(find.byType(TextField), '0');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await _settle(tester);
        await shot(tester, 'invalid');
      });
    });

    libraryTest('study options, saving, $theme', (tester, env) async {
      final deckId = await _seed(env, rootConfig: _override);
      final gate = Completer<void>();
      final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db))
        ..hold = gate;
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          _screen(deckId),
          brightness,
          overrides: [settingsRepositoryProvider.overrideWithValue(store)],
        );
        await tester.tap(find.byTooltip(_en.settingsMoreCards));
        await tester.pump();
        await tester.tap(find.text(_en.cardSave));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await shot(tester, 'saving');
      });
      store.hold = null;
      gate.complete();
      await _settle(tester);
    });

    libraryTest('study options, saved, $theme', (tester, env) async {
      final deckId = await _seed(env, rootConfig: _override);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(deckId), brightness);
        await tester.tap(find.byTooltip(_en.settingsMoreCards));
        await tester.pump();
        await tester.tap(find.text(_en.cardSave));
        await _settle(tester);
        await _settle(tester);
        await shot(tester, 'saved');
      });
    });

    libraryTest('study options, save failed, $theme', (tester, env) async {
      final deckId = await _seed(env);
      final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db))
        ..isFailing = true;
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          _screen(deckId),
          brightness,
          overrides: [settingsRepositoryProvider.overrideWithValue(store)],
        );
        await tester.tap(find.byType(MxToggle));
        await tester.pump();
        await tester.tap(find.byTooltip(_en.settingsMoreCards));
        await tester.pump();
        await tester.tap(find.text(_en.cardSave));
        await _settle(tester);
        await shot(tester, 'save_failed');
      });
    });

    libraryTest('study options, loading, $theme', (tester, env) async {
      final never = StreamController<Never>();
      addTearDown(never.close);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          _screen('any'),
          brightness,
          overrides: [
            studyOptionsProvider('any').overrideWith((ref) => never.stream),
          ],
        );
        await shot(tester, 'loading');
      });
    });
  }
}
