import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter/semantics.dart';
import 'package:memox/core/speech/speech_language.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study/presentation/widgets/support/session_footer_hint_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_centred_scroll_widget.dart';
import 'package:memox/shared/widgets/mx_choice_mark.dart';
import 'package:memox/shared/widgets/mx_choice_tile.dart';
import 'package:memox/features/study/presentation/widgets/support/study_face_card_widget.dart';
import 'package:memox/shared/widgets/mx_scroll_fade.dart';
import 'package:memox/features/study/presentation/widgets/support/study_speak_button_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_whole_word_text_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/core/theme/theme_rules.dart';

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
    required this.speechLanguage,
  });

  /// The language the term is read in; null until the session knows it.
  final SpeechLanguage? speechLanguage;

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
  /// The prompt's height cap, in controls (audit 2026-10-19, G5).
  static const int _promptMaxControls = 4;

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
    // The right option is the served card's own meaning (BR-STUDY-041).
    return l10n.studyGuessAnnounceWrong(widget.item.back);
  }

  void _continue() {
    _timer?.cancel();
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final question = widget.item.guess!;
    if (question.isBlocked) {
      // Close ends the session: nothing here can be retried (BR-STUDY-040).
      return StudyCentredScrollWidget(
        children: [
          MxErrorState(
            title: l10n.studyGuessBlockedTitle,
            body: l10n.studyGuessBlockedBody,
            icon: AppIcons.close,
            retryLabel: l10n.studySessionClose,
            onRetry: widget.onClose,
            // The top bar and the notice already show a ×
            // (critique 2026-09-30 part 3c-2, R5).
            actionIcon: null,
          ),
        ],
      );
    }
    final body = MxScrollFade(
      child: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            // The options' focus outline reaches past them; the room above
            // and below keeps the scroll view's clip off it.
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.screenMargin,
                vertical: context.focusOutlineReach,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: context.dimens.space8,
                children: [
                  // One word does not need half the screen: the prompt is at
                  // most four controls tall, and the room left goes between
                  // it and the options, which stay near the thumb (audit
                  // 2026-10-19, G5).
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight:
                            context.dimens.sizeControl * _promptMaxControls,
                      ),
                      child: StudyFaceCardWidget(
                        label: l10n.studyGuessPrompt,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          spacing: context.dimens.space8,
                          children: [
                            StudyWholeWordTextWidget(
                              widget.item.front,
                              style: context.texts.term,
                            ),
                            StudySpeakButtonWidget(
                              text: widget.item.front,
                              language: widget.speechLanguage,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  for (final (index, option) in question.options.indexed)
                    _option(context, index, option),
                ],
              ),
            ),
          ),
        ],
      ),
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
            padding: EdgeInsets.only(top: context.dimens.space8),
            child: Center(
              child: MxButton(
                label: l10n.studyGuessNext,
                size: MxButtonSize.study,
                onPressed: _continue,
              ),
            ),
          ),
        SessionFooterHintWidget(
          // Instructions take the info glyph (critique 2026-10-02, F7).
          icon: AppIcons.info,
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
    final isInPlay = !_isAnswered || tone != MxChoiceTone.idle;
    return MxChoiceTile(
      tone: tone,
      isFaded: !isInPlay,
      semanticsLabel: switch (tone) {
        MxChoiceTone.right => l10n.studyGuessOptionRight(label),
        MxChoiceTone.wrong => l10n.studyGuessOptionWrong(label),
        MxChoiceTone.idle || MxChoiceTone.selected => label,
      },
      padding: EdgeInsets.symmetric(
        horizontal: context.dimens.space16,
        vertical: context.dimens.space8,
      ),
      onTap: _isAnswered || widget.isBusy
          ? null
          : () => widget.onPick(option.cardId),
      builder: (foreground) => Row(
        spacing: context.dimens.space12,
        children: [
          _Letter(letter: letter, foreground: foreground),
          Expanded(
            child: Text(
              option.meaning,
              style: context.texts.caption.copyWith(color: foreground),
            ),
          ),
          MxChoiceMark(tone: tone, color: foreground),
        ],
      ),
    );
  }

  MxChoiceTone _toneOf(GuessOption option) {
    if (!_isAnswered) return MxChoiceTone.idle;
    if (option.cardId == widget.item.cardId) return MxChoiceTone.right;
    if (option.cardId == widget.chosenCardId) return MxChoiceTone.wrong;
    return MxChoiceTone.idle;
  }
}

/// The option's letter in a ringed circle (kit GuessScreen).
class _Letter extends StatelessWidget {
  const _Letter({required this.letter, required this.foreground});

  final String letter;
  final Color foreground;

  static const double _ring = 1.5;

  /// The letter circle's diameter. It is not a chip, so it does not follow
  /// `sizeChip`.
  static const double _size = 28;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: _size,
    child: DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: foreground, width: _ring),
      ),
      child: Center(
        child: Text(
          letter,
          style: context.texts.meta.copyWith(color: foreground),
        ),
      ),
    ),
  );
}
