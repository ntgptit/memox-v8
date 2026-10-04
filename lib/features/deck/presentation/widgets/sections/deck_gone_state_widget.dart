import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// The open deck went to the Trash while it was on screen (spec A8): say
/// so, and go back to the Library or open the Trash (FE-B1 D11).
class DeckGoneStateWidget extends StatelessWidget {
  const DeckGoneStateWidget({
    super.key,
    required this.onBackToLibrary,
    this.onOpenTrash,
  });

  final VoidCallback onBackToLibrary;

  /// Hidden without it.
  final VoidCallback? onOpenTrash;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxScreenScroll(
      children: [
        MxEmptyState(
          icon: AppIcons.searchOff,
          title: l10n.deckGoneTitle,
          body: l10n.deckGoneBody,
          actionLabel: l10n.deckBackToLibrary,
          onAction: onBackToLibrary,
          secondaryActionLabel: onOpenTrash == null
              ? null
              : l10n.commonOpenTrash,
          onSecondaryAction: onOpenTrash,
        ),
      ],
    );
  }
}
