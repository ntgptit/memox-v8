import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// Before a term: what search finds, read-only (UC-SEARCH-001 step 2; spec
/// D9). No statement runs (BR-SEARCH-003).
class SearchHintsWidget extends StatelessWidget {
  const SearchHintsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxScreenScroll(
      children: [
        const SizedBox(height: AppSpacing.control),
        MxListSectionHeader(label: l10n.searchFinds),
        MxCard(
          isFullBleed: true,
          child: Column(
            children: [
              MxListRow(
                title: l10n.searchHintDeckName,
                subtitle: l10n.searchHintDeckExample,
                leading: const MxIconTile(icon: AppIcons.library),
              ),
              MxListRow(
                title: l10n.searchHintCardTerm,
                subtitle: l10n.searchHintCardExample,
                leading: const MxIconTile(icon: AppIcons.cardDeck),
              ),
              MxListRow(
                title: l10n.searchHintTagName,
                subtitle: l10n.searchHintTagExample,
                leading: const MxIconTile(icon: AppIcons.tag),
                hasDivider: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.grouped),
        MxNote(text: l10n.searchAccentNote),
      ],
    );
  }
}
