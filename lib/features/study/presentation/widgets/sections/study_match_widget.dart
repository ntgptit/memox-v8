import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:memox/core/theme/app_decorations.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study/presentation/widgets/support/session_footer_hint_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_choice_widget.dart';
import 'package:memox/l10n/l10n_context.dart';

/// Screen 17, Match: the board's terms on the left and its meanings on the
/// right, in their stored order (BR-STUDY-049). Tap a term, then a meaning;
/// the pair is answered on that term (BR-STUDY-062). A right pair shows as
/// matched from the stream; a wrong one flashes in the wrong tone for 600 ms
/// once its write commits, with the hint saying it comes back, then both go
/// back to idle (BR-STUDY-063, BR-STUDY-070; FE-A6 P3 M1, M2, C7). Each
/// outcome is announced, and TalkBack reads the terms before the meanings
/// (C3, C8).
class StudyMatchWidget extends StatefulWidget {
  const StudyMatchWidget({
    super.key,
    required this.board,
    required this.result,
    required this.heldPair,
    required this.isBusy,
    required this.onPair,
    required this.onSettled,
  });

  final MatchBoard board;

  /// The committed outcome of [heldPair]; null before and after its hold.
  final TurnResult? result;

  /// The term and meaning of the turn on hold.
  final (String, String)? heldPair;
  final bool isBusy;
  final void Function(String termCardId, String meaningCardId) onPair;

  /// The hold is over: the stream's board shows again.
  final VoidCallback onSettled;

  @override
  State<StudyMatchWidget> createState() => _StudyMatchWidgetState();
}

class _StudyMatchWidgetState extends State<StudyMatchWidget> {
  static const Duration _flash = Duration(milliseconds: 600);

  /// The reading order's step between the two columns (C8).
  static const double _columnOrder = 100;

  String? _selectedTerm;
  Timer? _timer;

  bool get _isWrongPair => widget.result?.isCorrect == false;

  bool get _canTap => !widget.isBusy && widget.result == null;

  @override
  void didUpdateWidget(StudyMatchWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result == null && widget.result != null) _onAnswered();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onAnswered() {
    final l10n = context.l10n;
    final isRight = widget.result?.isCorrect ?? false;
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        isRight ? l10n.studyMatchAnnounceRight : l10n.studyMatchHintWrong,
        Directionality.of(context),
      ),
    );
    if (isRight) {
      // After this frame: the hold is a provider, not to be written mid-build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onSettled();
      });
      return;
    }
    _timer = Timer(_flash, widget.onSettled);
  }

  void _tapTerm(MatchTile term) {
    if (!_canTap || term.isMatched) return;
    setState(() => _selectedTerm = term.cardId);
  }

  void _tapMeaning(MatchTile meaning) {
    final term = _selectedTerm;
    if (!_canTap || meaning.isMatched || term == null) return;
    setState(() => _selectedTerm = null);
    widget.onPair(term, meaning.cardId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final board = widget.board;
    final rows = max(board.terms.length, board.meanings.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gutter,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpacing.control,
                    children: [
                      for (var row = 0; row < rows; row++)
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: AppSpacing.control,
                            children: [
                              Expanded(child: _term(context, board, row)),
                              Expanded(child: _meaning(context, board, row)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SessionFooterHintWidget(
          icon: AppIcons.check,
          text: _isWrongPair ? l10n.studyMatchHintWrong : l10n.studyMatchHint,
        ),
      ],
    );
  }

  Widget _term(BuildContext context, MatchBoard board, int row) {
    if (row >= board.terms.length) return const SizedBox.shrink();
    final term = board.terms[row];
    return _Tile(
      tile: term,
      label: context.l10n.studyMatchTerm(term.text),
      tone: _toneOf(term, isSelected: term.cardId == _selectedTerm),
      order: row.toDouble(),
      isTerm: true,
      onTap: () => _tapTerm(term),
    );
  }

  Widget _meaning(BuildContext context, MatchBoard board, int row) {
    if (row >= board.meanings.length) return const SizedBox.shrink();
    final meaning = board.meanings[row];
    return _Tile(
      tile: meaning,
      label: context.l10n.studyMatchMeaning(meaning.text),
      tone: _toneOf(meaning, isSelected: false),
      order: _columnOrder + row,
      isTerm: false,
      onTap: () => _tapMeaning(meaning),
    );
  }

  StudyChoiceTone _toneOf(MatchTile tile, {required bool isSelected}) {
    if (tile.isMatched) return StudyChoiceTone.right;
    final pair = widget.heldPair;
    final isInHeldPair =
        pair != null && (pair.$1 == tile.cardId || pair.$2 == tile.cardId);
    if (_isWrongPair && isInHeldPair) return StudyChoiceTone.wrong;
    if (isSelected) return StudyChoiceTone.selected;
    return StudyChoiceTone.idle;
  }
}

/// A board tile: a term in the term role, a meaning in the meaning role, a
/// matched one with its check (kit MatchScreen).
class _Tile extends StatelessWidget {
  const _Tile({
    required this.tile,
    required this.label,
    required this.tone,
    required this.order,
    required this.isTerm,
    required this.onTap,
  });

  final MatchTile tile;
  final String label;
  final StudyChoiceTone tone;
  final double order;
  final bool isTerm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    return StudyChoiceWidget(
      tone: tone,
      isSelected: tone == StudyChoiceTone.selected,
      semanticsLabel: switch (tone) {
        StudyChoiceTone.right => l10n.studyMatchTileMatched(label),
        StudyChoiceTone.selected => l10n.studyMatchTileSelected(label),
        StudyChoiceTone.idle || StudyChoiceTone.wrong => label,
      },
      sortKey: OrdinalSortKey(order),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.grouped,
        vertical: AppSpacing.gutter,
      ),
      onTap: tile.isMatched ? null : onTap,
      builder: (ink) => Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.micro,
          children: [
            if (tile.isMatched)
              IconTheme(
                data: IconThemeData(color: ink, size: AppIconSize.inline),
                child: const Icon(AppIcons.check),
              ),
            Flexible(
              child: Text(
                tile.text,
                textAlign: TextAlign.center,
                style: isTerm
                    ? styles.matchTerm(ink)
                    : styles.matchMeaning(ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
