import 'package:memox/features/reminders/data/repositories/unsupported_reminder_platform_repository_impl.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_platform_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reminder_platform_repository_provider.g.dart';

/// The platform side of the reminder: none on any platform until BE-B5b
/// adds Android's here, and Web keeps none (reminders spec D7).
@Riverpod(keepAlive: true)
ReminderPlatformRepository reminderPlatformRepository(Ref ref) =>
    const UnsupportedReminderPlatformRepositoryImpl();
