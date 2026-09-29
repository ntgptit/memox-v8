import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/logging/app_logger.dart';

/// Logs every provider that fails (ADR-018, replacing ADR-016 decision 6): an
/// expected [Failure] as a warning, anything else as an error, with its cause.
final class LogProviderObserver extends ProviderObserver {
  LogProviderObserver([AppLogger? logger]) : _logger = logger;

  final AppLogger? _logger;

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    final logger = _logger ?? appLogger;
    final provider = context.provider;
    final log = error is Failure ? logger.warning : logger.error;
    log(
      'state.provider_failed',
      error: error,
      stackTrace: stackTrace,
      context: {
        'provider': provider.name ?? provider.runtimeType.toString(),
        if (provider.argument != null) 'argument': provider.argument,
      },
    );
  }
}
