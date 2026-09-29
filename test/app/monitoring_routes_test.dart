import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/features/monitoring/di/is_admin_provider.dart';
import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/domain/models/log_page_model.dart';
import 'package:memox/features/monitoring/presentation/screens/monitoring_detail_screen.dart';
import 'package:memox/features/monitoring/presentation/screens/monitoring_screen.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';

import '../support/library_harness.dart';
import '../support/monitoring_fakes.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Finder _tab(String label) =>
    find.descendant(of: find.byType(MxBottomNav), matching: find.text(label));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

/// The routes of Monitoring (screen 28): an admin's pages on the root
/// navigator, under Settings.
void main() {
  test('a log\'s path names it, and the buffer is a query', () {
    expect(AppRoutes.settingsMonitoringLog('abc'), '/settings/monitoring/abc');
    expect(
      AppRoutes.settingsMonitoringLog('abc', isLocal: true),
      '/settings/monitoring/abc?local=1',
    );
    expect(AppRoutes.isLocalLog({'local': '1'}), isTrue);
    expect(AppRoutes.isLocalLog({}), isFalse);
    expect(AppRoutes.isLocalLog({'local': '0'}), isFalse);
  });

  libraryTest('Settings opens Monitoring above the shell, a row opens its '
      'detail, and Back climbs one page at a time', (tester, env) async {
    final repository = FakeMonitoringRepository()
      ..autoPage = LogPage(items: [summary('a', event: 'sync.push_failed')])
      ..servers['a'] = record('a');
    await pumpMemoxApp(
      tester,
      env,
      overrides: [
        isAdminProvider.overrideWithValue(true),
        monitoringRepositoryProvider.overrideWithValue(repository),
      ],
    );
    await tester.tap(_tab(_en.navSettings));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text(_en.settingsMonitoring), 200);
    // Clear of the bottom bar, which the row was scrolled under.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.settingsMonitoring));
    await _settle(tester);

    expect(find.byType(MonitoringScreen), findsOneWidget);
    expect(find.byType(MxBottomNav), findsNothing);

    await tester.tap(find.text('sync.push_failed'));
    await _settle(tester);
    expect(find.byType(MonitoringDetailScreen), findsOneWidget);

    await tester.tap(find.byTooltip(_en.commonBack));
    await _settle(tester);
    expect(find.byType(MonitoringScreen), findsOneWidget);
    expect(find.text('sync.push_failed'), findsOneWidget);
    expect(repository.queries, hasLength(1), reason: 'the pages are kept');

    await tester.tap(find.byTooltip(_en.commonBack));
    await _settle(tester);
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byType(MxBottomNav), findsOneWidget);
  });

  libraryTest('a deep link to a log opens its detail, and Back lands on '
      'Monitoring', (tester, env) async {
    final repository = FakeMonitoringRepository()
      ..autoPage = pageOf(1)
      ..pendings['a'] = record('a', status: null, event: 'sync.failed');
    await pumpMemoxApp(
      tester,
      env,
      overrides: [
        isAdminProvider.overrideWithValue(true),
        monitoringRepositoryProvider.overrideWithValue(repository),
      ],
    );

    GoRouter.of(tester.element(find.byType(MxBottomNav)))
        .go(AppRoutes.settingsMonitoringLog('a', isLocal: true));
    await _settle(tester);

    final detail = tester.widget<MonitoringDetailScreen>(
      find.byType(MonitoringDetailScreen),
    );
    expect((detail.logId, detail.isLocal), ('a', true));

    await tester.tap(find.byTooltip(_en.commonBack));
    await _settle(tester);
    expect(find.byType(MonitoringScreen), findsOneWidget);
  });

  // Codex review on PR #160: the entry is hidden, but a deep link must not
  // reach the device buffer either, which no server check guards.
  for (final (name, path) in [
    ('the list', AppRoutes.settingsMonitoring),
    ('a buffered log', AppRoutes.settingsMonitoringLog('a', isLocal: true)),
  ]) {
    libraryTest('a deep link to $name from an account that is not an admin '
        'builds nothing and says only an admin can see this', (
      tester,
      env,
    ) async {
      final repository = FakeMonitoringRepository()
        ..pendings['a'] = record('a', status: null);
      await pumpMemoxApp(
        tester,
        env,
        overrides: [
          isAdminProvider.overrideWithValue(false),
          monitoringRepositoryProvider.overrideWithValue(repository),
        ],
      );

      GoRouter.of(tester.element(find.byType(MxBottomNav))).go(path);
      await _settle(tester);

      expect(find.text(_en.monitoringNotAdminTitle), findsOneWidget);
      expect(find.byType(MonitoringScreen), findsNothing);
      expect(find.byType(MonitoringDetailScreen), findsNothing);
      expect(find.text('sync.push_failed'), findsNothing);
      expect(repository.queries, isEmpty);
    });
  }
}
