import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/study/di/study_entry_repository_provider.dart'
    show studyEntryRepositoryProvider;
import 'package:memox/features/study/di/study_session_repository_provider.dart'
    show studySessionRepositoryProvider;
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/transfer/data/repositories/transfer_file_repository_impl.dart';
import 'package:memox/features/transfer/di/transfer_file_repository_provider.dart';

import 'fake_day_clock.dart';
import 'study_entry_fixtures.dart';
import 'study_fixtures.dart';
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
      ),
      sessions = LockableSessions(studySessionRepository(db, clock.now)),
      entries = FailingEntries(studyEntryRepository(db, clock.now));

  final AppDatabase db;
  final FakeDayClock clock;
  final DeckRepository decks;
  final CardRepository cards;

  /// The app's session repository, on the fake day; a test locks it to
  /// find the database busy (UC-STUDY-001 E2).
  final LockableSessions sessions;

  /// The app's entry store, on the fake day; a test fails its openings
  /// (screen 14 startFailed).
  final FailingEntries entries;
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
  // The app's session repository reads the wall clock; the harness runs it
  // on the fake day, so a session opened in a test is today's.
  studySessionRepositoryProvider.overrideWithValue(env.sessions),
  // Openings run on the fake day, as the session store does.
  studyEntryRepositoryProvider.overrideWithValue(env.entries),
  _inlineTransferFiles,
];

/// A provider container over [env]'s backend, for a test that drives
/// providers without a widget tree. Disposed when the test ends.
ProviderContainer libraryContainer(
  LibraryEnv env, {
  List<Override> overrides = const [],
}) {
  final container = ProviderContainer(
    overrides: [..._backend(env), ...overrides],
  );
  addTearDown(container.dispose);
  return container;
}

/// The whole app over [env] on a 1080×2400 (3x) phone, or at
/// [physicalSize], settled on the Library root.
Future<void> pumpMemoxApp(
  WidgetTester tester,
  LibraryEnv env, {
  AppSettingsEntity? initialSettings,
  bool isSettled = true,
  List<Override> overrides = const [],
  Size physicalSize = const Size(1080, 2400),
  double devicePixelRatio = 3,
}) async {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = devicePixelRatio;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [..._backend(env), ...overrides],
      retry: _noRetry,
      child: MemoxApp(initialSettings: initialSettings),
    ),
  );
  if (isSettled) await tester.pumpAndSettle();
}

/// As `main.dart`: no hidden retry loop, so a failure shows as a failure.
Duration? _noRetry(int retryCount, Object error) => null;

/// Card transfer's file codecs without a background isolate, which a widget
/// test's fake clock never lets finish.
final Override _inlineTransferFiles = transferFileRepositoryProvider
    .overrideWithValue(
      TransferFileRepositoryImpl(
        run: <Q, R>(callback, message) async => callback(message),
      ),
    );
