import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/router/log_navigator_observer.dart';
import 'package:memox/core/logging/app_logger.dart';

import '../support/recording_log_sink.dart';

// Spec §3: navigation is logged at info.
void main() {
  testWidgets('a push and a pop are info nav.push and nav.pop with the route', (
    tester,
  ) async {
    final sink = RecordingLogSink();
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: key,
        navigatorObservers: [
          LogNavigatorObserver(AppLogger(sinks: [sink])),
        ],
        home: const SizedBox(),
      ),
    );
    sink.entries.clear();

    key.currentState!.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/deck/1'),
        builder: (_) => const SizedBox(),
      ),
    );
    await tester.pumpAndSettle();
    key.currentState!.pop();
    await tester.pumpAndSettle();

    expect(sink.events, ['nav.push', 'nav.pop']);
    expect(sink.entries.first.level, LogLevel.info);
    expect(sink.entries.first.category, LogCategory.navigation);
    expect(sink.entries.first.context['route'], '/deck/1');
  });
}
