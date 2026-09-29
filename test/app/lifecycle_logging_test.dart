import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/logging/log_entry.dart';

import '../support/library_harness.dart';

final class _FlushCountingSink implements LogSink {
  final events = <String>[];
  var flushes = 0;

  @override
  void write(LogEntry entry) => events.add(entry.event);

  @override
  Future<void> flush() async => flushes++;
}

// ADR-018; spec 2026-09-29-app-logging-design.md §3: a pause writes what the
// buffer still holds before the app may be killed.
void main() {
  libraryTest('a pause and a resume are logged, and the pause flushes', (
    tester,
    env,
  ) async {
    final previous = appLogger;
    addTearDown(() => AppLogger.install(previous));
    final sink = _FlushCountingSink();
    AppLogger.install(AppLogger(sinks: [sink]));
    await pumpMemoxApp(tester, env);

    for (final state in const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();
    expect(sink.events, contains('lifecycle.pause'));
    expect(sink.flushes, 1);

    for (final state in const [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
    expect(sink.events, contains('lifecycle.resume'));
  });
}
