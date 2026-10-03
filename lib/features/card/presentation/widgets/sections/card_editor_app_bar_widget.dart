import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

/// The card editor's top bar: close or Back, and in edit the flag toggle
/// (ruling P4a-L6).
class CardEditorAppBarWidget extends StatelessWidget {
  const CardEditorAppBarWidget({
    super.key,
    required this.isCreating,
    required this.isCardGone,
    required this.isFlagged,
    required this.isSaving,
    required this.onClose,
    required this.onToggleFlag,
  });

  final bool isCreating;
  final bool isCardGone;
  final bool isFlagged;
  final bool isSaving;
  final VoidCallback onClose;
  final VoidCallback onToggleFlag;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxAppBar(
      title: isCreating ? l10n.cardAddTitle : l10n.cardEditTitle,
      density: MxAppBarDensity.content,
      leading: MxIconButton(
        icon: isCreating ? AppIcons.close : AppIcons.back,
        semanticLabel: isCreating ? l10n.cardClose : l10n.commonBack,
        onPressed: isSaving ? null : onClose,
      ),
      actions: [
        // Ruling P4a-L6: the flag toggles here, in edit only.
        if (!isCreating && !isCardGone)
          // One node: the button and its toggled state.
          MergeSemantics(
            child: Semantics(
              toggled: isFlagged,
              child: MxIconButton(
                icon: isFlagged ? AppIcons.flagged : AppIcons.flag,
                semanticLabel: isFlagged
                    ? l10n.cardFlagClear
                    : l10n.cardFlagLabel,
                onPressed: onToggleFlag,
              ),
            ),
          ),
      ],
    );
  }
}
