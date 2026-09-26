import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study/presentation/widgets/support/session_footer_hint_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_cta_row_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_face_card_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// Screen 20, Fill: the meaning asks, the person types the term
/// (BR-STUDY-026). A right answer lets the next turn follow at once; a
/// wrong one stays on screen, the typed text struck through beside the
/// right term, until Continue (BR-STUDY-059, BR-STUDY-063, BR-STUDY-064).
/// The typed text lives only here and in the one answer sent; it is never
/// kept (BR-STUDY-027). The screen keys it per turn.
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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.control,
              children: [
                Expanded(
                  child: StudyFaceCardWidget(
                    label: l10n.studyBrowseMeaning,
                    child: Text(
                      item.back,
                      textAlign: TextAlign.center,
                      style: context.textStyles.studyPassage,
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
                            spacing: AppSpacing.grouped,
                            children: [
                              if (isHintShown) _HintRow(hint: hint),
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
        ListenableBuilder(
          listenable: _answer,
          builder: (context, _) => StudyCtaRowWidget(
            children: _isWrong
                ? [
                    MxButton(
                      label: l10n.studyContinue,
                      size: MxButtonSize.study,
                      onPressed: widget.onContinue,
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
        SessionFooterHintWidget(
          icon: AppIcons.edit,
          text: _isWrong
              ? l10n.studyFillHintWrong
              : isHintShown
              ? l10n.studyFillHintUsed
              : l10n.studyFillHintInput,
        ),
      ],
    );
  }
}

/// The card's hint, shown on request (BR-STUDY-028).
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
      spacing: AppSpacing.control,
      children: [
        IconTheme(
          data: IconThemeData(
            color: context.colors.onSurfaceVariant,
            size: AppIconSize.inline,
          ),
          child: const Icon(AppIcons.hint),
        ),
        Flexible(
          child: Text(
            hint,
            textAlign: TextAlign.center,
            style: context.textStyles.sessionHint,
          ),
        ),
      ],
    ),
  );
}

/// A wrong answer: what was typed, struck through in the error ink, the
/// right term below it, and when it comes back (F3, V1, V10).
class _Corrected extends StatelessWidget {
  const _Corrected({required this.typed, required this.term});

  final String typed;
  final String term;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final tag = l10n.studyFillTagWrong;
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.micro,
      children: [
        Text(
          typed,
          semanticsLabel: l10n.studyFillTyped(typed),
          textAlign: TextAlign.center,
          style: styles.fillAnswer(context.colors.error, isStruck: true),
        ),
        Text(
          term,
          textAlign: TextAlign.center,
          style: styles.fillAnswer(context.colors.onSurface, isStruck: false),
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.control),
          child: Text(
            tag.toUpperCase(),
            semanticsLabel: tag,
            textAlign: TextAlign.center,
            style: styles.statusLabel(context.derivedColors.warningInk),
          ),
        ),
      ],
    );
  }
}
