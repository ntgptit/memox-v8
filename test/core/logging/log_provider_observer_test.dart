import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/logging/log_provider_observer.dart';

import '../../support/recording_log_sink.dart';

final _broken = FutureProvider<int>(
  (ref) => throw StateError('boom'),
  name: 'brokenProvider',
);
final _refused = FutureProvider<int>(
  (ref) => throw const ConstraintFailure(cause: 'CHECK'),
  name: 'refusedProvider',
);

// Spec §3: a provider that fails is logged with its name.
void main() {
  late RecordingLogSink sink;
  late ProviderContainer container;

  setUp(() {
    sink = RecordingLogSink();
    container = ProviderContainer(
      observers: [
        LogProviderObserver(AppLogger(sinks: [sink])),
      ],
      retry: (_, _) => null,
    );
    addTearDown(container.dispose);
  });

  test('an unexpected error is error state.provider_failed', () async {
    await expectLater(container.read(_broken.future), throwsStateError);

    final entry = sink.entries.single;
    expect(
      (entry.level, entry.event),
      (LogLevel.error, 'state.provider_failed'),
    );
    expect(entry.context['provider'], 'brokenProvider');
    expect(entry.stackTrace, isNotNull);
  });

  test('a Failure is a warning, its cause included', () async {
    await expectLater(container.read(_refused.future), throwsA(isA<Failure>()));

    final entry = sink.entries.single;
    expect(entry.level, LogLevel.warning);
    expect(entry.errorMessage, contains('CHECK'));
  });
}
