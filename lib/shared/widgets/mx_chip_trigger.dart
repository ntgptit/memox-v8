import 'package:flutter/material.dart';
import 'package:memox/shared/widgets/primitives/mx_chip_shell.dart';

/// A ghost chip that opens a menu or a sheet ("Manual ⌄"); tinted
/// `primary-container` while what it opened is in force ("Manual · Due only").
class MxChipTrigger extends StatelessWidget {
  const MxChipTrigger({
    required this.label,
    required this.onOpen,
    this.isActive = false,
    super.key,
  });

  final String label;
  final VoidCallback onOpen;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: label,
      onTap: onOpen,
      child: MxChipShell(
        label: label,
        isSelected: isActive,
        isGhost: true,
        trailing: Icons.expand_more,
        onTap: onOpen,
      ),
    );
  }
}
