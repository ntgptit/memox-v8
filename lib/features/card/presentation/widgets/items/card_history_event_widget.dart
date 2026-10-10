import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/domain/models/review_history_model.dart';
import 'package:memox/features/card/presentation/widgets/support/card_history_labels_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_history_rail_widget.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/l10n/relative_time.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_card.dart';

/// One answer on the card history's timeline (DEV-170, kit "Flashcard
/// history"): a dot in the outcome's foreground on the rail, then a card with the
/// outcome, when (how long ago over the date and time), the kind, and the
/// values its row stored (BR-CARD-016).
class CardHistoryEventWidget extends StatelessWidget {
  const CardHistoryEventWidget({
    super.key,
    required this.entry,
    required this.now,
  });

  final ReviewHistoryEntry entry;

  /// The clock's now, for "how long ago".
  final DateTime now;

  static const String _easePattern = '0.00';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final semantic = context.semanticColors;
    final styles = context.textStyles;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final action = entry.action;
    final isLapse =
        action == EightBoxAction.forgotten || action == Sm2Action.again;
    // A right answer is success, never mastery or the action Indigo
    // (DESIGN.md; critique 2026-09-30 tone pass, T5). The dot and the
    // moves read in the same tone's foreground.
    final (tone, icon, foreground) = switch (entry.kind) {
      _ when isLapse => (
        MxBadgeTone.warning,
        AppIcons.lapses,
        semantic.warningText,
      ),
      ReviewKind.relearning => (
        MxBadgeTone.neutral,
        AppIcons.repeat,
        colors.onSurfaceVariant,
      ),
      _ => (MxBadgeTone.success, AppIcons.check, semantic.success),
    };
    final meta = _meta(l10n, locale, foreground);
    // The dot centres on the header row, which the two-line time sets:
    // the card's 20 interior, then the middle of those lines.
    return CardHistoryRailWidget(
      dotTop:
          AppSpacing.card +
          CardHistoryRailWidget.dotTopOn(context, styles.counter, lines: 2),
      foreground: foreground,
      child: MxCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.control,
          children: [
            Row(
              spacing: AppSpacing.control,
              children: [
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: MxBadge(
                      label: l10n.cardHistoryAction(action),
                      tone: tone,
                      icon: icon,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.ago(entry.answeredAt, now),
                      style: styles.historyAgo,
                    ),
                    Text(
                      DateFormat.MMMd(locale)
                          .add_Hm()
                          .format(entry.answeredAt.toLocal()),
                      style: styles.counter,
                    ),
                  ],
                ),
              ],
            ),
            Text(
              l10n.cardHistoryKind(entry.kind),
              style: context.texts.bodyMedium,
            ),
            if (meta.isNotEmpty)
              Wrap(
                spacing: AppSpacing.grouped,
                runSpacing: AppSpacing.micro,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: meta,
              ),
          ],
        ),
      ),
    );
  }

  /// Only what the row stored; before → after only when both are stored.
  /// The moves read in the outcome's foreground; the rest carry their glyph.
  List<Widget> _meta(AppLocalizations l10n, String locale, Color foreground) {
    final ease = NumberFormat(_easePattern, locale).format;
    return [
      if ((entry.previousBox, entry.nextBox) case (final from?, final to?))
        _Meta(text: l10n.cardHistoryBoxMove(from, to), foreground: foreground),
      if ((entry.previousEaseFactor, entry.nextEaseFactor) case (
        final from?,
        final to?,
      ))
        _Meta(
          text: l10n.cardHistoryEaseMove(ease(from), ease(to)),
          foreground: foreground,
        ),
      if ((entry.previousIntervalDays, entry.nextIntervalDays) case (
        final from?,
        final to?,
      ))
        _Meta(
          text: l10n.cardHistoryIntervalMove(from, to),
          foreground: foreground,
        ),
      _Meta(text: l10n.cardHistoryMode(entry.mode), icon: AppIcons.studyMode),
      if (entry.usedHint ?? false)
        _Meta(text: l10n.cardHistoryHintUsed, icon: AppIcons.hint),
      if (entry.isTimedOut)
        _Meta(text: l10n.cardHistoryTimedOut, icon: AppIcons.timeout),
      if (entry.nextDueAt case final due?)
        _Meta(
          text: l10n.cardHistoryNextDue(
            DateFormat.MMMd(locale).format(due.toLocal()),
          ),
          icon: AppIcons.clock,
        ),
    ];
  }
}

/// One metadata item: a glyph and words, or a move in the outcome's foreground.
class _Meta extends StatelessWidget {
  const _Meta({required this.text, this.icon, this.foreground});

  final String text;
  final IconData? icon;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final foreground = this.foreground;
    final icon = this.icon;
    final style = foreground == null
        ? styles.rowDescription
        : styles.historyMove(foreground);
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.micro,
      children: [
        if (icon != null)
          // The words carry the meaning; the glyph is not read out.
          ExcludeSemantics(
            child: Icon(
              icon,
              size: AppIconSize.inline,
              color: context.colors.onSurfaceVariant,
            ),
          ),
        Flexible(child: Text(text, style: style)),
      ],
    );
  }
}
