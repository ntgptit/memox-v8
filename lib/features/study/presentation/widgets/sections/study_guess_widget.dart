import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:memox/core/theme/app_decorations.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study/presentation/widgets/support/session_footer_hint_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_choice_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_face_card_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';

/// Screen 18, Guess: the term and five meanings; only the first pick counts
/// (BR-STUDY-037, BR-STUDY-042). Once its write commits, the pick and the
/// right option take their tones — the right one found by card id, never by
/// text (BR-STUDY-041) — the rest fade, and the outcome is announced. The
/// turn stays 1200 ms or until a tap, or until Next with TalkBack on
/// (FE-A6 P3 G1, C3, C6). A question that cannot be built shows a notice
/// whose Close ends the session (BR-STUDY-040, C2).
class StudyGuessWidget extends StatefulWidget {
  const StudyGuessWidget({
    super.key,
    required this.item,
    required this.chosenCardId,
    required this.result,
    required this.isBusy,
    required this.onPick,
    required this.onContinue,
    required this.onClose,
  });

  final StudyItem item;

  /// The option picked, once picked.
  final String? chosenCardId;

  /// The committed outcome while the turn is held; null before.
  final TurnResult? result;
  final bool isBusy;
  final ValueChanged<String> onPick;

  /// Releases the held turn: the next question follows.
  final VoidCallback onContinue;

  /// Ends the session (a blocked question).
  final VoidCallback onClose;

  @override
  State<StudyGuessWidget> createState() => _StudyGuessWidgetState();
}

class _StudyGuessWidgetState extends State<StudyGuessWidget> {
  static const Duration _hold = Duration(milliseconds: 1200);
  static const int _letterA = 0x41;

  Timer? _timer;

  bool get _isAnswered => widget.result != null;

  @override
  void didUpdateWidget(StudyGuessWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result == null && widget.result != null) _onAnswered();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onAnswered() {
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        _announcement(),
        Directionality.of(context),
      ),
    );
    // With TalkBack on the announcement is not cut short (C6).
    if (MediaQuery.accessibleNavigationOf(context)) return;
    _timer = Timer(_hold, _continue);
  }

  String _announcement() {
    final l10n = context.l10n;
    if (widget.result?.isCorrect ?? false) return l10n.studyGuessAnnounceRight;
    return l10n.studyGuessAnnounceWrong(_rightMeaning());
  }

  String _rightMeaning() => widget.item.guess!.options
      .firstWhere((option) => option.cardId == widget.item.cardId)
      .meaning;

  void _continue() {
    _timer?.cancel();
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final question = widget.item.guess!;
    if (question.isBlocked) {
      return MxErrorState(
        title: l10n.studyGuessBlockedTitle,
        body: l10n.studyGuessBlockedBody,
        icon: AppIcons.close,
        retryLabel: l10n.studySessionClose,
        onRetry: widget.onClose,
      );
    }
    final body = CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.control,
              children: [
                Expanded(
                  child: StudyFaceCardWidget(
                    label: l10n.studyGuessPrompt,
                    child: Text(
                      widget.item.front,
                      textAlign: TextAlign.center,
                      style: context.textStyles.studyTerm,
                    ),
                  ),
                ),
                for (final (index, option) in question.options.indexed)
                  _option(context, index, option),
              ],
            ),
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          // Once answered, a tap anywhere goes on (G1).
          child: _isAnswered
              ? GestureDetector(
                  onTap: _continue,
                  behavior: HitTestBehavior.translucent,
                  excludeFromSemantics: true,
                  child: body,
                )
              : body,
        ),
        if (_isAnswered && MediaQuery.accessibleNavigationOf(context))
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.control),
            child: Center(
              child: MxButton(
                label: l10n.studyGuessNext,
                size: MxButtonSize.study,
                onPressed: _continue,
              ),
            ),
          ),
        SessionFooterHintWidget(
          icon: AppIcons.check,
          text: _isAnswered
              ? l10n.studyGuessHintAnswered
              : l10n.studyGuessHintIdle,
        ),
      ],
    );
  }

  Widget _option(BuildContext context, int index, GuessOption option) {
    final l10n = context.l10n;
    final letter = String.fromCharCode(_letterA + index);
    final label = l10n.studyGuessOption(letter, option.meaning);
    final tone = _toneOf(option);
    final isInPlay = !_isAnswered || tone != StudyChoiceTone.idle;
    return StudyChoiceWidget(
      tone: tone,
      isFaded: !isInPlay,
      semanticsLabel: switch (tone) {
        StudyChoiceTone.right => l10n.studyGuessOptionRight(label),
        StudyChoiceTone.wrong => l10n.studyGuessOptionWrong(label),
        StudyChoiceTone.idle || StudyChoiceTone.selected => label,
      },
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.control,
      ),
      onTap: _isAnswered || widget.isBusy
          ? null
          : () => widget.onPick(option.cardId),
      builder: (ink) => Row(
        spacing: AppSpacing.grouped,
        children: [
          _Letter(letter: letter, ink: ink),
          Expanded(
            child: Text(
              option.meaning,
              style: context.textStyles.studyOption(ink),
            ),
          ),
          if (tone == StudyChoiceTone.right || tone == StudyChoiceTone.wrong)
            IconTheme(
              data: IconThemeData(color: ink, size: AppIconSize.inline),
              child: Icon(
                tone == StudyChoiceTone.right ? AppIcons.check : AppIcons.close,
              ),
            ),
        ],
      ),
    );
  }

  StudyChoiceTone _toneOf(GuessOption option) {
    if (!_isAnswered) return StudyChoiceTone.idle;
    if (option.cardId == widget.item.cardId) return StudyChoiceTone.right;
    if (option.cardId == widget.chosenCardId) return StudyChoiceTone.wrong;
    return StudyChoiceTone.idle;
  }
}

/// The option's letter in a ringed circle (kit GuessScreen).
class _Letter extends StatelessWidget {
  const _Letter({required this.letter, required this.ink});

  final String letter;
  final Color ink;

  static const double _ring = 1.5;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: AppSize.chip,
    child: DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ink, width: _ring),
      ),
      child: Center(
        child: Text(letter, style: context.textStyles.studyOptionLetter(ink)),
      ),
    ),
  );
}
