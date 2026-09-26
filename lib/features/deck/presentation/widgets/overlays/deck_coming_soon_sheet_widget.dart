import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

/// What the Library will offer later (spec A4, amended): one place that
/// names each feature instead of disabled controls across the screens.
/// Nothing here is actionable.
Future<void> showDeckComingSoonSheet(BuildContext context) =>
    showMxBottomSheet<void>(
      context,
      builder: (_) => const DeckComingSoonSheetWidget(),
    );

class DeckComingSoonSheetWidget extends StatelessWidget {
  const DeckComingSoonSheetWidget({super.key});

  static List<(IconData, String, String)> _features(AppLocalizations l10n) => [
    (AppIcons.settings, l10n.deckStudyOptions, l10n.comingSoonStudyOptionsBody),
    (
      AppIcons.progress,
      l10n.comingSoonProgressSort,
      l10n.comingSoonProgressSortBody,
    ),
    (AppIcons.tag, l10n.libraryTags, l10n.comingSoonTagsBody),
    (
      AppIcons.starterDecks,
      l10n.libraryStarterDecks,
      l10n.comingSoonStarterDecksBody,
    ),
    (AppIcons.delete, l10n.libraryTrash, l10n.comingSoonTrashBody),
    (AppIcons.transfer, l10n.comingSoonTransfer, l10n.comingSoonTransferBody),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final features = _features(l10n);
    return MxBottomSheet(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.card,
          AppSpacing.micro,
          AppSpacing.card,
          AppSpacing.grouped,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.micro,
          children: [
            Text(l10n.libraryComingSoon, style: styles.compactTitle),
            Text(l10n.libraryComingSoonBody, style: styles.dialogBody),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.control),
        child: Column(
          children: [
            for (final (index, (icon, title, body)) in features.indexed)
              MxListRow(
                title: title,
                subtitle: body,
                leading: MxIconTile(icon: icon),
                hasDivider: index < features.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}
