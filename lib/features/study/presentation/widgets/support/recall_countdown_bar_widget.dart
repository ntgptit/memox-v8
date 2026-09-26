import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
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

  static const double _trackHeight = 6;
  static const int _msPerSecond = 1000;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final styles = context.textStyles;
    final left = remainingMs.clamp(0, recallTurnMs);
    final seconds = (left / _msPerSecond).ceil();
    final fraction = MediaQuery.disableAnimationsOf(context)
        ? seconds * _msPerSecond / recallTurnMs
        : left / recallTurnMs;
    final ink = isTimedOut
        ? context.derivedColors.warningInk
        : colors.onSurfaceVariant;
    final fill = isTimedOut
        ? context.semanticColors.warning
        : colors.onSurfaceVariant;
    return Semantics(
      container: true,
      label: caption,
      value: l10n.studyRecallClockValue(seconds),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          0,
          AppSpacing.gutter,
          AppSpacing.grouped,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.micro,
          children: [
            Row(
              spacing: AppSpacing.control,
              children: [
                Expanded(child: Text(caption, style: styles.statusLabel(ink))),
                Text(
                  l10n.studyRecallClock(seconds, recallTurnMs ~/ _msPerSecond),
                  style: styles.statusLabel(ink),
                ),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
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
