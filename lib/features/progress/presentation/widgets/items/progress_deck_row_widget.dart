import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/progress/domain/models/progress_level_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

/// One row of a Progress level (kit 22): a deck, or the level's total
/// (FE-A9 D2), with the four numbers of the range (BR-PROGRESS-001). A deck
/// opens its own level; the total is not a button. A row with no activity
/// keeps full contrast and says so (D11). The card count and active days
/// lead the meta line, the card-days follow under their label, and a deck
/// ends in a chevron (critique 2026-09-30 part 3d-1, D3).
class ProgressDeckRowWidget extends StatelessWidget {
  const ProgressDeckRowWidget({
    super.key,
    required this.name,
    required this.numbers,
    this.onOpen,
  });

  final String name;
  final ProgressNumbers numbers;

  /// Null for the total row.
  final VoidCallback? onOpen;

  static const String _separator = ' · ';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final semantic = context.semanticColors;
    final caption = styles.footerCaption;
    final isActive = numbers.hasActivity;
    return MxListRow(
      titleMaxLines: 2,
      title: name,
      meta: isActive
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.progressRowCardsDays(
                    numbers.activeCards,
                    numbers.activeDays,
                  ),
                  style: caption,
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: l10n.progressRowCardDaysLead),
                      TextSpan(
                        text: l10n.progressRowLearning(
                          numbers.learningCardDays,
                        ),
                        style: styles.captionIn(semantic.learningText),
                      ),
                      const TextSpan(text: _separator),
                      TextSpan(
                        text: l10n.progressRowReviewing(
                          numbers.reviewingCardDays,
                        ),
                        style: styles.captionIn(semantic.primaryText),
                      ),
                    ],
                  ),
                  style: caption,
                ),
              ],
            )
          : Text(l10n.progressNoActivity, style: caption),
      // A deck opens its level; the total opens nothing (D3, FE-A9 D2).
      hasChevron: onOpen != null,
      onTap: onOpen,
    );
  }
}
