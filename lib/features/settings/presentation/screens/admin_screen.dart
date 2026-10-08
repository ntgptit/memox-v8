import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_section.dart';

/// Screen 23b, Admin (settings hub spec §5.3): the rows the monitoring,
/// account and settings features supply, which `app/` composes, in Logs
/// and People. The router puts it behind the admin gate (ADR-018 §7).
class AdminScreen extends StatelessWidget {
  const AdminScreen({
    super.key,
    required this.logsRows,
    required this.peopleRows,
  });

  /// Monitoring, then the SQL log switch.
  final List<Widget> logsRows;

  /// Users.
  final List<Widget> peopleRows;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.settingsAdmin,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: MxScreenScroll(
        children: [
          MxSection(title: l10n.settingsAdminLogs, children: logsRows),
          MxSection(title: l10n.settingsAdminPeople, children: peopleRows),
        ],
      ),
    );
  }
}
