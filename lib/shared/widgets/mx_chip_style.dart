import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_component_themes.dart';

/// What an Mx chip paints: the fill (null for none), the label and the edge.
typedef MxChipPaint = ({Color? fill, Color foreground, BorderSide edge});

/// The paint of a chip, read from the app's [chipTheme] (`chip`, which a widget
/// takes once from `Theme.of(context).chipTheme`). A ghost chip (MxChipTrigger)
/// keeps the theme's label and drops its fill and edge; it is never selected.
MxChipPaint chipPaint(
  ChipThemeData chip, {
  bool isSelected = false,
  bool isGhost = false,
}) {
  final states = {if (isSelected) WidgetState.selected};
  final label = isSelected ? chip.secondaryLabelStyle : chip.labelStyle;
  final foreground = label!.color!;
  if (isGhost) {
    return (fill: null, foreground: foreground, edge: BorderSide.none);
  }
  final side = chip.side;
  return (
    fill: chip.color?.resolve(states),
    foreground: foreground,
    edge: side is WidgetStateBorderSide
        ? side.resolve(states) ?? BorderSide.none
        : side ?? BorderSide.none,
  );
}

/// The painted box of a chip that is not a button (the tag editor's removable
/// chip): the `chip` theme's corner and resting edge around [fill].
ShapeDecoration chipDecoration(ChipThemeData chip, {Color? fill}) =>
    ShapeDecoration(
      color: fill,
      shape: chip.shape!.copyWith(side: chipPaint(chip).edge),
    );

/// Distance from the chip's edge to its first item: the leading glyph, else
/// the label (the chip's padding plus the label's).
double chipStartInset(ChipThemeData chip, {required bool hasLeading}) =>
    _inset(chip, hasGlyph: hasLeading);

/// Distance from the chip's last item to its edge: the trailing glyph, else
/// the label.
double chipEndInset(ChipThemeData chip, {required bool hasTrailing}) =>
    _inset(chip, hasGlyph: hasTrailing);

double _inset(ChipThemeData chip, {required bool hasGlyph}) {
  final edge = chip.padding!.horizontal / 2;
  return hasGlyph ? edge : edge + chip.labelPadding!.horizontal / 2;
}

/// The gap between a leading glyph and the label.
double chipGap(ChipThemeData chip) => chip.labelPadding!.horizontal / 2;

/// The button style of an Mx chip: [buttonStyle]'s states, focus ring and
/// disabled paint on the `chip` theme's shape, colours, glyph and padding, and the
/// `sizeChip` height. The touch target stays 48.
ButtonStyle chipButtonStyle(
  ThemeTokens t,
  ChipThemeData chip, {
  bool isSelected = false,
  bool isGhost = false,
  bool hasLeading = false,
  bool hasTrailing = false,
}) {
  final paint = chipPaint(chip, isSelected: isSelected, isGhost: isGhost);
  final glyph = switch ((isGhost, isSelected)) {
    (true, _) => paint.foreground,
    (_, true) => chip.checkmarkColor!,
    _ => chip.iconTheme!.color!,
  };
  return buttonStyle(
    t,
    fill: paint.fill,
    foreground: paint.foreground,
    edge: paint.edge.style == BorderStyle.none ? null : paint.edge,
    shape: chip.shape!,
  ).copyWith(
    minimumSize: WidgetStatePropertyAll(Size(0, t.dimens.sizeChip)),
    padding: WidgetStatePropertyAll(
      EdgeInsetsDirectional.only(
        start: chipStartInset(chip, hasLeading: hasLeading),
        end: chipEndInset(chip, hasTrailing: hasTrailing),
      ),
    ),
    iconSize: WidgetStatePropertyAll(chip.iconTheme!.size),
    iconColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? t.onSurfaceAt(t.dimens.opacityDisabledContent)
          : glyph,
    ),
  );
}
