import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/widgets/support/session_footer_hint_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_card.dart';

/// Screen 16, Browse (handoff 16): both faces of the card at once, nothing
/// graded (BR-MODE-005, BR-MODE-006). A left swipe goes on; a right swipe
/// looks back at a card of the round already shown, which writes nothing
/// and moves no counter (BR-STUDY-048). The session shell draws the top
/// bar and the context line around it.
class StudyBrowseWidget extends StatefulWidget {
  const StudyBrowseWidget({
    super.key,
    required this.view,
    required this.item,
    required this.isBusy,
    required this.onAdvance,
  });

  final StudySessionView view;

  /// The live card, the one the session serves.
  final StudyItem item;

  /// A write is running: going on is dropped (BR-STUDY-004).
  final bool isBusy;

  /// Answers the live card: the session moves on.
  final VoidCallback onAdvance;

  @override
  State<StudyBrowseWidget> createState() => _StudyBrowseWidgetState();
}

class _StudyBrowseWidgetState extends State<StudyBrowseWidget> {
  static const double _swipeDistance = 70;
  static const double _swipeVelocity = 600;

  /// How many cards back from the live one is shown; 0 is the live card.
  int _lookBack = 0;
  double _dragDx = 0;

  bool get _canLookBack => _lookBack < widget.view.trail.length;

  _Face get _shown {
    if (_lookBack == 0) return _Face.ofItem(widget.item);
    final trail = widget.view.trail;
    return _Face.ofTrail(trail[trail.length - _lookBack]);
  }

  @override
  void didUpdateWidget(StudyBrowseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new live card: the look back starts over from it.
    if (oldWidget.item.cardId != widget.item.cardId) _lookBack = 0;
  }

  void _forward() {
    if (_lookBack > 0) {
      setState(() => _lookBack--);
      return;
    }
    if (widget.isBusy) return;
    widget.onAdvance();
  }

  void _back() {
    // D20: on the round's first card a right swipe does nothing.
    if (!_canLookBack) return;
    setState(() => _lookBack++);
  }

  void _onDragUpdate(DragUpdateDetails details) =>
      setState(() => _dragDx += details.delta.dx);

  void _onDragEnd(DragEndDetails details) {
    final dx = _dragDx;
    final velocity = details.primaryVelocity ?? 0;
    setState(() => _dragDx = 0);
    if (dx < -_swipeDistance || velocity < -_swipeVelocity) {
      _forward();
      return;
    }
    if (dx > _swipeDistance || velocity > _swipeVelocity) _back();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isStill = MediaQuery.disableAnimationsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Semantics(
              container: true,
              customSemanticsActions: {
                CustomSemanticsAction(label: l10n.studyBrowseNext): _forward,
                if (_canLookBack)
                  CustomSemanticsAction(label: l10n.studyBrowsePrevious): _back,
              },
              child: GestureDetector(
                onHorizontalDragUpdate: _onDragUpdate,
                onHorizontalDragEnd: _onDragEnd,
                child: Transform.translate(
                  // The card follows the finger, unless motion is reduced.
                  offset: Offset(isStill ? 0 : _dragDx, 0),
                  child: _Card(face: _shown, isLookingBack: _lookBack > 0),
                ),
              ),
            ),
          ),
        ),
        SessionFooterHintWidget(
          icon: AppIcons.swipe,
          text: l10n.studyBrowseHint,
        ),
      ],
    );
  }
}

/// What the card face draws, from the live card or one of the trail.
final class _Face {
  const _Face({
    required this.front,
    required this.back,
    required this.pronunciation,
    required this.example,
  });

  factory _Face.ofItem(StudyItem item) => _Face(
    front: item.front,
    back: item.back,
    pronunciation: item.pronunciation,
    example: item.example,
  );

  factory _Face.ofTrail(TrailCard card) => _Face(
    front: card.front,
    back: card.back,
    pronunciation: card.pronunciation,
    example: card.example,
  );

  final String front;
  final String back;
  final String? pronunciation;
  final String? example;
}

/// The split card: the term half, a hairline, the meaning half (kit).
class _Card extends StatelessWidget {
  const _Card({required this.face, required this.isLookingBack});

  final _Face face;
  final bool isLookingBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    return MxCard(
      isFullBleed: true,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Half(
                  label: l10n.studyBrowseTerm,
                  main: Text(
                    face.front,
                    textAlign: TextAlign.center,
                    style: styles.studyTerm,
                  ),
                  detail: face.pronunciation,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.card,
                ),
                child: SizedBox(
                  height: AppStroke.hairline,
                  child: ColoredBox(color: context.derivedColors.ghostBorder),
                ),
              ),
              Expanded(
                child: _Half(
                  label: l10n.studyBrowseMeaning,
                  main: Text(
                    face.back,
                    textAlign: TextAlign.center,
                    style: styles.studyMeaning,
                  ),
                  detail: face.example,
                ),
              ),
            ],
          ),
          if (isLookingBack)
            Positioned(
              top: AppSpacing.grouped,
              right: AppSpacing.grouped,
              child: MxBadge(
                label: l10n.studyBrowseLookingBack,
                tone: MxBadgeTone.neutral,
              ),
            ),
        ],
      ),
    );
  }
}

/// One half of the card: its label in the corner, its face centred, and a
/// detail line under it. The face wraps and never ellipsizes (FE-A6 D19).
class _Half extends StatelessWidget {
  const _Half({required this.label, required this.main, required this.detail});

  final String label;
  final Widget main;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final detail = this.detail;
    return Stack(
      children: [
        Positioned(
          top: AppSpacing.gutter,
          left: AppSpacing.card,
          child: Text(
            label.toUpperCase(),
            semanticsLabel: label,
            style: styles.overline,
          ),
        ),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.major,
              AppSpacing.gutter,
              AppSpacing.gutter,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.control,
              children: [
                main,
                if (detail != null)
                  Text(
                    detail,
                    textAlign: TextAlign.center,
                    style: styles.studyDetail,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
