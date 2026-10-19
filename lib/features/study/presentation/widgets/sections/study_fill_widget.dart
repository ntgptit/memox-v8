import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/semantics.dart';
import 'package:memox/core/text/folded_text.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study/presentation/widgets/support/session_footer_hint_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_settle_guard_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_cta_row_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_face_card_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';
import 'package:memox/core/theme/theme_rules.dart';

/// Screen 20, Fill: the meaning asks, the person types the term
/// (BR-STUDY-026). A right answer lets the next turn follow at once; a
/// wrong one stays on screen, the typed text struck through beside the
/// right term, until Continue (BR-STUDY-059, BR-STUDY-063, BR-STUDY-064).
/// The typed text lives only here and in the one answer sent; it is never
/// kept (BR-STUDY-030). The screen keys it per turn. Its actions settle
/// after a swap (critique 2026-09-30 part 3c-2, R1).
class StudyFillWidget extends StatefulWidget {
  const StudyFillWidget({
    super.key,
    required this.item,
    required this.result,
    required this.isBusy,
    required this.onCheck,
    required this.onShowHint,
    required this.onContinue,
  });

  final StudyItem item;

  /// The checked answer's committed result, held on screen (spec D5).
  final TurnResult? result;
  final bool isBusy;
  final ValueChanged<String> onCheck;
  final VoidCallback onShowHint;
  final VoidCallback onContinue;

  @override
  State<StudyFillWidget> createState() => _StudyFillWidgetState();
}

class _StudyFillWidgetState extends State<StudyFillWidget> {
  final _answer = TextEditingController();
  final _focus = FocusNode();

  /// The answer as it was last checked: what a wrong result strikes
  /// through, even when a busy database made it wait for Retry (E2).
  String? _typed;

  bool get _isWrong => widget.result?.isCorrect == false;

  bool get _canCheck =>
      !widget.isBusy && widget.result == null && _answer.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    // The keyboard opens with the turn (V7).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void didUpdateWidget(StudyFillWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final result = widget.result;
    if (oldWidget.result != null || result == null) return;
    if (result.isCorrect == true) {
      // No feedback frame: the next turn follows (F3). After the frame, as
      // the release writes a provider.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onContinue();
      });
      return;
    }
    _focus.unfocus();
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        context.l10n.studyFillAnnounceWrong(widget.item.front),
        Directionality.of(context),
      ),
    );
  }

  @override
  void dispose() {
    _answer.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Check, or IME Done: nothing on an empty answer (BR-STUDY-029, V7).
  void _check() {
    if (!_canCheck) return;
    final typed = _answer.text;
    setState(() => _typed = typed);
    widget.onCheck(typed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final item = widget.item;
    final hint = item.hint;
    final isHintShown = item.isHintShown && hint != null;
    final canShowHint = hint != null && !item.isHintShown && !_isWrong;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.screenMargin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: context.dimens.space8,
              children: [
                Expanded(
                  child: StudyFaceCardWidget(
                    label: l10n.studyBrowseMeaning,
                    child: Text(
                      item.back,
                      textAlign: TextAlign.center,
                      style: context.texts.content,
                    ),
                  ),
                ),
                Expanded(
                  child: StudyFaceCardWidget(
                    label: l10n.studyBrowseTerm,
                    isAnswer: true,
                    child: _isWrong
                        ? _Corrected(typed: _typed ?? '', term: item.front)
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            spacing: context.dimens.space12,
                            children: [
                              // Laid out from the start, so showing it moves
                              // nothing (critique 2026-09-30 part 3c-2, R4).
                              if (hint != null)
                                Visibility(
                                  visible: isHintShown,
                                  maintainSize: true,
                                  maintainAnimation: true,
                                  maintainState: true,
                                  child: _HintRow(hint: hint),
                                ),
                              MxTextField(
                                controller: _answer,
                                focusNode: _focus,
                                label: l10n.studyFillField,
                                variant: MxTextFieldVariant.study,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _check(),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _actions(context, canShowHint: canShowHint),
        // An instruction takes the info glyph and a wrong answer the repeat
        // one, as in every mode (critique 2026-10-02 F7).
        SessionFooterHintWidget(
          // The wrong state's footer states the grading rule, not the
          // comeback (the tag above says that), so it takes info (audit
          // 2026-10-19, G6).
          icon: AppIcons.info,
          text: _isWrong
              ? l10n.studyFillHintWrong
              : isHintShown
              ? l10n.studyFillHintUsed
              : l10n.studyFillHintInput,
        ),
      ],
    );
  }

  /// The CTA row. Show hint going away is a swap as much as Check becoming
  /// Continue: a double tap on Show hint must not check a half-typed answer
  /// (critique 2026-09-30 part 3c-2, R1 and its final review).
  Widget _actions(BuildContext context, {required bool canShowHint}) {
    final l10n = context.l10n;
    return StudySettleGuardWidget(
      phase: (_isWrong, canShowHint),
      child: ListenableBuilder(
        listenable: _answer,
        builder: (context, _) => StudyCtaRowWidget(
          children: _isWrong
              ? [
                  MxButton(
                    label: l10n.studyContinue,
                    size: MxButtonSize.study,
                    onPressed: widget.isBusy ? null : widget.onContinue,
                  ),
                ]
              : [
                  if (canShowHint)
                    MxButton(
                      label: l10n.studyFillShowHint,
                      tone: MxButtonTone.outline,
                      size: MxButtonSize.study,
                      icon: AppIcons.hint,
                      isBlock: true,
                      onPressed: widget.isBusy ? null : widget.onShowHint,
                    ),
                  MxButton(
                    label: l10n.studyFillCheck,
                    size: MxButtonSize.study,
                    isBlock: canShowHint,
                    onPressed: _canCheck ? _check : null,
                  ),
                ],
        ),
      ),
    );
  }
}

/// The card's hint, shown on request (BR-STUDY-028), at the study detail
/// role (the body role; critique 2026-09-30 part 3c-2, R4).
class _HintRow extends StatelessWidget {
  const _HintRow({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: context.l10n.studyFillHintRow(hint),
    excludeSemantics: true,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: context.dimens.space8,
      children: [
        IconTheme(
          data: IconThemeData(
            color: context.colors.mutedForeground,
            size: context.dimens.sizeIconInline,
          ),
          child: const Icon(AppIcons.hint),
        ),
        Flexible(
          child: Text(
            hint,
            textAlign: TextAlign.center,
            style: context.texts.body.copyWith(
              color: context.colors.mutedForeground,
            ),
          ),
        ),
      ],
    ),
  );
}

/// A wrong answer: what was typed, struck through with its slip in the error
/// foreground ([typedAgainst]), the right term below it, and when it comes
/// back (F3, V1, V10).
class _Corrected extends StatelessWidget {
  const _Corrected({required this.typed, required this.term});

  final String typed;
  final String term;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tag = l10n.studyFillTagWrong;
    final colors = context.colors;
    final struck = context.texts.term.copyWith(
      color: colors.mutedForeground,
      decoration: TextDecoration.lineThrough,
      decorationColor: colors.mutedForeground,
    );
    final differing = struck.copyWith(
      color: colors.error,
      decorationColor: colors.error,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: context.dimens.space4,
      children: [
        // Struck through as a whole; only the letters that differ from the
        // term are in `error`, so the eye finds the slip (V1; audit
        // 2026-10-19, G6).
        Text.rich(
          TextSpan(
            children: [
              for (final (grapheme, isMatch) in typedAgainst(typed, term))
                TextSpan(text: grapheme, style: isMatch ? null : differing),
            ],
          ),
          semanticsLabel: l10n.studyFillTyped(typed),
          textAlign: TextAlign.center,
          style: struck,
        ),
        Text(
          term,
          textAlign: TextAlign.center,
          style: context.texts.term.copyWith(color: context.colors.foreground),
        ),
        Padding(
          padding: EdgeInsets.only(top: context.dimens.space8),
          child: Text(
            tag.toUpperCase(),
            semanticsLabel: tag,
            textAlign: TextAlign.center,
            style: context.texts.meta.copyWith(color: context.status.warning),
          ),
        ),
      ],
    );
  }
}

/// Each character of [typed] and whether it is one the term also has, in
/// order (the longest common subsequence, compared as grading folds them:
/// case and NFC ignored); the rest are the slip a wrong answer shows in
/// `error`. Spaces at either end, which grading trims, are never the slip.
/// When every character is in the term, the slip is a missing letter, which
/// has no character to mark, so the whole answer is the slip.
List<(String, bool)> typedAgainst(String typed, String term) {
  final all = typed.characters.toList();
  var start = 0;
  var end = all.length;
  while (start < end && all[start].trim().isEmpty) {
    start++;
  }
  while (end > start && all[end - 1].trim().isEmpty) {
    end--;
  }
  final a = [for (final g in all.sublist(start, end)) foldText(g)];
  final b = [for (final g in term.characters) foldText(g)];
  // lengths[i][j]: the common subsequence of a[i..] and b[j..].
  final lengths = List.generate(
    a.length + 1,
    (_) => List.filled(b.length + 1, 0),
  );
  for (var i = a.length - 1; i >= 0; i--) {
    for (var j = b.length - 1; j >= 0; j--) {
      lengths[i][j] = a[i] == b[j]
          ? lengths[i + 1][j + 1] + 1
          : math.max(lengths[i + 1][j], lengths[i][j + 1]);
    }
  }
  final isMatch = List.filled(a.length, false);
  var i = 0;
  var j = 0;
  while (i < a.length) {
    if (j < b.length && a[i] == b[j]) {
      isMatch[i] = true;
      i++;
      j++;
      continue;
    }
    if (j < b.length && lengths[i][j + 1] >= lengths[i + 1][j]) {
      j++;
      continue;
    }
    i++;
  }
  final isOmission = !isMatch.contains(false);
  return [
    for (final g in all.sublist(0, start)) (g, true),
    for (final (k, g) in all.sublist(start, end).indexed)
      (g, isMatch[k] && !isOmission),
    for (final g in all.sublist(end)) (g, true),
  ];
}
