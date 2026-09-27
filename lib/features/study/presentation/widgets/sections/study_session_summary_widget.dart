import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// How a session ended, as screen 21 tells it (handoff 21). `contentDeleted`
/// cannot happen in V8.0 (no Trash) and reads as a reset; `large` reads as
/// its kind's finished state until the summary carries the card limit.
enum _Ending {
  review,
  learning,
  leftEarly,
  interrupted,
  reset,
  schedulerChanged,
  saveError;

  static _Ending of(StudySessionView view) => switch (view.status) {
    SessionStatus.completed || SessionStatus.inProgress => switch (view.kind) {
      SessionKind.learning => learning,
      SessionKind.reviewing => review,
    },
    SessionStatus.abandoned =>
      view.endReason == SessionEndReason.interrupted ? interrupted : leftEarly,
    SessionStatus.invalidated =>
      view.endReason == SessionEndReason.schedulerChanged
          ? schedulerChanged
          : reset,
    SessionStatus.failed => saveError,
  };

  /// Finished or stopped by the person: studying the deck again makes sense.
  bool get offersStudyAgain =>
      this == review || this == learning || this == leftEarly;
}

/// Screen 21: the session summary, on the session's own route once it has
/// ended (spec D2).
class StudySessionSummaryWidget extends StatelessWidget {
  const StudySessionSummaryWidget({
    super.key,
    required this.view,
    required this.summary,
    required this.onDone,
    required this.onStudyThisDeck,
  });

  final StudySessionView view;
  final SessionSummary summary;
  final VoidCallback onDone;
  final VoidCallback onStudyThisDeck;

  String _title(AppLocalizations l10n, _Ending ending) => switch (ending) {
    _Ending.review => l10n.studySummaryTitleReview,
    _Ending.learning => l10n.studySummaryTitleLearning,
    _Ending.leftEarly => l10n.studySummaryTitleLeftEarly,
    _Ending.interrupted => l10n.studySummaryTitleInterrupted,
    _Ending.reset => l10n.studySummaryTitleReset,
    _Ending.schedulerChanged => l10n.studySummaryTitleSchedulerChanged,
    _Ending.saveError => l10n.studySummaryTitleSaveError,
  };

  String _body(AppLocalizations l10n, _Ending ending) => switch (ending) {
    _Ending.review => l10n.studySummaryBodyReview(summary.answeredCardCount),
    _Ending.learning => l10n.studySummaryBodyLearning(
      summary.learnedCardCount ?? 0,
    ),
    _Ending.leftEarly => l10n.studySummaryBodyLeftEarly(
      summary.answeredCardCount,
      summary.cardCount,
    ),
    _Ending.interrupted => l10n.studySummaryBodyInterrupted,
    _Ending.reset => l10n.studySummaryBodyReset,
    _Ending.schedulerChanged => l10n.studySummaryBodySchedulerChanged,
    _Ending.saveError => l10n.studySummaryBodySaveError,
  };

  IconData _icon(_Ending ending) => switch (ending) {
    _Ending.review || _Ending.learning => AppIcons.check,
    _Ending.leftEarly || _Ending.interrupted => AppIcons.play,
    _Ending.reset || _Ending.schedulerChanged => AppIcons.info,
    _Ending.saveError => AppIcons.alert,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final ending = _Ending.of(view);
    final count = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    // The kit draws no facts under an algorithm change: every card is new
    // again, and the note says nothing was lost.
    final hasFacts = ending != _Ending.schedulerChanged;
    return MxAppShell(
      appBar: MxAppBar(title: l10n.studySummaryTitle),
      body: MxScreenScroll(
        children: [
          MxCard(
            isHero: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.grouped,
              children: [
                MxIconTile(icon: _icon(ending), size: MxIconTileSize.large),
                Text(_title(l10n, ending), style: styles.screenTitle),
                Text(_body(l10n, ending), style: styles.dialogBody),
              ],
            ),
          ),
          if (hasFacts) ...[
            const SizedBox(height: AppSpacing.grouped),
            MxListSectionHeader(label: l10n.studySummaryFactsHeader),
            MxCard(
              isFullBleed: true,
              child: Column(
                children: [
                  MxListRow(
                    title: l10n.studySummaryFactAnswered,
                    trailing: Text(
                      count.format(summary.answeredCardCount),
                      style: styles.settingsLabel,
                    ),
                  ),
                  MxListRow(
                    title: l10n.studySummaryFactWrong,
                    subtitle: l10n.studySummaryFactOfTurns(summary.turnCount),
                    trailing: Text(
                      count.format(summary.wrongTurnCount),
                      style: styles.settingsLabel,
                    ),
                    hasDivider: false,
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.grouped),
            MxNote(text: l10n.studySummaryEndNoteSchedulerChanged),
          ],
        ],
      ),
      footer: MxFooterBar(
        caption: l10n.studySummaryDoneCaption,
        child: Row(
          spacing: AppSpacing.control,
          children: [
            if (ending.offersStudyAgain)
              Expanded(
                child: MxButton(
                  label: l10n.studySummaryStudyThisDeck,
                  tone: MxButtonTone.outline,
                  isBlock: true,
                  onPressed: onStudyThisDeck,
                ),
              ),
            Expanded(
              child: MxButton(
                label: l10n.studySummaryDone,
                isBlock: true,
                onPressed: onDone,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
