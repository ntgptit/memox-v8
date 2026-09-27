import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// The editor or the detail once its card or deck is gone (ruling P4a-L4):
/// it says why, and leads back to the deck or to the Trash (FE-B1 D11).
class CardGoneWidget extends StatelessWidget {
  const CardGoneWidget({
    super.key,
    required this.title,
    required this.body,
    required this.onBack,
    this.onOpenTrash,
  });

  final String title;
  final String body;
  final VoidCallback onBack;

  /// Hidden without it.
  final VoidCallback? onOpenTrash;

  @override
  Widget build(BuildContext context) => MxScreenScroll(
    children: [
      const SizedBox(height: AppSpacing.gutter),
      MxEmptyState(
        icon: AppIcons.searchOff,
        title: title,
        body: body,
        tone: MxEmptyStateTone.neutral,
        actionLabel: context.l10n.cardBackToDeck,
        onAction: onBack,
        secondaryActionLabel: onOpenTrash == null
            ? null
            : context.l10n.commonOpenTrash,
        onSecondaryAction: onOpenTrash,
      ),
    ],
  );
}
