import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/controllers/study_session_controller.dart';
import 'package:memox/features/study/presentation/providers/self_assess_preview_provider.dart';
import 'package:memox/features/study/presentation/providers/study_session_provider.dart';
import 'package:memox/features/study/presentation/states/session_context_state.dart';
import 'package:memox/features/study/presentation/states/session_ending_state.dart';
import 'package:memox/features/study/presentation/states/study_turn_state.dart';
import 'package:memox/features/study/presentation/widgets/sections/session_summary_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_browse_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_fill_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_guess_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_match_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_recall_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_self_assess_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_session_error_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/session_context_line_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_labels_widget.dart';
import 'package:memox/features/study/presentation/widgets/overlays/study_exit_dialog_widget.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';
import 'package:memox/shared/widgets/mx_study_top_bar.dart';

/// The session route (spec D2): the open session's stage in its shell, and
/// once it has ended, its summary on the same route (D3). ✕ and system Back
/// end it at once and the summary follows (the owner's ruling on D8); a
/// deck gone (A5) or a stale write (E4) leaves with a word.
class StudySessionScreen extends ConsumerStatefulWidget {
  const StudySessionScreen({
    super.key,
    required this.sessionId,
    required this.onDone,
    required this.onStudyDeck,
    required this.onLeave,
  });

  final String sessionId;

  /// The summary's Done: back to the session's deck.
  final ValueChanged<String> onDone;

  /// The summary's Study this deck: the deck's Study Entry.
  final ValueChanged<String> onStudyDeck;

  /// Leaves after a toast: to the deck (E4), or the Library when the deck is
  /// gone (null, A5).
  final ValueChanged<String?> onLeave;

  @override
  ConsumerState<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends ConsumerState<StudySessionScreen> {
  /// A leave runs once, whatever the stream emits after it.
  var _hasLeft = false;

  /// A leave that arrived while this route was covered (the exit dialog is a
  /// route): remembered, and run when the dialog's future completes (2.07).
  (String, String?)? _pendingLeave;

  /// The exit dialog is open: ✕ and Back do nothing meanwhile (2.08).
  var _isConfirming = false;

  /// Set while the exit dialog is up; Recall's clock follows it (2.11).
  final ValueNotifier<bool> _overlayOpen = ValueNotifier(false);

  /// The last view of the open session that served a card: a held turn is
  /// drawn in it even after its answer ended the session or stalled the
  /// round (spec D5).
  StudySessionView? _lastOpenView;

  /// The summary last drawn. When its deck is lost the stream turns
  /// `Rejected`; the summary stays, without Study this deck, and Done leaves
  /// for the Library (2.51).
  ({StudySessionView view, SummaryOutcome outcome})? _shownSummary;

  /// Read once: a mode body's dispose (Recall's time save) calls it while
  /// the tree is being torn down, when no ancestor can be looked up.
  late final StudySessionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(
      studySessionControllerProvider(widget.sessionId).notifier,
    );
  }

  @override
  void dispose() {
    _overlayOpen.dispose();
    super.dispose();
  }

  /// The ✕ and system Back ask first (spec D8, owner ruling 2026-09-27);
  /// Stop abandons, Keep studying changes nothing. One dialog at a time
  /// (2.08).
  void _abandon() => unawaited(_confirmAbandon());

  Future<void> _confirmAbandon() async {
    if (_isConfirming) return;
    _isConfirming = true;
    _overlayOpen.value = true;
    final bool shouldStop;
    try {
      shouldStop = await showStudyExitDialog(context);
    } finally {
      _isConfirming = false;
      if (mounted) _overlayOpen.value = false;
    }
    if (!mounted) return;
    // The deck went, or the session was reset, while the dialog was up: the
    // leave the listener could not run runs now, and there is nothing to
    // stop (2.07).
    final pending = _pendingLeave;
    if (pending != null) {
      _pendingLeave = null;
      _leave(pending.$1, pending.$2);
      return;
    }
    if (!shouldStop) return;
    final didStop = await _controller.abandon();
    if (!didStop && mounted) {
      showMxSnackbar(context, message: context.l10n.studyStopFailed);
    }
  }

  void _advance(StudyItem item) =>
      unawaited(_controller.answer(item, const AdvanceAnswer()));

  /// The Guess option picked for the turn on screen (G1).
  String? _chosenCardId;

  void _pick(StudyItem item, String optionCardId) {
    setState(() => _chosenCardId = optionCardId);
    unawaited(
      _controller.answer(
        item,
        GuessAnswer(optionCardId),
        shouldHoldFeedback: true,
      ),
    );
  }

  /// The Match pair on hold: its term, then its meaning (M2).
  (String, String)? _heldPair;

  void _pair(StudyItem item, String termCardId, String meaningCardId) {
    setState(() => _heldPair = (termCardId, meaningCardId));
    unawaited(
      _controller.answer(
        item,
        MatchAnswer(meaningCardId),
        shouldHoldFeedback: true,
        cardId: termCardId,
      ),
    );
  }

  /// The held turn met its continue condition (D5): the next one follows.
  void _release() {
    _chosenCardId = null;
    _heldPair = null;
    _controller.release();
  }

  /// The clock ran out: a wrong turn, held until Continue (R2, D5).
  void _timeUp(StudyItem item) => unawaited(
    _controller.answer(
      item,
      const RecallAnswer(RecallOutcome.timedOut),
      shouldHoldFeedback: true,
    ),
  );

  /// A Fill answer is held: a right one is released at once, a wrong one
  /// on Continue (F3, D5).
  void _check(StudyItem item, String typed) => unawaited(
    _controller.answer(item, FillAnswer(typed), shouldHoldFeedback: true),
  );

  void _grade(StudyItem item, Sm2Action action) =>
      unawaited(_controller.answer(item, SelfAssessAnswer(action)));

  void _retry() => unawaited(_controller.retry());

  /// Watched while the card is served, so the grades have it at the reveal
  /// (16a). A failed read shows no interval.
  Map<Object, int>? _previewOf(StudySessionView view, StudyItem item) => ref
      .watch(
        selfAssessPreviewProvider(
          kind: view.kind,
          cardId: item.cardId,
          round: item.round,
          answersInSession: item.answersInSession,
        ),
      )
      .value;

  void _reload() => ref.invalidate(studySessionProvider(widget.sessionId));

  void _onView(
    AsyncValue<Outcome<StudySessionView, StudyRejection>>? _,
    AsyncValue<Outcome<StudySessionView, StudyRejection>> next,
  ) {
    final l10n = context.l10n;
    switch (next) {
      // A summary on screen stays (2.51); an open session whose deck is gone
      // leaves with a word (A5).
      case AsyncData(value: Rejected()) when _shownSummary == null:
        _leave(l10n.studyEntryDeckGone, null);
      case AsyncData(value: Ok(:final value))
          when sessionEndingOf(value) is LeaveStale:
        _leave(l10n.studySessionStaleToast, value.deckId);
      // A held turn is on screen first; its release settles (spec D5).
      case AsyncData(value: Ok(:final value))
          when value.isStalled && !_isHolding:
        unawaited(_controller.settle());
      default:
        break;
    }
  }

  bool get _isHolding =>
      ref.read(studySessionControllerProvider(widget.sessionId)).held != null;

  /// A released hold lets a round stalled meanwhile settle (spec D5, D12).
  void _onTurn(StudyTurnState? previous, StudyTurnState next) {
    if (previous?.held == null || next.held != null) return;
    final current = ref.read(studySessionProvider(widget.sessionId));
    if (current case AsyncData(value: Ok(:final value)) when value.isStalled) {
      unawaited(_controller.settle());
    }
  }

  void _leave(String message, String? deckId) {
    if (_hasLeft) return;
    // Under the exit dialog the route is not current: keep the leave for
    // when it closes (2.07).
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) {
      _pendingLeave = (message, deckId);
      return;
    }
    _hasLeft = true;
    showMxSnackbar(context, message: message);
    widget.onLeave(deckId);
  }

  /// System Back: an open session ends (A3); an ended one is Done.
  void _onPop(bool didPop, Object? _) {
    if (didPop) return;
    final current = ref.read(studySessionProvider(widget.sessionId));
    if (current case AsyncData(value: Ok(:final value))
        when sessionEndingOf(value) is ShowSummary) {
      widget.onDone(value.deckId);
      return;
    }
    // A summary kept over a lost deck: Back is Done (2.51).
    if (_shownSummary != null) {
      widget.onLeave(null);
      return;
    }
    _abandon();
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..listen(studySessionProvider(widget.sessionId), _onView)
      ..listen(studySessionControllerProvider(widget.sessionId), _onTurn);
    final turn = ref.watch(studySessionControllerProvider(widget.sessionId));
    final page = switch (ref.watch(studySessionProvider(widget.sessionId))) {
      AsyncData(value: Ok(:final value)) => _pageOf(value, turn),
      // The deck is gone: the listener leaves, unless a summary is on
      // screen, which stays (2.51).
      AsyncData() => switch (_shownSummary) {
        final shown? => _summaryPage(
          shown.view,
          shown.outcome,
          isDeckLost: true,
        ),
        null => const MxAppShell(body: SizedBox.shrink()),
      },
      AsyncError(:final isLoading) => StudySessionErrorWidget(
        onClose: () => widget.onLeave(null),
        onRetry: _reload,
        isRetrying: isLoading,
      ),
      _ => const StudySessionLoadingWidget(),
    };
    return PopScope(canPop: false, onPopInvokedWithResult: _onPop, child: page);
  }

  Widget _pageOf(StudySessionView view, StudyTurnState turn) {
    final ending = sessionEndingOf(view);
    // While a write runs or a turn is held, the screen stays on the view the
    // answer was given in: the stream may already serve the next board or
    // round, and a mode keyed by it would lose its hold (spec D5; P3 final
    // review). Only a view that serves a card can frame a turn.
    final isFrozen = turn.isBusy || turn.held != null;
    if (!isFrozen &&
        ending == null &&
        view.progress != null &&
        view.currentItem != null) {
      _lastOpenView = view;
    }
    // The held turn stays until its mode releases it, even when its answer
    // ended the session: only then does the summary show (spec D5).
    final frame = _lastOpenView;
    if (turn.held != null || (turn.isBusy && frame != null)) {
      return _sessionPage(context, frame ?? view, turn);
    }
    return switch (ending) {
      ShowSummary(:final outcome) => _summaryPage(
        view,
        outcome,
        isDeckLost: false,
      ),
      LeaveStale() => const MxAppShell(body: SizedBox.shrink()),
      null => _sessionPage(context, view, turn),
    };
  }

  Widget _summaryPage(
    StudySessionView view,
    SummaryOutcome outcome, {
    required bool isDeckLost,
  }) {
    _shownSummary = (view: view, outcome: outcome);
    return SessionSummaryWidget(
      view: view,
      outcome: outcome,
      canStudyDeck: !isDeckLost,
      // The deck's route is gone with it: Done leaves for the Library.
      onDone: () =>
          isDeckLost ? widget.onLeave(null) : widget.onDone(view.deckId),
      onStudyDeck: () => widget.onStudyDeck(view.deckId),
    );
  }

  Widget _sessionPage(
    BuildContext context,
    StudySessionView view,
    StudyTurnState turn,
  ) {
    final l10n = context.l10n;
    final progress = view.progress;
    // A held turn stays on screen until its mode releases it (D5).
    final item = turn.held?.item ?? view.currentItem;
    // Stalled: the listener settles it.
    if (progress == null || item == null) {
      return const StudySessionLoadingWidget();
    }
    final mode = l10n.studyMode(view.currentMode);
    // A busy database refused an answer (Retry saves it), or a reveal was
    // refused or failed (the Show the meaning button is its retry, 2.12).
    final isAnswerUnsaved = turn.unsaved != null;
    final (bannerTitle, bannerBody) = isAnswerUnsaved
        ? (l10n.studyAnswerBusyTitle, l10n.studyAnswerBusyBody)
        : (l10n.studyRevealFailedTitle, l10n.studyRevealFailedBody);
    return MxAppShell(
      appBar: MxStudyTopBar(
        modeLabel: mode,
        current: min(progress.completed + 1, progress.total),
        total: progress.total,
        counterLabel: l10n.studySessionCounter(
          min(progress.completed + 1, progress.total),
          progress.total,
        ),
        closeLabel: l10n.studySessionClose,
        onClose: _abandon,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SessionContextLineWidget(
            text: sessionContextOf(l10n, view),
            shown: sessionContextShownOf(l10n, view),
          ),
          if (isAnswerUnsaved || turn.hasWriteFailed)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                0,
                AppSpacing.gutter,
                AppSpacing.grouped,
              ),
              child: MxInlineBanner(
                // A refused answer is unsaved (danger); a failed reveal lost
                // nothing (warning).
                tone: isAnswerUnsaved
                    ? MxBannerTone.danger
                    : MxBannerTone.warning,
                title: bannerTitle,
                message: bannerBody,
                actions: [
                  if (isAnswerUnsaved)
                    MxButton(
                      label: l10n.commonRetry,
                      size: MxButtonSize.compact,
                      onPressed: _retry,
                    ),
                ],
              ),
            ),
          // Keyed so a banner above it coming or going keeps the mode's state
          // (Recall's clock) instead of rebuilding it.
          Expanded(
            key: const ValueKey('mode-body'),
            child: _modeBody(view, item, turn),
          ),
        ],
      ),
    );
  }

  /// One body per mode (D3): a seventh mode is a compile error here.
  Widget _modeBody(
    StudySessionView view,
    StudyItem item,
    StudyTurnState turn,
  ) => switch (view.currentMode) {
    StudyMode.browse => StudyBrowseWidget(
      view: view,
      item: item,
      isBusy: turn.isBusy,
      onAdvance: () => _advance(item),
    ),
    StudyMode.selfAssess => StudySelfAssessWidget(
      key: ValueKey('${item.cardId}#${item.answersInSession}'),
      item: item,
      intervals: _previewOf(view, item),
      isBusy: turn.isBusy,
      onGrade: (action) => _grade(item, action),
    ),
    StudyMode.guess => StudyGuessWidget(
      key: ValueKey('guess#${item.cardId}#${item.round}'),
      item: item,
      chosenCardId: _chosenCardId,
      result: turn.held?.result,
      isBusy: turn.isBusy,
      onPick: (optionCardId) => _pick(item, optionCardId),
      onContinue: _release,
      onClose: _abandon,
    ),
    StudyMode.match => StudyMatchWidget(
      key: ValueKey('match#${item.round}#${view.board!.terms.first.cardId}'),
      board: view.board!,
      result: turn.held?.result,
      heldPair: _heldPair,
      isBusy: turn.isBusy,
      onPair: (term, meaning) => _pair(item, term, meaning),
      onSettled: _release,
    ),
    StudyMode.recall => StudyRecallWidget(
      key: ValueKey('recall#${item.cardId}#${item.answersInSession}'),
      item: item,
      result: turn.held?.result,
      isBusy: turn.isBusy,
      hasWriteFailed: turn.hasWriteFailed,
      overlayOpen: _overlayOpen,
      onReveal: (ms) => unawaited(_controller.revealRecall(item, ms)),
      onSaveTime: (ms) => unawaited(_controller.saveRecallTime(item, ms)),
      onAnswer: (outcome) =>
          unawaited(_controller.answer(item, RecallAnswer(outcome))),
      onTimeUp: () => _timeUp(item),
      onContinue: _release,
    ),
    StudyMode.fill => StudyFillWidget(
      key: ValueKey('fill#${item.cardId}#${item.answersInSession}'),
      item: item,
      result: turn.held?.result,
      isBusy: turn.isBusy,
      onCheck: (typed) => _check(item, typed),
      onShowHint: () => unawaited(_controller.showFillHint(item)),
      onContinue: _release,
    ),
  };
}
