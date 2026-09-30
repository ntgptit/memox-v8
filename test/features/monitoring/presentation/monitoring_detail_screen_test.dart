import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/presentation/screens/monitoring_detail_screen.dart';
import 'package:memox/features/monitoring/presentation/widgets/support/monitoring_labels_widget.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

import '../../../support/library_harness.dart';
import '../../../support/monitoring_fakes.dart';

// Monitoring spec §3.3, §3.4, §5: the detail page and its triage.

List<Override> _overrides(FakeMonitoringRepository repository) => [
  monitoringRepositoryProvider.overrideWithValue(repository),
];

/// The page on a tall phone, so every card is built: a list builds only
/// what is near the screen.
Future<void> _pump(
  WidgetTester tester,
  LibraryEnv env,
  FakeMonitoringRepository repository, {
  bool isLocal = false,
  Locale locale = const Locale('en'),
}) async {
  await pumpLibraryScreen(
    tester,
    env,
    MonitoringDetailScreen(logId: 'a', isLocal: isLocal),
    overrides: _overrides(repository),
    locale: locale,
  );
  tester.view.physicalSize = const Size(360, 4000);
  await tester.pump();
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Marks the log fixed through the sheet, with [note].
Future<void> _markFixed(WidgetTester tester, {String note = ''}) async {
  await tester.tap(find.widgetWithText(MxButton, 'Mark fixed'));
  await tester.pumpAndSettle();
  if (note.isNotEmpty) {
    await tester.enterText(find.byType(TextField), note);
  }
  await tester.tap(find.widgetWithText(MxButton, 'Mark fixed').last);
  await _settle(tester);
}

void main() {
  libraryTest('an open error shows its summary, message, error, stack '
      'trace and context', (tester, env) async {
    final repository = FakeMonitoringRepository()..servers['a'] = record('a');

    await _pump(tester, env, repository);

    expect(find.text('sync.push_failed'), findsOneWidget);
    expect(find.text('Event'), findsNothing);
    expect(find.text('Error'), findsWidgets);
    expect(find.text('Sep 26, 2026 08:30:15'), findsOneWidget);
    expect(find.widgetWithText(MxBadge, 'Open'), findsOneWidget);
    expect(find.text('sync'), findsOneWidget);
    expect(find.text(monitoringIdText('device-1')), findsOneWidget);
    expect(find.text('8.0.0 (12)'), findsOneWidget);
    expect(find.text('android 14'), findsOneWidget);
    expect(find.text('The server refused the push'), findsOneWidget);
    expect(find.textContaining('PostgrestException'), findsWidgets);
    expect(find.textContaining('SyncCoordinator.runOnce'), findsOneWidget);
    expect(find.textContaining('"entity": "deck"'), findsOneWidget);
    expect(find.widgetWithText(MxButton, 'Mark fixed'), findsOneWidget);
  });

  libraryTest('the stack trace and context are set in the code style, '
      'selectable', (tester, env) async {
    final repository = FakeMonitoringRepository()..servers['a'] = record('a');

    await _pump(tester, env, repository);

    final trace = tester.widget<SelectableText>(
      find.widgetWithText(
        SelectableText,
        '#0      SyncCoordinator.runOnce (sync_coordinator.dart:42)',
      ),
    );
    expect(trace.style!.fontFamily, 'monospace');
    expect(find.byType(SelectableText), findsNWidgets(4));
  });

  // Impeccable 2026-09-29 F1: what triage reads comes first.
  libraryTest('the message, error and trace come before the details', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()..servers['a'] = record('a');

    await _pump(tester, env, repository);

    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(top('MESSAGE'), lessThan(top('ERROR')));
    expect(top('ERROR'), lessThan(top('STACK TRACE')));
    expect(top('CONTEXT'), lessThan(top('DETAILS')));
    expect(top('Open'), lessThan(top('MESSAGE')));
  });

  // Impeccable 2026-09-29 F6: the type reads apart from its message.
  libraryTest('the error card sets its type apart from its message', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()..servers['a'] = record('a');

    await _pump(tester, env, repository);

    final card = tester.widget<SelectableText>(
      find.widgetWithText(
        SelectableText,
        'PostgrestException\nPostgrestException(message: NOT_AUTHENTICATED)',
      ),
    );
    final type = card.textSpan!.children!.first as TextSpan;
    expect(type.text, 'PostgrestException');
    expect(type.style!.fontWeight, FontWeight.w600);
  });

  // Impeccable 2026-09-29 F6: a new frame reads apart from a wrapped line.
  libraryTest('a stack trace marks where each frame starts', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()
      ..servers['a'] = record(
        'a',
        stackTrace:
            '#0      a (a.dart:1)\n<asynchronous suspension>\n#1      b',
      );

    await _pump(tester, env, repository);

    final trace = tester.widget<SelectableText>(
      find.widgetWithText(
        SelectableText,
        '#0      a (a.dart:1)\n<asynchronous suspension>\n#1      b',
      ),
    );
    final spans = <TextSpan>[];
    trace.textSpan!.visitChildren((span) {
      if (span is TextSpan && span.text != null) spans.add(span);
      return true;
    });
    final base = trace.style!.color;
    Color? colorOf(String text) =>
        spans.firstWhere((span) => span.text == text).style?.color ?? base;
    expect(colorOf('#0'), isNot(base));
    expect(colorOf('#1'), colorOf('#0'));
    expect(colorOf('      a (a.dart:1)'), base);
  });

  // Impeccable 2026-09-29 F2: an id is copied alone, for the filter.
  libraryTest('the device and user rows each copy their id', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()..servers['a'] = record('a');
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _pump(tester, env, repository);

    await tester.tap(find.byTooltip('Copy device ID'));
    await _settle(tester);
    await tester.tap(find.byTooltip('Copy user ID'));
    await _settle(tester);

    expect(copied, ['device-1', '00000000-0000-0000-0000-00000000dead']);
    expect(find.text('Copied'), findsWidgets);
  });

  libraryTest('a fixed error says who and when, shows the note, and offers '
      'Reopen', (tester, env) async {
    final repository = FakeMonitoringRepository()
      ..servers['a'] = record(
        'a',
        status: LogStatus.fixed,
        statusNote: 'index added',
        statusChangedBy: 'admin-1',
        statusChangedAt: DateTime.utc(2026, 9, 27, 9, 30, 5),
      );

    await _pump(tester, env, repository);

    expect(find.widgetWithText(MxBadge, 'Fixed'), findsOneWidget);
    expect(find.text('Fixed by'), findsOneWidget);
    expect(find.text(monitoringIdText('admin-1')), findsOneWidget);
    expect(find.text('Fixed at'), findsOneWidget);
    expect(find.text('Sep 27, 2026 09:30:05'), findsOneWidget);
    expect(find.text('index added'), findsOneWidget);
    expect(find.widgetWithText(MxButton, 'Reopen'), findsOneWidget);
    expect(find.widgetWithText(MxButton, 'Mark fixed'), findsNothing);
  });

  libraryTest('a row of the device buffer has no triage and no user', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()
      ..pendings['a'] = record('a', status: null, userId: null);

    await _pump(tester, env, repository, isLocal: true);

    expect(find.byType(MxFooterBar), findsNothing);
    expect(find.byType(MxBadge), findsNothing);
    expect(find.text('User'), findsNothing);
    expect(find.text('MESSAGE'), findsOneWidget);
  });

  libraryTest('an info with no error, trace or context shows only what it '
      'has', (tester, env) async {
    final repository = FakeMonitoringRepository()
      ..servers['a'] = record(
        'a',
        level: LogLevel.info,
        status: null,
        errorType: null,
        errorMessage: null,
        stackTrace: null,
        context: const {},
      );

    await _pump(tester, env, repository);

    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.text('Stack trace'), findsNothing);
    expect(find.byType(MxFooterBar), findsNothing);
  });

  libraryTest('Mark fixed asks for an optional note, says so, and the button '
      'becomes Reopen', (tester, env) async {
    final repository = FakeMonitoringRepository()..servers['a'] = record('a');
    await _pump(tester, env, repository);

    await _markFixed(tester, note: '  index added ');

    expect(repository.statusChanges.single.status, LogStatus.fixed);
    expect(repository.statusChanges.single.note, 'index added');
    expect(find.text('Marked fixed'), findsOneWidget);
    expect(find.widgetWithText(MxButton, 'Reopen'), findsOneWidget);
    expect(find.text('index added'), findsOneWidget);
  });

  libraryTest('cancelling the sheet changes nothing', (tester, env) async {
    final repository = FakeMonitoringRepository()..servers['a'] = record('a');
    await _pump(tester, env, repository);

    await tester.tap(find.widgetWithText(MxButton, 'Mark fixed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(repository.statusChanges, isEmpty);
    expect(find.widgetWithText(MxButton, 'Mark fixed'), findsOneWidget);
  });

  libraryTest('Reopen says Reopened', (tester, env) async {
    final repository = FakeMonitoringRepository()
      ..servers['a'] = record('a', status: LogStatus.fixed);
    await _pump(tester, env, repository);

    await tester.tap(find.widgetWithText(MxButton, 'Reopen'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MxButton, 'Reopen').last);
    await _settle(tester);

    expect(repository.statusChanges.single.status, LogStatus.open);
    expect(find.text('Reopened'), findsOneWidget);
  });

  // Review focus: a status change failing offline.
  libraryTest('a change that fails offline says nothing changed and Retry '
      'does it', (tester, env) async {
    final repository = FakeMonitoringRepository()
      ..servers['a'] = record('a')
      ..statusError = const OfflineFailure(cause: 'x');
    await _pump(tester, env, repository);

    await _markFixed(tester, note: 'index added');

    expect(find.text("Couldn't change that. Nothing changed."), findsOneWidget);
    expect(find.widgetWithText(MxButton, 'Mark fixed'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);

    repository.statusError = null;
    await tester.tap(find.text('Retry'));
    await _settle(tester);

    expect(repository.statusChanges, hasLength(2));
    expect(repository.statusChanges.last.note, 'index added');
    expect(find.widgetWithText(MxButton, 'Reopen'), findsOneWidget);
  });

  // Final review I1: the toast's Retry belongs to the page; it leaves with it.
  libraryTest('leaving the page takes its failed-change toast with it', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()
      ..servers['a'] = record('a')
      ..statusError = const OfflineFailure(cause: 'x');
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: Builder(
          builder: (context) => MxButton(
            label: 'Go',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    const MonitoringDetailScreen(logId: 'a', isLocal: false),
              ),
            ),
          ),
        ),
      ),
      overrides: _overrides(repository),
    );
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
    await _markFixed(tester);
    expect(find.text("Couldn't change that. Nothing changed."), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();

    expect(find.text("Couldn't change that. Nothing changed."), findsNothing);
    expect(find.text('Retry'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  libraryTest('Copy puts the whole log on the clipboard as JSON', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()..servers['a'] = record('a');
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _pump(tester, env, repository);

    await tester.tap(find.byTooltip('Copy log'));
    await _settle(tester);

    expect(copied, contains('"event": "sync.push_failed"'));
    expect(copied, contains('"stackTrace"'));
    expect(copied, contains('"deviceId": "device-1"'));
    expect(find.text('Copied'), findsOneWidget);
  });

  libraryTest('while it loads the page is a skeleton, with no actions', (
    tester,
    env,
  ) async {
    final repository = FakeMonitoringRepository()
      ..servers['a'] = record('a')
      ..readGate = Completer<void>();

    await _pump(tester, env, repository);

    expect(find.byType(MxSkeletonList), findsOneWidget);
    expect(find.byTooltip('Copy log'), findsNothing);
    expect(find.byType(MxFooterBar), findsNothing);
    repository.readGate!.complete();
    await _settle(tester);
    expect(find.byType(MxSkeletonList), findsNothing);
  });

  libraryTest('a log that is gone says it may have been cleaned up', (
    tester,
    env,
  ) async {
    await _pump(tester, env, FakeMonitoringRepository());

    expect(find.text('This log is gone'), findsOneWidget);
    expect(find.text('It may have been cleaned up.'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  libraryTest('offline and other failures offer Retry, not an admin its '
      'words', (tester, env) async {
    final repository = FakeMonitoringRepository()
      ..readError = const OfflineFailure(cause: 'x');
    await _pump(tester, env, repository);
    expect(find.text("Can't reach the server"), findsOneWidget);
    expect(find.byType(MxErrorState), findsOneWidget);

    repository.readError = const NotAdminFailure(cause: 'x');
    await tester.tap(find.text('Retry'));
    await _settle(tester);
    expect(find.text('Only an admin can see this'), findsOneWidget);
  });

  // Review focus: a 256 kB context on the detail.
  libraryTest('a 256 kB context renders whole, selectable, in a scroll', (
    tester,
    env,
  ) async {
    final big = List.generate(4096, (i) => 'line $i ${'x' * 50}').join('\n');
    final repository = FakeMonitoringRepository()
      ..servers['a'] = record('a', context: {'args': big});

    await _pump(tester, env, repository);
    await tester.fling(find.byType(ListView), const Offset(0, -30000), 20000);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(SelectableText), findsWidgets);
  });
}
