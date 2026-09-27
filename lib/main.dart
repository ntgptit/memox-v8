import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/startup_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // DB errors are mapped to Failure explicitly (core/error/failure.dart);
  // Riverpod's default retry-on-error would otherwise sit a failed provider
  // in a hidden retry loop while showing AsyncLoading.
  final container = ProviderContainer(retry: _noRetry);
  // The stored theme and language before the first frame (FE-A3 D5).
  final settings = await readStartupSettings(container);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: MemoxApp(initialSettings: settings),
    ),
  );
}

Duration? _noRetry(int retryCount, Object error) => null;
