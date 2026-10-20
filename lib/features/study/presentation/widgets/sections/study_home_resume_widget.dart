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
/// session in context, its progress and Resume (Study home spec H3):
/// - the title names the deck under its root ("Korean › Words");
/// - the session's kind and mode, then the progress track and its count;
/// - Resume shares the last row with the progress while it fits, and goes
///   under it as a block on a narrow card or at a large text scale.
///
/// The dot is static and decorative, in primary, as on 14 (FE-A8 S3;
/// UI-base ledger row 28).
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

  /// The narrowest card content that holds the track, its count and a
  /// compact Resume on one row (a 360 dp phone's card).
  static const double _compactMinWidth = 280;

  /// From this text scale on, Resume takes a row of its own.
  static const double _compactMaxTextScale = 1.3;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kind = switch (session.kind) {
      SessionKind.learning => l10n.studyKindLearning,
      SessionKind.reviewing => l10n.studyKindReview,
    };
    final progress = session.progress;
    Widget resume({required bool isBlock}) => MxButton(
      label: l10n.studyHomeResume,
      icon: AppIcons.play,
      isBlock: isBlock,
      onPressed: isResuming ? null : onResume,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: context.dimens.space8,
      children: [
        MxDotOverline(label: l10n.studyHomeResumeOverline),
        // A full-width card takes the default padding; compact is for cards
        // side by side (spacing spec L5).
        MxCard(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact =
                  constraints.maxWidth >= _compactMinWidth &&
                  MediaQuery.textScalerOf(context).scale(1) <
                      _compactMaxTextScale;
              final track = progress == null || progress.total == 0
                  ? null
                  : _Track(done: progress.completed, total: progress.total);
              // Content to the closing action is 16 (spacing spec L8).
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: context.dimens.space16,
                children: [
                  _Heading(session: session, kind: kind),
                  if (isCompact)
                    Row(
                      spacing: context.dimens.space12,
                      children: [
                        Expanded(child: track ?? const SizedBox.shrink()),
                        resume(isBlock: false),
                      ],
                    ),
                  if (!isCompact) ...[?track, resume(isBlock: true)],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// The paused tile, the deck in context and the session's kind and mode.
class _Heading extends StatelessWidget {
  const _Heading({required this.session, required this.kind});

  final ResumableSession session;
  final String kind;

  static const int _titleMaxLines = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final root = session.rootName;
    return Row(
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
            spacing: context.dimens.spaceRowLine,
            children: [
              Text(
                root == null
                    ? session.deckName
                    : l10n.studyHomeResumeTitle(root, session.deckName),
                // The user's own names: two lines, then an ellipsis (The One
                // Line Rule).
                // TalkBack reads the deck, then its root, not the › glyph.
                semanticsLabel: root == null
                    ? null
                    : l10n.studyHomeResumeTitleSpoken(root, session.deckName),
                maxLines: _titleMaxLines,
                overflow: TextOverflow.ellipsis,
                style: context.texts.itemTitle,
              ),
              Text(
                // Short terms: they break only between them (The Wrap Rule).
                metaLine(
                  l10n.studyEntryResumeLineNoProgress(
                    kind,
                    l10n.studyMode(session.mode),
                  ),
                ),
                style: context.texts.body.copyWith(
                  color: context.colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The round's progress: the track, then "{done} / {total} cards" at its end.
/// The track says nothing; the count is read (FE-A8 S7).
class _Track extends StatelessWidget {
  const _Track({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) => Row(
    spacing: context.dimens.space8,
    children: [
      Expanded(child: MxLinearProgress(value: done / total)),
      Text(
        context.l10n.studyHomeResumeProgress(done, total),
        style: context.texts.meta.copyWith(
          color: context.colors.mutedForeground,
        ),
      ),
    ],
  );
}
