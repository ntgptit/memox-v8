import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study/presentation/widgets/support/study_labels_widget.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';

/// Screen 14's resume banner (UC-STUDY-001 A3b, BR-STUDY-072): today's open
/// session of this deck, and the choice to take it up. The dot is
/// decorative, in the primary ink (UI-base ledger row 28: no streak tone).
class StudyEntryResumeWidget extends StatelessWidget {
  const StudyEntryResumeWidget({
    super.key,
    required this.session,
    required this.isLocked,
    required this.onContinue,
  });

  final ResumableSession session;

  /// A start is running: Continue is locked (BR-STUDY-004).
  final bool isLocked;
  final VoidCallback onContinue;

  static const double _dotSize = 6;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
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
          Row(
            spacing: AppSpacing.micro,
            children: [
              ExcludeSemantics(
                child: SizedBox.square(
                  dimension: _dotSize,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.colors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Text(
                l10n.studyEntryResumeOverline.toUpperCase(),
                semanticsLabel: l10n.studyEntryResumeOverline,
                style: styles.overline,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.control),
          Text(
            progress == null
                ? l10n.studyEntryResumeLineNoProgress(kind, mode)
                : l10n.studyEntryResumeLine(
                    kind,
                    mode,
                    progress.completed,
                    progress.total,
                  ),
            style: styles.rowTitle,
          ),
          const SizedBox(height: AppSpacing.micro),
          Text(l10n.studyEntryResumeBody, style: styles.noteText),
          const SizedBox(height: AppSpacing.grouped),
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
