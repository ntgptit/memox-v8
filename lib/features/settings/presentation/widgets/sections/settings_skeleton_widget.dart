import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// A settings page loading as its sections: cards of rows on one pulse
/// (critique 2026-09-30 part 3d-2, E12).
class SettingsSkeletonWidget extends StatelessWidget {
  const SettingsSkeletonWidget({
    super.key,
    required this.semanticLabel,
    this.rowsPerSection = hubRows,
  });

  final String semanticLabel;

  /// One entry per section card, the rows it holds.
  final List<int> rowsPerSection;

  /// The hub's shape: Account & sync, Study, App, Reset (spec §5.1).
  static const List<int> hubRows = [2, 1, 3, 1];

  /// The hub's shape in a build without an account: Study, App, Reset.
  static const List<int> hubRowsWithoutAccount = [1, 3, 1];

  /// Screen 23a's shape: Session, Speech (spec §5.2).
  static const List<int> studyRows = [2, 2];
  static const double _headerWidth = 96;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: semanticLabel,
    child: ExcludeSemantics(
      child: MxSkeletonPulse(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final rows in rowsPerSection) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.control),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: MxSkeleton(width: _headerWidth),
                ),
              ),
              MxCard(
                child: Column(
                  children: [
                    for (var i = 0; i < rows; i++) const MxSkeletonRow(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
