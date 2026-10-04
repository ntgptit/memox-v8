import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/models/log_window_model.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import '../../../support/library_harness.dart';
import '../../../support/monitoring_fakes.dart';
import '../../../support/monitoring_screen_harness.dart';

// Monitoring spec §3.2: the filter chips and their sheets.
void main() {
  libraryTest('the Level chip shows its choice and its sheet applies it', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()..autoPage = pageOf(1);
    await pumpMonitoring(tester, env, repository);
    // One or two choices are named, three or more counted (critique
    // 2026-09-30 part 3b).
    expect(find.text('Level · Warning, Error'), findsOneWidget);
    expect(find.text('Status · Open'), findsOneWidget);

    await tapMonitoringChip(tester, 'Level');
    await tester.tap(find.byType(MxToggle).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.text('Level · 3'), findsOneWidget);
    expect(repository.lastQuery.filter.levels, {
      LogLevel.info,
      LogLevel.warning,
      LogLevel.error,
    });
    expect(repository.lastQuery.filter.statuses, isEmpty);
    expect(find.text('Status'), findsOneWidget);
  });

  // Impeccable 2026-09-29 F8: "Level · 2" names the levels when read.
  libraryTest('a chip with several choices names them to a screen reader', (
    tester,
    env,
  ) async {
    final semantics = tester.ensureSemantics();
    final repository = FakeMonitoringRepository()..autoPage = pageOf(1);
    await pumpMonitoring(tester, env, repository);

    expect(find.bySemanticsLabel('Level · Warning, Error'), findsOneWidget);
    expect(find.bySemanticsLabel('Status · Open'), findsOneWidget);
    semantics.dispose();
  });

  libraryTest('Reset puts a sheet back to its default, Apply keeps it', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()..autoPage = pageOf(1);
    await pumpMonitoring(tester, env, repository);

    await tapMonitoringChip(tester, 'Status');
    await tester.tap(find.byType(MxToggle).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(repository.queries, hasLength(1), reason: 'the default is kept');
    expect(find.text('Status · Open'), findsOneWidget);
  });

  libraryTest('the Category sheet lists every LogCategory value', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()..autoPage = pageOf(1);
    await pumpMonitoring(tester, env, repository);

    await tapMonitoringChip(tester, 'Category');

    expect(find.byType(MxToggle), findsNWidgets(LogCategory.values.length));
    for (final category in LogCategory.values) {
      expect(find.text(category.name), findsOneWidget);
    }
  });

  libraryTest('the Time sheet picks one window', (tester, env) async {
    final repository = FakeMonitoringRepository()..autoPage = pageOf(1);
    await pumpMonitoring(tester, env, repository);

    await tapMonitoringChip(tester, 'Time');
    await tester.tap(find.text('Last 24 hours'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(repository.lastQuery.filter.window, LogWindow.day);
    expect(find.text('Time · Last 24 hours'), findsOneWidget);
  });

  libraryTest('the device and user sheet sets both, and refuses a bad user', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()..autoPage = pageOf(1);
    await pumpMonitoring(tester, env, repository);

    await tapMonitoringChip(tester, 'Device');
    await tester.enterText(find.byType(TextField).at(1), 'dev-1');
    await tester.enterText(find.byType(TextField).at(2), 'not a uuid');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(find.text("That isn't a valid user ID."), findsOneWidget);
    expect(repository.queries, hasLength(1));

    const user = '00000000-0000-0000-0000-00000000dead';
    await tester.enterText(find.byType(TextField).at(2), user);
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(repository.lastQuery.filter.deviceId, 'dev-1');
    expect(repository.lastQuery.filter.userId, user);
    expect(find.text('Device / user · 2'), findsOneWidget);
  });
}
