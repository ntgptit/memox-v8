import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/presentation/screens/monitoring_screen.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';

import 'library_harness.dart';
import 'monitoring_fakes.dart';

List<Override> monitoringOverrides(FakeMonitoringRepository repository) => [
  monitoringRepositoryProvider.overrideWithValue(repository),
];

/// Screen 28's list over [repository], on the library harness.
Future<void> pumpMonitoring(
  WidgetTester tester,
  LibraryEnv env,
  FakeMonitoringRepository repository, {
  ValueChanged<String>? onOpenServerLog,
  ValueChanged<String>? onOpenPendingLog,
  double textScale = 1,
  Locale locale = const Locale('en'),
}) => pumpLibraryScreen(
  tester,
  env,
  MonitoringScreen(
    onOpenServerLog: onOpenServerLog ?? (_) {},
    onOpenPendingLog: onOpenPendingLog ?? (_) {},
  ),
  overrides: monitoringOverrides(repository),
  textScale: textScale,
  locale: locale,
);

Future<void> settleMonitoring(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

/// Opens the Not sent tab. Its skeleton pulses for ever until the buffer
/// answers, so this never waits for the animations to end.
Future<void> openNotSentTab(WidgetTester tester) async {
  await tester.tap(find.textContaining('Not sent ('));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Taps the filter chip whose label holds [label], scrolling it in first.
Future<void> tapMonitoringChip(WidgetTester tester, String label) async {
  final chip = find.descendant(
    of: find.byType(MxChipTrigger),
    matching: find.textContaining(label),
  );
  await tester.ensureVisible(chip);
  await tester.tap(chip);
  await tester.pumpAndSettle();
}
