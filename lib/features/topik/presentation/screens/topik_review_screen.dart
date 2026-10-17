import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_summary_model.dart';
import 'package:memox/features/topik/domain/models/topik_audio_model.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/presentation/providers/topik_review_provider.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_answer_filter_chips_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_group_pane_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_review_question_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_two_pane_widget.dart';
import 'package:memox/core/theme/theme_rules.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_action_pair.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// Screen 39 (UC-TOPIK-005): each question of a submitted attempt with its
/// right answer and supporting content, read-only (BR-TOPIK-010).
///
/// - Filtered as on 38; Previous and Next walk the filter.
/// - The group's material and audio as on 37, with the script open.
/// - The content's own version decides the banner, and its absence
///   contentMissing (BR-TOPIK-019).
class TopikReviewScreen extends ConsumerStatefulWidget {
  const TopikReviewScreen({
    super.key,
    required this.attemptId,
    this.initialQuestionNo,
    required this.onBack,
    required this.onBackToSummary,
  });

  final String attemptId;

  /// The question to open (`?q=`); null or unknown opens the first.
  final int? initialQuestionNo;

  /// Leaves: Back, Done, and the way out of attemptMissing.
  final VoidCallback onBack;

  /// The test is gone: the summary still works.
  final VoidCallback onBackToSummary;

  @override
  ConsumerState<TopikReviewScreen> createState() => _TopikReviewScreenState();
}

class _TopikReviewScreenState extends ConsumerState<TopikReviewScreen> {
  var _filter = TopikAnswerFilter.all;

  /// The question shown; null until the person moves (then the initial one).
  int? _no;

  var _isCollapsed = false;

  /// The person's own hide or show of a group's script; open by default.
  final _scriptChoice = <String, bool>{};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = topikReviewProvider(widget.attemptId);
    return switch (ref.watch(provider)) {
      AsyncError(:final error, :final isLoading) => _plain(
        MxErrorState(
          title: l10n.topikReviewErrorTitle,
          body: error is Failure ? l10n.failure(error) : l10n.topikErrorBody,
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.invalidate(provider),
          isRetrying: isLoading,
        ),
      ),
      // Gone, the account changed, or not submitted: nothing to review.
      AsyncData(value: null) => _missing(),
      AsyncValue(:final value?) when !value.detail.attempt.isCompleted =>
        _missing(),
      AsyncValue(:final value?) when value.isUnavailable => _plain(
        MxEmptyState(
          icon: AppIcons.searchOff,
          title: l10n.topikReviewUnavailableTitle,
          body: l10n.topikReviewUnavailableBody,
          tone: MxEmptyStateTone.neutral,
          actionLabel: l10n.topikBackToSummary,
          onAction: widget.onBackToSummary,
        ),
      ),
      AsyncValue(:final value?) => _loaded(value),
      _ => _plain(
        MxCard(
          isFullBleed: true,
          child: MxSkeletonList(semanticLabel: l10n.topikLoadingReview),
        ),
      ),
    };
  }

  Widget _missing() {
    final l10n = context.l10n;
    return _plain(
      MxEmptyState(
        icon: AppIcons.searchOff,
        title: l10n.topikAttemptMissing,
        tone: MxEmptyStateTone.neutral,
        actionLabel: l10n.topikBackToTest,
        onAction: widget.onBack,
      ),
    );
  }

  MxAppBar _appBar(String title) => MxAppBar(
    title: title,
    leading: MxIconButton(
      icon: AppIcons.back,
      semanticLabel: context.l10n.commonBack,
      onPressed: widget.onBack,
    ),
  );

  /// A state with nothing to review: the bar and [body], no footer.
  Widget _plain(Widget body) => MxAppShell(
    appBar: _appBar(context.l10n.topikReview),
    body: MxScreenScroll(children: [body]),
  );

  Widget _loaded(TopikReviewView view) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    final test = view.test!;
    final summary = topikAttemptSummaryOf(view.detail);
    final numbers = [
      for (final answer in summary.answersFor(_filter)) answer.questionNo,
    ];
    final wanted = _no ?? widget.initialQuestionNo;
    final current = numbers.contains(wanted) ? wanted! : numbers.first;
    final index = numbers.indexOf(current);
    final question = test.questions.firstWhere((q) => q.no == current);
    final answer = summary.answers.firstWhere((a) => a.questionNo == current);
    final group = test.groups.firstWhere((g) => g.groupId == question.groupId);
    final isScriptShown = _scriptChoice[group.groupId] ?? true;
    final isLast = index == numbers.length - 1;
    return MxAppShell(
      // The same column as the attempt (The Column Rule).
      isSession: true,
      appBar: _appBar(l10n.topikReviewTitle(current, test.questions.last.no)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.screenMargin,
              vertical: dimens.space8,
            ),
            child: TopikAnswerFilterChipsWidget(
              summary: summary,
              selected: _filter,
              isEmptyDisabled: true,
              onSelected: (filter) {
                // The chip already picked keeps the place; another opens
                // its first question (UC-TOPIK-005 A3).
                if (filter == _filter) return;
                setState(() {
                  _filter = filter;
                  _no = summary.answersFor(filter).first.questionNo;
                });
              },
            ),
          ),
          Expanded(
            child: TopikTwoPaneWidget(
              top: TopikGroupPaneWidget(
                key: ValueKey(group.groupId),
                group: group,
                audio: topikGroupClip(test, group),
                isCollapsed: _isCollapsed,
                isScriptShown: isScriptShown,
                onToggleCollapsed: () =>
                    setState(() => _isCollapsed = !_isCollapsed),
                onToggleScript: () => setState(
                  () => _scriptChoice[group.groupId] = !isScriptShown,
                ),
              ),
              bottom: TopikReviewQuestionWidget(
                key: ValueKey(current),
                question: question,
                answer: answer,
                isContentUpdated: view.isContentChanged,
              ),
            ),
          ),
        ],
      ),
      footer: MxFooterBar(
        child: MxActionPair(
          leading: MxButton(
            label: l10n.topikPrevious,
            tone: MxButtonTone.outline,
            isBlock: true,
            isSingleLine: true,
            onPressed: index == 0
                ? null
                : () => setState(() => _no = numbers[index - 1]),
          ),
          trailing: MxButton(
            label: isLast ? l10n.topikDone : l10n.topikNext,
            isBlock: true,
            isSingleLine: true,
            onPressed: isLast
                ? widget.onBack
                : () => setState(() => _no = numbers[index + 1]),
          ),
        ),
      ),
    );
  }
}
