import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

/// The session could not be read (UC-STUDY-001 E5): retry, or close.
class StudySessionErrorWidget extends StatelessWidget {
  const StudySessionErrorWidget({
    super.key,
    required this.onClose,
    required this.onRetry,
  });

  final VoidCallback onClose;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.navStudy,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.close,
          semanticLabel: l10n.studySessionClose,
          onPressed: onClose,
        ),
      ),
      body: MxScreenScroll(
        children: [
          MxErrorState(
            title: l10n.studySessionErrorTitle,
            body: l10n.studySessionErrorBody,
            retryLabel: l10n.commonRetry,
            onRetry: onRetry,
          ),
        ],
      ),
    );
  }
}

/// Before the session's first view: nothing to show but the wait. The
/// summary arrives with the session's view, so it has no loading of its
/// own (D2).
class StudySessionLoadingWidget extends StatelessWidget {
  const StudySessionLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) => MxAppShell(
    body: Center(child: MxSpinner(semanticLabel: context.l10n.commonLoading)),
  );
}
