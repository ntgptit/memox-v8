import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:memox/features/reminders/data/datasources/plugin_reminder_plugins_data_source.dart';
import 'package:memox/features/reminders/data/datasources/reminder_plugins_data_source.dart';
import 'package:memox/features/reminders/di/reminder_background_bindings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reminder_plugins_data_source_provider.g.dart';

/// The reminder's two plugins, on Android only; null everywhere else, Web
/// and the host running the tests included (reminders spec D7, BE-B5b).
@Riverpod(keepAlive: true)
ReminderPluginsDataSource? reminderPluginsDataSource(Ref ref) {
  if (kIsWeb || !Platform.isAndroid) return null;
  return PluginReminderPluginsDataSource(deliverReminderInBackground);
}
