import 'package:flutter/material.dart';
import 'package:memox/shared/widgets/primitives/mx_chip_shell.dart';

/// A filter that is on or off: 28 pill, `primary` under `on-primary` when
/// selected (DESIGN.md, Inputs). Announced as a selected or unselected button.
class MxFilterChip extends StatelessWidget {
  const MxFilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      excludeSemantics: true,
      label: label,
      onTap: () => onSelected(!isSelected),
      child: MxChipShell(
        label: label,
        isSelected: isSelected,
        isGhost: false,
        onTap: () => onSelected(!isSelected),
      ),
    );
  }
}
