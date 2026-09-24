import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_workload_line_widget.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

/// A deck in reorder mode: its drag handle takes the chevron's place (spec
/// §6.1). The list around it gives TalkBack its move actions.
class DeckReorderRowWidget extends StatelessWidget {
  const DeckReorderRowWidget({
    super.key,
    required this.tile,
    required this.index,
    this.hasDivider = true,
  });

  final DeckTile tile;

  /// The row's place in the list, which the drag handle reports.
  final int index;
  final bool hasDivider;

  @override
  Widget build(BuildContext context) => MxListRow(
    title: tile.name,
    leading: const MxIconTile(
      icon: AppIcons.library,
      size: MxIconTileSize.large,
    ),
    meta: DeckWorkloadLineWidget(
      overdueCount: tile.overdueCount,
      todayCount: tile.dueTodayCount,
      newCount: tile.newCount,
      cardCount: tile.cardCount,
    ),
    trailing: ReorderableDragStartListener(
      index: index,
      child: const SizedBox.square(
        dimension: AppSize.touchTarget,
        child: Icon(AppIcons.dragHandle),
      ),
    ),
    hasDivider: hasDivider,
  );
}
