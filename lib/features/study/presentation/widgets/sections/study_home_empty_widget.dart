import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// Screen 13 before there is anything to study (BR-STUDY-077): no root deck,
/// where the Starter Library comes first and the Library second (UC-STUDY-002
/// A4), or root decks with no card, where the Library is the way forward. No
/// number is made up.
class StudyHomeEmptyWidget extends StatelessWidget {
  const StudyHomeEmptyWidget({
    super.key,
    required this.hasDecks,
    required this.onOpenLibrary,
    required this.onOpenStarterDecks,
  });

  /// Root decks exist, none with a card.
  final bool hasDecks;
  final VoidCallback onOpenLibrary;
  final VoidCallback onOpenStarterDecks;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (hasDecks) {
      return MxEmptyState(
        icon: AppIcons.cardDeck,
        title: l10n.studyHomeNoCardsTitle,
        body: l10n.studyHomeNoCardsBody,
        tone: MxEmptyStateTone.neutral,
        actionLabel: l10n.studyHomeGoToLibrary,
        onAction: onOpenLibrary,
      );
    }
    return MxEmptyState(
      icon: AppIcons.starterDecks,
      title: l10n.studyHomeNoDecksTitle,
      body: l10n.studyHomeNoDecksBody,
      actionLabel: l10n.studyHomeBrowseStarterDecks,
      onAction: onOpenStarterDecks,
      secondaryActionLabel: l10n.studyHomeGoToLibrary,
      onSecondaryAction: onOpenLibrary,
    );
  }
}

/// Screen 13's first read: the hero's and the rows' shapes, heard once as
/// "Loading" (kit loading; FE-A8 S11).
class StudyHomeLoadingWidget extends StatelessWidget {
  const StudyHomeLoadingWidget({super.key});

  static const double _overlineWidth = 90;
  static const double _titleWidth = 140;
  static const double _titleHeight = 24;
  static const int _rows = 3;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AppSpacing.gutter,
    children: [
      const MxSkeletonPulse(
        child: MxCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.control,
            children: [
              MxSkeleton(width: _overlineWidth),
              MxSkeleton(width: _titleWidth, height: _titleHeight),
            ],
          ),
        ),
      ),
      MxCard(
        isFullBleed: true,
        child: MxSkeletonList(
          rows: _rows,
          semanticLabel: context.l10n.commonLoading,
        ),
      ),
    ],
  );
}
