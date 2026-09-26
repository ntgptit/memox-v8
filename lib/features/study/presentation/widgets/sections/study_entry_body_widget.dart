import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
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
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// Screen 14 below its app bar: the deck's path, then the entry in its
/// state — loading, failed, nothing due, or the hero and what it offers.
class StudyEntryBodyWidget extends ConsumerWidget {
  const StudyEntryBodyWidget({
    super.key,
    required this.deckId,
    required this.breadcrumb,
    required this.onLearn,
    required this.onContinue,
  });

  final String deckId;

  /// The deck's path from the Library, built by `app/` (FE-A6 D16).
  final Widget breadcrumb;

  /// Starts a learning session (BR-STUDY-051).
  final VoidCallback onLearn;

  /// Takes up today's open session (UC-STUDY-001 A3b).
  final ValueChanged<String> onContinue;

  /// A review list is shown only when there is a choice (BR-STUDY-055).
  static const int _minModesToChoose = 2;

  void _retry(WidgetRef ref) => ref.invalidate(studyEntryProvider(deckId));

  void _pick(WidgetRef ref, StudyMode mode) =>
      ref.read(reviewModePickControllerProvider(deckId).notifier).pick(mode);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final start = ref.watch(studyEntryControllerProvider(deckId));
    final picked = ref.watch(reviewModePickControllerProvider(deckId));
    final content = switch (ref.watch(studyEntryProvider(deckId))) {
      AsyncData(value: Ok(:final value)) => _loaded(ref, value, start, picked),
      // The screen leaves on notFound (UC-STUDY-001 E1).
      AsyncData() => const <Widget>[],
      AsyncError() => [
        MxErrorState(
          title: l10n.studyEntryErrorTitle,
          body: l10n.studyEntryErrorBody,
          retryLabel: l10n.commonRetry,
          onRetry: () => _retry(ref),
        ),
      ],
      _ => const [_LoadingEntry()],
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        breadcrumb,
        Expanded(child: MxScreenScroll(children: content)),
      ],
    );
  }

  List<Widget> _loaded(
    WidgetRef ref,
    StudyEntry entry,
    StudyStartState start,
    StudyMode? picked,
  ) {
    final offer = studyEntryOfferOf(entry, picked: picked);
    final resumable = entry.resumable;
    return [
      const SizedBox(height: AppSpacing.micro),
      // The hero stays over the nothing-due state, reading 0 and 0 (kit).
      StudyEntryHeroWidget(entry: entry),
      if (resumable != null && offer.canContinue) ...[
        const SizedBox(height: AppSpacing.grouped),
        StudyEntryResumeWidget(
          session: resumable,
          isLocked: start.isStarting,
          onContinue: () => onContinue(resumable.sessionId),
        ),
      ],
      if (offer.isNothingDue) ...[
        const SizedBox(height: AppSpacing.grouped),
        const _NothingDue(),
      ],
      if (entry.newCardCount > 0) ...[
        const SizedBox(height: AppSpacing.grouped),
        StudyEntryLearnWidget(
          entry: entry,
          offer: offer,
          onLearn: start.isStarting ? null : onLearn,
        ),
      ],
      // A review needs due cards (kit onlyNew, nothing).
      if (entry.dueCardCount > 0 &&
          offer.reviews.length >= _minModesToChoose) ...[
        const SizedBox(height: AppSpacing.grouped),
        StudyEntryReviewWidget(
          reviews: offer.reviews,
          target: offer.reviewTarget,
          isLocked: start.isStarting,
          onPick: (mode) => _pick(ref, mode),
        ),
      ],
      if (start.status == StudyStartStatus.refused ||
          start.status == StudyStartStatus.failed) ...[
        const SizedBox(height: AppSpacing.grouped),
        StudyEntryBannerWidget(start: start),
      ],
    ];
  }
}

/// Nothing new and nothing due: a calm, positive state (BR-STUDY-008,
/// BR-STUDY-054).
class _NothingDue extends StatelessWidget {
  const _NothingDue();

  @override
  Widget build(BuildContext context) => MxEmptyState(
    icon: AppIcons.learned,
    title: context.l10n.studyEntryNothingTitle,
    body: context.l10n.studyEntryNothingBody,
    tone: MxEmptyStateTone.success,
    isCompact: true,
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
            const SizedBox(height: AppSpacing.micro),
            const MxCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.grouped,
                children: [
                  MxSkeleton(width: _overlineWidth),
                  MxSkeleton(height: _figuresHeight),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.grouped),
            MxCard(
              child: Column(
                spacing: AppSpacing.grouped,
                children: [
                  for (var i = 0; i < _optionRows; i++)
                    const Row(
                      spacing: AppSpacing.grouped,
                      children: [
                        MxSkeleton(
                          width: _radioSize,
                          height: _radioSize,
                          isCircle: true,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: AppSpacing.micro,
                            children: [
                              MxSkeleton(width: _titleWidth),
                              MxSkeleton(width: _lineWidth),
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
