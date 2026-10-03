import 'package:flutter/widgets.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

/// The draft kept on this device, offered back above the fields (SP2a R9).
/// Neutral: nothing is wrong. Restore is secondary, since the footer's Save
/// is the screen's one primary (the One Indigo Rule); Discard is outline, and
/// the primary-weight action sits last.
class CardDraftBannerWidget extends StatelessWidget {
  const CardDraftBannerWidget({
    super.key,
    required this.onRestore,
    required this.onDiscard,
  });

  final VoidCallback onRestore;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxInlineBanner(
      tone: MxBannerTone.neutral,
      title: l10n.cardDraftTitle,
      message: l10n.cardDraftBody,
      actions: [
        MxButton(
          label: l10n.cardDiscard,
          size: MxButtonSize.compact,
          tone: MxButtonTone.outline,
          onPressed: onDiscard,
        ),
        MxButton(
          label: l10n.cardDraftRestore,
          size: MxButtonSize.compact,
          tone: MxButtonTone.secondary,
          onPressed: onRestore,
        ),
      ],
    );
  }
}
