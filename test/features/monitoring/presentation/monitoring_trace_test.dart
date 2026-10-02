import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/presentation/screens/monitoring_detail_screen.dart';

import '../../../support/library_harness.dart';
import '../../../support/monitoring_fakes.dart';

// Screen 28's stack trace laid out a frame per row (critique 2026-09-30 part
// 3d-2, E11): what a copy gives back, and room for any frame number (final
// review).

Future<void> _pump(
  WidgetTester tester,
  LibraryEnv env,
  String stackTrace,
) async {
  final repository = FakeMonitoringRepository()
    ..servers['a'] = record('a', stackTrace: stackTrace);
  await pumpLibraryScreen(
    tester,
    env,
    const MonitoringDetailScreen(logId: 'a', isLocal: false),
    overrides: [monitoringRepositoryProvider.overrideWithValue(repository)],
  );
  tester.view.physicalSize = const Size(360, 4000);
  await tester.pump();
}

void main() {
  libraryTest('copying the trace gives it back as written, a line per frame', (
    tester,
    env,
  ) async {
    const trace = '#0      a (a.dart:1)\n<asynchronous suspension>\n#1      b';
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
    await _pump(tester, env, trace);

    final region = tester.state<SelectableRegionState>(
      find.descendant(
        of: find.byType(SelectionArea),
        matching: find.byType(SelectableRegion),
      ),
    );
    region.selectAll();
    await tester.pump();
    region.copySelection(SelectionChangedCause.toolbar);
    await tester.pump();

    expect(copied, trace);
  });

  libraryTest('a three-digit frame number keeps clear of the frame text', (
    tester,
    env,
  ) async {
    await _pump(tester, env, '#9      a\n#100    b');

    expect(
      tester.getTopRight(find.text('#100')).dx,
      lessThan(tester.getTopLeft(find.text('b')).dx),
    );
    // Every frame's text starts at one column.
    expect(
      tester.getTopLeft(find.text('a')).dx,
      tester.getTopLeft(find.text('b')).dx,
    );
  });
}
