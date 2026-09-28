import 'package:memox/features/reminders/di/reminder_platform_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'open_notification_settings_provider.g.dart';

/// Screen 24's "Open system settings" (FE-B6). No use case and no gate: one
/// platform call that changes nothing the reminder stores.
@riverpod
Future<bool> Function() openNotificationSettings(Ref ref) =>
    ref.watch(reminderPlatformRepositoryProvider).openNotificationSettings;
