import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

/// One tag of screen 05: its name, its cards and ⋮, which spins while the
/// tag's write runs (`busy`). A long name ends in an ellipsis; the action
/// sheet names it whole.
class TagRowWidget extends StatelessWidget {
  const TagRowWidget({
    super.key,
    required this.tag,
    required this.isBusy,
    required this.onActions,
  });

  final TagCount tag;
  final bool isBusy;
  final VoidCallback onActions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxListRow(
      titleMaxLines: 2,
      leading: const MxIconTile(icon: AppIcons.tag),
      title: tag.name,
      subtitle: l10n.tagsCardCount(tag.cardCount),
      isBusy: isBusy,
      onTap: isBusy ? null : onActions,
      trailing: MxIconButton(
        icon: AppIcons.more,
        semanticLabel: l10n.tagsRowActions(tag.name),
        onPressed: onActions,
      ),
    );
  }
}
