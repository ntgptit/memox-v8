import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/features/study/domain/models/study_entry_model.dart';
import 'package:memox/features/study/presentation/controllers/review_mode_pick_controller.dart';
import 'package:memox/features/study/presentation/controllers/study_entry_controller.dart';
import 'package:memox/features/study/presentation/providers/study_entry_provider.dart';
import 'package:memox/features/study/presentation/states/study_entry_offer_state.dart';
import 'package:memox/features/study/presentation/states/study_start_state.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_entry_banner_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_entry_hero_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_entry_learn_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_entry_resume_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_entry_review_widget.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/core/theme/theme_context.dart';

/// Screen 14 below its app bar: the deck's path, then the entry in its
/// state — loading, failed, nothing due, or the hero and what it offers.
class StudyEntryBodyWidget extends ConsumerWidget {
  const StudyEntryBodyWidget({
    super.key,
    required this.deckId,
    required this.breadcrumb,
    required this.onLearn,
    required this.onContinue,
    this.onOpenInLibrary,
  });

  final String deckId;

  /// The deck's path from the Library, built by `app/` (FE-A6 D16).
  final Widget breadcrumb;

  /// Starts a learning session (BR-STUDY-051).
  final VoidCallback onLearn;

  /// Takes up today's open session (UC-STUDY-001 A3b).
  final ValueChanged<String> onContinue;

  /// Opens this deck in the Library from the empty deck's state (spec D7);
  /// null hides the action.
  final VoidCallback? onOpenInLibrary;

  void _retry(WidgetRef ref) => ref.invalidate(studyEntryProvider(deckId));

  void _pick(WidgetRef ref, StudyMode mode) =>
      ref.read(reviewModePickControllerProvider(deckId).notifier).pick(mode);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final start = ref.watch(studyEntryControllerProvider(deckId));
    final picked = ref.watch(reviewModePickControllerProvider(deckId));
    final content = switch (ref.watch(studyEntryProvider(deckId))) {
      AsyncData(value: Ok(:final value)) => _loaded(
        context,
        ref,
        value,
        start,
        picked,
      ),
      // The screen leaves on notFound (UC-STUDY-001 E1).
      AsyncData() => const <Widget>[],
      AsyncError(:final isLoading) => [
        MxErrorState(
          title: l10n.studyEntryErrorTitle,
          body: l10n.studyEntryErrorBody,
          retryLabel: l10n.commonRetry,
          onRetry: () => _retry(ref),
          isRetrying: isLoading,
        ),
      ],
      _ => const [_LoadingEntry()],
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        breadcrumb,
        Expanded(
          // The breadcrumb's inset is the gap (screen 01), in every branch.
          child: MxScreenScroll(top: 0, children: content),
        ),
      ],
    );
  }

  List<Widget> _loaded(
    BuildContext context,
    WidgetRef ref,
    StudyEntry entry,
    StudyStartState start,
    StudyMode? picked,
  ) {
    final offer = studyEntryOfferOf(entry, picked: picked);
    final resumable = entry.resumable;
    final hasLearn = entry.newCardCount > 0;
    // A review list is shown only when there is a choice (BR-STUDY-055).
    final hasReviews =
        entry.dueCardCount > 0 && offer.reviews.length >= minModesToChoose;
    return [
      // The hero stays over the nothing-due state, reading 0 and 0 (kit).
      StudyEntryHeroWidget(entry: entry),
      if (resumable != null && offer.canContinue) ...[
        SizedBox(height: context.dimens.space16),
        StudyEntryResumeWidget(
          session: resumable,
          isOnThisDeck: resumable.deckId == deckId,
          isLocked: start.isStarting,
          onContinue: () => onContinue(resumable.sessionId),
        ),
      ],
      // A refused or failed start reads here, under the hero, above the
      // choices: the footer's Try again points at it, and below the choices
      // it could sit past the fold (audit 2026-10-17).
      if (start.status == StudyStartStatus.refused ||
          start.status == StudyStartStatus.failed) ...[
        SizedBox(height: context.dimens.space16),
        StudyEntryBannerWidget(start: start),
      ],
      // Beside a session that can be continued, every other start ends it:
      // the choices sit under a section that says so (spec E1, BR-STUDY-072).
      // With no choice in the body (SM-2 with due cards alone) the footer's
      // caption says it (final review I2).
      if (offer.isOtherSessionNoteShown) ...[
        SizedBox(height: context.dimens.space16),
        MxListSectionHeader(label: context.l10n.studyEntryOtherSessionHeader),
        MxNote(text: context.l10n.studyEntryOtherSessionNote),
      ],
      if (offer.isNothingDue) ...[
        SizedBox(height: context.dimens.space16),
        _NothingDue(
          isEmpty: entry.cardCount == 0,
          onOpenInLibrary: onOpenInLibrary,
          isLocked: start.isStarting,
        ),
      ],
      if (hasLearn) ...[
        SizedBox(height: context.dimens.space16),
        StudyEntryLearnWidget(
          entry: entry,
          offer: offer,
          onLearn: start.isStarting ? null : onLearn,
        ),
      ],
      // A review needs due cards (kit onlyNew, nothing).
      if (hasReviews) ...[
        SizedBox(height: context.dimens.space16),
        StudyEntryReviewWidget(
          reviews: offer.reviews,
          target: offer.reviewTarget,
          isLocked: start.isStarting,
          onPick: (mode) => _pick(ref, mode),
        ),
      ],
    ];
  }
}

/// Nothing new and nothing due: a calm, positive state (BR-STUDY-008,
/// BR-STUDY-054). It says why, from the data: every card rests, or the deck
/// has none; its title names this deck, so it never reads against another
/// deck's Continue above it (owner 2026-10-21).
class _NothingDue extends StatelessWidget {
  const _NothingDue({
    required this.isEmpty,
    required this.onOpenInLibrary,
    required this.isLocked,
  });

  /// The deck and its subtree hold no live card.
  final bool isEmpty;

  /// Opens this deck in the Library, where cards are added (spec D7); null
  /// draws no action.
  final VoidCallback? onOpenInLibrary;

  /// A start runs: the action is drawn disabled (BR-STUDY-004).
  final bool isLocked;

  @override
  Widget build(BuildContext context) => MxEmptyState(
    icon: AppIcons.learned,
    title: isEmpty
        ? context.l10n.studyEntryNoCardsTitle
        : context.l10n.studyEntryNothingInDeckTitle,
    body: isEmpty
        ? context.l10n.studyEntryNoCardsBody
        : context.l10n.studyEntryNothingBody,
    tone: MxEmptyStateTone.success,
    isCompact: true,
    // Under the hero, and beside another deck's session: the lead role, not
    // a headline (owner 2026-10-21, spec D11).
    isQuiet: true,
    secondaryActionLabel: isEmpty && onOpenInLibrary != null
        ? context.l10n.studyEntryOpenInLibrary
        : null,
    onSecondaryAction: isEmpty && !isLocked ? onOpenInLibrary : null,
  );
}

/// The entry's shape while it loads (kit loading): the hero's overline and
/// figures, then a card of three option rows, so nothing jumps when the
/// entry arrives. Heard once as loading; the bars say nothing.
class _LoadingEntry extends StatelessWidget {
  const _LoadingEntry();

  static const int _optionRows = 3;
  static const double _overlineWidth = 120;
  static const double _figuresHeight = 56;
  static const double _radioSize = 20;
  static const double _titleWidth = 120;
  static const double _lineWidth = 200;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: context.l10n.commonLoading,
    child: ExcludeSemantics(
      child: MxSkeletonPulse(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MxCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: context.dimens.space12,
                children: [
                  const MxSkeleton(width: _overlineWidth),
                  const MxSkeleton(height: _figuresHeight),
                ],
              ),
            ),
            SizedBox(height: context.dimens.space16),
            MxCard(
              child: Column(
                spacing: context.dimens.space12,
                children: [
                  for (var i = 0; i < _optionRows; i++)
                    Row(
                      spacing: context.dimens.space12,
                      children: [
                        const MxSkeleton(
                          width: _radioSize,
                          height: _radioSize,
                          isCircle: true,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: context.dimens.space4,
                            children: [
                              const MxSkeleton(width: _titleWidth),
                              const MxSkeleton(width: _lineWidth),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
