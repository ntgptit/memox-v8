import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';

/// A tag on the card being edited (kit `RemovableTagChip`): the shared
/// outline chip at rest, its label and a ✕ after it. Its whole 48 area
/// removes the tag (ruling P4a-L8); the read-only `MxTagChip` is a different
/// control.
class CardRemovableTagChipWidget extends StatelessWidget {
  const CardRemovableTagChipWidget({
    super.key,
    required this.name,
    required this.onRemove,
  });

  final String name;
  final VoidCallback onRemove;

  // The chip's label names it as its own TalkBack node with its tap, so the
  // tag editor's row never merges the chips (SW-REV-005).
  @override
  Widget build(BuildContext context) => MxChipTrigger(
    label: name,
    onPressed: onRemove,
    icon: AppIcons.close,
    semanticLabel: context.l10n.cardTagRemove(name),
    isGhost: false,
  );
}
