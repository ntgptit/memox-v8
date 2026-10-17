import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/presentation/controllers/topik_test_detail_controller.dart';
import 'package:memox/features/topik/presentation/providers/topik_test_detail_provider.dart';
import 'package:memox/features/topik/presentation/widgets/overlays/topik_attempt_dialogs_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_history_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_overview_widget.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

enum _Tab { overview, history }

/// Screen 36 (UC-TOPIK-002): one test's Overall Progress, recent attempts
/// and History, the door to a new attempt (BR-TOPIK-011), and deleting one
/// (BR-TOPIK-018). Figures and numbers follow every write (A3). Where an
/// attempt, a summary or a review leads, `app/` decides.
class TopikTestDetailScreen extends ConsumerStatefulWidget {
  const TopikTestDetailScreen({
    super.key,
    required this.testId,
    required this.onOpenAttempt,
    required this.onOpenSummary,
    required this.onOpenReview,
    required this.onBackToTests,
  });

  final String testId;
  final ValueChanged<String> onOpenAttempt;
  final ValueChanged<String> onOpenSummary;
  final ValueChanged<String> onOpenReview;
  final VoidCallback onBackToTests;

  @override
  ConsumerState<TopikTestDetailScreen> createState() =>
      _TopikTestDetailScreenState();
}

class _TopikTestDetailScreenState extends ConsumerState<TopikTestDetailScreen> {
  var _tab = _Tab.overview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final detailProvider = topikTestDetailProvider(widget.testId);
    final async = ref.watch(detailProvider);
    // Content only from data: on an error Riverpod keeps the last value,
    // and the error state has neither the FAB nor the test's title
    // (The Content Gate Rule).
    final detail = async.hasError ? null : async.value;
    final test = detail?.test;
    final now = ref.watch(dayClockProvider).now();
    // Watched so the controller lives as long as the screen: its busy flag
    // must outlast the first tap for a second one to be ignored.
    ref.watch(topikTestDetailControllerProvider(widget.testId));
    final children = switch (async) {
      AsyncError(:final error, :final isLoading) => [
        MxErrorState(
          title: l10n.topikDetailErrorTitle,
          body: error is Failure ? l10n.failure(error) : l10n.topikErrorBody,
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.invalidate(detailProvider),
          isRetrying: isLoading,
        ),
      ],
      AsyncValue(:final value?) when value.test == null => [
        MxEmptyState(
          // Not an error: the test is not there, as a route that leads
          // nowhere (RouteNotFoundScreen).
          icon: AppIcons.searchOff,
          title: l10n.topikTestMissingTitle,
          tone: MxEmptyStateTone.neutral,
          actionLabel: l10n.topikBackToTests,
          onAction: widget.onBackToTests,
        ),
      ],
      AsyncValue(:final value?) => _loaded(value, now),
      _ => [
        MxCard(
          isFullBleed: true,
          child: MxSkeletonList(semanticLabel: l10n.topikLoadingTest),
        ),
      ],
    };
    // The FAB exists with the test and an attempt to add a sibling to; on
    // an empty Overview the empty state's Start is the one action
    // (The Content Gate Rule, critique F2).
    final hasFab =
        test != null &&
        detail != null &&
        !(detail.progress.isEmpty && _tab == _Tab.overview);
    return MxAppShell(
      appBar: MxAppBar(
        title: test?.titleKo ?? l10n.topikTitle,
        subtitle: test == null
            ? null
            : l10n.topikTestSubtitle(
                l10n.topikLevelName(test.level),
                l10n.topikSectionName(test.section),
              ),
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      fab: hasFab
          ? MxFab(
              icon: AppIcons.add,
              semanticLabel: l10n.topikStart,
              onPressed: () => unawaited(_start(detail)),
            )
          : null,
      body: MxScreenScroll(
        clearance: hasFab ? MxScrollClearance.fab : MxScrollClearance.base,
        children: children,
      ),
    );
  }

  List<Widget> _loaded(TopikTestDetail detail, DateTime now) {
    final l10n = context.l10n;
    return [
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: MxSegmentedTray<_Tab>(
          segments: [
            MxSegment(value: _Tab.overview, label: l10n.topikOverview),
            MxSegment(value: _Tab.history, label: l10n.topikHistory),
          ],
          selected: _tab,
          onSelected: (tab) => setState(() => _tab = tab),
          isWide: true,
        ),
      ),
      SizedBox(height: context.dimens.space16),
      switch (_tab) {
        _Tab.overview => TopikOverviewWidget(
          detail: detail,
          now: now,
          onStart: () => unawaited(_start(detail)),
          onOpenAttempt: widget.onOpenAttempt,
          onOpenSummary: widget.onOpenSummary,
        ),
        _Tab.history => TopikHistoryWidget(
          attempts: detail.attempts,
          onOpenAttempt: widget.onOpenAttempt,
          onOpenSummary: widget.onOpenSummary,
          onOpenReview: widget.onOpenReview,
          onDelete: (id) => unawaited(_delete(id)),
        ),
      },
    ];
  }

  TopikTestDetailController get _controller =>
      ref.read(topikTestDetailControllerProvider(widget.testId).notifier);

  /// BR-TOPIK-011: with an attempt in progress, Continue or Start new; Start
  /// new asks once more before the attempt in progress goes.
  Future<void> _start(TopikTestDetail detail) async {
    final inProgress = detail.inProgress;
    if (inProgress != null) {
      final choice = await showTopikContinueDialog(context);
      if (!mounted || choice == null) return;
      if (choice == TopikContinueChoice.continueAttempt) {
        widget.onOpenAttempt(inProgress.attempt.id);
        return;
      }
      if (!await showTopikStartNewDialog(context) || !mounted) return;
    }
    await _command(
      () => _controller.start(replaceInProgress: inProgress != null),
      onDone: (attempt) => widget.onOpenAttempt(attempt.id),
    );
  }

  Future<void> _delete(String attemptId) async {
    if (!await showTopikDeleteDialog(context) || !mounted) return;
    await _command(() => _controller.delete(attemptId), onDone: (_) {});
  }

  /// Runs a command; a refusal or a failure is a snackbar, and nothing is
  /// lost (UC-TOPIK-002 E3). A refusal for an attempt already gone says
  /// nothing: the row has already left.
  Future<void> _command<T>(
    Future<Outcome<T, TopikRejection>?> Function() command, {
    required void Function(T value) onDone,
  }) async {
    try {
      final outcome = await command();
      if (!mounted || outcome == null) return;
      switch (outcome) {
        case Ok(:final value):
          onDone(value);
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
      showMxSnackbar(context, message: context.l10n.failure(failure));
    }
  }
}
