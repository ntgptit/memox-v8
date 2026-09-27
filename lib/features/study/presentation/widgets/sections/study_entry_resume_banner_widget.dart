import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/presentation/providers/study_session_view_provider.dart';
import 'package:memox/features/study/presentation/widgets/support/study_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';

/// The resume banner (kit 14, BR-STUDY-072): today's `in_progress` session
/// of this deck, with its kind, stage and progress read from the session
/// itself.
class StudyEntryResumeBannerWidget extends ConsumerWidget {
  const StudyEntryResumeBannerWidget({
    super.key,
    required this.sessionId,
    required this.isBusy,
    required this.onContinue,
  });

  final String sessionId;
  final bool isBusy;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final view = switch (ref.watch(studySessionViewProvider(sessionId))) {
      AsyncData(value: Ok(:final value)) => value,
      _ => null,
    };
    final progress = view?.progress;
    return MxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.grouped,
        children: [
          Text(
            l10n.studyEntryResumeOverline.toUpperCase(),
            semanticsLabel: l10n.studyEntryResumeOverline,
            style: styles.overline,
          ),
          // Data displays without their data are hidden (spec A5).
          if (view != null && progress != null)
            Text(
              l10n.studyEntryResumeLine(
                l10n.studySessionKind(view.kind),
                l10n.studyMode(view.currentMode),
                progress.completed,
                progress.total,
              ),
              style: styles.dialogBody,
            ),
          Text(l10n.studyEntryResumeExplain, style: styles.rowDescription),
          MxButton(
            label: l10n.studyEntryContinue,
            isBlock: true,
            isLoading: isBusy,
            onPressed: isBusy ? null : onContinue,
          ),
        ],
      ),
    );
  }
}
