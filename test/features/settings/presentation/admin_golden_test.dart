@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/features/account/presentation/widgets/items/users_entry_row_widget.dart';
import 'package:memox/features/monitoring/presentation/widgets/items/monitoring_entry_row_widget.dart';
import 'package:memox/features/settings/presentation/screens/admin_screen.dart';
import 'package:memox/features/settings/presentation/widgets/items/sql_log_row_widget.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

// Screen 23b (settings hub spec §5.3).
void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;
    libraryTest('admin, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          AdminScreen(
            logsRows: [
              MonitoringEntryRowWidget(onOpen: () {}),
              const SqlLogRowWidget(),
            ],
            peopleRows: [UsersEntryRowWidget(onOpen: () {})],
          ),
          brightness,
          overrides: [isAdminProvider.overrideWithValue(true)],
        );
        await expectBoundaryGolden(tester, 'goldens/admin_$theme.png');
      });
    });
  }
}
