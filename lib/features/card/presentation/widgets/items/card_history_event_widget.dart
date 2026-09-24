import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/domain/models/review_history_model.dart';
import 'package:memox/features/card/presentation/widgets/support/card_history_labels_widget.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_card.dart';

/// One answer in a card's history (kit 10, ruling P4b-L3): kind and action,
/// when, then the values its row stored (BR-CARD-016).
class CardHistoryEventWidget extends StatelessWidget {
  const CardHistoryEventWidget({super.key, required this.entry});

  final ReviewHistoryEntry entry;

  static const String _easePattern = '0.00';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final action = entry.action;
    final isLapse =
        action == EightBoxAction.forgotten || action == Sm2Action.again;
    final (tone, icon) = switch (entry.kind) {
      _ when isLapse => (MxBadgeTone.warning, AppIcons.lapses),
      ReviewKind.relearning => (MxBadgeTone.neutral, AppIcons.repeat),
      _ => (MxBadgeTone.primary, AppIcons.check),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.control),
      child: MxCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.control,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.control,
              runSpacing: AppSpacing.micro,
              children: [
                MxBadge(
                  label: l10n.cardHistoryEvent(
                    l10n.cardHistoryKind(entry.kind),
                    l10n.cardHistoryAction(action),
                  ),
                  tone: tone,
                  icon: icon,
                ),
                Text(
                  DateFormat.MMMd(locale)
                      .add_Hm()
                      .format(entry.answeredAt.toLocal()),
                  style: context.textStyles.counter,
                ),
              ],
            ),
            Wrap(
              spacing: AppSpacing.grouped,
              runSpacing: AppSpacing.micro,
              children: [
                for (final (icon, text) in _meta(l10n, locale))
                  _Meta(icon: icon, text: text),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Only what the row stored; before → after only when both are stored.
  List<(IconData, String)> _meta(AppLocalizations l10n, String locale) {
    final ease = NumberFormat(_easePattern, locale).format;
    return [
      (AppIcons.library, l10n.cardHistoryMode(entry.mode)),
      if ((entry.previousBox, entry.nextBox) case (final from?, final to?))
        (AppIcons.progress, l10n.cardHistoryBoxMove(from, to)),
      if ((entry.previousEaseFactor, entry.nextEaseFactor) case (
        final from?,
        final to?,
      ))
        (AppIcons.progress, l10n.cardHistoryEaseMove(ease(from), ease(to))),
      if ((entry.previousIntervalDays, entry.nextIntervalDays) case (
        final from?,
        final to?,
      ))
        (AppIcons.calendar, l10n.cardHistoryIntervalMove(from, to)),
      if (entry.usedHint ?? false) (AppIcons.hint, l10n.cardHistoryHintUsed),
      if (entry.isTimedOut) (AppIcons.timeout, l10n.cardHistoryTimedOut),
      if (entry.nextDueAt case final due?)
        (
          AppIcons.calendar,
          l10n.cardHistoryNextDue(
            DateFormat.MMMd(locale).format(due.toLocal()),
          ),
        ),
    ];
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: AppSpacing.micro,
    children: [
      Icon(icon, size: AppIconSize.inline),
      Flexible(child: Text(text, style: context.textStyles.rowDescription)),
    ],
  );
}
