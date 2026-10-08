import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_tile_signs_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

/// A deck in reorder mode, in the browse row's shape: one MxCard per deck
/// with the same glyph and structure line as the browse row (handoff 01,
/// ruling M3-D2; DEV-232). Its drag handle takes the chevron's place (spec
/// §6.1). The list around it gives TalkBack its move actions.
class DeckReorderRowWidget extends StatelessWidget {
  const DeckReorderRowWidget({
    super.key,
    required this.tile,
    required this.index,
  });

  final DeckTile tile;

  /// The row's place in the list, which the drag handle reports.
  final int index;

  @override
  Widget build(BuildContext context) => MxCard(
    isFullBleed: true,
    child: MxListRow(
      title: tile.name,
      // The meta slot, not the one-line subtitle: the structure line wraps
      // between whole terms at large text, as the browse row's does
      // (critique 2026-09-30).
      meta: Text(
        deckTileMeta(tile, context.l10n),
        style: context.textStyles.rowSubtitle,
      ),
      leading: MxIconTile(
        icon: deckTileGlyph(tile),
        size: MxIconTileSize.large,
      ),
      trailing: ReorderableDragStartListener(
        index: index,
        child: const SizedBox.square(
          dimension: AppSize.touchTarget,
          child: Icon(AppIcons.dragHandle),
        ),
      ),
    ),
  );
}
