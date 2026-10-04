import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/features/monitoring/presentation/widgets/sections/monitoring_admin_gate_widget.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

import '../../../support/account_harness.dart';
import '../../../support/library_harness.dart';

void main() {
  libraryTest('while the account is still being confirmed, the gate waits '
      'instead of refusing (plan ruling 13)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      const MonitoringAdminGateWidget(child: Text('logs')),
      overrides: [
        isAdminProvider.overrideWithValue(false),
        authStateOf(const Validating(null)),
      ],
    );

    expect(find.byType(MxSkeletonList), findsOneWidget);
    expect(find.byType(MxEmptyState), findsNothing);
    expect(find.text('logs'), findsNothing);
  });

  libraryTest('a settled non-admin is refused', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      const MonitoringAdminGateWidget(child: Text('logs')),
      overrides: [
        isAdminProvider.overrideWithValue(false),
        authStateOf(const LocalOnly()),
      ],
    );

    expect(find.byType(MxEmptyState), findsOneWidget);
    expect(find.text('logs'), findsNothing);
  });

  libraryTest('the gate names the screen it guards (users plan ruling 2)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      const MonitoringAdminGateWidget(title: 'Users', child: Text('users')),
      overrides: [
        isAdminProvider.overrideWithValue(false),
        authStateOf(const LocalOnly()),
      ],
    );

    expect(find.text('Users'), findsOneWidget);
    expect(find.text('Monitoring'), findsNothing);
  });
}
