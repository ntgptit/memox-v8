import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/reminders/data/datasources/reminder_plugins_data_source.dart';
import 'package:memox/features/reminders/di/reminder_plugins_data_source_provider.dart';
import 'package:memox/features/study/presentation/screens/study_home_screen.dart';

import '../support/library_harness.dart';

/// The plugins as the app sees them: taps it can send, and the payload that
/// launched the app.
final class _FakePlugins implements ReminderPluginsDataSource {
  _FakePlugins({this.launch, this.launchFails = false});

  final String? launch;
  final bool launchFails;
  final _taps = StreamController<String?>.broadcast();
  var initialized = 0;

  void tap(String? payload) => _taps.add(payload);

  @override
  Future<void> initialize() async => initialized++;

  @override
  Stream<String?> get taps => _taps.stream;

  @override
  Future<String?> launchPayload() async {
    if (launchFails) throw StateError('plugin not ready');
    return launch;
  }

  @override
  Future<bool?> requestNotificationPermission() async => true;

  @override
  Future<bool> scheduleAlarm(DateTime at) async => true;

  @override
  Future<bool> cancelAlarm() async => true;

  @override
  Future<void> showNotification(String body) async {}

  @override
  Future<void> cancelNotification() async {}

  @override
  Future<bool> openNotificationSettings() async => true;
}

void main() {
  libraryTest('a tap on the reminder opens Study Home (BR-REMINDER-008)', (
    tester,
    env,
  ) async {
    final plugins = _FakePlugins();
    await pumpMemoxApp(
      tester,
      env,
      overrides: [reminderPluginsDataSourceProvider.overrideWithValue(plugins)],
    );
    expect(find.byType(StudyHomeScreen), findsNothing);

    plugins.tap(reminderTapPayload);
    await tester.pumpAndSettle();

    expect(find.byType(StudyHomeScreen), findsOneWidget);
  });

  libraryTest('a reminder that launched the app opens on Study Home', (
    tester,
    env,
  ) async {
    await pumpMemoxApp(
      tester,
      env,
      overrides: [
        reminderPluginsDataSourceProvider.overrideWithValue(
          _FakePlugins(launch: reminderTapPayload),
        ),
      ],
    );

    expect(find.byType(StudyHomeScreen), findsOneWidget);
  });

  libraryTest('a tap that carries anything else leaves the app where it is', (
    tester,
    env,
  ) async {
    final plugins = _FakePlugins();
    await pumpMemoxApp(
      tester,
      env,
      overrides: [reminderPluginsDataSourceProvider.overrideWithValue(plugins)],
    );

    plugins
      ..tap(null)
      ..tap('something-else');
    await tester.pumpAndSettle();

    expect(find.byType(StudyHomeScreen), findsNothing);
  });

  libraryTest('a launch payload that cannot be read leaves the app running', (
    tester,
    env,
  ) async {
    await pumpMemoxApp(
      tester,
      env,
      overrides: [
        reminderPluginsDataSourceProvider.overrideWithValue(
          _FakePlugins(launchFails: true),
        ),
      ],
    );

    expect(find.byType(StudyHomeScreen), findsNothing);
  });
}
