import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import 'fake_day_clock.dart';
import 'golden_harness.dart';
import 'test_database.dart';

/// The day every Library test lives in: 2026-09-24, mid-morning local time.
final DateTime libraryToday = DateTime(2026, 9, 24, 9);

/// The real backend behind a screen: an in-memory database, a day moved by
/// hand, and the deck repository for fixtures.
final class LibraryEnv {
  LibraryEnv(this.db, this.clock) : decks = DeckRepositoryImpl(db);

  final AppDatabase db;
  final FakeDayClock clock;
  final DeckRepository decks;
}

/// A widget test over [LibraryEnv]. The widget tree is torn down before the
/// database closes, so no Drift stream outlives the test.
void libraryTest(
  String description,
  Future<void> Function(WidgetTester tester, LibraryEnv env) body,
) {
  testWidgets(description, (tester) async {
    final env = LibraryEnv(openTestDatabase(), FakeDayClock(libraryToday));
    try {
      await body(tester, env);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      await env.db.close();
    }
  });
}

List<Override> _backend(LibraryEnv env) => [
  databaseProvider.overrideWithValue(env.db),
  dayClockProvider.overrideWithValue(env.clock),
];

Widget _app(
  LibraryEnv env,
  Widget screen, {
  required Brightness brightness,
  required double textScale,
  required Locale locale,
  required List<Override> overrides,
}) => ProviderScope(
  overrides: [..._backend(env), ...overrides],
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    themeAnimationDuration: Duration.zero,
    theme: brightness == Brightness.light
        ? buildLightTheme()
        : buildDarkTheme(),
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: screen,
      ),
    ),
  ),
);

/// Pumps [screen] on a 360×800 phone over the real backend and lets its
/// first streams emit.
Future<void> pumpLibraryScreen(
  WidgetTester tester,
  LibraryEnv env,
  Widget screen, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
  Locale locale = const Locale('en'),
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _app(
      env,
      screen,
      brightness: brightness,
      textScale: textScale,
      locale: locale,
      overrides: overrides,
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// [screen] over the real backend at 1080×2400 (3x), inside the golden
/// boundary. Compare with [expectBoundaryGolden] inside [withRealShadows].
Future<void> pumpLibraryGolden(
  WidgetTester tester,
  LibraryEnv env,
  Widget screen,
  Brightness brightness, {
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(
      key: goldenBoundaryKey,
      child: _app(
        env,
        screen,
        brightness: brightness,
        textScale: 1,
        locale: const Locale('en'),
        overrides: overrides,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}
