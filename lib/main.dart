import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/startup_settings.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/features/reminders/di/reminder_plugins_data_source_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // DB errors are mapped to Failure explicitly (core/error/failure.dart);
  // Riverpod's default retry-on-error would otherwise sit a failed provider
  // in a hidden retry loop while showing AsyncLoading.
  final container = ProviderContainer(retry: _noRetry);
  // The stored theme and language before the first frame (FE-A3 D5).
  final settings = await readStartupSettings(container);
  // ADR-015: sync starts with the app when this build names a Supabase project.
  final supabase = container.read(supabaseConfigProvider);
  if (supabase.isEnabled) {
    await Supabase.initialize(
      url: supabase.url,
      publishableKey: supabase.publishableKey,
    );
  }
  container.read(syncSchedulerProvider);
  // BE-B5b: the reminder's plugins, on Android only, before anything
  // schedules. A failure here leaves the reminder to report its own typed
  // reason when it is used; the app starts regardless.
  try {
    await container.read(reminderPluginsDataSourceProvider)?.initialize();
  } on Object catch (error) {
    log('Reminder plugins: ${error.runtimeType}', name: 'reminders');
  }
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: MemoxApp(initialSettings: settings),
    ),
  );
}

Duration? _noRetry(int retryCount, Object error) => null;
