import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/monitoring/presentation/controllers/monitoring_list_controller.dart';
import 'package:memox/features/monitoring/presentation/widgets/sections/monitoring_filter_bar_widget.dart';
import 'package:memox/features/monitoring/presentation/widgets/sections/monitoring_server_list_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

/// The Server tab: the search field and the filters above the list, which
/// alone scrolls. The search field's text is the screen's, so a reset of
/// the filters can clear it.
class MonitoringServerTabWidget extends ConsumerWidget {
  const MonitoringServerTabWidget({
    super.key,
    required this.search,
    required this.onOpenLog,
    required this.onOpenNotSent,
    required this.onClearFilters,
  });

  final TextEditingController search;
  final ValueChanged<String> onOpenLog;
  final VoidCallback onOpenNotSent;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.watch(monitoringListControllerProvider.notifier);
    final filter = ref.watch(
      monitoringListControllerProvider.select((state) => state.filter),
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.grouped,
            AppSpacing.gutter,
            AppSpacing.control,
          ),
          child: MxSearchField(
            controller: search,
            hintText: l10n.monitoringSearchHint,
            clearLabel: l10n.monitoringSearchClear,
            onChanged: controller.search,
          ),
        ),
        MonitoringFilterBarWidget(
          filter: filter,
          onChanged: controller.setFilter,
        ),
        Expanded(
          child: MonitoringServerListWidget(
            onOpenLog: onOpenLog,
            onOpenNotSent: onOpenNotSent,
            onClearFilters: onClearFilters,
          ),
        ),
      ],
    );
  }
}
