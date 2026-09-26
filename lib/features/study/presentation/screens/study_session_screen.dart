import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/controllers/study_session_controller.dart';
import 'package:memox/features/study/presentation/providers/study_session_provider.dart';
import 'package:memox/features/study/presentation/states/session_ending_state.dart';
import 'package:memox/features/study/presentation/states/study_turn_state.dart';
import 'package:memox/features/study/presentation/widgets/sections/session_summary_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_browse_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_mode_not_built_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/session_context_line_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_labels_widget.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';
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

  /// The last view of the open session that served a card: a held turn is
  /// drawn in it even after its answer ended the session or stalled the
  /// round (spec D5).
  StudySessionView? _lastOpenView;

  StudySessionController get _controller =>
      ref.read(studySessionControllerProvider(widget.sessionId).notifier);

  void _abandon() => unawaited(_controller.abandon());

  void _advance(StudyItem item) =>
      unawaited(_controller.answer(item, const AdvanceAnswer()));

  void _retry() => unawaited(_controller.retry());

  void _reload() => ref.invalidate(studySessionProvider(widget.sessionId));

  void _onView(
    AsyncValue<Outcome<StudySessionView, StudyRejection>>? _,
    AsyncValue<Outcome<StudySessionView, StudyRejection>> next,
  ) {
    final l10n = context.l10n;
    switch (next) {
      case AsyncData(value: Rejected()):
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
    if (_hasLeft || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
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
      // The deck is gone: the listener leaves.
      AsyncData() => const MxAppShell(body: SizedBox.shrink()),
      AsyncError() => _errorPage(context),
      _ => const _LoadingPage(),
    };
    return PopScope(canPop: false, onPopInvokedWithResult: _onPop, child: page);
  }

  Widget _pageOf(StudySessionView view, StudyTurnState turn) {
    final ending = sessionEndingOf(view);
    // Only a view that serves a card can frame a held turn.
    if (ending == null && view.progress != null && view.currentItem != null) {
      _lastOpenView = view;
    }
    // The held turn stays until its mode releases it, even when its answer
    // ended the session: only then does the summary show (spec D5).
    if (turn.held != null) {
      return _sessionPage(context, _lastOpenView ?? view, turn);
    }
    return switch (ending) {
      ShowSummary(:final outcome) => SessionSummaryWidget(
        view: view,
        outcome: outcome,
        onDone: () => widget.onDone(view.deckId),
        onStudyDeck: () => widget.onStudyDeck(view.deckId),
      ),
      LeaveStale() => const MxAppShell(body: SizedBox.shrink()),
      null => _sessionPage(context, view, turn),
    };
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
    if (progress == null || item == null) return const _LoadingPage();
    final mode = l10n.studyMode(view.currentMode);
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
          if (view.kind == SessionKind.learning)
            SessionContextLineWidget(
              text: l10n.studyContextLearning(
                view.deckName,
                l10n.studyKindLearning,
                view.currentStageIndex + 1,
                view.stages.length,
                mode,
              ),
            ),
          if (turn.unsaved != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                0,
                AppSpacing.gutter,
                AppSpacing.grouped,
              ),
              child: MxInlineBanner(
                tone: MxBannerTone.danger,
                title: l10n.studyAnswerBusyTitle,
                message: l10n.studyAnswerBusyBody,
                actions: [
                  MxButton(
                    label: l10n.commonRetry,
                    size: MxButtonSize.compact,
                    onPressed: _retry,
                  ),
                ],
              ),
            ),
          Expanded(child: _modeBody(view, item, turn)),
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
    StudyMode.selfAssess ||
    StudyMode.match ||
    StudyMode.guess ||
    StudyMode.recall ||
    StudyMode.fill => StudyModeNotBuiltWidget(mode: view.currentMode),
  };

  /// The session could not be read (E5): retry, or close.
  Widget _errorPage(BuildContext context) {
    final l10n = context.l10n;
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.navStudy,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.close,
          semanticLabel: l10n.studySessionClose,
          onPressed: () => widget.onLeave(null),
        ),
      ),
      body: MxScreenScroll(
        children: [
          MxErrorState(
            title: l10n.studySessionErrorTitle,
            body: l10n.studySessionErrorBody,
            retryLabel: l10n.commonRetry,
            onRetry: _reload,
          ),
        ],
      ),
    );
  }
}

/// Before the session's first view: nothing to show but the wait. The
/// summary arrives with the session's view, so it has no loading of its
/// own (D2).
class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) => MxAppShell(
    body: Center(child: MxSpinner(semanticLabel: context.l10n.commonLoading)),
  );
}
