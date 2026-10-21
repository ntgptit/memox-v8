import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/features/study/presentation/widgets/overlays/study_deck_location_sheet_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_session_title_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_labels_widget.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_dot_overline.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_linear_progress.dart';
import 'package:memox/shared/widgets/mx_term_line.dart';

/// Screen 13's Resume card (UC-STUDY-002, BR-STUDY-075): today's open
/// session in context, its progress and Resume (Study home spec H3):
/// - the title names the deck alone, its location one tap away (owner
///   2026-10-21);
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
                  _Heading(
                    session: session,
                    kind: kind,
                    isResuming: isResuming,
                  ),
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

/// The paused tile, then the deck by its name with the session's kind and
/// mode under it and the ⓘ to its location (owner 2026-10-21, spec D2).
/// The name comes before the decorative tile (D9): the tile shows only
/// under a 1.3 text scale while the name, as drawn, fits two lines beside
/// it.
class _Heading extends StatelessWidget {
  const _Heading({
    required this.session,
    required this.kind,
    required this.isResuming,
  });

  final ResumableSession session;
  final String kind;
  final bool isResuming;

  static const double _tileMaxTextScale = 1.3;
  static const int _nameMaxLines = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = StudySessionTitleWidget(
      path: session.deckPath,
      // Short terms, laid out whole (The Wrap Rule).
      line: MxTermLine.text(
        l10n.studyEntryResumeLineNoProgress(kind, l10n.studyMode(session.mode)),
      ),
      onShowLocation: isResuming
          ? null
          : () => showStudyDeckLocationSheet(context, session.deckPath),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!_hasRoomForTile(context, constraints.maxWidth)) return title;
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
            Expanded(child: title),
          ],
        );
      },
    );
  }

  /// Under a 1.3 text scale, the name as drawn fits two lines in the width
  /// the tile and the ⓘ leave it.
  bool _hasRoomForTile(BuildContext context, double width) {
    if (MediaQuery.textScalerOf(context).scale(1) >= _tileMaxTextScale) {
      return false;
    }
    final dimens = context.dimens;
    final nameWidth =
        width - MxIconTile.mediumBox - dimens.space12 - dimens.sizeControl;
    final painter = drawnTextPainter(
      context,
      session.deckPath.last,
      style: context.texts.itemTitle,
      maxLines: _nameMaxLines,
    )..layout(maxWidth: nameWidth);
    final fits = !painter.didExceedMaxLines;
    painter.dispose();
    return fits;
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
