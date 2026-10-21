import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study/presentation/widgets/overlays/study_deck_location_sheet_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_session_title_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_labels_widget.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_dot_overline.dart';
import 'package:memox/shared/widgets/mx_linear_progress.dart';
import 'package:memox/shared/widgets/mx_term_line.dart';

/// Screen 14's resume banner (UC-STUDY-001 A3b, BR-STUDY-072): today's open
/// session, of this deck or of another one, which it then names, its
/// location one tap away (owner 2026-10-21), its progress as text and track
/// (FE-A8 H2), and the choice to take it up. The dot is static and decorative, in the primary foreground
/// (UI-base ledger row 28: no streak tone; FE-A8 S3: no pulse).
class StudyEntryResumeWidget extends StatelessWidget {
  const StudyEntryResumeWidget({
    super.key,
    required this.session,
    required this.isOnThisDeck,
    required this.isLocked,
    required this.onContinue,
  });

  final ResumableSession session;

  /// The session was opened on the deck this entry shows; otherwise the
  /// banner names the deck it belongs to, so the two are never confused
  /// (owner 2026-10-21).
  final bool isOnThisDeck;

  /// A start is running: Continue is locked (BR-STUDY-004).
  final bool isLocked;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kind = switch (session.kind) {
      SessionKind.learning => l10n.studyKindLearning,
      SessionKind.reviewing => l10n.studyKindReview,
    };
    final mode = l10n.studyMode(session.mode);
    final progress = session.progress;
    final sessionLine = progress == null
        ? l10n.studyEntryResumeLineNoProgress(kind, mode)
        : l10n.studyEntryResumeLine(
            kind,
            mode,
            progress.completed,
            progress.total,
          );
    return MxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Another deck's session says so first (owner 2026-10-21).
          MxDotOverline(
            label: isOnThisDeck
                ? l10n.studyEntryResumeOverline
                : l10n.studyEntryResumeOverlineOtherDeck,
          ),
          SizedBox(height: context.dimens.space8),
          // The card's lead line is itemTitle: another deck's name leads, or
          // on this deck the session line (owner 2026-10-21, spec §3.3).
          if (isOnThisDeck)
            MxTermLine.text(
              sessionLine,
              role: MxTermLineRole.itemTitle,
              tone: MxTermTone.foreground,
            ),
          if (!isOnThisDeck)
            StudySessionTitleWidget(
              path: session.deckPath,
              line: MxTermLine.text(sessionLine),
              onShowLocation: isLocked
                  ? null
                  : () => showStudyDeckLocationSheet(context, session.deckPath),
            ),
          if (progress != null && progress.total > 0) ...[
            SizedBox(height: context.dimens.space8),
            MxLinearProgress(value: progress.completed / progress.total),
          ],
          // Content to the closing action is 16 (spacing spec L8).
          SizedBox(height: context.dimens.space16),
          MxButton(
            label: l10n.studyEntryContinue,
            icon: AppIcons.play,
            isBlock: true,
            onPressed: isLocked ? null : onContinue,
          ),
        ],
      ),
    );
  }
}
