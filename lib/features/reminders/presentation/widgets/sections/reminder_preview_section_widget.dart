import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

/// Kit 24's "What it says": the notification's own sentence, built from the
/// same strings the notification uses, over the kit's sample numbers, and
/// what it never carries (BR-REMINDER-005, BR-REMINDER-008).
class ReminderPreviewSectionWidget extends StatelessWidget {
  const ReminderPreviewSectionWidget({super.key});

  static const int _sampleDue = 86;
  static const int _sampleOtherDecks = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxSection(
      title: l10n.reminderPreviewTitle,
      children: [
        MxSettingsRow(
          label: l10n.reminderPreviewQuoted(
            l10n.reminderBodyWithOthers(
              l10n.reminderDueCards(_sampleDue),
              l10n.reminderPreviewDeck,
              l10n.reminderOtherDecks(_sampleOtherDecks),
            ),
          ),
          subtitle: l10n.reminderPreviewHint,
        ),
      ],
    );
  }
}
