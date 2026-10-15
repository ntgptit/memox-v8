import 'package:flutter/widgets.dart';

/// Screen 37's body (owner brief 2026-10-15): the group's material on top,
/// at most half the height and scrolling on its own, the question below
/// taking the rest. A question with no shared material has no top pane.
class TopikTwoPaneWidget extends StatelessWidget {
  const TopikTwoPaneWidget({
    super.key,
    required this.top,
    required this.bottom,
  });

  final Widget? top;
  final Widget bottom;

  /// The share of the body the top pane may take.
  static const double _topShare = 0.5;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (top case final material?)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: constraints.maxHeight * _topShare,
            ),
            child: material,
          ),
        Expanded(child: bottom),
      ],
    ),
  );
}
