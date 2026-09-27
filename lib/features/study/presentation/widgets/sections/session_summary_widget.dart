import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/states/session_ending_state.dart';
import 'package:memox/features/study/presentation/widgets/sections/session_summary_facts_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/session_summary_hero_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_action_pair.dart';

/// Screen 21, the session summary (kit StudyResultScreenV3): how the
/// session ended, what it did, and the way back (UC-STUDY-001 step 13, A3,
/// E3). A page of its own, drawn on the session's route (spec D2).
class SessionSummaryWidget extends StatelessWidget {
  const SessionSummaryWidget({
    super.key,
    required this.view,
    required this.outcome,
    required this.onDone,
    required this.onStudyDeck,
  });

  final StudySessionView view;
  final SummaryOutcome outcome;

  /// Back to the deck.
  final VoidCallback onDone;

  /// The deck's Study Entry (handoff 21 ruling).
  final VoidCallback onStudyDeck;

  static const int _studyFlex = 5;
  static const int _doneFlex = 6;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final summary = view.summary;
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.summaryAppBar,
        density: MxAppBarDensity.content,
      ),
      body: MxScreenScroll(
        children: [
          const SizedBox(height: AppSpacing.micro),
          if (summary != null) ...[
            SessionSummaryHeroWidget(
              view: view,
              summary: summary,
              outcome: outcome,
            ),
            if (outcome.drawsFacts && summary.hasAnswers) ...[
              const SizedBox(height: AppSpacing.grouped),
              SessionSummaryFactsWidget(view: view, summary: summary),
            ],
          ],
          ..._note(context),
        ],
      ),
      footer: MxFooterBar(
        caption: l10n.summaryDoneCaption,
        child: MxActionPair(
          leading: outcome.canStudyAgain
              ? MxButton(
                  label: l10n.studyThisDeck,
                  tone: MxButtonTone.outline,
                  icon: AppIcons.play,
                  isBlock: true,
                  isSingleLine: true,
                  onPressed: onStudyDeck,
                )
              : null,
          trailing: MxButton(
            label: l10n.summaryDone,
            icon: AppIcons.check,
            isBlock: true,
            isSingleLine: true,
            onPressed: onDone,
          ),
          leadingFlex: _studyFlex,
          trailingFlex: _doneFlex,
        ),
      ),
    );
  }

  List<Widget> _note(BuildContext context) {
    final l10n = context.l10n;
    final note = switch (outcome) {
      SummaryOutcome.schedulerChanged => MxNote(text: l10n.summaryNoteHistory),
      SummaryOutcome.contentDeleted => MxNote(
        text: l10n.summaryNoteTrash,
        icon: AppIcons.history,
      ),
      _ => null,
    };
    if (note == null) return const [];
    return [const SizedBox(height: AppSpacing.grouped), note];
  }
}
