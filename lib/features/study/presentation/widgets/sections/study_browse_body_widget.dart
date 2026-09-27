import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/controllers/study_session_controller.dart';
import 'package:memox/features/study/presentation/widgets/support/study_turn_hold_widget.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

/// Screen 16: both faces of the card at once, nothing graded (BR-MODE-005,
/// BR-MODE-006). A swipe left records the card and moves on; a swipe right
/// looks back at a card already shown in this stage without recording
/// anything (BR-STUDY-048). Screen readers get the same two moves as
/// actions, since the kit draws no visible control.
class StudyBrowseBodyWidget extends ConsumerStatefulWidget {
  const StudyBrowseBodyWidget({
    super.key,
    required this.sessionId,
    required this.currentItem,
  });

  final String sessionId;
  final StudyItem currentItem;

  @override
  ConsumerState<StudyBrowseBodyWidget> createState() =>
      _StudyBrowseBodyWidgetState();
}

class _StudyBrowseBodyWidgetState extends ConsumerState<StudyBrowseBodyWidget>
    with StudyTurnHoldMixin<StudyBrowseBodyWidget> {
  /// A drag this far, or this fast, counts as a swipe.
  static const double _swipeDistance = 64;
  static const double _swipeVelocity = 300;

  /// The cards shown in this stage, oldest first (BR-STUDY-048).
  final List<StudyItem> _shown = [];

  /// The card being looked back at, as an index into [_shown]; null on the
  /// current card.
  int? _lookBack;

  /// The last write hit a busy database: Retry stays on this card
  /// (UC-STUDY-001 E2).
  bool _isLocked = false;

  double _dragDx = 0;

  @override
  void initState() {
    super.initState();
    _shown.add(widget.currentItem);
  }

  @override
  void didUpdateWidget(StudyBrowseBodyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentItem.cardId == oldWidget.currentItem.cardId) return;
    _shown.add(widget.currentItem);
    _lookBack = null;
  }

  Future<void> _next() async {
    if (_lookBack != null) {
      final forward = _lookBack! + 1;
      setState(() => _lookBack = forward < _shown.length - 1 ? forward : null);
      return;
    }
    final item = widget.currentItem;
    try {
      final outcome = await ref
          .read(studySessionControllerProvider(widget.sessionId).notifier)
          .answer(cardId: item.cardId, answer: const AdvanceAnswer());
      if (!mounted || outcome == null) return;
      setState(() => _isLocked = false);
      // Browse has no outcome to show: the hold releases at once (spec D5).
      // A refusal (a stale session, a gone deck) ends the session, and the
      // screen leaves it (spec D7).
      if (outcome case Ok(:final value)) {
        holdTurn(item, value);
        continueTurn();
      }
    } on DatabaseLockedFailure {
      if (!mounted) return;
      setState(() => _isLocked = true);
    }
  }

  void _back() {
    final current = _lookBack ?? _shown.length - 1;
    if (current == 0) return;
    setState(() => _lookBack = current - 1);
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final dx = _dragDx;
    _dragDx = 0;
    if (dx <= -_swipeDistance || velocity <= -_swipeVelocity) {
      unawaited(_next());
      return;
    }
    if (dx >= _swipeDistance || velocity >= _swipeVelocity) _back();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lookBack = _lookBack;
    final item = lookBack == null
        ? shownItem(widget.currentItem)!
        : _shown[lookBack];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.grouped,
      children: [
        if (_isLocked)
          MxInlineBanner(
            tone: MxBannerTone.danger,
            title: l10n.studySessionLockedRetryTitle,
            message: l10n.studySessionLockedRetryBody,
            actions: [
              MxButton(
                label: l10n.commonRetry,
                size: MxButtonSize.compact,
                onPressed: () => unawaited(_next()),
              ),
            ],
          ),
        Expanded(
          child: Semantics(
            customSemanticsActions: {
              CustomSemanticsAction(label: l10n.studyBrowseNext): () =>
                  unawaited(_next()),
              CustomSemanticsAction(label: l10n.studyBrowseBack): _back,
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (details) =>
                  _dragDx += details.primaryDelta ?? 0,
              onHorizontalDragEnd: _onDragEnd,
              child: _BrowseCard(item: item),
            ),
          ),
        ),
      ],
    );
  }
}

/// The two-pane card: term over meaning, both always shown (BR-MODE-006).
class _BrowseCard extends StatelessWidget {
  const _BrowseCard({required this.item});

  final StudyItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    return MxCard(
      isFullBleed: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Face(
              label: l10n.studyBrowseTermLabel,
              children: [
                Text(
                  item.front,
                  textAlign: TextAlign.center,
                  style: styles.screenTitle,
                ),
                if (item.pronunciation case final pronunciation?)
                  Text(
                    pronunciation,
                    textAlign: TextAlign.center,
                    style: styles.rowDescription,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _Face(
              label: l10n.studyBrowseMeaningLabel,
              children: [
                Text(
                  item.back,
                  textAlign: TextAlign.center,
                  style: styles.dialogBody,
                ),
                if (item.example case final example?)
                  Text(
                    example,
                    textAlign: TextAlign.center,
                    style: styles.rowDescription,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.card),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.control,
      children: [
        Text(
          label.toUpperCase(),
          semanticsLabel: label,
          style: context.textStyles.overline,
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.control,
              children: children,
            ),
          ),
        ),
      ],
    ),
  );
}
