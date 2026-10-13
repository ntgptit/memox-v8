import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/presentation/screens/admin_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/library_harness.dart';

// Settings hub spec §5.3: the admin rows the features supply, in Logs and
// People; the gate is the router's (account_routes_test).

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  libraryTest('Logs holds Monitoring and the SQL switch, People holds Users, '
      'in that order', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      const AdminScreen(
        logsRows: [Text('Monitoring'), Text('Log SQL statements')],
        peopleRows: [Text('Users')],
      ),
    );

    expect(find.text(_en.settingsAdmin), findsOneWidget); // the title
    expect(find.text(_en.settingsAdminLogs.toUpperCase()), findsOneWidget);
    expect(find.text(_en.settingsAdminPeople.toUpperCase()), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Monitoring')).dy,
      lessThan(tester.getTopLeft(find.text('Log SQL statements')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Log SQL statements')).dy,
      lessThan(tester.getTopLeft(find.text('Users')).dy),
    );
    expect(find.byTooltip(_en.commonBack), findsOneWidget);
  });
}
