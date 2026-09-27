import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/controllers/study_session_controller.dart';
import 'package:memox/features/study/presentation/providers/study_session_view_provider.dart';
import 'package:memox/features/study/presentation/widgets/overlays/study_exit_dialog_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/session_context_line_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/session_footer_hint_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_browse_body_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_session_summary_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_labels_widget.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';
import 'package:memox/shared/widgets/mx_study_top_bar.dart';

/// Screens 16 to 21 on one route (spec D2, D3): the running session's body,
/// picked by an exhaustive switch over [StudyMode], and its summary once it
/// has ended. A reset elsewhere or a deleted deck leaves the route with a
/// message instead (spec D7).
class StudySessionScreen extends ConsumerStatefulWidget {
  const StudySessionScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends ConsumerState<StudySessionScreen> {
  static const int _skeletonRows = 4;

  /// Set once the route is being left, so a second emission does not pop
  /// twice.
  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(
      studySessionViewProvider(widget.sessionId),
      _onView,
      fireImmediately: true,
    );
  }

  Future<void> _exit() async {
    if (!await showStudyExitDialog(context)) return;
    await ref
        .read(studySessionControllerProvider(widget.sessionId).notifier)
        .abandon();
    // The stream re-emits with the session ended, and this route shows its
    // summary (spec D2, D8). Nothing is popped here.
  }

  /// Leaves the route after this frame, with the message [messageOf]
  /// picks: this can run from initState, before localizations are read.
  void _leave(String Function(AppLocalizations l10n) messageOf) {
    if (_isLeaving) return;
    _isLeaving = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showMxSnackbar(context, message: messageOf(context.l10n));
      unawaited(Navigator.of(context).maybePop());
    });
  }

  void _onView(
    AsyncValue<Outcome<StudySessionView, StudyRejection>>? previous,
    AsyncValue<Outcome<StudySessionView, StudyRejection>> next,
  ) {
    switch (next) {
      case AsyncData(value: Rejected()):
        _leave((l10n) => l10n.studySessionGoneSnackbar);
      case AsyncData(value: Ok(:final value))
          when value.endReason == SessionEndReason.staleGeneration:
        _leave((l10n) => l10n.studySessionStaleSnackbar);
      case _:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = studySessionViewProvider(widget.sessionId);
    return switch (ref.watch(provider)) {
      AsyncData(value: Ok(:final value))
          when value.endReason == SessionEndReason.staleGeneration =>
        const MxAppShell(body: SizedBox.shrink()),
      AsyncData(value: Ok(:final value)) when value.summary != null =>
        StudySessionSummaryWidget(
          view: value,
          summary: value.summary!,
          // P1's only way into a session is the Study entry, so one pop lands
          // on it again: Done back to the deck, Study this deck to study on.
          onDone: () => unawaited(Navigator.of(context).maybePop()),
          onStudyThisDeck: () => unawaited(Navigator.of(context).maybePop()),
        ),
      AsyncData(value: Ok(:final value)) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) unawaited(_exit());
        },
        child: _RunningSession(
          sessionId: widget.sessionId,
          view: value,
          onExit: () => unawaited(_exit()),
        ),
      ),
      AsyncData(value: Rejected()) => const MxAppShell(body: SizedBox.shrink()),
      AsyncError() => MxAppShell(
        body: MxScreenScroll(
          children: [
            MxErrorState(
              title: l10n.studySessionLoadErrorTitle,
              body: l10n.libraryLoadErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(provider),
            ),
          ],
        ),
      ),
      _ => MxAppShell(
        body: MxScreenScroll(
          children: [
            MxSkeletonList(
              semanticLabel: l10n.commonLoading,
              rows: _skeletonRows,
            ),
          ],
        ),
      ),
    };
  }
}

class _RunningSession extends StatelessWidget {
  const _RunningSession({
    required this.sessionId,
    required this.view,
    required this.onExit,
  });

  final String sessionId;
  final StudySessionView view;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progress = view.progress;
    final total = progress?.total ?? 0;
    final current = total == 0 ? 0 : (progress!.completed + 1).clamp(1, total);
    final modeLabel = l10n.studyMode(view.currentMode);
    final item = view.currentItem;
    return MxAppShell(
      appBar: MxStudyTopBar(
        modeLabel: modeLabel,
        current: current,
        total: total,
        counterLabel: l10n.studySessionCounterLabel(current, total),
        closeLabel: l10n.studySessionExitLabel,
        onClose: onExit,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.control,
          AppSpacing.gutter,
          AppSpacing.gutter,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.grouped,
          children: [
            SessionContextLineWidget(
              deckName: view.deckName,
              sessionKind: l10n.studySessionKind(view.kind),
              stage: view.currentStageIndex + 1,
              totalStages: view.stages.length,
              modeLabel: modeLabel,
            ),
            Expanded(
              child: item == null
                  ? MxSkeletonList(semanticLabel: l10n.commonLoading)
                  : switch (view.currentMode) {
                      StudyMode.browse => StudyBrowseBodyWidget(
                        sessionId: sessionId,
                        currentItem: item,
                      ),
                      StudyMode.selfAssess ||
                      StudyMode.match ||
                      StudyMode.guess ||
                      StudyMode.recall ||
                      StudyMode.fill => Center(
                        child: Text(
                          l10n.studySessionComingSoonBody(modeLabel),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    },
            ),
            if (view.currentMode == StudyMode.browse)
              SessionFooterHintWidget(text: l10n.studyBrowseFooterHint),
          ],
        ),
      ),
    );
  }
}
