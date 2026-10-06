import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/network/supabase_config.dart';
import 'package:memox/core/network/di/network_providers.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/features/account/presentation/widgets/items/users_entry_row_widget.dart';
import 'package:memox/features/monitoring/presentation/widgets/items/monitoring_entry_row_widget.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';

import '../../../support/library_harness.dart';
import '../../../support/monitoring_fakes.dart';

// Monitoring spec §3.1, §5: the entry shows only for an admin.
// Users spec U2: Settings owns the section; the features supply its rows.
SettingsScreen _screen({
  required void Function() onOpen,
  void Function()? onOpenUsers,
}) => SettingsScreen(
  onOpenTheme: () {},
  onOpenLanguage: () {},
  onOpenReminder: () {},
  resetAppOptions: () async => const Ok(null),
  onOpenSync: () {},
  adminRows: [
    MonitoringEntryRowWidget(onOpen: onOpen),
    UsersEntryRowWidget(onOpen: onOpenUsers ?? () {}),
  ],
);

const _enabled = SupabaseConfig(
  url: 'https://x.supabase.co',
  publishableKey: 'key',
);

void main() {
  libraryTest('a non-admin sees no Admin section at all', (tester, env) async {
    await pumpLibraryScreen(tester, env, _screen(onOpen: () {}));
    await tester.scrollUntilVisible(find.text('Reset app options'), 200);

    expect(find.text('ADMIN'), findsNothing);
    expect(find.text('Monitoring'), findsNothing);
    expect(find.text('Users'), findsNothing);
  });

  libraryTest('an admin sees Monitoring then Users, and Users opens its '
      'screen (users spec U2)', (tester, env) async {
    var opened = 0;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(onOpen: () {}, onOpenUsers: () => opened++),
      overrides: [isAdminProvider.overrideWithValue(true)],
    );
    await tester.scrollUntilVisible(find.text('Users'), 200);

    expect(find.text('Who can manage the app'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Monitoring')).dy,
      lessThan(tester.getTopLeft(find.text('Users')).dy),
    );
    await tester.tap(find.text('Users'));
    expect(opened, 1);
  });

  libraryTest('an admin sees Monitoring and it opens the screen', (
    tester,
    env,
  ) async {
    var opened = 0;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(onOpen: () => opened++),
      overrides: [isAdminProvider.overrideWithValue(true)],
    );
    await tester.scrollUntilVisible(find.text('Monitoring'), 200);

    expect(find.text('ADMIN'), findsOneWidget);
    expect(find.text('Logs of the app and the server'), findsOneWidget);
    await tester.tap(find.text('Monitoring'));
    expect(opened, 1);
  });

  libraryTest(
    'a build with no Supabase shows nothing: its account stays local',
    (tester, env) async {
      await pumpLibraryScreen(
        tester,
        env,
        _screen(onOpen: () {}),
        overrides: [
          supabaseConfigProvider.overrideWithValue(
            const SupabaseConfig(url: '', publishableKey: ''),
          ),
        ],
      );
      await tester.scrollUntilVisible(find.text('Reset app options'), 200);

      expect(find.text('Monitoring'), findsNothing);
      expect(find.text('Users'), findsNothing);
    },
  );

  // Review focus: a token refresh that adds the admin role while Settings is
  // open.
  libraryTest('an account confirmed as admin shows the row without a '
      'restart, and a lost confirmation hides it', (tester, env) async {
    final states = StreamController<AuthState>();
    addTearDown(states.close);
    await pumpLibraryScreen(
      tester,
      env,
      _screen(onOpen: () {}),
      overrides: [
        supabaseConfigProvider.overrideWithValue(_enabled),
        authStateProvider.overrideWith((ref) => states.stream),
      ],
    );
    states.add(const Ready(userAccount));
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Reset app options'), 200);
    expect(find.text('Monitoring'), findsNothing);

    states.add(const Ready(adminAccount));
    await tester.pump();
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Monitoring'), 200);
    expect(find.text('Monitoring'), findsOneWidget);

    states.add(const Validating(null));
    await tester.pump();
    await tester.pump();
    expect(find.text('Monitoring'), findsNothing);
  });
}
