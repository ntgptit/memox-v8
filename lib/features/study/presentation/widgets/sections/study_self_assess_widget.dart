import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/widgets/support/session_footer_hint_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_face_card_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_grade_row_widget.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';

/// Screen 16a, Self-assess: the prompt, the answer once revealed, then the
/// four grades (BR-MODE-006, BR-MODE-011). Revealing writes nothing; one
/// grade commits the turn with no confirm (16a). The side asked comes from
/// the card's row (BR-MODE-014); a learning session's card asks term first.
/// The screen keys it per turn, so each turn starts unrevealed.
class StudySelfAssessWidget extends StatefulWidget {
  const StudySelfAssessWidget({
    super.key,
    required this.item,
    required this.intervals,
    required this.isBusy,
    required this.onGrade,
  });

  final StudyItem item;

  /// The preview of this turn; null while it loads and on a turn without one.
  final Map<Object, int>? intervals;
  final bool isBusy;
  final ValueChanged<Sm2Action> onGrade;

  @override
  State<StudySelfAssessWidget> createState() => _StudySelfAssessWidgetState();
}

class _StudySelfAssessWidgetState extends State<StudySelfAssessWidget> {
  var _isRevealed = false;

  void _reveal() => setState(() => _isRevealed = true);

  bool get _isMeaningFirst =>
      widget.item.direction == QuestionDirection.meaningToKorean;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canTapToReveal = !_isRevealed;
    final termFace = StudyFaceCardWidget(
      label: l10n.studyBrowseTerm,
      isAnswer: _isMeaningFirst,
      onTap: !_isMeaningFirst && canTapToReveal ? _reveal : null,
      child: _TermFace(
        item: widget.item,
        isShown: !_isMeaningFirst || _isRevealed,
      ),
    );
    final meaningFace = StudyFaceCardWidget(
      label: l10n.studyBrowseMeaning,
      isAnswer: !_isMeaningFirst,
      onTap: _isMeaningFirst && canTapToReveal ? _reveal : null,
      child: _MeaningFace(
        item: widget.item,
        isShown: _isMeaningFirst || _isRevealed,
        hasExample: _isRevealed,
      ),
    );
    final (prompt, answer) = _isMeaningFirst
        ? (meaningFace, termFace)
        : (termFace, meaningFace);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.control,
              children: [
                Expanded(child: prompt),
                Expanded(child: answer),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.gutter,
            AppSpacing.gutter,
            0,
          ),
          child: _isRevealed
              ? StudyGradeRowWidget(
                  intervals: widget.intervals,
                  isBusy: widget.isBusy,
                  onGrade: widget.onGrade,
                )
              : Center(
                  child: MxButton(
                    label: l10n.studySelfAssessShowAnswer,
                    size: MxButtonSize.study,
                    onPressed: _reveal,
                  ),
                ),
        ),
        SessionFooterHintWidget(
          icon: AppIcons.check,
          text: _isRevealed
              ? l10n.studySelfAssessHintGrade
              : l10n.studySelfAssessHintPrompt,
        ),
      ],
    );
  }
}

/// The term, with its pronunciation.
class _TermFace extends StatelessWidget {
  const _TermFace({required this.item, required this.isShown});

  final StudyItem item;
  final bool isShown;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final pronunciation = item.pronunciation;
    return _Appearing(
      isShown: isShown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.control,
        children: [
          Text(
            item.front,
            textAlign: TextAlign.center,
            style: styles.studyTerm,
          ),
          if (pronunciation != null)
            Text(
              pronunciation,
              textAlign: TextAlign.center,
              style: styles.studyDetail,
            ),
        ],
      ),
    );
  }
}

/// The meaning, with the example once revealed.
class _MeaningFace extends StatelessWidget {
  const _MeaningFace({
    required this.item,
    required this.isShown,
    required this.hasExample,
  });

  final StudyItem item;
  final bool isShown;

  /// The example names the term, so it waits for the reveal whichever side
  /// asks (BR-MODE-014).
  final bool hasExample;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final example = item.example;
    return _Appearing(
      isShown: isShown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.control,
        children: [
          Text(
            item.back,
            textAlign: TextAlign.center,
            style: styles.studyMeaning,
          ),
          if (hasExample && example != null)
            Text(
              example,
              textAlign: TextAlign.center,
              style: styles.studyDetail,
            ),
        ],
      ),
    );
  }
}

/// The kit's still placeholder bar until [isShown], then [child] fading and
/// rising in (16a Motion); at once under Remove animations.
class _Appearing extends StatelessWidget {
  const _Appearing({required this.isShown, required this.child});

  final bool isShown;
  final Widget child;

  static const Offset _rise = Offset(0, 0.04);

  @override
  Widget build(BuildContext context) {
    final isStill = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: isStill ? Duration.zero : AppDurations.standard,
      switchInCurve: Easing.standard,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(begin: _rise, end: Offset.zero).animate(animation),
          child: child,
        ),
      ),
      child: isShown
          ? KeyedSubtree(key: const ValueKey(true), child: child)
          : const _HiddenBar(key: ValueKey(false)),
    );
  }
}

/// A hidden face (kit Recall): a still bar, not a loading skeleton — nothing
/// is loading, and it says nothing to TalkBack.
class _HiddenBar extends StatelessWidget {
  const _HiddenBar({super.key});

  static const Size _size = Size(140, 14);

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.fromSize(
      size: _size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
      ),
    ),
  );
}
