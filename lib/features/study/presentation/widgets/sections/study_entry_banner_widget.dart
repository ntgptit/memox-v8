import 'package:flutter/material.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/presentation/states/study_start_state.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

/// Screen 14's inline banners: refused (warning) when the cards or the
/// session changed since the screen opened, startFailed (danger) when the
/// write failed and nothing was saved (BR-STUDY-018). Nothing otherwise.
class StudyEntryBannerWidget extends StatelessWidget {
  const StudyEntryBannerWidget({super.key, required this.start});

  final StudyStartState start;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (title, message) = switch (start.status) {
      StudyStartStatus.failed => (
        l10n.studyEntryStartFailedTitle,
        l10n.studyEntryStartFailedBody,
      ),
      StudyStartStatus.refused => switch (start.refusal) {
        StudyRejection.nothingDue => (
          l10n.studyEntryRefusedDueTitle,
          l10n.studyEntryRefusedDueBody,
        ),
        StudyRejection.nothingToLearn => (
          l10n.studyEntryRefusedNewTitle,
          l10n.studyEntryRefusedNewBody,
        ),
        StudyRejection.modeUnavailable => (
          l10n.studyEntryRefusedModeTitle,
          l10n.studyEntryRefusedModeBody,
        ),
        // A Continue on a session that ended, expired or was reset.
        _ => (
          l10n.studyEntryRefusedSessionTitle,
          l10n.studyEntryRefusedSessionBody,
        ),
      },
      StudyStartStatus.idle || StudyStartStatus.starting => (null, null),
    };
    if (title == null || message == null) return const SizedBox.shrink();
    return MxInlineBanner(
      tone: start.status == StudyStartStatus.failed
          ? MxBannerTone.danger
          : MxBannerTone.warning,
      title: title,
      message: message,
    );
  }
}
