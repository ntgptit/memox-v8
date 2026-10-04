import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';
import 'package:memox/features/reminders/presentation/providers/reminder_preview_digest_provider.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

/// Kit 24's "What it says": the notification's own sentence, built from the
/// same strings the notification uses, over the live workload as the
/// notification reads it, and what it never carries (BR-REMINDER-005,
/// BR-REMINDER-008; critique 2026-09-30 part 1).
class ReminderPreviewSectionWidget extends ConsumerWidget {
  const ReminderPreviewSectionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final label = switch (ref.watch(reminderPreviewDigestProvider)) {
      AsyncData(:final value?) => l10n.reminderPreviewQuoted(
        _sentence(l10n, value),
      ),
      // Loading keeps the row's place; nothing due or a failed read says
      // the reminder would stay silent (BR-REMINDER-003).
      AsyncLoading() => '',
      _ => l10n.reminderPreviewNothingDue,
    };
    return MxSection(
      title: l10n.reminderPreviewTitle,
      children: [
        MxSettingsRow(label: label, subtitle: l10n.reminderPreviewHint),
      ],
    );
  }

  /// The notification's own sentence (reminder_notification_mapper.dart),
  /// built from the same strings.
  static String _sentence(AppLocalizations l10n, ReminderDigest digest) {
    final due = l10n.reminderDueCards(digest.dueCount);
    if (digest.otherDeckCount == 0) {
      return l10n.reminderBody(due, digest.deckName);
    }
    return l10n.reminderBodyWithOthers(
      due,
      digest.deckName,
      l10n.reminderOtherDecks(digest.otherDeckCount),
    );
  }
}
