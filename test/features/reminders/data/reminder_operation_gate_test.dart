import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/reminders/data/datasources/reminder_operation_gate_data_source.dart';

void main() {
  test('two operations started together run one after the other', () async {
    final gate = ReminderOperationGate();
    final log = <String>[];
    final firstMayEnd = Completer<void>();

    final first = gate.run(() async {
      log.add('first starts');
      await firstMayEnd.future;
      log.add('first ends');
      return 1;
    });
    final second = gate.run(() async {
      log.add('second starts');
      return 2;
    });

    await pumpEventQueue();
    expect(log, ['first starts']);
    firstMayEnd.complete();
    expect(await first, 1);
    expect(await second, 2);
    expect(log, ['first starts', 'first ends', 'second starts']);
  });

  test('a failed operation reaches its caller and frees the gate', () async {
    final gate = ReminderOperationGate();
    final failing = gate.run<int>(() async => throw StateError('platform'));
    final next = gate.run(() async => 'ran');

    await expectLater(failing, throwsStateError);
    expect(await next, 'ran');
  });
}
