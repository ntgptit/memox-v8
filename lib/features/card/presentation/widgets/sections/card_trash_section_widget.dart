import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/presentation/widgets/overlays/card_delete_dialog_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';

/// Kit 09 "More": moves the card being edited to the Trash after the same
/// dialog as the list's (FE-B1 D13), then closes the editor with true, so
/// the page that opened it can close too.
class CardTrashSectionWidget extends StatelessWidget {
  const CardTrashSectionWidget({super.key, required this.card});

  final CardEntity card;

  Future<void> _move(BuildContext context) async {
    // Taken before the dialog: once the card is gone the editor swaps the
    // form for its gone state, and [context] with it. The edits are left
    // behind with the card, so the route closes without asking.
    final navigator = Navigator.of(context);
    final isMoved = await showDeleteCardsDialog(
      context,
      cardIds: {card.id},
      preview: (front: card.front, back: card.back),
    );
    if (isMoved && navigator.mounted) navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The overline sits as the editor's "Optional details" does.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.micro,
              0,
              AppSpacing.micro,
              AppSpacing.control,
            ),
            child: Text(
              l10n.cardEditMore.toUpperCase(),
              semanticsLabel: l10n.cardEditMore,
              style: styles.overline,
            ),
          ),
          MxCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.micro,
              children: [
                Text(l10n.cardEditTrashTitle, style: styles.rowTitle),
                Text(l10n.cardEditTrashBody, style: styles.rowDescription),
                const SizedBox(height: AppSpacing.control),
                MxButton(
                  label: l10n.cardMoveToTrash,
                  icon: AppIcons.delete,
                  tone: MxButtonTone.outline,
                  size: MxButtonSize.small,
                  onPressed: () => unawaited(_move(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
