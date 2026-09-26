import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/states/session_ending_state.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';

/// Screen 21's facts (kit Facts): what finished, what was answered, and the
/// wrong turns out of all, each a row with its value on the right.
class SessionSummaryFactsWidget extends StatelessWidget {
  const SessionSummaryFactsWidget({
    super.key,
    required this.view,
    required this.summary,
  });

  final StudySessionView view;
  final SessionSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final colors = context.colors;
    final isLearning = view.kind == SessionKind.learning;
    final wrong = summary.wrongTurnCount;
    final turns = summary.turnCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxListSectionHeader(label: l10n.summaryFactsHeader),
        MxCard(
          isFullBleed: true,
          child: Column(
            children: [
              MxListRow(
                title: isLearning
                    ? l10n.summaryFactLearned
                    : l10n.summaryFactReviewed,
                subtitle: isLearning
                    ? l10n.summaryFactLearnedSub
                    : l10n.summaryFactReviewedSub,
                leading: const MxIconTile(
                  icon: AppIcons.learned,
                  tone: MxIconTileTone.success,
                ),
                trailing: Text(
                  l10n.studyCount(summaryFinishedCount(view, summary)),
                  style: styles.factValue(context.derivedColors.successInk),
                ),
              ),
              MxListRow(
                title: l10n.summaryFactAnswered,
                leading: const MxIconTile(icon: AppIcons.cardDeck),
                trailing: Text(
                  l10n.studyCount(summary.answeredCardCount),
                  style: styles.factValue(colors.onSurface),
                ),
              ),
              MxListRow(
                title: l10n.summaryFactWrong,
                // The kit wraps this line; the row's own subtitle is one.
                meta: Text(
                  wrong > 0
                      ? l10n.summaryFactWrongCameBack(turns)
                      : l10n.summaryFactWrongSub(turns),
                  style: styles.noteText,
                ),
                // The glyph takes its value's tone (kit ResultRow).
                leading: MxIconTile(
                  icon: AppIcons.lapses,
                  tone: wrong > 0
                      ? MxIconTileTone.caution
                      : MxIconTileTone.tinted,
                ),
                trailing: Text(
                  l10n.summaryWrongOf(wrong, turns),
                  style: styles.factValue(
                    wrong > 0
                        ? context.derivedColors.warningInk
                        : colors.onSurface,
                  ),
                ),
                hasDivider: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
