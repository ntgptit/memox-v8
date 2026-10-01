import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';

/// Whether a root's algorithm can still change (screen 02): open while no
/// card has finished learning, locked from then until a reset (BR-SRS-003).
/// The lock is named in words, not colour alone.
class DeckLockStripWidget extends StatelessWidget {
  const DeckLockStripWidget({super.key, required this.view});

  final DeckView view;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final isLocked = view.isSchedulerLocked;
    final (title, body) = isLocked
        ? (
            l10n.algorithmLockedTitle(view.deck.generation!),
            l10n.algorithmLockedBody(_lockDate(context)),
          )
        : (l10n.algorithmUnlockedTitle, l10n.algorithmUnlockedBody);
    return Semantics(
      container: true,
      child: MxCard(
        // Status, not a door: no hero ground (critique 2026-09-30 part 3d-2,
        // E5; DESIGN.md "a hero leads somewhere tappable").
        isWarning: isLocked,
        // The tile centres on the title and body (owner 2026-09-26).
        child: Row(
          spacing: AppSpacing.grouped,
          children: [
            MxIconTile(
              icon: isLocked ? AppIcons.lock : AppIcons.lockOpen,
              size: MxIconTileSize.medium,
              tone: isLocked ? MxIconTileTone.warning : MxIconTileTone.primary,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.micro,
                children: [
                  Text(title, style: styles.rowTitle),
                  Text(body, style: styles.rowDescription),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The day the first card finished learning, local and for the locale.
  String _lockDate(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.yMMMd(locale)
        .format(view.deck.firstAnsweredAt!.toLocal());
  }
}
