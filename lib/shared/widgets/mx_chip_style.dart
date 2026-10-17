import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:memox/shared/widgets/mx_tap_target.dart';

/// The chip the filter chip, the chip trigger and the card editor's
/// removable tag share: ForUI's extra-small touch button (32), drawn inside
/// a 48 touch target. An outline chip at rest; [isGhost] drops the fill and
/// the edge (MxChipTrigger).
FButtonStyle mxChipStyle(BuildContext context, {bool isGhost = false}) =>
    mxTargetStyle(context, _chip(context, isGhost: isGhost));

/// The resting box of a chip that is not a button (the tag editor's
/// removable chip).
Decoration mxChipDecoration(BuildContext context) =>
    _chip(context).decoration.base;

/// A chip's label style.
TextStyle mxChipLabelStyle(BuildContext context) =>
    _chip(context).contentStyle.textStyle.base;

/// A chip's glyph colour and size.
IconThemeData mxChipIconTheme(BuildContext context) =>
    _chip(context).contentStyle.iconStyle.base;

/// The space between a chip's edge and its label.
EdgeInsetsGeometry mxChipPadding(BuildContext context) =>
    _chip(context).contentStyle.padding;

/// The gap between a chip's glyph and its label.
double mxChipGap(BuildContext context) => _chip(context).contentStyle.spacing;

FButtonStyle _chip(BuildContext context, {bool isGhost = false}) {
  final buttons = FTheme.of(context).buttonStyles;
  return (isGhost ? buttons.ghost : buttons.outline).resolve({
    context.platformVariant,
    FButtonSizeVariant.xs,
  });
}
