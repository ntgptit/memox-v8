import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/monitoring/presentation/controllers/monitoring_list_controller.dart';
import 'package:memox/features/monitoring/presentation/controllers/pending_logs_controller.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_tab_state.dart';
import 'package:memox/features/monitoring/presentation/widgets/sections/monitoring_pending_tab_widget.dart';
import 'package:memox/features/monitoring/presentation/widgets/sections/monitoring_server_tab_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';

/// Screen 28, Monitoring (ADR-018 §8): the admin reads the app's logs and
/// triages them. Not in the kit; shaped with Impeccable 2026-09-29. Two
/// tabs: the server's logs and the device's buffer. Navigation arrives as
/// callbacks.
class MonitoringScreen extends ConsumerStatefulWidget {
  const MonitoringScreen({
    super.key,
    required this.onOpenServerLog,
    required this.onOpenPendingLog,
  });

  final ValueChanged<String> onOpenServerLog;
  final ValueChanged<String> onOpenPendingLog;

  @override
  ConsumerState<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends ConsumerState<MonitoringScreen> {
  final _search = TextEditingController();
  var _tab = MonitoringTab.server;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _search.clear();
    ref.read(monitoringListControllerProvider.notifier).clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Both tabs' controllers live as long as the screen, so switching tabs
    // or coming back from a detail keeps the pages read (spec §3.5).
    ref.listen(
      monitoringListControllerProvider.select((state) => state.filter),
      (_, _) {},
    );
    final waiting = ref.watch(
      pendingLogsControllerProvider.select(
        (state) => state.logs.value?.total ?? 0,
      ),
    );
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.control,
              AppSpacing.gutter,
              0,
            ),
            child: MxSegmentedTray<MonitoringTab>(
              segments: [
                MxSegment(
                  value: MonitoringTab.server,
                  label: l10n.monitoringTabServer,
                ),
                MxSegment(
                  value: MonitoringTab.notSent,
                  label: l10n.monitoringTabNotSent(waiting),
                ),
              ],
              selected: _tab,
              onSelected: (tab) => setState(() => _tab = tab),
            ),
          ),
          Expanded(
            child: switch (_tab) {
              MonitoringTab.server => MonitoringServerTabWidget(
                search: _search,
                onOpenLog: widget.onOpenServerLog,
                onOpenNotSent: () =>
                    setState(() => _tab = MonitoringTab.notSent),
                onClearFilters: _clearFilters,
              ),
              MonitoringTab.notSent => MonitoringPendingTabWidget(
                onOpenLog: widget.onOpenPendingLog,
              ),
            },
          ),
        ],
      ),
    );
  }
}
