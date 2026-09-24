import 'package:flutter/material.dart';
import 'package:memox/app/gallery/gallery_section.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_stepper.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

/// Group D: the surfaces and the rows that fill them, live where they have
/// state.
class GallerySurfacesSection extends StatefulWidget {
  const GallerySurfacesSection({super.key});

  @override
  State<GallerySurfacesSection> createState() => _GallerySurfacesSectionState();
}

class _GallerySurfacesSectionState extends State<GallerySurfacesSection> {
  static const int _minCards = 1;
  static const int _maxCards = 200;

  var _isReminderOn = true;
  var _cards = 20;

  @override
  Widget build(BuildContext context) => GallerySection(
    title: 'D · Surfaces, rows & content',
    children: [
      const MxCard(
        isHero: true,
        child: MxListSectionHeader(
          label: 'Hero card',
          trailing: MxBadge(label: '23 due', isSolid: true),
        ),
      ),
      const MxCard(
        isWarning: true,
        child: MxListSectionHeader(label: 'Warning card'),
      ),
      Row(
        spacing: AppSpacing.grouped,
        children: [
          const MxIconTile(icon: AppIcons.library),
          const MxIconTile(
            icon: AppIcons.reminder,
            size: MxIconTileSize.medium,
          ),
          const MxIconTile(icon: AppIcons.library, size: MxIconTileSize.large),
          MxIconTile(
            icon: AppIcons.folder,
            seed: context.semanticColors.mastery,
          ),
          const MxIconTile(
            icon: AppIcons.lockOpen,
            size: MxIconTileSize.medium,
            tone: MxIconTileTone.primary,
          ),
          const MxIconTile(
            icon: AppIcons.lock,
            size: MxIconTileSize.medium,
            tone: MxIconTileTone.warning,
          ),
        ],
      ),
      MxListSectionHeader(
        label: 'Decks',
        trailing: MxChipTrigger(
          label: 'Sort: Due',
          icon: AppIcons.sort,
          onPressed: () {},
        ),
      ),
      MxCard(
        isFullBleed: true,
        child: Column(
          children: [
            MxListRow(
              title: 'Kanji N5',
              subtitle: '42 cards · 12 due',
              leading: const MxIconTile(icon: AppIcons.library),
              hasChevron: true,
              onTap: () {},
            ),
            MxListRow(
              title: 'A deck name long enough to be cut with an ellipsis',
              subtitle: 'Nested three levels deep',
              leading: const MxIconTile(icon: AppIcons.folder),
              trailing: MxIconButton(
                icon: AppIcons.more,
                semanticLabel: 'Deck actions',
                onPressed: () {},
              ),
              onTap: () {},
            ),
            MxListRow(
              title: 'Importing',
              subtitle: '120 of 300 cards',
              leading: const MxIconTile(icon: AppIcons.library),
              isBusy: true,
              onTap: () {},
            ),
            MxListRow(
              title: 'Grammar',
              subtitle: 'Cannot hold another deck',
              leading: const MxIconTile(icon: AppIcons.folder),
              isEnabled: false,
              onTap: () {},
              hasDivider: false,
            ),
          ],
        ),
      ),
      MxSection(
        title: 'Reminders',
        note: 'Changes apply to future sessions.',
        children: [
          MxSettingsRow(
            label: 'Daily reminder',
            subtitle: 'One nudge at the time you choose',
            icon: AppIcons.reminder,
            trailing: MxToggle(
              isOn: _isReminderOn,
              onChanged: (value) => setState(() => _isReminderOn = value),
              semanticLabel: 'Daily reminder',
            ),
          ),
          MxSettingsRow(
            label: 'Cards per session',
            icon: AppIcons.library,
            wideControl: MxStepper(
              value: _cards,
              decrementLabel: 'Fewer cards',
              incrementLabel: 'More cards',
              onDecrement: _cards > _minCards
                  ? () => setState(() => _cards--)
                  : null,
              onIncrement: _cards < _maxCards
                  ? () => setState(() => _cards++)
                  : null,
            ),
          ),
          MxSettingsRow(
            label: 'Language',
            icon: AppIcons.settings,
            onTap: () {},
          ),
          const MxSettingsRow(
            label: 'Unavailable while notifications are off',
            icon: AppIcons.reminder,
            isEnabled: false,
          ),
        ],
      ),
      MxCard(
        child: Column(
          children: [
            MxActionSheetCommandRow(
              icon: AppIcons.edit,
              label: 'Rename',
              subtitle: 'Change the deck name',
              onTap: () {},
            ),
            MxActionSheetCommandRow(
              icon: AppIcons.folder,
              label: 'Move',
              hasChevron: true,
              onTap: () {},
            ),
            MxActionSheetCommandRow(
              icon: AppIcons.delete,
              label: 'Delete',
              subtitle: 'Recoverable for 30 days',
              isDestructive: true,
              onTap: () {},
            ),
          ],
        ),
      ),
    ],
  );
}
