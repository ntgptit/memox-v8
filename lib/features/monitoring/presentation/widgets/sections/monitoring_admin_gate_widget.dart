import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// Screen 28 opens only for an admin (ADR-018 §7). Screen 23 hides the entry
/// from everyone else, but a deep link still lands here, and the device
/// buffer has no server check behind it. So for a non-admin the page builds
/// none of [child], reads nothing, and says only an admin can see this.
class MonitoringAdminGateWidget extends ConsumerWidget {
  const MonitoringAdminGateWidget({super.key, required this.child, this.title});

  final Widget child;

  /// The app bar's title while it refuses; Monitoring's when null (users
  /// plan ruling 2).
  final String? title;

  static const int _waitRows = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(isAdminProvider)) return child;
    // While the account is still being confirmed, isAdmin is not known yet
    // (account UI spec §4): wait instead of refusing.
    final isSettling = switch (ref.watch(authStateProvider).value) {
      null || Booting() || Bootstrapping() || Validating() => true,
      _ => false,
    };
    final l10n = context.l10n;
    return MxAppShell(
      appBar: MxAppBar(
        title: title ?? l10n.monitoringTitle,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: MxScreenScroll(
        children: [
          if (isSettling)
            MxSkeletonList(semanticLabel: l10n.commonLoading, rows: _waitRows)
          else
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
