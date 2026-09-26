import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';

import '../support/card_fixtures.dart';
import '../support/deck_fixtures.dart';
import '../support/library_harness.dart';
import '../support/study_fixtures.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _pumpApp(
  WidgetTester tester,
  LibraryEnv env, {
  bool hasGallery = true,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(env.db),
        dayClockProvider.overrideWithValue(env.clock),
      ],
      child: MemoxApp(hasGallery: hasGallery),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _barTitle(String title, {bool skipOffstage = true}) => find.descendant(
  of: find.byType(MxAppBar, skipOffstage: skipOffstage),
  matching: find.text(title, skipOffstage: skipOffstage),
  skipOffstage: skipOffstage,
);

MxBottomNav _nav(WidgetTester tester) =>
    tester.widget<MxBottomNav>(find.byType(MxBottomNav));

/// A tab label inside the bottom nav; the app bar may show the same text.
Finder _tab(String label) =>
    find.descendant(of: find.byType(MxBottomNav), matching: find.text(label));

void main() {
  libraryTest('cold start lands on Library', (tester, env) async {
    await _pumpApp(tester, env);

    expect(_barTitle(_en.navLibrary), findsOneWidget);
    expect(_nav(tester).selectedIndex, 0);
  });

  libraryTest('no debug banner over the app', (tester, env) async {
    await _pumpApp(tester, env);

    expect(
      tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .debugShowCheckedModeBanner,
      isFalse,
    );
  });

  libraryTest('four tabs in navigation.md order', (tester, env) async {
    await _pumpApp(tester, env);

    expect(_nav(tester).destinations.map((d) => d.label), [
      _en.navLibrary,
      _en.navStudy,
      _en.navProgress,
      _en.navSettings,
    ]);
  });

  libraryTest('switching tabs keeps the other branch alive', (
    tester,
    env,
  ) async {
    await _pumpApp(tester, env);
    await tester.tap(_tab(_en.navStudy));
    await tester.pumpAndSettle();

    expect(_nav(tester).selectedIndex, 1);
    expect(_barTitle(_en.navStudy), findsOneWidget);
    expect(_barTitle(_en.navLibrary, skipOffstage: false), findsOneWidget);
  });

  libraryTest('re-tapping the current tab keeps it selected', (
    tester,
    env,
  ) async {
    await _pumpApp(tester, env);
    await tester.tap(_tab(_en.navLibrary));
    await tester.pumpAndSettle();

    expect(_nav(tester).selectedIndex, 0);
    expect(tester.takeException(), isNull);
  });

  libraryTest('Library opens on its screen; the other tabs are placeholders', (
    tester,
    env,
  ) async {
    await _pumpApp(tester, env);
    expect(find.text(_en.libraryEmptyTitle), findsOneWidget);
    expect(find.text(_en.placeholderTitle), findsNothing);

    await tester.tap(_tab(_en.navStudy));
    await tester.pumpAndSettle();
    expect(find.text(_en.placeholderTitle), findsOneWidget);
  });

  libraryTest('Vietnamese device locale gives Vietnamese tabs', (
    tester,
    env,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('vi')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await _pumpApp(tester, env);
    final vi = lookupAppLocalizations(const Locale('vi'));

    expect(_nav(tester).destinations.map((d) => d.label), [
      vi.navLibrary,
      vi.navStudy,
      vi.navProgress,
      vi.navSettings,
    ]);
  });

  libraryTest('an unsupported locale falls back to English', (
    tester,
    env,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await _pumpApp(tester, env);

    expect(_barTitle(_en.navLibrary), findsOneWidget);
  });

  libraryTest('dark system theme gives the dark page ground', (
    tester,
    env,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await _pumpApp(tester, env);

    expect(
      tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor,
      AppColorSchemes.dark.surface,
    );
  });

  libraryTest('the status inset is consumed once, above the tab app bar', (
    tester,
    env,
  ) async {
    tester.view.padding = const FakeViewPadding(top: 72, bottom: 60);
    addTearDown(tester.view.resetPadding);
    await _pumpApp(tester, env);

    // 72 physical px at 3x = 24 logical.
    expect(tester.getTopLeft(find.byType(MxAppBar)).dy, 24);
    expect(tester.getSize(find.byType(MxAppBar)).height, 56);
  });

  libraryTest('Settings offers the gallery in debug builds', (
    tester,
    env,
  ) async {
    await _pumpApp(tester, env);
    await tester.tap(_tab(_en.navSettings));
    await tester.pumpAndSettle();

    expect(find.byTooltip(_en.openGallery), findsOneWidget);
  });

  libraryTest('without the gallery there is no route and no action', (
    tester,
    env,
  ) async {
    await _pumpApp(tester, env, hasGallery: false);
    await tester.tap(_tab(_en.navSettings));
    await tester.pumpAndSettle();

    expect(find.byTooltip(_en.openGallery), findsNothing);
    final router = buildAppRouter(hasGallery: false);
    addTearDown(router.dispose);
    expect(
      router.configuration.routes.whereType<GoRoute>().map((r) => r.path),
      isNot(contains(AppRoutes.gallery)),
    );
  });

  libraryTest("the app closes an earlier day's open session as interrupted "
      'when it starts (BR-STUDY-072, FE-A6 D9)', (tester, env) async {
    final root = await env.decks.root('Korean');
    await insertCard(env.db, id: 'c1', deckId: root.id);
    await studyEntryRepository(
      env.db,
      () => DateTime(2026, 9, 23, 20),
    ).openLearningSession(deckId: root.id);
    await _pumpApp(tester, env);

    final session = await env.db
        .customSelect('SELECT status, end_reason FROM study_session')
        .getSingle();
    expect(
      (session.read<String>('status'), session.read<String>('end_reason')),
      ('abandoned', 'interrupted'),
    );
  });
}
