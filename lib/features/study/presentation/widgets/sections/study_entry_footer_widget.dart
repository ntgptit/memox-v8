import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/study/domain/models/study_entry_model.dart';
import 'package:memox/features/study/presentation/controllers/review_mode_pick_controller.dart';
import 'package:memox/features/study/presentation/controllers/study_entry_controller.dart';
import 'package:memox/features/study/presentation/states/study_entry_offer_state.dart';
import 'package:memox/features/study/presentation/states/study_start_state.dart';
import 'package:memox/features/study/presentation/widgets/support/study_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';

/// Screen 14's footer: one block action with its caption (kit), or nothing
/// when the entry offers no start. While a session opens the button spins
/// and the caption says so (BR-STUDY-004); after a failed write it is
/// Try again.
class StudyEntryFooterWidget extends ConsumerWidget {
  const StudyEntryFooterWidget({
    super.key,
    required this.deckId,
    required this.entry,
    required this.onReview,
    required this.onLearn,
    required this.onRetry,
  });

  final String deckId;
  final StudyEntry entry;
  final VoidCallback onReview;
  final VoidCallback onLearn;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final start = ref.watch(studyEntryControllerProvider(deckId));
    if (start.status == StudyStartStatus.failed) {
      return MxFooterBar(
        child: MxButton(
          label: l10n.studyEntryTryAgain,
          icon: AppIcons.retry,
          isBlock: true,
          onPressed: onRetry,
        ),
      );
    }
    final offer = studyEntryOfferOf(
      entry,
      picked: ref.watch(reviewModePickControllerProvider(deckId)),
    );
    final target = offer.reviewTarget;
    final (label, icon, caption, onPressed) = switch (entryFooterActionOf(
      offer,
    )) {
      EntryFooterAction.review when target != null => (
        entry.resumable == null
            ? l10n.studyEntryReviewCta(target.cardCount)
            : l10n.studyEntryReviewInstead,
        AppIcons.play,
        // SM-2 asks its direction next; Eight boxes names the mode (E1).
        target.isDirectionRequired
            ? l10n.studyEntryReviewCaption(target.cardCount, entry.dueCardCount)
            : l10n.studyEntryModeCaption(
                l10n.studyMode(target.mode),
                target.cardCount,
              ),
        onReview,
      ),
      EntryFooterAction.learn => (
        l10n.studyEntryLearnCta(offer.learnShown),
        AppIcons.starterDecks,
        entry.dueCardCount == 0 ? l10n.studyEntryNothingDueCaption : null,
        onLearn,
      ),
      EntryFooterAction.review || null => (null, null, null, null),
    };
    if (label == null) return const SizedBox.shrink();
    return MxFooterBar(
      caption: start.isStarting ? l10n.studyEntryStart : caption,
      child: MxButton(
        label: label,
        icon: icon,
        isBlock: true,
        isLoading: start.isStarting,
        onPressed: onPressed,
      ),
    );
  }
}
