import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/progress/domain/models/progress_level_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

/// One row of a Progress level (kit 22): a deck, or the level's total
/// (FE-A9 D2), with the four numbers of the range (BR-PROGRESS-001). A deck
/// opens its own level; the total is not a button. A row with no activity
/// keeps full contrast and says so (D11).
class ProgressDeckRowWidget extends StatelessWidget {
  const ProgressDeckRowWidget({
    super.key,
    required this.name,
    required this.numbers,
    required this.hasDivider,
    this.onOpen,
  });

  final String name;
  final ProgressNumbers numbers;
  final bool hasDivider;

  /// Null for the total row.
  final VoidCallback? onOpen;

  static const String _separator = ' · ';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final colors = context.colors;
    final derived = context.derivedColors;
    final caption = styles.footerCaption;
    final isActive = numbers.hasActivity;
    return MxListRow(
      title: name,
      meta: isActive
          ? Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: l10n.progressRowDays(numbers.activeDays)),
                  const TextSpan(text: _separator),
                  TextSpan(
                    text: l10n.progressRowLearning(numbers.learningCardDays),
                    style: styles.captionIn(derived.statusLearningInk),
                  ),
                  const TextSpan(text: _separator),
                  TextSpan(
                    text: l10n.progressRowReviewing(numbers.reviewingCardDays),
                    style: styles.captionIn(derived.primaryInk),
                  ),
                ],
              ),
              style: caption,
            )
          : Text(l10n.progressNoActivity, style: caption),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${numbers.activeCards}',
            style: styles.factValue(
              isActive ? colors.onSurface : colors.onSurfaceVariant,
            ),
          ),
          Text(l10n.progressRowCards, style: caption),
        ],
      ),
      onTap: onOpen,
      hasDivider: hasDivider,
    );
  }
}
