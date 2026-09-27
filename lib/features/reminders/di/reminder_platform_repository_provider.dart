import 'dart:ui';

import 'package:memox/features/reminders/data/repositories/android_reminder_platform_repository_impl.dart';
import 'package:memox/features/reminders/data/repositories/unsupported_reminder_platform_repository_impl.dart';
import 'package:memox/features/reminders/di/reminder_plugins_data_source_provider.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_platform_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reminder_platform_repository_provider.g.dart';

/// The platform side of the reminder: Android's where the plugins run
/// (BE-B5b), the unsupported one everywhere else, Web included (reminders
/// spec D7).
@Riverpod(keepAlive: true)
ReminderPlatformRepository reminderPlatformRepository(Ref ref) {
  final plugins = ref.watch(reminderPluginsDataSourceProvider);
  if (plugins == null) return const UnsupportedReminderPlatformRepositoryImpl();
  return AndroidReminderPlatformRepositoryImpl(
    plugins,
    systemLocale: () => PlatformDispatcher.instance.locale,
  );
}
