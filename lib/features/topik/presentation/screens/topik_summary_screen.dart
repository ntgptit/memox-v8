import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_summary_model.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/presentation/providers/topik_summary_provider.dart';
import 'package:memox/features/topik/presentation/widgets/items/topik_answer_row_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_answer_filter_chips_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_question_bar_chart_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_summary_figures_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_summary_hero_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_type_stats_widget.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_action_pair.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_divided_column.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// Screen 38 (UC-TOPIK-004): one submitted attempt's result, from its
/// snapshot (BR-TOPIK-013, -019).
///
/// - The score and a donut of correct answers.
/// - The figures.
/// - The answers by status, filtered, as a time chart and rows.
/// - The result per question type, with the weakest marked (BR-TOPIK-024).
/// - The eye hides the right answers.
///
/// Where Review and Done lead, `app/` decides.
class TopikSummaryScreen extends ConsumerStatefulWidget {
  const TopikSummaryScreen({
    super.key,
    required this.attemptId,
    required this.onReview,
    required this.onDone,
  });

  final String attemptId;

  /// Opens Review (39), at [questionNo] when one was picked.
  final void Function(int? questionNo) onReview;

  /// Leaves: Done, Back, and the way out of attemptMissing.
  final VoidCallback onDone;

  @override
  ConsumerState<TopikSummaryScreen> createState() => _TopikSummaryScreenState();
}

class _TopikSummaryScreenState extends ConsumerState<TopikSummaryScreen> {
  var _filter = TopikAnswerFilter.all;

  /// The eye: the right answers are hidden (UC-TOPIK-004 step 6).
  var _isRightHidden = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = topikSummaryProvider(widget.attemptId);
    return switch (ref.watch(provider)) {
      AsyncError(:final error, :final isLoading) => _plain(
        MxErrorState(
          title: l10n.topikSummaryErrorTitle,
          body: error is Failure ? l10n.failure(error) : l10n.topikErrorBody,
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.invalidate(provider),
          isRetrying: isLoading,
        ),
      ),
      // Gone (deleted elsewhere, the account changed) or not submitted.
      AsyncData(value: null) => _plain(
        MxEmptyState(
          icon: AppIcons.searchOff,
          title: l10n.topikAttemptMissing,
          tone: MxEmptyStateTone.neutral,
          actionLabel: l10n.topikBackToTest,
          onAction: widget.onDone,
        ),
      ),
      AsyncValue(:final value?) => _loaded(value),
      _ => _plain(
        MxCard(
          isFullBleed: true,
          child: MxSkeletonList(semanticLabel: l10n.topikLoadingSummary),
        ),
      ),
    };
  }

  MxAppBar _appBar({List<Widget> actions = const []}) {
    final l10n = context.l10n;
    return MxAppBar(
      title: l10n.topikSummary,
      leading: MxIconButton(
        icon: AppIcons.back,
        semanticLabel: l10n.commonBack,
        onPressed: widget.onDone,
      ),
      actions: actions,
    );
  }

  /// A state with nothing to show: the bar and [body], no footer.
  Widget _plain(Widget body) => MxAppShell(
    appBar: _appBar(),
    body: MxScreenScroll(children: [body]),
  );

  Widget _loaded(TopikSummaryView view) {
    final l10n = context.l10n;
    final dimens = context.dimens;
    final summary = view.summary;
    final shown = summary.answersFor(_filter);
    return MxAppShell(
      appBar: _appBar(
        actions: [
          MxIconButton(
            icon: AppIcons.preview,
            semanticLabel: _isRightHidden
                ? l10n.topikShowAnswers
                : l10n.topikHideAnswers,
            onPressed: () => setState(() => _isRightHidden = !_isRightHidden),
          ),
        ],
      ),
      body: MxScreenScroll(
        children: [
          TopikSummaryHeroWidget(attempt: view.attempt, summary: summary),
          SizedBox(height: dimens.space24),
          TopikSummaryFiguresWidget(summary: summary),
          SizedBox(height: dimens.space24),
          // The weakest type says what to study next, so it comes before the
          // long list of answers (audit 2026-10-19, G3).
          if (summary.typeStats.isNotEmpty) ...[
            TopikTypeStatsWidget(summary: summary),
            SizedBox(height: dimens.space24),
          ],
          MxListSectionHeader(label: l10n.topikAnswers),
          TopikAnswerFilterChipsWidget(
            summary: summary,
            selected: _filter,
            onSelected: (filter) => setState(() => _filter = filter),
          ),
          SizedBox(height: dimens.space16),
          ..._answers(shown),
        ],
      ),
      footer: MxFooterBar(
        child: MxActionPair(
          leading: MxButton(
            label: l10n.topikDone,
            tone: MxButtonTone.outline,
            isBlock: true,
            isSingleLine: true,
            onPressed: widget.onDone,
          ),
          trailing: MxButton(
            label: l10n.topikReviewAnswers,
            isBlock: true,
            isSingleLine: true,
            onPressed: () => widget.onReview(null),
          ),
        ),
      ),
    );
  }

  /// The filtered answers as the time chart and their rows, or what an empty
  /// filter says (UC-TOPIK-004 A1).
  List<Widget> _answers(List<TopikAttemptAnswer> shown) {
    final l10n = context.l10n;
    if (shown.isEmpty) {
      return [
        MxEmptyState(
          icon: AppIcons.check,
          title: l10n.topikFilterEmpty(_filter),
          tone: MxEmptyStateTone.neutral,
          isCompact: true,
        ),
      ];
    }
    return [
      MxListSectionHeader(label: l10n.topikTimePerQuestion),
      TopikQuestionBarChartWidget(answers: shown, onOpen: widget.onReview),
      SizedBox(height: context.dimens.space16),
      MxCard(
        isFullBleed: true,
        child: MxDividedColumn(
          children: [
            for (final answer in shown)
              TopikAnswerRowWidget(
                answer: answer,
                isRightHidden: _isRightHidden,
                onOpen: () => widget.onReview(answer.questionNo),
              ),
          ],
        ),
      ),
    ];
  }
}
