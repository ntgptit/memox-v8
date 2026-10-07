import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/core/logging/sql_log_switch.dart';
import 'package:memox/core/logging/sql_log_switch_feeder.dart';

import '../../support/recording_log_sink.dart';

// SQL log switch spec §4.3: the row is the source of truth; the switch
// follows it, and each change after the first read is logged once.
void main() {
  late SqlLogSwitch target;
  late StreamController<bool> flags;
  late RecordingLogSink sink;
  late SqlLogSwitchFeeder feeder;

  setUp(() {
    target = SqlLogSwitch();
    flags = StreamController<bool>();
    sink = RecordingLogSink();
    feeder = SqlLogSwitchFeeder(
      target: target,
      flags: flags.stream,
      logger: AppLogger(sinks: [sink]),
    );
  });
  tearDown(() async {
    feeder.dispose();
    await flags.close();
    target.dispose();
  });

  test('the first read sets the switch without a log row', () async {
    flags.add(false);
    await Future<void>.delayed(Duration.zero);
    expect(target.value, isFalse);
    expect(sink.events, isEmpty);
  });

  test('a later change moves the switch and logs it once', () async {
    flags
      ..add(true)
      ..add(false)
      ..add(false)
      ..add(true);
    await Future<void>.delayed(Duration.zero);
    expect(target.value, isTrue);
    expect(sink.events, [
      'logging.sql_statements_changed',
      'logging.sql_statements_changed',
    ]);
    expect(sink.entries.first.context['enabled'], false);
    expect(sink.entries.last.context['enabled'], true);
  });

  test('a failing stream leaves the switch and logs a warning', () async {
    flags
      ..add(false)
      ..addError(StateError('closed'));
    await Future<void>.delayed(Duration.zero);
    expect(target.value, isFalse);
    expect(sink.events, ['logging.sql_switch_unavailable']);
    expect(sink.entries.single.level, LogLevel.warning);
  });
}
