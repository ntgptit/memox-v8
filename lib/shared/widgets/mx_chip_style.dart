import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:memox/shared/widgets/mx_tap_target.dart';

/// The chip the filter chip and the chip trigger (the card editor's
/// removable tag among them) share: ForUI's extra-small touch button (32), drawn inside
/// a 48 touch target. An outline chip at rest; [isGhost] drops the fill and
/// the edge (MxChipTrigger).
FButtonStyle mxChipStyle(BuildContext context, {bool isGhost = false}) =>
    mxTargetStyle(context, _chip(context, isGhost: isGhost));

FButtonStyle _chip(BuildContext context, {bool isGhost = false}) {
  final buttons = FTheme.of(context).buttonStyles;
  return (isGhost ? buttons.ghost : buttons.outline).resolve({
    context.platformVariant,
    FButtonSizeVariant.xs,
  });
}
