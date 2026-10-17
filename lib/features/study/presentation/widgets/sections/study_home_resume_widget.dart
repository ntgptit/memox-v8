import 'package:flutter/widgets.dart';
import 'package:memox/l10n/meta_line.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study/presentation/widgets/support/study_labels_widget.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_dot_overline.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kind = switch (session.kind) {
      SessionKind.learning => l10n.studyKindLearning,
      SessionKind.reviewing => l10n.studyKindReview,
    };
    final mode = l10n.studyMode(session.mode);
    final progress = session.progress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: context.dimens.space8,
      children: [
        MxDotOverline(label: l10n.studyHomeResumeOverline),
        MxCard(
          isCompact: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: context.dimens.space12,
            children: [
              Row(
                spacing: context.dimens.space12,
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
                      spacing: context.dimens.space4,
                      children: [
                        Text(session.deckName, style: context.texts.itemTitle),
                        Text(
                          // Short terms: they break only between them (The Wrap Rule).
                          metaLine(
                            progress == null
                                ? l10n.studyEntryResumeLineNoProgress(
                                    kind,
                                    mode,
                                  )
                                : l10n.studyEntryResumeLine(
                                    kind,
                                    mode,
                                    progress.completed,
                                    progress.total,
                                  ),
                          ),
                          style: context.texts.body.copyWith(
                            color: context.colors.mutedForeground,
                          ),
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
