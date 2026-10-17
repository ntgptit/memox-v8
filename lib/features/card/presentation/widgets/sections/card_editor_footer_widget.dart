import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_action_pair.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The editor's save bar (kit 08/09): an inline banner after a failed save,
/// Cancel and the save button sharing the row 1 : 1 as every footer pair
/// does (DEV-169), and the caption line (ruling P4a-L3).
class CardEditorFooterWidget extends StatelessWidget {
  const CardEditorFooterWidget({
    super.key,
    required this.caption,
    required this.saveLabel,
    required this.hasFailed,
    required this.isSaving,
    required this.onCancel,
    required this.onSave,
  });

  final String caption;
  final String saveLabel;
  final bool hasFailed;
  final bool isSaving;
  final VoidCallback onCancel;

  /// Null while the card is not valid.
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxFooterBar(
      caption: caption,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: context.dimens.space8,
        children: [
          if (hasFailed)
            MxInlineBanner(
              tone: MxBannerTone.danger,
              title: l10n.cardSaveFailedTitle,
              message: l10n.cardSaveFailedBody,
              isInCommitBar: true,
            ),
          MxActionPair(
            leading: MxButton(
              label: l10n.commonCancel,
              tone: MxButtonTone.outline,
              isBlock: true,
              isSingleLine: true,
              onPressed: onCancel,
            ),
            trailing: MxButton(
              label: hasFailed ? l10n.cardRetrySave : saveLabel,
              icon: hasFailed ? AppIcons.retry : AppIcons.check,
              isBlock: true,
              isSingleLine: true,
              isLoading: isSaving,
              onPressed: onSave,
            ),
          ),
        ],
      ),
    );
  }
}
