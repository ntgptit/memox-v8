import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/logging_bootstrap.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/logging/di/logging_providers.dart';

// ADR-018 §3: logging never stops the app from starting.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a log buffer that cannot open leaves the console logger, and the '
      'start goes on', () async {
    final previous = appLogger;
    final flutterOnError = FlutterError.onError;
    final dispatcherOnError = PlatformDispatcher.instance.onError;
    addTearDown(() {
      AppLogger.install(previous);
      FlutterError.onError = flutterOnError;
      PlatformDispatcher.instance.onError = dispatcherOnError;
    });
    final container = ProviderContainer(
      overrides: [
        logDatabaseProvider.overrideWith((ref) => throw StateError('no disk')),
      ],
      retry: (_, _) => null,
    );
    addTearDown(container.dispose);

    await expectLater(installAppLogger(container), completes);

    expect(identical(appLogger, previous), isTrue);
    expect(FlutterError.onError, isNot(flutterOnError));
  });
}
