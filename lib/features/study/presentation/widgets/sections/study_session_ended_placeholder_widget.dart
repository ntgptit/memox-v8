import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// The session has ended: the same route now shows its summary (spec D2).
/// The next task fills the body with handoff 21's states.
class StudySessionEndedPlaceholderWidget extends StatelessWidget {
  const StudySessionEndedPlaceholderWidget({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxAppShell(
      appBar: MxAppBar(title: l10n.studySummaryTitle),
      body: const MxScreenScroll(children: []),
      footer: MxFooterBar(
        child: MxButton(
          label: l10n.studySummaryDone,
          isBlock: true,
          onPressed: onDone,
        ),
      ),
    );
  }
}
