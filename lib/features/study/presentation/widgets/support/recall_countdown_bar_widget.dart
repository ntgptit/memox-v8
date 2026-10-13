import 'package:flutter/material.dart';
import 'package:memox/core/theme/mastery_ramp.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study_mode/domain/models/recall_mode.dart';
import 'package:memox/l10n/l10n_context.dart';

/// Screen 19's turn clock: its caption, the seconds left of the turn, and a
/// thin track that drains. It measures one turn, not the session (the top
/// bar does that). A neutral signal until the time is up, then warning
/// (FE-A6 P4 V2). One semantics node, read when reached, never announced per
/// tick (V3, V5); under Remove animations the fill steps by whole seconds
/// (V9).
class RecallCountdownBarWidget extends StatelessWidget {
  const RecallCountdownBarWidget({
    super.key,
    required this.caption,
    required this.remainingMs,
    required this.isTimedOut,
  });

  final String caption;

  /// The time left of the turn, 0 to [recallTurnMs].
  final int remainingMs;
  final bool isTimedOut;

  /// The app's thin track (MxLinearProgress, MxStudyTopBar), M3's 4dp
  /// (ruling M3-F2).
  static const double _trackHeight = 4;
  static const int _msPerSecond = 1000;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final left = remainingMs.clamp(0, recallTurnMs);
    final seconds = (left / _msPerSecond).ceil();
    final fraction = MediaQuery.disableAnimationsOf(context)
        ? seconds * _msPerSecond / recallTurnMs
        : left / recallTurnMs;
    final ink = isTimedOut ? context.mxColors.warning : colors.onSurfaceVariant;
    final fill = isTimedOut
        ? context.mxColors.warningContainer
        : colors.onSurfaceVariant;
    return Semantics(
      container: true,
      label: caption,
      value: l10n.studyRecallClockValue(seconds),
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.dimens.space16,
          0,
          context.dimens.space16,
          context.dimens.space12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: context.dimens.space4,
          children: [
            Row(
              spacing: context.dimens.space8,
              children: [
                Expanded(
                  child: Text(
                    caption,
                    style: context.texts.labelSmall?.copyWith(color: ink),
                  ),
                ),
                Text(
                  l10n.studyRecallClock(seconds, recallTurnMs ~/ _msPerSecond),
                  style: context.texts.labelSmall?.copyWith(color: ink),
                ),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(_trackHeight / 2),
              child: SizedBox(
                height: _trackHeight,
                child: ColoredBox(
                  color: MasteryRamp.track(colors),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FractionallySizedBox(
                      widthFactor: fraction,
                      heightFactor: 1,
                      child: ColoredBox(color: fill),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
