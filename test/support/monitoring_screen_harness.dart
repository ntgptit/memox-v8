import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/domain/models/pending_logs_model.dart';
import 'package:memox/features/monitoring/presentation/screens/monitoring_screen.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

import 'library_harness.dart';
import 'monitoring_fakes.dart';
import 'widget_harness.dart';

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
  Widget? pendingHeader,
  double textScale = 1,
  Locale locale = const Locale('en'),
}) => pumpLibraryScreen(
  tester,
  env,
  MonitoringScreen(
    onOpenServerLog: onOpenServerLog ?? (_) {},
    onOpenPendingLog: onOpenPendingLog ?? (_) {},
    pendingHeader: pendingHeader,
  ),
  overrides: monitoringOverrides(repository),
  textScale: textScale,
  locale: locale,
);

Future<void> settleMonitoring(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

/// The app bar's refresh, which a screen reader can reach where the drag
/// down is out of reach (audit 2026-10-17 SET-11).
final monitoringRefreshAction = find.byWidgetPredicate(
  (widget) => widget is MxIconButton && widget.semanticLabel == 'Refresh',
);

/// Opens the Not sent tab. Its skeleton pulses for ever until the buffer
/// answers, so this never waits for the animations to end.
Future<void> openNotSentTab(WidgetTester tester) async {
  await tester.tap(find.textContaining('Not sent ('));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Feeds one unsent log to the pending watch and opens the Not sent tab on
/// it.
Future<void> openNotSentTabWithOne(
  WidgetTester tester,
  FakeMonitoringRepository repository,
) async {
  repository.watches.single.feed.add(
    PendingLogs(items: [summary('p1', status: null)], total: 1),
  );
  await settleMonitoring(tester);
  await tester.tap(find.text('Not sent (1)'));
  await tester.pumpAndSettle();
}

/// Taps the filter chip whose label holds [label], scrolling it in first.
Future<void> tapMonitoringChip(WidgetTester tester, String label) async {
  final chip = find.descendant(
    of: find.byType(MxChipTrigger),
    matching: find.textContaining(label),
  );
  await tapVisible(tester, chip);
  await tester.pumpAndSettle();
}
