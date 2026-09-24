import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_workload_line_widget.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

/// One deck of a level: its tile, its name and its workload. Opening a deck
/// arrives in phase 2 (ruling L1).
class DeckRowWidget extends StatelessWidget {
  const DeckRowWidget({super.key, required this.tile, this.hasDivider = true});

  final DeckTile tile;
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
    hasDivider: hasDivider,
  );
}
