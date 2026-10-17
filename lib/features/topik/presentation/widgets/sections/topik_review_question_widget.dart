import 'package:flutter/widgets.dart';
import 'package:memox/l10n/meta_line.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_model.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_choice_tile.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_scroll_fade.dart';
import 'package:memox/shared/widgets/mx_section.dart';

/// Screen 39's question (detail file 39, critique V2–V4):
/// - the banner when the content changed after the attempt (BR-TOPIK-019);
/// - "{no}. {stem}";
/// - the options: the right one in the study `right` tone, the person's
///   wrong choice in `wrong`, nothing tappable (BR-TOPIK-010);
/// - "Your answer ③ · Right answer ①";
/// - the supporting content in the UI language, a section only when it has
///   data (BR-TOPIK-006, A2).
///
/// The right answer is the snapshot's, the one that scored. The pane fades its
/// bottom edge while more lies below, as on 37 (owner 2026-10-17).
class TopikReviewQuestionWidget extends StatelessWidget {
  const TopikReviewQuestionWidget({
    super.key,
    required this.question,
    required this.answer,
    required this.isContentUpdated,
  });

  final TopikQuestion question;
  final TopikAttemptAnswer answer;
  final bool isContentUpdated;

  int get _right => answer.correctIdx ?? question.answerIdx;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    return MxScrollFade(
      child: MxScreenScroll(
        children: [
          SizedBox(height: dimens.space16),
          if (isContentUpdated) ...[
            MxInlineBanner(
              tone: MxBannerTone.warning,
              title: l10n.topikUpdatedTitle,
              message: l10n.topikUpdatedBody,
              hasBottomMargin: false,
            ),
            SizedBox(height: dimens.space16),
          ],
          // A polite live region: Next, Previous and a filter change the
          // question while focus stays on the footer, and TalkBack says the
          // new "{no}. {stem}" (WCAG 4.1.3; 39 has no study bar counter).
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.topikQuestionStem(question.no, question.stemKo),
              style: context.texts.content,
            ),
          ),
          SizedBox(height: dimens.space16),
          for (final option in question.options) ...[
            _option(context, option),
            SizedBox(height: dimens.space8),
          ],
          _answerMeta(context),
          ..._support(context),
        ],
      ),
    );
  }

  Widget _answerMeta(BuildContext context) {
    final meta = context.l10n.topikAnswerMeta(
      selected: answer.selectedIdx,
      right: _right,
    );
    return Text(
      meta.shown,
      semanticsLabel: meta.spoken,
      style: context.texts.label.copyWith(
        color: context.colors.mutedForeground,
      ),
    );
  }

  Widget _option(BuildContext context, TopikOption option) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    final isRight = option.idx == _right;
    final isWrongChoice = !isRight && option.idx == answer.selectedIdx;
    final text = option.textKo ?? l10n.topikPicture;
    return MxChoiceTile(
      tone: isRight
          ? MxChoiceTone.right
          : (isWrongChoice ? MxChoiceTone.wrong : MxChoiceTone.idle),
      isSelected: option.idx == answer.selectedIdx,
      semanticsLabel: isRight || isWrongChoice
          ? l10n.topikOptionReviewLabel(
              option.idx,
              text,
              isRight ? l10n.topikRightState : l10n.topikYourWrongState,
            )
          : l10n.topikOptionLabel(option.idx, text),
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space16,
        vertical: dimens.space12,
      ),
      builder: (foreground) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: dimens.space8,
        children: [
          Text(
            [topikCircled(option.idx), ?option.textKo].join(' '),
            style: context.texts.content.copyWith(color: foreground),
          ),
          if (option.image case final image?)
            Image.asset(image, fit: BoxFit.contain, excludeFromSemantics: true),
        ],
      ),
    );
  }

  /// Explanation, Translation, Words, Grammar: each only with data.
  List<Widget> _support(BuildContext context) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    Widget line(String text) => Padding(
      padding: EdgeInsets.all(dimens.space16),
      child: Text(text, style: context.texts.body),
    );
    final sections = [
      if (question.explanation case final text?)
        MxSection(
          title: l10n.topikTagExplanation,
          children: [line(l10n.topikText(text))],
        ),
      if (question.translation case final text?)
        MxSection(
          title: l10n.topikTagTranslation,
          children: [line(l10n.topikText(text))],
        ),
      if (question.words.isNotEmpty)
        MxSection(
          title: l10n.topikTagWords,
          children: [
            for (final word in question.words)
              line(
                // The word stays whole; its meaning is prose (Q-C-2).
                '${metaTerms([word.ko, ?word.pos])}'
                '$metaTermSeparator${l10n.topikText(word.meaning)}',
              ),
          ],
        ),
      if (question.grammars.isNotEmpty)
        MxSection(
          title: l10n.topikTagGrammar,
          children: [
            for (final grammar in question.grammars)
              line(
                '${wholeTerm(grammar.pattern)}'
                '$metaTermSeparator${l10n.topikText(grammar.meaning)}',
              ),
          ],
        ),
    ];
    return [
      for (final section in sections) ...[
        SizedBox(height: dimens.space24),
        section,
      ],
    ];
  }
}
