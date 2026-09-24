import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/presentation/widgets/support/card_list_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';

/// The card's content (kit 10): front and back, the flag and status, then
/// only the optional fields that have a value (BR-CARD-014), then tags.
class CardDetailContentWidget extends StatelessWidget {
  const CardDetailContentWidget({super.key, required this.detail});

  final CardDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final card = detail.card;
    final status = detail.displayStatus;
    final optional = [
      (AppIcons.example, l10n.cardFieldExample, card.example),
      (AppIcons.hint, l10n.cardFieldHint, card.hint),
      (AppIcons.pronunciation, l10n.cardFieldPronunciation, card.pronunciation),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
      child: MxCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.grouped,
          children: [
            // Status first, so a long front keeps the full width.
            Row(
              spacing: AppSpacing.control,
              children: [
                MxStatusBadge(
                  status: mxCardStatus(status),
                  label: l10n.cardStatus(status),
                ),
                // Its own node, or the label merges into the card's.
                if (card.isFlagged)
                  Semantics(
                    container: true,
                    child: Icon(
                      AppIcons.flagged,
                      size: AppIconSize.inline,
                      semanticLabel: l10n.cardFlaggedLabel,
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.micro,
              children: [
                Text(card.front, style: styles.screenTitle),
                Text(card.back, style: styles.dialogBody),
              ],
            ),
            for (final (icon, label, value) in optional)
              if (value != null && value.trim().isNotEmpty)
                _OptionalField(icon: icon, label: label, value: value),
            if (detail.tags.isNotEmpty)
              Wrap(
                spacing: AppSpacing.micro,
                runSpacing: AppSpacing.micro,
                children: [
                  for (final tag in detail.tags) MxTagChip(label: tag.name),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionalField extends StatelessWidget {
  const _OptionalField({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.control,
      children: [
        Icon(icon, size: AppIconSize.inline),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.micro,
            children: [
              Text(
                label.toUpperCase(),
                semanticsLabel: label,
                style: styles.overline,
              ),
              Text(value, style: styles.dialogBody),
            ],
          ),
        ),
      ],
    );
  }
}
