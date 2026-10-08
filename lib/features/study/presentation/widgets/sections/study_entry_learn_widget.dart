import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/domain/models/study_entry_model.dart';
import 'package:memox/features/study/presentation/states/study_entry_offer_state.dart';
import 'package:memox/features/study/presentation/widgets/support/study_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

/// Screen 14's Learn row: the stages a learning session runs and how many
/// new cards it takes (BR-STUDY-056, BR-STUDY-057). Its button starts the
/// session directly (BR-STUDY-051); until every stage is built it says
/// "Coming soon" instead (FE-A6 spec §3). When the footer already offers
/// Learn, the row has no button (critique 2026-09-30 part 3d-1, D2).
class StudyEntryLearnWidget extends StatelessWidget {
  const StudyEntryLearnWidget({
    super.key,
    required this.entry,
    required this.offer,
    this.onLearn,
  });

  final StudyEntry entry;
  final StudyEntryOffer offer;

  /// Opens a learning session; null while a start runs (BR-STUDY-004).
  final VoidCallback? onLearn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final line = l10n.studyEntryLearnLine(
      l10n.studyLearnStages(entry.schedulerType),
      l10n.studyEntryLearnCount(offer.learnShown, entry.newCardCount),
    );
    return MxCard(
      isFullBleed: true,
      child: MxListRow(
        title: l10n.studyEntryLearnTitle,
        // The kit wraps the line; the row's own subtitle is one line.
        meta: Text(line, style: context.textStyles.noteText),
        trailing: _trailing(context),
      ),
    );
  }

  Widget? _trailing(BuildContext context) {
    final l10n = context.l10n;
    // With only new cards the footer offers Learn; the row does not offer
    // it again (critique 2026-09-30 part 3d-1, D2).
    if (!offer.canLearn ||
        entryFooterActionOf(offer) == EntryFooterAction.learn) {
      return null;
    }
    return MxButton(
      label: l10n.studyEntryLearn,
      icon: AppIcons.starterDecks,
      size: MxButtonSize.compact,
      tone: MxButtonTone.secondary,
      onPressed: onLearn,
    );
  }
}
