import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/app_startup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // DB errors are mapped to Failure explicitly (core/error/failure.dart);
  // Riverpod's default retry-on-error would otherwise sit a failed provider
  // in a hidden retry loop while showing AsyncLoading.
  final container = ProviderContainer(retry: _noRetry);
  await runStartupTasks(container);
  runApp(
    UncontrolledProviderScope(container: container, child: const MemoxApp()),
  );
}

Duration? _noRetry(int retryCount, Object error) => null;
