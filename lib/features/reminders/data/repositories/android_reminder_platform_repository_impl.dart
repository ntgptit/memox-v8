import 'dart:ui';

import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/data/datasources/reminder_plugins_data_source.dart';
import 'package:memox/features/reminders/data/mappers/reminder_notification_mapper.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/reminders/domain/repositories/reminder_platform_repository.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// The reminder on Android (BE-B5b), over the two plugins behind
/// [ReminderPluginsDataSource]. No call throws: a plugin error comes back as
/// the port's typed reason (BR-REMINDER-012, UC-REMINDER-001 E3).
final class AndroidReminderPlatformRepositoryImpl
    implements ReminderPlatformRepository {
  /// [systemLocale] is the device's language, read when `System` is chosen.
  AndroidReminderPlatformRepositoryImpl(
    this._plugins, {
    required this._systemLocale,
  });

  final ReminderPluginsDataSource _plugins;
  final Locale Function() _systemLocale;

  @override
  Future<ReminderCapability> capability() async => ReminderCapability.supported;

  @override
  Future<ReminderPermission> requestPermission() async {
    try {
      final granted = await _plugins.requestNotificationPermission();
      // Null: Android before 13 has no notification permission to ask.
      return granted == false
          ? ReminderPermission.denied
          : ReminderPermission.granted;
    } on Object {
      return ReminderPermission.denied;
    }
  }

  @override
  Future<Outcome<void, ReminderRejection>> schedule({
    required DateTime at,
  }) async {
    try {
      if (await _plugins.scheduleAlarm(at)) return const Ok(null);
    } on Object {
      // Falls through to the typed reason.
    }
    return const Rejected(ReminderRejection.couldNotSchedule);
  }

  /// The alarm and the notification go independently, so one refusing never
  /// keeps the other; `Ok` only when both went.
  @override
  Future<Outcome<void, ReminderRejection>> cancel() async {
    final alarmGone = await _succeeds(_plugins.cancelAlarm);
    final notificationGone = await _succeeds(() async {
      await _plugins.cancelNotification();
      return true;
    });
    return alarmGone && notificationGone
        ? const Ok(null)
        : const Rejected(ReminderRejection.couldNotCancel);
  }

  /// [call]'s answer, with a throw read as a refusal.
  Future<bool> _succeeds(Future<bool> Function() call) async {
    try {
      return await call();
    } on Object {
      return false;
    }
  }

  @override
  Future<Outcome<void, ReminderRejection>> show({
    required ReminderDigest digest,
    required LanguageChoice language,
  }) async {
    try {
      await _plugins.showNotification(
        reminderNotificationBody(digest, _localeOf(language)),
      );
      return const Ok(null);
    } on Object {
      return const Rejected(ReminderRejection.couldNotShow);
    }
  }

  @override
  Future<bool> openNotificationSettings() =>
      _succeeds(_plugins.openNotificationSettings);

  /// `System` follows the device when the app speaks its language, and
  /// English otherwise, as the app itself does (BR-SETTINGS-006).
  Locale _localeOf(LanguageChoice language) => switch (language) {
    LanguageChoice.en => const Locale('en'),
    LanguageChoice.vi => const Locale('vi'),
    LanguageChoice.system => _supported(_systemLocale()),
  };

  Locale _supported(Locale device) {
    final spoken = AppLocalizations.supportedLocales.any(
      (locale) => locale.languageCode == device.languageCode,
    );
    return spoken ? Locale(device.languageCode) : const Locale('en');
  }
}
