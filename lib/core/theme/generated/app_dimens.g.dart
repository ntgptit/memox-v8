// GENERATED from design/tokens.json by tools/design/generate.py. Do not edit.

import 'package:flutter/material.dart';

/// Spacing, shape, size, breakpoint, stroke and opacity tokens, read as `context.dimens`.
@immutable
class AppDimens extends ThemeExtension<AppDimens> {
  const AppDimens({
    this.space4 = 4,
    this.space8 = 8,
    this.space12 = 12,
    this.space16 = 16,
    this.space24 = 24,
    this.space32 = 32,
    this.space48 = 48,
    this.marginScreen = 16,
    this.marginScreenMedium = 24,
    this.radiusXs = 4,
    this.radiusSm = 8,
    this.radiusMd = 12,
    this.radiusLg = 16,
    this.radiusXl = 28,
    this.sizeControl = 48,
    this.sizeButton = 40,
    this.sizeButtonSmall = 32,
    this.sizeSearch = 56,
    this.sizeAvatar = 48,
    this.sizeTile = 64,
    this.sizeNav = 64,
    this.sizeRail = 80,
    this.sizeNavIndicatorWidth = 56,
    this.sizeNavIndicatorHeight = 32,
    this.sizeIcon = 24,
    this.sizeIconTile = 32,
    this.sizeTrack = 4,
    this.sizeBadge = 12,
    this.sizeDot = 8,
    this.sizeDotSmall = 4,
    this.sizeContentMax = 599,
    this.sizeContentMaxWide = 1040,
    this.breakpointMedium = 600,
    this.breakpointExpanded = 840,
    this.strokeHairline = 1,
    this.strokeFocus = 2,
    this.opacityHover = 0.08,
    this.opacityPressed = 0.1,
    this.opacityFocus = 0.1,
    this.opacityDragged = 0.16,
    this.opacityDisabledContent = 0.38,
    this.opacityDisabledContainer = 0.12,
    // App-only — not yet in the design system.
    this.sizeChip = 32,
    this.sizeInput = 56,
    this.sizeListRow = 56,
    this.sizeListRowTwoLine = 72,
    this.sizeFab = 56,
    this.breakpointCompactHeight = 480,
    this.sizeAppBar = 64,
    this.sizeIconInline = 16,
    this.sizeIconCompact = 20,
    this.sizeIconButton = 18,
    this.sizeSelectionControl = 18,
    this.sizeRadioDot = 9,
    this.radiusCheckbox = 2,
    this.strokeFocusGap = 2,
    this.strokeControl = 2,
    this.strokeIndicator = 2,
    this.opacityMuted = 0.7,
    this.opacityScrim = 0.32,
  });

  final double space4;
  final double space8;
  final double space12;
  final double space16;
  final double space24;
  final double space32;
  final double space48;
  final double marginScreen;
  final double marginScreenMedium;
  final double radiusXs;
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusXl;
  final double sizeControl;
  final double sizeButton;
  final double sizeButtonSmall;
  final double sizeSearch;
  final double sizeAvatar;
  final double sizeTile;
  final double sizeNav;
  final double sizeRail;
  final double sizeNavIndicatorWidth;
  final double sizeNavIndicatorHeight;
  final double sizeIcon;
  final double sizeIconTile;
  final double sizeTrack;
  final double sizeBadge;
  final double sizeDot;
  final double sizeDotSmall;
  final double sizeContentMax;
  final double sizeContentMaxWide;
  final double breakpointMedium;
  final double breakpointExpanded;
  final double strokeHairline;
  final double strokeFocus;
  final double opacityHover;
  final double opacityPressed;
  final double opacityFocus;
  final double opacityDragged;
  final double opacityDisabledContent;
  final double opacityDisabledContainer;
  // App-only — not yet in the design system.
  /// Chip and filter chip height, as the Material 3 chip container. A chip never wraps, its row scrolls.
  final double sizeChip;

  /// Text field height, as the Material 3 text field container.
  final double sizeInput;

  /// Minimum height of a one-line list row, as the Material 3 list item container. Content rows, settings rows, option rows and sheet commands share it.
  final double sizeListRow;

  /// Minimum height of a list row with a supporting line (subtitle or meta), as the Material 3 two-line list item container.
  final double sizeListRowTwoLine;

  /// Floating action button, square, icon only, as the Material 3 FAB container.
  final double sizeFab;

  /// Window height below which the window is compact in height (Material 3 window size classes): navigation is a bottom bar even when the width is medium or wider.
  final double breakpointCompactHeight;

  /// App bar height (48 + 2 x 8).
  final double sizeAppBar;

  /// Icon inside body text; the smallest icon.
  final double sizeIconInline;

  /// Dense rows, metadata, nav glyphs.
  final double sizeIconCompact;

  /// The leading glyph of a button, as the Material 3 button icon size; its gap to the label is space8.
  final double sizeIconButton;

  /// The radio ring and the checkbox box, as the Material 3 selection controls (Checkbox.width; the radio ring is stroked at the centre of a 16 circle).
  final double sizeSelectionControl;

  /// The selected radio dot, as the Material 3 inner radius of 4.5.
  final double sizeRadioDot;

  /// The checkbox corner, as the Material 3 checkbox shape.
  final double radiusCheckbox;

  /// Gap between a control and its focus ring (tokens.json: focus ring in primary, offset 2px). Buttons and the FAB draw an offset ring.
  final double strokeFocusGap;

  /// Radio ring (unselected and selected) and unselected checkbox border.
  final double strokeControl;

  /// Spinner arc and other progress strokes.
  final double strokeIndicator;

  /// Readable content that steps back: an answered choice out of play, a footer caption.
  final double opacityMuted;

  /// Alpha of the scrim behind a dialog or a bottom sheet: the Material 3 scrim, 32%. The Design System defines the scrim colour, not its opacity (ADR-022).
  final double opacityScrim;

  @override
  AppDimens copyWith() => this;

  @override
  AppDimens lerp(ThemeExtension<AppDimens>? other, double t) => this;
}
