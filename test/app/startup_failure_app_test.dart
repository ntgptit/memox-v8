import 'dart:io';
import 'dart:ui';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/app_bootstrap.dart';
import 'package:memox/app/app_root.dart';
import 'package:memox/app/startup_failure_app.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/network/supabase_config.dart';
import 'package:memox/core/network/di/network_providers.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';

import '../support/fake_day_clock.dart';
import '../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));
const _disabled = SupabaseConfig(url: '', publishableKey: '');

StartupDatabaseUnavailable _failure({(int, int)? migration}) =>
    StartupDatabaseUnavailable(
      const FileSystemException('full'),
      StackTrace.empty,
      migration: migration,
    );

// DEV-195: the recovery screen says nothing was deleted, offers Retry and
// Send report, and names a stopped upgrade step; Retry on AppRoot runs the
// start again and swaps in the app once the file opens.
void main() {
  testWidgets('the recovery screen shows the title, the body, Retry and Send '
      'report, and confirms a queued report', (tester) async {
    var retries = 0;
    var reports = 0;
    Widget app({bool isReportQueued = false}) => StartupFailureApp(
      failure: _failure(),
      onRetry: () => retries++,
      onSendReport: () => reports++,
      isReportQueued: isReportQueued,
    );
    await tester.pumpWidget(app());

    expect(find.text(_en.startupDatabaseErrorTitle), findsOneWidget);
    expect(find.text(_en.startupDatabaseErrorBody), findsOneWidget);
    expect(find.byType(MxErrorState), findsOneWidget);

    await tester.tap(find.text(_en.commonRetry));
    await tester.tap(find.text(_en.startupSendReport));
    expect(retries, 1);
    expect(reports, 1);

    await tester.pumpWidget(app(isReportQueued: true));
    expect(find.text(_en.startupReportQueued), findsOneWidget);
    expect(find.text(_en.startupSendReport), findsNothing);
  });

  testWidgets('an open that stopped inside an upgrade step names it', (
    tester,
  ) async {
    await tester.pumpWidget(
      StartupFailureApp(
        failure: _failure(migration: (13, 14)),
        onRetry: () {},
        onSendReport: () {},
      ),
    );

    expect(
      find.textContaining(_en.startupDatabaseMigrationHint(13, 14)),
      findsOneWidget,
    );
  });

  testWidgets('Retry on AppRoot runs the start again and swaps in the app '
      'once the file opens', (tester) async {
    final root = Directory.systemTemp.createTempSync('memox_root');
    addTearDown(() => root.deleteSync(recursive: true));
    // A regular file where the directory should be: the open fails until
    // it is removed.
    final blocker = File('${root.path}/blocker')..createSync();
    final file = File('${blocker.path}/app.db');
    var opens = 0;
    final container = ProviderContainer(
      overrides: [
        supabaseConfigProvider.overrideWithValue(_disabled),
        accountCoordinatorProvider.overrideWithValue(null),
        dayClockProvider.overrideWithValue(FakeDayClock(libraryToday)),
        databaseProvider.overrideWith((ref) {
          opens++;
          final db = AppDatabase(NativeDatabase(file));
          ref.onDispose(db.close);
          return db;
        }),
      ],
    );
    addTearDown(container.dispose);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    // startApp installs the app's logger and error routes, which a widget
    // test must give back to the binding before it pumps.
    final previous = appLogger;
    final flutterOnError = FlutterError.onError;
    final dispatcherOnError = PlatformDispatcher.instance.onError;
    final first = await startApp(container, initializeSupabase: (_) async {});
    AppLogger.install(previous);
    FlutterError.onError = flutterOnError;
    PlatformDispatcher.instance.onError = dispatcherOnError;
    expect(first, isA<StartupDatabaseUnavailable>());

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: AppRoot(initial: first),
      ),
    );
    expect(find.byType(StartupFailureApp), findsOneWidget);

    blocker.deleteSync(); // the disk is back
    await tester.tap(find.text(_en.commonRetry));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(find.byType(MemoxApp), findsOneWidget);
    expect(find.byType(StartupFailureApp), findsNothing);
    expect(opens, 2);
  });
}
