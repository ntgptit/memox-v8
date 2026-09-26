import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_workload_breakdown_line.dart';

/// Screen 13's "Your decks": every root deck with its whole-tree workload,
/// in the order the read model gives (BR-STUDY-076). Each row always states
/// its three counts; a deck with no card is shown but cannot be opened, and
/// says so (FE-A8 S4).
class StudyHomeDecksWidget extends StatelessWidget {
  const StudyHomeDecksWidget({
    super.key,
    required this.decks,
    required this.onOpenDeck,
    required this.onOpenLibrary,
  });

  final List<StudyHomeDeck> decks;
  final ValueChanged<String> onOpenDeck;
  final VoidCallback onOpenLibrary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxListSectionHeader(
          label: l10n.studyHomeDecks,
          trailing: MxButton(
            label: l10n.studyHomeLibrary,
            size: MxButtonSize.compact,
            tone: MxButtonTone.secondary,
            onPressed: onOpenLibrary,
          ),
        ),
        MxCard(
          isFullBleed: true,
          child: Column(
            children: [
              for (final (index, deck) in decks.indexed)
                _Row(
                  deck: deck,
                  hasDivider: index < decks.length - 1,
                  onOpen: () => onOpenDeck(deck.deckId),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.deck,
    required this.hasDivider,
    required this.onOpen,
  });

  final StudyHomeDeck deck;
  final bool hasDivider;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final due = deck.overdueCount + deck.dueTodayCount;
    return MxListRow(
      title: deck.name,
      leading: const MxIconTile(icon: AppIcons.library),
      meta: MxWorkloadBreakdownLine(
        overdueCount: deck.overdueCount,
        todayCount: deck.dueTodayCount,
        newCount: deck.newCount,
        overdueLabel: l10n.workloadOverdue,
        todayLabel: l10n.workloadToday,
        newLabel: l10n.workloadNew,
        fallback: deck.canStudy
            ? l10n.workloadNothingDue(deck.cardCount)
            : l10n.workloadNoCards,
      ),
      trailing: due > 0 ? MxBadge(label: l10n.studyHomeRowDue(due)) : null,
      hasChevron: due == 0 && deck.canStudy,
      // A deck with no card keeps the action but disables it, so it is
      // dimmed and read as a disabled button, not silently inert (S4).
      onTap: onOpen,
      isEnabled: deck.canStudy,
      hasDivider: hasDivider,
    );
  }
}
