import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/data/datasources/reminder_plugins_data_source.dart';
import 'package:memox/features/reminders/data/repositories/android_reminder_platform_repository_impl.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';

/// Records every plugin call; [fails] makes each call throw, [refuses] makes
/// the alarm calls answer `false`.
final class _FakePlugins implements ReminderPluginsDataSource {
  bool fails = false;
  bool refuses = false;

  /// The calls that throw on their own, whatever [fails] says.
  final failing = <String>{};
  bool? permission = true;
  final calls = <String>[];
  final shown = <String>[];

  Future<T> _call<T>(String name, T value) async {
    calls.add(name);
    if (fails || failing.contains(name)) throw StateError('plugin');
    return value;
  }

  @override
  Future<void> initialize() => _call('initialize', null);

  @override
  Future<bool?> requestNotificationPermission() =>
      _call('permission', permission);

  @override
  Future<bool> scheduleAlarm(DateTime at) => _call('schedule $at', !refuses);

  @override
  Future<bool> cancelAlarm() => _call('cancelAlarm', !refuses);

  @override
  Future<void> showNotification(String body) async {
    await _call('show', null);
    shown.add(body);
  }

  @override
  Future<void> cancelNotification() => _call('cancelNotification', null);

  @override
  Stream<String?> get taps => const Stream.empty();

  @override
  Future<String?> launchPayload() async => null;

  @override
  Future<bool> openNotificationSettings() => _call('openSettings', !refuses);
}

Matcher _rejected(ReminderRejection reason) =>
    isA<Rejected<void, ReminderRejection>>().having(
      (r) => r.reason,
      'reason',
      reason,
    );

void main() {
  late _FakePlugins plugins;
  late AndroidReminderPlatformRepositoryImpl platform;
  var systemLocale = const Locale('en');

  setUp(() {
    plugins = _FakePlugins();
    systemLocale = const Locale('en');
    platform = AndroidReminderPlatformRepositoryImpl(
      plugins,
      systemLocale: () => systemLocale,
    );
  });

  const digest = ReminderDigest(
    deckName: 'Korean',
    dueCount: 86,
    otherDeckCount: 2,
  );
  const english =
      '86 cards are due in Korean, and 2 other decks have cards waiting.';

  test('Android can deliver the reminder (BR-REMINDER-012)', () async {
    expect(await platform.capability(), ReminderCapability.supported);
  });

  group('requestPermission (BR-REMINDER-011)', () {
    test('granted, and granted where no permission exists', () async {
      plugins.permission = true;
      expect(await platform.requestPermission(), ReminderPermission.granted);
      plugins.permission = null;
      expect(await platform.requestPermission(), ReminderPermission.granted);
    });

    test('refused, or a failure to ask, is denied', () async {
      plugins.permission = false;
      expect(await platform.requestPermission(), ReminderPermission.denied);
      plugins.fails = true;
      expect(await platform.requestPermission(), ReminderPermission.denied);
    });
  });

  group('schedule (BR-REMINDER-009, BR-REMINDER-010)', () {
    final at = DateTime(2026, 9, 28, 8, 30);

    test('one alarm at the time asked', () async {
      expect(
        await platform.schedule(at: at),
        isA<Ok<void, ReminderRejection>>(),
      );
      expect(plugins.calls.where((c) => c.startsWith('schedule')), [
        'schedule $at',
      ]);
    });

    test('a refusal or a throw is couldNotSchedule', () async {
      plugins.refuses = true;
      expect(
        await platform.schedule(at: at),
        _rejected(ReminderRejection.couldNotSchedule),
      );
      plugins
        ..refuses = false
        ..fails = true;
      expect(
        await platform.schedule(at: at),
        _rejected(ReminderRejection.couldNotSchedule),
      );
    });
  });

  group('cancel', () {
    test('removes the alarm and the notification', () async {
      expect(await platform.cancel(), isA<Ok<void, ReminderRejection>>());
      expect(plugins.calls, containsAll(['cancelAlarm', 'cancelNotification']));
    });

    test('a notification that will not go still leaves the alarm cancelled, '
        'and says so', () async {
      plugins.failing.add('cancelNotification');
      expect(
        await platform.cancel(),
        _rejected(ReminderRejection.couldNotCancel),
      );
      expect(plugins.calls, containsAll(['cancelAlarm', 'cancelNotification']));
    });

    test(
      'an alarm that will not cancel still lets the notification go',
      () async {
        plugins.failing.add('cancelAlarm');
        expect(
          await platform.cancel(),
          _rejected(ReminderRejection.couldNotCancel),
        );
        expect(plugins.calls, contains('cancelNotification'));
      },
    );

    test('a refusal or a throw is couldNotCancel', () async {
      plugins.refuses = true;
      expect(
        await platform.cancel(),
        _rejected(ReminderRejection.couldNotCancel),
      );
      plugins
        ..refuses = false
        ..fails = true;
      expect(
        await platform.cancel(),
        _rejected(ReminderRejection.couldNotCancel),
      );
    });
  });

  group('show (BR-REMINDER-004, BR-REMINDER-005)', () {
    test('writes the digest in the language asked', () async {
      await platform.show(digest: digest, language: LanguageChoice.en);
      await platform.show(digest: digest, language: LanguageChoice.vi);
      expect(plugins.shown, [
        english,
        '86 thẻ đến hạn trong Korean, và 2 deck khác có thẻ đang chờ.',
      ]);
    });

    test(
      'System follows the device, and English stands in for the rest',
      () async {
        systemLocale = const Locale('vi', 'VN');
        await platform.show(digest: digest, language: LanguageChoice.system);
        systemLocale = const Locale('fr');
        await platform.show(digest: digest, language: LanguageChoice.system);
        expect(plugins.shown, [
          '86 thẻ đến hạn trong Korean, và 2 deck khác có thẻ đang chờ.',
          english,
        ]);
      },
    );

    test('a throw is couldNotShow', () async {
      plugins.fails = true;
      expect(
        await platform.show(digest: digest, language: LanguageChoice.en),
        _rejected(ReminderRejection.couldNotShow),
      );
    });
  });

  group('openNotificationSettings (FE-B6)', () {
    test('opens the app\'s notification settings', () async {
      expect(await platform.openNotificationSettings(), isTrue);
      expect(plugins.calls, ['openSettings']);
    });

    test('a refusal is false', () async {
      plugins.refuses = true;
      expect(await platform.openNotificationSettings(), isFalse);
    });

    test('a throw is false, never thrown', () async {
      plugins.fails = true;
      expect(await platform.openNotificationSettings(), isFalse);
    });
  });
}
