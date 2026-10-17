import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/presentation/providers/topik_catalog_provider.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';

/// Screen 13's Practice section (detail file 13, owner brief 2026-10-15):
/// one row that opens TOPIK, with the number of valid tests once known. The
/// row opens TOPIK whatever the read says: screen 34 shows its own error.
class TopikPracticeEntryWidget extends ConsumerWidget {
  const TopikPracticeEntryWidget({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final count = ref.watch(topikCatalogProvider).value?.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MxListSectionHeader(label: l10n.topikPractice),
        MxCard(
          isFullBleed: true,
          child: MxListRow(
            title: l10n.topikEntryTitle,
            meta: count == null
                ? null
                : Text(
                    l10n.topikTestCount(count),
                    style: context.texts.body.copyWith(
                      color: context.colors.mutedForeground,
                    ),
                  ),
            leading: const MxIconTile(icon: AppIcons.fileText),
            hasChevron: true,
            onTap: onOpen,
          ),
        ),
      ],
    );
  }
}
