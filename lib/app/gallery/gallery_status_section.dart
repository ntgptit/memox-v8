import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/app/gallery/gallery_section.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_mastery_donut.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_outcome_tile.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';
import 'package:memox/shared/widgets/mx_workload_breakdown_line.dart';

/// Group E: counts, lifecycle, tags, rules and the workload and mastery
/// indicators.
class GalleryStatusSection extends StatelessWidget {
  const GalleryStatusSection({super.key});

  @override
  Widget build(BuildContext context) => GallerySection(
    title: context.l10n.galleryEStatusMetadata,
    children: [
      Wrap(
        spacing: AppSpacing.control,
        runSpacing: AppSpacing.control,
        children: [
          MxBadge(label: context.l10n.gallery23Due),
          MxBadge(
            label: context.l10n.gallery4Mastered,
            tone: MxBadgeTone.mastery,
          ),
          MxBadge(label: context.l10n.gallery2Late, tone: MxBadgeTone.warning),
          MxBadge(label: context.l10n.gallery1Failed, tone: MxBadgeTone.danger),
          MxBadge(
            label: context.l10n.gallery128Cards,
            tone: MxBadgeTone.neutral,
          ),
          MxBadge(label: context.l10n.gallery23Due, isSolid: true),
          MxBadge(
            label: context.l10n.gallery12Ready,
            tone: MxBadgeTone.mastery,
            icon: AppIcons.check,
          ),
        ],
      ),
      Row(
        spacing: AppSpacing.control,
        children: [
          Expanded(
            child: MxOutcomeTile(
              label: context.l10n.galleryKept,
              body: context.l10n.galleryDecksCardsAndHistory,
              tone: MxOutcomeTone.kept,
            ),
          ),
          Expanded(
            child: MxOutcomeTile(
              label: context.l10n.galleryLost,
              body: context.l10n.gallerySchedulesAndDueDates,
              tone: MxOutcomeTone.lost,
            ),
          ),
        ],
      ),
      Wrap(
        spacing: AppSpacing.control,
        runSpacing: AppSpacing.control,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          MxStatusBadge(
            status: MxCardStatus.newCard,
            label: context.l10n.galleryNew,
          ),
          MxStatusBadge(
            status: MxCardStatus.learning,
            label: context.l10n.galleryLearning,
          ),
          MxStatusBadge(
            status: MxCardStatus.reviewing,
            label: context.l10n.galleryReviewing,
          ),
          MxStatusBadge(
            status: MxCardStatus.mastered,
            label: context.l10n.galleryMastered,
          ),
          MxStatusBadge(
            status: MxCardStatus.learning,
            label: context.l10n.galleryLearning,
            isDot: true,
          ),
        ],
      ),
      Wrap(
        spacing: AppSpacing.control,
        runSpacing: AppSpacing.control,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          MxTagChip(label: context.l10n.galleryVerbs),
          MxTagChip(label: context.l10n.galleryN5, isDense: true),
          MxTagChip(label: context.l10n.galleryATagLongEnoughTo),
        ],
      ),
      MxNote(text: context.l10n.galleryDeletedDecksStayRecoverableFor),
      MxWorkloadBreakdownLine(
        overdueCount: 3,
        todayCount: 12,
        newCount: 5,
        overdueLabel: context.l10n.galleryOverdue,
        todayLabel: context.l10n.galleryToday,
        newLabel: context.l10n.galleryNewCount,
        fallback: context.l10n.galleryNothingDue,
        suffix: context.l10n.galleryAcross4Decks,
      ),
      MxWorkloadBreakdownLine(
        overdueCount: 0,
        todayCount: 0,
        newCount: 0,
        overdueLabel: context.l10n.galleryOverdue,
        todayLabel: context.l10n.galleryToday,
        newLabel: context.l10n.galleryNewCount,
        fallback: context.l10n.gallery42CardsNothingDue,
      ),
      const Row(
        spacing: AppSpacing.gutter,
        children: [
          MxMasteryDonut(fraction: 0),
          MxMasteryDonut(fraction: 0.2),
          MxMasteryDonut(fraction: 0.5),
          MxMasteryDonut(fraction: 1),
        ],
      ),
    ],
  );
}
