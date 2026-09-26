import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
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
    title: context.l10n.galleryDSurfacesRowsContent,
    children: [
      MxCard(
        isHero: true,
        child: MxListSectionHeader(
          label: context.l10n.galleryHeroCard,
          trailing: MxBadge(label: context.l10n.gallery23Due, isSolid: true),
        ),
      ),
      MxCard(
        isWarning: true,
        child: MxListSectionHeader(label: context.l10n.galleryWarningCard),
      ),
      MxCard(
        isSuccess: true,
        child: MxListSectionHeader(label: context.l10n.gallerySuccessCard),
      ),
      MxCard(
        isDanger: true,
        child: MxListSectionHeader(label: context.l10n.galleryDangerCard),
      ),
      MxCard(
        isSelected: true,
        child: MxListSectionHeader(label: context.l10n.gallerySelectedCard),
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
      const Row(
        spacing: AppSpacing.grouped,
        children: [
          MxIconTile(
            icon: AppIcons.check,
            size: MxIconTileSize.medium,
            tone: MxIconTileTone.success,
          ),
          MxIconTile(
            icon: AppIcons.resetProgress,
            size: MxIconTileSize.medium,
            tone: MxIconTileTone.caution,
          ),
          MxIconTile(
            icon: AppIcons.alert,
            size: MxIconTileSize.medium,
            tone: MxIconTileTone.danger,
          ),
        ],
      ),
      MxListSectionHeader(
        label: context.l10n.galleryDecks,
        trailing: MxChipTrigger(
          label: context.l10n.gallerySortDue,
          icon: AppIcons.sort,
          onPressed: () {},
        ),
      ),
      MxCard(
        isFullBleed: true,
        child: Column(
          children: [
            MxListRow(
              title: context.l10n.galleryKanjiN5,
              subtitle: context.l10n.gallery42Cards12Due,
              leading: const MxIconTile(icon: AppIcons.library),
              hasChevron: true,
              onTap: () {},
            ),
            MxListRow(
              title: context.l10n.galleryADeckNameLongEnough,
              subtitle: context.l10n.galleryNestedThreeLevelsDeep,
              leading: const MxIconTile(icon: AppIcons.folder),
              trailing: MxIconButton(
                icon: AppIcons.more,
                semanticLabel: context.l10n.galleryDeckActions,
                onPressed: () {},
              ),
              onTap: () {},
            ),
            MxListRow(
              title: context.l10n.galleryImporting,
              subtitle: context.l10n.gallery120Of300Cards,
              leading: const MxIconTile(icon: AppIcons.library),
              isBusy: true,
              onTap: () {},
            ),
            MxListRow(
              title: context.l10n.galleryGrammar,
              subtitle: context.l10n.galleryCannotHoldAnotherDeck,
              leading: const MxIconTile(icon: AppIcons.folder),
              isEnabled: false,
              onTap: () {},
              hasDivider: false,
            ),
          ],
        ),
      ),
      MxSection(
        title: context.l10n.galleryReminders,
        note: context.l10n.galleryChangesApplyToFutureSessions,
        children: [
          MxSettingsRow(
            label: context.l10n.galleryDailyReminder,
            subtitle: context.l10n.galleryOneNudgeAtTheTime,
            icon: AppIcons.reminder,
            trailing: MxToggle(
              isOn: _isReminderOn,
              onChanged: (value) => setState(() => _isReminderOn = value),
              semanticLabel: context.l10n.galleryDailyReminder,
            ),
          ),
          MxSettingsRow(
            label: context.l10n.galleryCardsPerSession,
            icon: AppIcons.library,
            wideControl: MxStepper(
              value: _cards,
              decrementLabel: context.l10n.galleryFewerCards,
              incrementLabel: context.l10n.galleryMoreCards,
              onDecrement: _cards > _minCards
                  ? () => setState(() => _cards--)
                  : null,
              onIncrement: _cards < _maxCards
                  ? () => setState(() => _cards++)
                  : null,
            ),
          ),
          MxSettingsRow(
            label: context.l10n.galleryLanguage,
            icon: AppIcons.settings,
            onTap: () {},
          ),
          MxSettingsRow(
            label: context.l10n.galleryUnavailableWhileNotificationsAreOff,
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
              label: context.l10n.galleryRename,
              subtitle: context.l10n.galleryChangeTheDeckName,
              onTap: () {},
            ),
            MxActionSheetCommandRow(
              icon: AppIcons.folder,
              label: context.l10n.galleryMove,
              hasChevron: true,
              onTap: () {},
            ),
            MxActionSheetCommandRow(
              icon: AppIcons.delete,
              label: context.l10n.galleryDelete,
              subtitle: context.l10n.galleryRecoverableFor30Days,
              isDestructive: true,
              onTap: () {},
            ),
          ],
        ),
      ),
    ],
  );
}
