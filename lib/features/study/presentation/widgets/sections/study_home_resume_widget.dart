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
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_linear_progress.dart';

/// Screen 13's Resume card (UC-STUDY-002, BR-STUDY-075): today's open
/// session, its progress and Resume. The dot is static and decorative, in
/// primary, as on 14 (FE-A8 S3; UI-base ledger row 28).
class StudyHomeResumeWidget extends StatelessWidget {
  const StudyHomeResumeWidget({
    super.key,
    required this.session,
    required this.isResuming,
    required this.onResume,
  });

  final ResumableSession session;

  /// A Resume runs: the button waits (BR-STUDY-004).
  final bool isResuming;
  final VoidCallback onResume;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.control,
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
            Flexible(
              child: Text(
                l10n.studyHomeResumeOverline.toUpperCase(),
                semanticsLabel: l10n.studyHomeResumeOverline,
                style: styles.overline,
              ),
            ),
          ],
        ),
        MxCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.grouped,
            children: [
              Row(
                spacing: AppSpacing.grouped,
                children: [
                  const ExcludeSemantics(
                    child: MxIconTile(
                      icon: AppIcons.pause,
                      size: MxIconTileSize.medium,
                      tone: MxIconTileTone.primary,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: AppSpacing.micro,
                      children: [
                        Text(session.deckName, style: styles.rowTitle),
                        Text(
                          progress == null
                              ? l10n.studyEntryResumeLineNoProgress(kind, mode)
                              : l10n.studyEntryResumeLine(
                                  kind,
                                  mode,
                                  progress.completed,
                                  progress.total,
                                ),
                          style: styles.noteText,
                        ),
                        if (progress != null && progress.total > 0)
                          MxLinearProgress(
                            value: progress.completed / progress.total,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              MxButton(
                label: l10n.studyHomeResume,
                icon: AppIcons.play,
                isBlock: true,
                onPressed: isResuming ? null : onResume,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
