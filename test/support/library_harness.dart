import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_add_fab_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_deck_app_bar_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_deck_breadcrumb_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_section_widget.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/features/deck/presentation/screens/deck_algorithm_screen.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_level_screen.dart';

import 'fake_day_clock.dart';
import 'golden_harness.dart';
import 'test_database.dart';

/// The day every Library test lives in: 2026-09-24, mid-morning local time.
final DateTime libraryToday = DateTime(2026, 9, 24, 9);

/// The real backend behind a screen: an in-memory database, a day moved by
/// hand, and the deck repository for fixtures.
final class LibraryEnv {
  LibraryEnv(this.db, this.clock)
    : decks = DeckRepositoryImpl(db),
      cards = CardRepositoryImpl(
        db,
        ScheduleRepositoryImpl(db),
        TagRepositoryImpl(db),
      );

  final AppDatabase db;
  final FakeDayClock clock;
  final DeckRepository decks;
  final CardRepository cards;
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

/// A provider container over [env]'s backend, for a test that drives
/// providers without a widget tree. Disposed when the test ends.
ProviderContainer libraryContainer(LibraryEnv env) {
  final container = ProviderContainer(overrides: _backend(env));
  addTearDown(container.dispose);
  return container;
}

Widget _app(
  LibraryEnv env,
  Widget screen, {
  required Brightness brightness,
  required double textScale,
  required Locale locale,
  required List<Override> overrides,
}) => ProviderScope(
  overrides: [..._backend(env), ...overrides],
  retry: _noRetry,
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
  double textScale = 1,
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
        textScale: textScale,
        locale: const Locale('en'),
        overrides: overrides,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// A deck level whose navigation goes nowhere, for screen tests: the Library
/// root when [deckId] is null.
DeckLevelScreen deckScreen({
  String? deckId,
  ValueChanged<String>? onOpenDeck,
  ValueChanged<String?>? onOpenAncestor,
  ValueChanged<String>? onAddCard,
  Widget Function(DeckView view)? cardContent,
  Widget Function(DeckView view, Widget back, Widget deckActions)? cardAppBar,
  Widget Function(String deckId, Widget breadcrumb)? cardBreadcrumb,
  Widget Function(String deckId)? cardFab,
  VoidCallback? onSearch,
  ValueChanged<String>? onOpenAlgorithm,
  ValueChanged<String>? onOpenStudy,
}) => DeckLevelScreen(
  deckId: deckId,
  onOpenDeck: onOpenDeck ?? (_) {},
  onOpenAncestor: onOpenAncestor ?? (_) {},
  onSearch: onSearch ?? () {},
  onOpenAlgorithm: onOpenAlgorithm ?? (_) {},
  onOpenStudy: onOpenStudy ?? (_) {},
  onAddCard: onAddCard ?? (_) {},
  cardContent: cardContent ?? (_) => const SizedBox.shrink(),
  cardAppBar:
      cardAppBar ??
      (view, back, actions) => MxAppBar(
        title: view.deck.name,
        density: MxAppBarDensity.content,
        leading: back,
        actions: [actions],
      ),
  cardBreadcrumb: cardBreadcrumb ?? (_, breadcrumb) => breadcrumb,
  cardFab: cardFab ?? (_) => const SizedBox.shrink(),
);

/// Screen 07: the open deck as `app/` composes it (A14).
DeckLevelScreen cardDeckScreen(String deckId) => deckScreen(
  deckId: deckId,
  cardContent: (view) => CardListSectionWidget(
    deckId: view.deck.id,
    algorithm: 'Eight boxes',
    onAddCard: () {},
    onOpenCard: (_) {},
  ),
  cardAppBar: (view, back, actions) =>
      CardDeckAppBarWidget(view: view, back: back, deckActions: actions),
  cardBreadcrumb: (id, child) =>
      CardDeckBreadcrumbWidget(deckId: id, child: child),
  cardFab: (id) => CardAddFabWidget(deckId: id, onAddCard: () {}),
);

/// Screen 02 for [deckId], with its breadcrumb callback.
DeckAlgorithmScreen deckAlgorithmScreen({
  required String deckId,
  ValueChanged<String?>? onOpenAncestor,
}) => DeckAlgorithmScreen(
  deckId: deckId,
  onOpenAncestor: onOpenAncestor ?? (_) {},
);

/// The whole app over [env] on a 1080×2400 (3x) phone, settled on the
/// Library root.
Future<void> pumpMemoxApp(WidgetTester tester, LibraryEnv env) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: _backend(env),
      retry: _noRetry,
      child: const MemoxApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// As `main.dart`: no hidden retry loop, so a failure shows as a failure.
Duration? _noRetry(int retryCount, Object error) => null;
