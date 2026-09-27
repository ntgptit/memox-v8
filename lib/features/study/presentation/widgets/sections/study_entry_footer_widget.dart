import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';

/// The Study Entry footer while no stage chain of this deck is built
/// (spec §3): a disabled action says what is coming, and nothing starts.
class StudyEntryFooterWidget extends StatelessWidget {
  const StudyEntryFooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxFooterBar(
      caption: l10n.studyEntryComingSoonCaption,
      child: MxButton(
        label: l10n.studyEntryComingSoon,
        isBlock: true,
        onPressed: null,
      ),
    );
  }
}
