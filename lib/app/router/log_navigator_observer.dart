import 'package:flutter/widgets.dart';
import 'package:memox/core/logging/app_logger.dart';

/// Logs each navigation step at `info` (ADR-018; spec §3).
final class LogNavigatorObserver extends NavigatorObserver {
  LogNavigatorObserver([AppLogger? logger]) : _logger = logger;

  final AppLogger? _logger;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _log('nav.push', route, previousRoute);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _log('nav.pop', route, previousRoute);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _log('nav.replace', newRoute, oldRoute);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _log('nav.remove', route, previousRoute);

  void _log(String event, Route<dynamic>? route, Route<dynamic>? other) =>
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
