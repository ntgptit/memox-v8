import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study/presentation/widgets/support/study_deck_path_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_labels_widget.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_dot_overline.dart';
import 'package:memox/shared/widgets/mx_linear_progress.dart';
import 'package:memox/shared/widgets/mx_term_line.dart';

/// Screen 14's resume banner (UC-STUDY-001 A3b, BR-STUDY-072): today's open
/// session, of this deck or of another one, which it then names by its
/// path, its progress as text and track (FE-A8 H2), and the choice to take
/// it up. The dot is static and decorative, in the primary foreground
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
    return MxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MxDotOverline(label: l10n.studyEntryResumeOverline),
          SizedBox(height: context.dimens.space8),
          if (!isOnThisDeck) ...[
            StudyDeckPathWidget(path: session.deckPath),
            SizedBox(height: context.dimens.spaceRowLine),
          ],
          // Short terms, laid out whole (The Wrap Rule).
          MxTermLine.text(
            progress == null
                ? l10n.studyEntryResumeLineNoProgress(kind, mode)
                : l10n.studyEntryResumeLine(
                    kind,
                    mode,
                    progress.completed,
                    progress.total,
                  ),
            role: MxTermLineRole.sectionTitle,
            tone: MxTermTone.foreground,
          ),
          if (progress != null && progress.total > 0) ...[
            SizedBox(height: context.dimens.space8),
            MxLinearProgress(value: progress.completed / progress.total),
          ],
          SizedBox(height: context.dimens.space4),
          Text(
            l10n.studyEntryResumeBody,
            style: context.texts.body.copyWith(
              color: context.colors.mutedForeground,
            ),
          ),
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
