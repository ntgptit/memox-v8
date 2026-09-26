import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/study/presentation/widgets/support/study_labels_widget.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';

/// A stage whose screen is not built yet (FE-A6 spec §3): the session is
/// kept, and ✕ closes it. The entry never offers such a stage; a session
/// reaches one only when a test opens it past Browse.
class StudyModeNotBuiltWidget extends StatelessWidget {
  const StudyModeNotBuiltWidget({super.key, required this.mode});

  final StudyMode mode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: Center(
        child: MxEmptyState(
          icon: AppIcons.upcoming,
          title: l10n.studyModeNotBuiltTitle(l10n.studyMode(mode)),
          body: l10n.studyModeNotBuiltBody,
          tone: MxEmptyStateTone.neutral,
          isCompact: true,
        ),
      ),
    );
  }
}
