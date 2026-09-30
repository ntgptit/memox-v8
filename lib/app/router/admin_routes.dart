import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/features/account/presentation/widgets/items/users_entry_row_widget.dart';
import 'package:memox/features/monitoring/presentation/widgets/items/monitoring_entry_row_widget.dart';

/// Screen 23's Admin rows (users spec U2): Monitoring, then Users. Settings
/// draws the section, and only for an admin.
List<Widget> adminSettingsRows(BuildContext context) => [
  MonitoringEntryRowWidget(
    onOpen: () => unawaited(context.push(AppRoutes.settingsMonitoring)),
  ),
  UsersEntryRowWidget(
    onOpen: () => unawaited(context.push(AppRoutes.settingsUsers)),
  ),
];
