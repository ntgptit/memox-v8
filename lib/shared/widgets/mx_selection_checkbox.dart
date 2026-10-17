import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// The selection-mode box on a card row: ForUI's [FCheckbox], painted only
/// (ruling I6): the caller's row is the tap target and carries the checked
/// semantics.
class MxSelectionCheckbox extends StatelessWidget {
  const MxSelectionCheckbox({super.key, required this.isChecked});

  final bool isChecked;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: FCheckbox(value: isChecked, onChange: (_) {}),
    ),
  );
}
