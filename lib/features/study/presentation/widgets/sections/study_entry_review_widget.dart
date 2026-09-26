import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/study/presentation/states/study_entry_offer_state.dart';
import 'package:memox/features/study/presentation/widgets/support/study_labels_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

/// Screen 14's review modes (UC-STUDY-001 step 4): each with its card count,
/// or its reason when the due cards cannot run it (BR-STUDY-044,
/// BR-MODE-009), or "Coming soon" while the app has no screen for it (FE-A6
/// spec §3). Nothing here can be picked until a mode is built.
class StudyEntryReviewWidget extends StatelessWidget {
  const StudyEntryReviewWidget({super.key, required this.reviews});

  final List<ReviewOffer> reviews;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasUnavailable = reviews.any(
      (review) => review.status == ReviewOfferStatus.unavailable,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxListSectionHeader(label: l10n.studyEntryReviewHeader),
        MxCard(
          isFullBleed: true,
          child: Column(
            children: [
              for (final (index, review) in reviews.indexed)
                MxOptionRow(
                  title: l10n.studyMode(review.option.mode),
                  description: _description(l10n, review),
                  isSelected: false,
                  onSelected: null,
                  trailing: _badge(l10n, review),
                  hasDivider: index < reviews.length - 1,
                ),
            ],
          ),
        ),
        if (hasUnavailable) ...[
          const SizedBox(height: AppSpacing.grouped),
          MxNote(text: l10n.studyEntryUnavailableNote),
        ],
      ],
    );
  }

  static String? _description(AppLocalizations l10n, ReviewOffer review) {
    final reason = review.option.unavailableReason;
    if (reason != null) return l10n.studyReason(reason);
    return l10n.studyModeBody(review.option.mode);
  }

  static MxBadge _badge(AppLocalizations l10n, ReviewOffer review) =>
      switch (review.status) {
        ReviewOfferStatus.available => MxBadge(
          label: l10n.studyEntryModeCards(review.option.cardCount),
        ),
        ReviewOfferStatus.unavailable => MxBadge(
          label: l10n.studyEntryNotAvailable,
          tone: MxBadgeTone.neutral,
        ),
        ReviewOfferStatus.comingSoon => MxBadge(
          label: l10n.studyComingSoon,
          tone: MxBadgeTone.neutral,
        ),
      };
}
