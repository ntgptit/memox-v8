import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';

/// Screen 02's way to a new cycle: what a reset does, and the button that
/// asks for it (UC-SRS-001).
class DeckStartOverWidget extends StatelessWidget {
  const DeckStartOverWidget({super.key, required this.onReset});

  /// Off while another change to the deck's schedule is running.
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: context.dimens.space4,
        children: [
          Text(l10n.algorithmResetTitle, style: context.texts.sectionTitle),
          Text(
            l10n.algorithmResetBody,
            style: context.texts.body.copyWith(
              color: context.colors.mutedForeground,
            ),
          ),
          SizedBox(height: context.dimens.space8),
          MxButton(
            label: l10n.algorithmResetAction,
            tone: MxButtonTone.outline,
            icon: AppIcons.resetProgress,
            onPressed: onReset,
          ),
        ],
      ),
    );
  }
}
