import 'package:flutter/material.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/core/theme/theme_context.dart';

/// Screen 23 loading as its sections: three cards of rows, on one pulse
/// (critique 2026-09-30 part 3d-2, E12).
class SettingsSkeletonWidget extends StatelessWidget {
  const SettingsSkeletonWidget({super.key, required this.semanticLabel});

  final String semanticLabel;

  static const List<int> _rowsPerSection = [2, 3, 2];
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
            for (final rows in _rowsPerSection) ...[
              Padding(
                padding: EdgeInsets.symmetric(vertical: context.dimens.space8),
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
