import 'package:flutter/widgets.dart';
import 'package:memox/core/logging/app_logger.dart';

/// Logs each navigation step at `info` (ADR-018; spec §3).
final class LogNavigatorObserver extends NavigatorObserver {
  LogNavigatorObserver([AppLogger? logger]) : _logger = logger;

  final AppLogger? _logger;

  @override
  void didPush(Route<Object?> route, Route<Object?>? previousRoute) =>
      _log('nav.push', route, previousRoute);

  @override
  void didPop(Route<Object?> route, Route<Object?>? previousRoute) =>
      _log('nav.pop', route, previousRoute);

  @override
  void didReplace({Route<Object?>? newRoute, Route<Object?>? oldRoute}) =>
      _log('nav.replace', newRoute, oldRoute);

  @override
  void didRemove(Route<Object?> route, Route<Object?>? previousRoute) =>
      _log('nav.remove', route, previousRoute);

  void _log(String event, Route<Object?>? route, Route<Object?>? other) =>
      (_logger ?? appLogger).info(
        event,
        category: LogCategory.navigation,
        context: {
          'route': route?.settings.name,
          'arguments': ?route?.settings.arguments,
          'previous': other?.settings.name,
        },
      );
}
