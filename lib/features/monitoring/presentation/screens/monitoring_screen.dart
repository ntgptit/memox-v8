import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/app_icons.dart';
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
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';

/// Screen 28, Monitoring (ADR-018 §8): the admin reads the app's logs and
/// triages them. Not in the kit; shaped with Impeccable 2026-09-29. Two
/// tabs: the server's logs and the device's buffer. Navigation arrives as
/// callbacks.
class MonitoringScreen extends ConsumerStatefulWidget {
  const MonitoringScreen({
    super.key,
    required this.onOpenServerLog,
    required this.onOpenPendingLog,
    this.pendingHeader,
  });

  final ValueChanged<String> onOpenServerLog;
  final ValueChanged<String> onOpenPendingLog;

  /// A row `app/` draws at the top of the Not sent tab: the SQL log switch
  /// (SQL log switch spec §5). The screen never imports the settings feature
  /// (ADR-011), so it takes the row as a slot, as Settings takes the Admin
  /// rows.
  final Widget? pendingHeader;

  @override
  ConsumerState<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends ConsumerState<MonitoringScreen> {
  final _search = TextEditingController();
  var _tab = MonitoringTab.server;
  var _isRefreshing = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _search.clear();
    ref.read(monitoringListControllerProvider.notifier).clearFilters();
  }

  /// The Refresh action stays off until the first page lands, so a tap is
  /// seen (and heard as disabled) rather than doing nothing visible.
  Future<void> _refresh(MonitoringListController controller) async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await controller.refresh();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
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
    final listController = ref.watch(monitoringListControllerProvider.notifier);
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.monitoringTitle,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
        actions: [
          // The drag down has no TalkBack or keyboard equivalent; the Not
          // sent tab watches its rows and needs none.
          if (_tab == MonitoringTab.server)
            MxIconButton(
              icon: AppIcons.retry,
              semanticLabel: l10n.commonRefresh,
              onPressed: _isRefreshing
                  ? null
                  : () => unawaited(_refresh(listController)),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.screenMargin,
              context.dimens.space8,
              context.screenMargin,
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
                header: widget.pendingHeader,
              ),
            },
          ),
        ],
      ),
    );
  }
}
