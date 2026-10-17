import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// [label] as ForUI's tooltip over [child], shown on a long press, a hover
/// or focus.
///
/// ForUI's tooltip adds its long press to a semantics node of its own, around
/// the labelled control, which screen readers would announce as an unlabelled
/// action. Merging folds that action into the control's labelled node, so the
/// pair reads as one control.
class MxTooltip extends StatelessWidget {
  const MxTooltip({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: FTooltip(tipBuilder: (_, _) => Text(label), child: child),
  );
}
