import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// Screen 22 loading in its own shape: the Today card, the Streak card and
/// the deck list, on one pulse (critique 2026-09-30 part 3d-2, E12). A
/// deck's level has no summary cards. Cards stand a gutter apart, as on
/// the loaded screen.
class ProgressSkeletonWidget extends StatelessWidget {
  const ProgressSkeletonWidget({
    super.key,
    required this.semanticLabel,
    this.hasSummary = true,
  });

  final String semanticLabel;
  final bool hasSummary;

  static const int _deckRows = 3;
  static const double _eyebrowWidth = 72;
  static const double _figureHeight = 28;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: semanticLabel,
    child: ExcludeSemantics(
      child: MxSkeletonPulse(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.gutter,
          children: [
            if (hasSummary)
              for (var i = 0; i < 2; i++)
                const MxCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.grouped,
                    children: [
                      MxSkeleton(width: _eyebrowWidth),
                      MxSkeleton(height: _figureHeight),
                    ],
                  ),
                ),
            MxCard(
              child: Column(
                children: [
                  for (var i = 0; i < _deckRows; i++) const MxSkeletonRow(),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
