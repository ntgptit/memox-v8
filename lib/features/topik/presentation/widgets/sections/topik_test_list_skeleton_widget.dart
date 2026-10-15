import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// Screen 35 loading in its own shape (detail file 35): the header card,
/// then the rows, on one pulse; heard once as [semanticLabel].
class TopikTestListSkeletonWidget extends StatelessWidget {
  const TopikTestListSkeletonWidget({super.key, required this.semanticLabel});

  final String semanticLabel;

  static const int _rows = 3;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: semanticLabel,
    child: ExcludeSemantics(
      child: MxSkeletonPulse(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: context.dimens.space16,
          children: [
            const MxCard(isFullBleed: true, child: MxSkeletonRow()),
            MxCard(
              isFullBleed: true,
              child: Column(
                children: [
                  for (var i = 0; i < _rows; i++) const MxSkeletonRow(),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
