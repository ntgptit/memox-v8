import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study/presentation/widgets/support/recall_countdown_bar_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/session_footer_hint_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_appearing_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_cta_row_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_face_card_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_whole_word_text_widget.dart';
import 'package:memox/features/study_mode/domain/models/recall_mode.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';

/// Screen 19, Recall: the term, the meaning hidden behind the turn's
/// 20-second clock (BR-STUDY-031). Revealing records nothing; only the
/// self-check after it does, and the next card follows at once
/// (BR-STUDY-032, BR-STUDY-065). At zero the turn counts as forgot and waits
/// for Continue (BR-STUDY-033, BR-STUDY-066).
///
/// The clock is this widget's (spec D12): it stops whenever the app leaves
/// the foreground, and saves the time left on pause and when the turn's
/// screen goes, never per tick (BR-STUDY-036). The screen keys it per turn.
class StudyRecallWidget extends StatefulWidget {
  const StudyRecallWidget({
    super.key,
    required this.item,
    required this.result,
    required this.isBusy,
    required this.onReveal,
    required this.onSaveTime,
    required this.onAnswer,
    required this.onTimeUp,
    required this.onContinue,
  });

  final StudyItem item;

  /// The timed-out turn's committed result, held on screen (spec D5).
  final TurnResult? result;
  final bool isBusy;

  /// Show the meaning, with the time left.
  final ValueChanged<int> onReveal;

  /// Keep the time left of a turn still counting down.
  final ValueChanged<int> onSaveTime;

  /// The self-check after the reveal.
  final ValueChanged<RecallOutcome> onAnswer;

  /// The clock reached zero.
  final VoidCallback onTimeUp;
  final VoidCallback onContinue;

  @override
  State<StudyRecallWidget> createState() => _StudyRecallWidgetState();
}

class _StudyRecallWidgetState extends State<StudyRecallWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;
  late final AppLifecycleListener _lifecycle;

  /// Show the meaning was tapped; the reveal is being written.
  var _isStopped = false;

  /// The clock reached zero; the timeout is being written.
  var _hasTimedUp = false;

  int get _remainingMs => (_clock.value * recallTurnMs).round();

  bool get _isTimedOut => widget.result != null;

  bool get _isRunning =>
      !widget.item.isRevealed && !_isStopped && !_hasTimedUp && !_isTimedOut;

  @override
  void initState() {
    super.initState();
    final left = widget.item.remainingMs ?? recallTurnMs;
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: recallTurnMs),
      value: left / recallTurnMs,
    )..addStatusListener(_onClockStatus);
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycle);
    if (!_isRunning) return;
    if (left == 0) {
      // A turn saved at zero: its time is already up.
      WidgetsBinding.instance.addPostFrameCallback((_) => _timeUp());
      return;
    }
    unawaited(_clock.reverse());
  }

  @override
  void didUpdateWidget(StudyRecallWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result == null && widget.result != null) _announceTimeout();
    // A reveal the database refused: the turn counts down again.
    final isRefused =
        oldWidget.isBusy &&
        !widget.isBusy &&
        _isStopped &&
        !widget.item.isRevealed;
    if (isRefused) {
      _isStopped = false;
      unawaited(_clock.reverse());
    }
  }

  @override
  void dispose() {
    if (_isRunning) widget.onSaveTime(_remainingMs);
    _lifecycle.dispose();
    _clock.dispose();
    super.dispose();
  }

  void _onClockStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && _isRunning) _timeUp();
  }

  void _timeUp() {
    if (!mounted || !_isRunning) return;
    setState(() => _hasTimedUp = true);
    widget.onTimeUp();
  }

  /// Background time is not the turn's (BR-STUDY-036): a resumed ticker
  /// would jump by it, so the clock stops on any state but resumed.
  void _onLifecycle(AppLifecycleState state) {
    if (!_isRunning) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(_clock.reverse());
      return;
    }
    _clock.stop();
    if (state == AppLifecycleState.paused) widget.onSaveTime(_remainingMs);
  }

  void _reveal() {
    _clock.stop();
    setState(() => _isStopped = true);
    widget.onReveal(_remainingMs);
  }

  void _announceTimeout() => unawaited(
    SemanticsService.sendAnnouncement(
      View.of(context),
      context.l10n.studyRecallAnnounceTimedOut(widget.item.back),
      Directionality.of(context),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isTimedOut = _isTimedOut;
    final isRevealed = !isTimedOut && widget.item.isRevealed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedBuilder(
          animation: _clock,
          builder: (context, _) => RecallCountdownBarWidget(
            caption: isTimedOut
                ? l10n.studyRecallCaptionTimedOut
                : isRevealed
                ? l10n.studyRecallCaptionRevealed
                : l10n.studyRecallCaptionCounting,
            remainingMs: isTimedOut
                ? 0
                : isRevealed
                ? widget.item.remainingMs ?? _remainingMs
                : _remainingMs,
            isTimedOut: isTimedOut,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.control,
              children: [
                Expanded(
                  child: StudyFaceCardWidget(
                    label: l10n.studyBrowseTerm,
                    child: StudyWholeWordTextWidget(
                      widget.item.front,
                      style: context.textStyles.studyTerm,
                    ),
                  ),
                ),
                Expanded(
                  child: StudyFaceCardWidget(
                    label: l10n.studyBrowseMeaning,
                    isAnswer: true,
                    child: StudyAppearingWidget(
                      isShown: isRevealed || isTimedOut,
                      child: _Meaning(
                        meaning: widget.item.back,
                        isTimedOut: isTimedOut,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        StudyCtaRowWidget(children: _actions(isTimedOut, isRevealed)),
        SessionFooterHintWidget(
          icon: AppIcons.check,
          text: isTimedOut
              ? l10n.studyRecallHintTimedOut
              : isRevealed
              ? l10n.studyRecallHintRevealed
              : l10n.studyRecallHintCounting,
        ),
      ],
    );
  }

  List<Widget> _actions(bool isTimedOut, bool isRevealed) {
    final l10n = context.l10n;
    final isBusy = widget.isBusy;
    if (isTimedOut) {
      return [
        MxButton(
          label: l10n.studyContinue,
          size: MxButtonSize.study,
          onPressed: isBusy ? null : widget.onContinue,
        ),
      ];
    }
    if (isRevealed) {
      return [
        MxButton(
          label: l10n.studyRecallForgot,
          tone: MxButtonTone.outline,
          size: MxButtonSize.study,
          isBlock: true,
          onPressed: isBusy
              ? null
              : () => widget.onAnswer(RecallOutcome.forgot),
        ),
        MxButton(
          label: l10n.studyRecallRemembered,
          size: MxButtonSize.study,
          isBlock: true,
          onPressed: isBusy
              ? null
              : () => widget.onAnswer(RecallOutcome.remembered),
        ),
      ];
    }
    return [
      MxButton(
        label: l10n.studyRecallShowMeaning,
        size: MxButtonSize.study,
        onPressed: isBusy || !_isRunning ? null : _reveal,
      ),
    ];
  }
}

/// The meaning, tagged "Counted as forgot" once the time ran out.
class _Meaning extends StatelessWidget {
  const _Meaning({required this.meaning, required this.isTimedOut});

  final String meaning;
  final bool isTimedOut;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final tag = context.l10n.studyRecallTagTimedOut;
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.grouped,
      children: [
        Text(meaning, textAlign: TextAlign.center, style: styles.studyPassage),
        if (isTimedOut)
          Text(
            tag.toUpperCase(),
            semanticsLabel: tag,
            textAlign: TextAlign.center,
            style: styles.statusLabel(context.derivedColors.warningInk),
          ),
      ],
    );
  }
}
