import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/progress/domain/models/progress_level_model.dart';
import 'package:memox/features/progress/presentation/providers/progress_range_provider.dart';
import 'package:memox/features/progress/presentation/widgets/items/progress_deck_row_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_divided_column.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_note.dart';

/// A level's list (UC-PROGRESS-002 steps 1–3): the header of the range, the
/// total row (FE-A9 D2), a row per deck in the range's order
/// (BR-PROGRESS-006), the notes of a quiet range (A3) and of a deck with no
/// children (A1), and the read-only line.
class ProgressLevelListWidget extends ConsumerWidget {
  const ProgressLevelListWidget({
    super.key,
    required this.level,
    required this.isDeckLevel,
    required this.onOpenDeck,
  });

  final ProgressLevel level;

  /// A deck's level: "Sub-decks" and "Whole deck"; the library's otherwise.
  final bool isDeckLevel;
  final ValueChanged<String> onOpenDeck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final range = ref.watch(progressRangeChoiceProvider);
    final total = level.total.of(range);
    final decks = level.decksFor(range);
    // The range segment above states the range (critique 2026-09-30
    // part 3b).
    final header = isDeckLevel ? l10n.progressSubDecks : l10n.progressByDeck;
    final note = switch ((decks.isEmpty, total.hasActivity, range)) {
      (true, _, _) => l10n.progressLeafNote,
      (false, false, ProgressRange.week) => l10n.progressQuietWeek,
      (false, false, ProgressRange.month) => l10n.progressQuietMonth,
      (false, true, _) => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxListSectionHeader(label: header),
        MxCard(
          isFullBleed: true,
          child: MxDividedColumn(
            children: [
              ProgressDeckRowWidget(
                name: isDeckLevel
                    ? l10n.progressWholeDeck
                    : l10n.progressAllDecks,
                numbers: total,
              ),
              for (final deck in decks)
                ProgressDeckRowWidget(
                  name: deck.name,
                  numbers: deck.progress.of(range),
                  onOpen: () => onOpenDeck(deck.deckId),
                ),
            ],
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: AppSpacing.grouped),
          MxNote(text: note),
        ],
        const SizedBox(height: AppSpacing.gutter),
        Text(
          l10n.progressFooter,
          textAlign: TextAlign.center,
          style: context.textStyles.footerCaption,
        ),
      ],
    );
  }
}
