import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/database/log/log_database.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/logging/buffer_sink.dart';
import 'package:memox/core/logging/console_sink.dart';
import 'package:memox/core/logging/di/logging_providers.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// ADR-018 §3: the app's logger — the console and the device buffer — stamped
/// with this device and build, and every uncaught error routed to it. Runs
/// first in `main`, so what starts after it logs to the buffer. Nothing here
/// stops the app from starting: a part that fails leaves its field empty.
Future<void> installAppLogger(ProviderContainer container) async {
  _routeUncaughtErrors();
  final LogDatabase logs;
  try {
    logs = container.read(logDatabaseProvider);
  } on Object catch (error, stackTrace) {
    appLogger.warning(
      'lifecycle.log_buffer_unavailable',
      category: LogCategory.lifecycle,
      error: error,
      stackTrace: stackTrace,
    );
    return;
  }
  AppLogger.install(
    AppLogger(
      sinks: [const ConsoleSink(), BufferSink(logs)],
      stamp: await _stamp(container),
    ),
  );
  // After the first frame's reads, not before them.
  unawaited(_prune(logs));
}

void _routeUncaughtErrors() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    appLogger.error(
      'ui.uncaught',
      category: LogCategory.ui,
      error: details.exception,
      stackTrace: details.stack,
      context: {
        'library': details.library,
        'context': details.context?.toString(),
      },
    );
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    appLogger.error(
      'ui.uncaught',
      category: LogCategory.ui,
      error: error,
      stackTrace: stackTrace,
      context: const {'library': 'platform dispatcher'},
    );
    return true;
  };
}

Future<void> _prune(LogDatabase logs) async {
  try {
    await logs.prune(now: DateTime.now());
  } on Object catch (error, stackTrace) {
    appLogger.warning(
      'lifecycle.log_prune_failed',
      category: LogCategory.lifecycle,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

Future<LogStamp> _stamp(ProviderContainer container) async {
  final deviceId = await _orNull(
    () => container.read(syncStoreProvider).deviceId(),
  );
  final package = await _orNull(PackageInfo.fromPlatform);
  return LogStamp(
    deviceId: deviceId,
    appVersion: package?.version,
    buildNumber: package?.buildNumber,
    platform: defaultTargetPlatform.name,
    osVersion: kIsWeb ? null : Platform.operatingSystemVersion,
  );
}

Future<T?> _orNull<T>(Future<T> Function() read) async {
  try {
    return await read();
  } on Object {
    return null;
  }
}
