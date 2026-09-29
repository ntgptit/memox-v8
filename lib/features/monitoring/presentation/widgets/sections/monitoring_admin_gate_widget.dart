import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/monitoring/di/is_admin_provider.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// Screen 28 opens only for an admin (ADR-018 §7). Screen 23 hides the entry
/// from everyone else, but a deep link still lands here, and the device
/// buffer has no server check behind it. So for a non-admin the page builds
/// none of [child], reads nothing, and says only an admin can see this.
class MonitoringAdminGateWidget extends ConsumerWidget {
  const MonitoringAdminGateWidget({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(isAdminProvider)) return child;
    final l10n = context.l10n;
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.monitoringTitle,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: MxScreenScroll(
        children: [
          MxEmptyState(
            icon: AppIcons.lock,
            title: l10n.monitoringNotAdminTitle,
            tone: MxEmptyStateTone.neutral,
            isCompact: true,
          ),
        ],
      ),
    );
  }
}
