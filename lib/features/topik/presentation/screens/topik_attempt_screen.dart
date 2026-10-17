import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_audio_model.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/presentation/controllers/topik_attempt_controller.dart';
import 'package:memox/features/topik/presentation/providers/topik_attempt_provider.dart';
import 'package:memox/features/topik/presentation/widgets/overlays/topik_attempt_dialogs_widget.dart';
import 'package:memox/features/topik/presentation/widgets/overlays/topik_question_grid_sheet_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_attempt_footer_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_group_pane_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_question_pane_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_two_pane_widget.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';
import 'package:memox/shared/widgets/mx_study_top_bar.dart';

/// Screen 37 (UC-TOPIK-003): one question per page under its group's
/// material, in Practice mode.
///
/// - A pick is saved at once and shows only as chosen (BR-TOPIK-012, -016).
/// - Previous, Next and the grid move (BR-TOPIK-015).
/// - Submit asks when questions are blank (BR-TOPIK-014).
/// - Leaving loses nothing (BR-TOPIK-010).
///
/// The question clock lives in [TopikAttemptController]; this screen pauses
/// and resumes it with the app, and writes it when it goes. Where Close and
/// a submit lead, `app/` decides.
class TopikAttemptScreen extends ConsumerStatefulWidget {
  const TopikAttemptScreen({
    super.key,
    required this.attemptId,
    required this.onClose,
    required this.onSubmitted,
  });

  final String attemptId;

  /// Leaves: Close, and the way out of the states with nothing to answer.
  final VoidCallback onClose;

  /// The attempt was submitted: its summary (38) replaces this screen.
  final ValueChanged<String> onSubmitted;

  @override
  ConsumerState<TopikAttemptScreen> createState() => _TopikAttemptScreenState();
}

class _TopikAttemptScreenState extends ConsumerState<TopikAttemptScreen> {
  late final TopikAttemptController _controller;
  late final AppLifecycleListener _lifecycle;

  /// A question is on screen, as the clock was last told.
  var _isQuestionShown = false;

  /// The group pane shows its instruction alone (critique F5).
  var _isCollapsed = false;

  /// The person's own show or hide of a group's script, by group; without
  /// one, the script shows once the current question is answered (D15).
  final _scriptChoice = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _controller = ref.read(
      topikAttemptControllerProvider(widget.attemptId).notifier,
    );
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycle);
    // The clock follows what is on screen, so it is driven by the state
    // changing and not by the build (audit 2026-10-17 TOPIK-3).
    ref.listenManual(
      topikAttemptProvider(widget.attemptId),
      (_, _) => _syncClock(),
      fireImmediately: true,
    );
    ref.listenManual(
      topikAttemptControllerProvider(widget.attemptId),
      (_, _) => _syncClock(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    // The screen goes (Close, Back, a route on top that replaces it): the
    // current question keeps its time (BR-TOPIK-015).
    unawaited(_controller.leave());
    super.dispose();
  }

  /// Starts the question clock when a question comes on screen and stops it
  /// when one goes (BR-TOPIK-015); a repeat of the same answer does nothing.
  void _syncClock() {
    final isAnswering = _isAnswering(
      ref.read(topikAttemptProvider(widget.attemptId)),
      ref.read(topikAttemptControllerProvider(widget.attemptId)),
    );
    if (isAnswering == _isQuestionShown) return;
    _isQuestionShown = isAnswering;
    if (isAnswering) return _controller.showQuestion();
    unawaited(_controller.hideQuestion());
  }

  /// Whether [build] shows a question: its last branch, in the order of the
  /// switch there (an error shows its state even over a previous value).
  bool _isAnswering(AsyncValue<TopikAttemptView?> async, bool isSubmitting) =>
      switch (async) {
        AsyncError() => false,
        AsyncValue(:final value?) =>
          !(value.detail.attempt.isCompleted && !isSubmitting) &&
              !value.isContentMissing,
        _ => false,
      };

  void _onLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _controller.resume();
      case AppLifecycleState.hidden ||
          AppLifecycleState.paused ||
          AppLifecycleState.detached:
        unawaited(_controller.pause());
      case AppLifecycleState.inactive:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final attemptProvider = topikAttemptProvider(widget.attemptId);
    final async = ref.watch(attemptProvider);
    final isSubmitting = ref.watch(
      topikAttemptControllerProvider(widget.attemptId),
    );
    return switch (async) {
      AsyncError(:final error, :final isLoading) => _plain(
        MxErrorState(
          title: l10n.topikAttemptErrorTitle,
          body: error is Failure ? l10n.failure(error) : l10n.topikErrorBody,
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.invalidate(attemptProvider),
          isRetrying: isLoading,
        ),
      ),
      AsyncData(value: null) => _plain(
        // Deleted elsewhere or the account changed (UC-TOPIK-003 E2): a gone
        // item, not an error.
        MxEmptyState(
          icon: AppIcons.searchOff,
          title: l10n.topikAttemptMissing,
          tone: MxEmptyStateTone.neutral,
          actionLabel: l10n.topikBackToTest,
          onAction: widget.onClose,
        ),
      ),
      AsyncValue(:final value?)
          when value.detail.attempt.isCompleted && !isSubmitting =>
        _plain(
          MxEmptyState(
            icon: AppIcons.check,
            title: l10n.topikSubmittedTitle,
            tone: MxEmptyStateTone.neutral,
            actionLabel: l10n.topikSeeSummary,
            onAction: () => widget.onSubmitted(widget.attemptId),
          ),
        ),
      AsyncValue(:final value?) when value.isContentMissing => _plain(
        MxEmptyState(
          icon: AppIcons.alert,
          title: l10n.topikContentChangedTitle,
          tone: MxEmptyStateTone.warning,
          actionLabel: l10n.topikDeleteAttempt,
          onAction: () => unawaited(_delete()),
        ),
      ),
      AsyncValue(:final value?) => _answering(value, isSubmitting),
      _ => _plain(
        MxCard(
          isFullBleed: true,
          child: MxSkeletonList(semanticLabel: l10n.topikLoadingAttempt),
        ),
      ),
    };
  }

  /// A state with nothing to answer: the plain bar with Close, and [body]
  /// (The Content Gate Rule: no footer, no grid; critique F8). No question
  /// is on screen, so the clock is stopped (BR-TOPIK-015; [_syncClock]).
  Widget _plain(Widget body) {
    final l10n = context.l10n;
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.topikPractice,
        leading: MxIconButton(
          icon: AppIcons.close,
          semanticLabel: l10n.topikClose,
          onPressed: widget.onClose,
        ),
      ),
      body: MxScreenScroll(children: [body]),
    );
  }

  Widget _answering(TopikAttemptView view, bool isSubmitting) {
    final l10n = context.l10n;
    final test = view.test!;
    final questions = test.questions;
    final attempt = view.detail.attempt;
    final index = max(
      0,
      questions.indexWhere((q) => q.no == attempt.currentQuestionNo),
    );
    final question = questions[index];
    final group = test.groups.firstWhere((g) => g.groupId == question.groupId);
    final selected = {
      for (final answer in view.detail.answers)
        answer.questionNo: ?answer.selectedIdx,
    };
    final isScriptShown =
        _scriptChoice[group.groupId] ?? selected.containsKey(question.no);
    return PopScope(
      // Back while submitting does nothing (BR-TOPIK-014).
      canPop: !isSubmitting,
      child: MxAppShell(
        isSession: true,
        hasOwnAppBarGround: true,
        appBar: MxStudyTopBar(
          modeLabel: l10n.topikPractice,
          // The track is the position, as the counter (critique F2).
          current: index + 1,
          total: questions.length,
          counterLabel: l10n.topikOfTotal(question.no, questions.last.no),
          closeLabel: l10n.topikClose,
          onClose: isSubmitting ? null : widget.onClose,
        ),
        body: TopikTwoPaneWidget(
          top: TopikGroupPaneWidget(
            key: ValueKey(group.groupId),
            group: group,
            audio: topikGroupClip(test, group),
            isCollapsed: _isCollapsed,
            isScriptShown: isScriptShown,
            onToggleCollapsed: () =>
                setState(() => _isCollapsed = !_isCollapsed),
            onToggleScript: () =>
                setState(() => _scriptChoice[group.groupId] = !isScriptShown),
          ),
          bottom: TopikQuestionPaneWidget(
            key: ValueKey(question.no),
            question: question,
            selectedIdx: selected[question.no],
            onPick: isSubmitting
                ? null
                : (idx) => unawaited(_answer(question.no, idx)),
          ),
        ),
        footer: TopikAttemptFooterWidget(
          onPrevious: index == 0
              ? null
              : () => unawaited(_move(questions[index - 1].no)),
          onNext: index == questions.length - 1
              ? null
              : () => unawaited(_move(questions[index + 1].no)),
          onQuestions: () => unawaited(
            _openGrid(view, [for (final q in questions) q.no], selected),
          ),
          onSubmit: () => unawaited(_submit(view, selected.length)),
          isSubmitting: isSubmitting,
        ),
      ),
    );
  }

  Future<void> _answer(int questionNo, int idx) => _command(
    () => _controller.answer(questionNo: questionNo, selectedIdx: idx),
    failureMessage: context.l10n.topikChoiceNotSaved,
  );

  Future<void> _move(int questionNo) =>
      _command(() => _controller.move(questionNo));

  Future<void> _openGrid(
    TopikAttemptView view,
    List<int> questionNos,
    Map<int, int> selected,
  ) async {
    final current = view.detail.attempt.currentQuestionNo;
    final pick = await showTopikQuestionGrid(
      context,
      questionNos: questionNos,
      answered: selected.keys.toSet(),
      current: current,
    );
    if (!mounted) return;
    switch (pick) {
      case TopikGridQuestion(:final no) when no != current:
        await _move(no);
      case TopikGridSubmit():
        await _submit(view, selected.length);
      case TopikGridQuestion() || null:
        return;
    }
  }

  Future<void> _submit(TopikAttemptView view, int answeredCount) async {
    final l10n = context.l10n;
    final blanks = view.detail.answers.length - answeredCount;
    if (blanks > 0) {
      final isSure = await showMxConfirm(
        context,
        title: l10n.topikUnansweredTitle(blanks),
        body: l10n.topikUnansweredBody,
        cancelLabel: l10n.topikKeepAnswering,
        confirmLabel: l10n.topikSubmit,
      );
      if (!isSure || !mounted) return;
    }
    await _command(
      () => _controller.submit(view.detail.attempt.testId),
      onDone: (_) => widget.onSubmitted(widget.attemptId),
    );
  }

  Future<void> _delete() async {
    if (!await showTopikDeleteDialog(context) || !mounted) return;
    await _command(_controller.delete, onDone: (_) => widget.onClose());
  }

  /// Runs a command. A refusal is a snackbar naming it, except for an
  /// attempt already gone, which the screen shows. A database failure is
  /// [failureMessage], or the failure's own words; nothing was lost
  /// (UC-TOPIK-003 E4).
  Future<void> _command<T>(
    Future<Outcome<T, TopikRejection>?> Function() command, {
    void Function(T value)? onDone,
    String? failureMessage,
  }) async {
    try {
      final outcome = await command();
      if (!mounted || outcome == null) return;
      switch (outcome) {
        case Ok(:final value):
          onDone?.call(value);
        case Rejected(reason: TopikRejection.notFound):
          return;
        case Rejected(:final reason):
          showMxSnackbar(
            context,
            message: context.l10n.topikRejectionMessage(reason),
          );
      }
    } on Failure catch (failure) {
      if (!mounted) return;
      showMxSnackbar(
        context,
        message: failureMessage ?? context.l10n.failure(failure),
      );
    }
  }
}
