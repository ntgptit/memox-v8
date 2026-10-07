import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/features/account/presentation/screens/users_screen.dart';
import 'package:memox/features/account/presentation/widgets/items/users_entry_row_widget.dart';
import 'package:memox/features/monitoring/presentation/widgets/items/monitoring_entry_row_widget.dart';
import 'package:memox/features/monitoring/presentation/widgets/sections/monitoring_admin_gate_widget.dart';
import 'package:memox/features/settings/presentation/widgets/items/sql_log_row_widget.dart';
import 'package:memox/l10n/l10n_context.dart';

/// Screen 23's Admin rows (users spec U2): Monitoring, then Users, then the
/// SQL log switch (SQL log switch spec §5). Settings draws the section, and
/// only for an admin.
List<Widget> adminSettingsRows(BuildContext context) => [
  MonitoringEntryRowWidget(
    onOpen: () => unawaited(context.push(AppRoutes.settingsMonitoring)),
  ),
  UsersEntryRowWidget(
    onOpen: () => unawaited(context.push(AppRoutes.settingsUsers)),
  ),
  const SqlLogRowWidget(),
];

/// Screen 33 (users spec U5) under Settings on the root navigator, behind
/// the admin gate a deep link meets too.
GoRoute usersRoute(GlobalKey<NavigatorState> rootNavigator) => GoRoute(
  path: AppRoutes.settingsUsersChild,
  parentNavigatorKey: rootNavigator,
  builder: (context, state) => MonitoringAdminGateWidget(
    title: context.l10n.usersTitle,
    child: const UsersScreen(),
  ),
);
