import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_component_themes.dart';
import 'package:memox/core/theme/theme_context.dart';

/// One option of an MxSegmentedTray.
@immutable
final class MxSegment<T> {
  const MxSegment({required this.value, required this.label});

  final T value;
  final String label;
}

/// A two- or three-option exclusive switch: Material 3's `SegmentedButton`,
/// styled by the theme's `segmentedButtonTheme`. A stadium 40 tall in a 48
/// touch band, a `outline` edge round and between the options, and a check
/// before the chosen one. When the labels stop fitting on one line (long copy,
/// large text), the options stack, one per line (FE-A3 ruling). Beyond three
/// options, use MxOptionRow instead.
class MxSegmentedTray<T> extends StatelessWidget {
  const MxSegmentedTray({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelected,
    this.isWide = false,
  }) : assert(
         segments.length >= _minSegments && segments.length <= _maxSegments,
         'a tray holds two or three options',
       );

  final List<MxSegment<T>> segments;

  /// Null draws no option as chosen: a choice the person must make, with no
  /// default (BR-SRS-001).
  final T? selected;

  /// Null disables the tray: no option takes a tap, and it takes Material's
  /// disabled colours.
  final ValueChanged<T>? onSelected;

  /// The Progress range tray's wider option padding (16 instead of 12).
  final bool isWide;

  static const int _minSegments = 2;
  static const int _maxSegments = 3;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) =>
        _naturalWidth(context) > constraints.maxWidth
        ? _stacked(context)
        : _inline(context),
  );

  void _report(Set<T> choice) {
    // Tapping the chosen option empties the set: report it again, as a radio.
    final value = choice.isEmpty ? selected : choice.first;
    if (value is T) onSelected?.call(value);
  }

  double _padding(BuildContext context) =>
      isWide ? context.dimens.space16 : context.dimens.space12;

  /// The one-line width: the widest option's label, padding and check slot,
  /// times the options (the segmented button gives each the widest width).
  /// The check is counted for every option so the choice never changes the
  /// layout between inline and stacked.
  double _naturalWidth(BuildContext context) {
    final dimens = context.dimens;
    final textScaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    var widest = 0.0;
    for (final segment in segments) {
      final painter = TextPainter(
        text: TextSpan(text: segment.label, style: context.texts.labelLarge),
        textDirection: direction,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();
      widest = math.max(widest, painter.width);
      painter.dispose();
    }
    final check = dimens.sizeIconButton + dimens.space8 + dimens.space4;
    return (widest + _padding(context) * 2 + check) * segments.length;
  }

  Widget _inline(BuildContext context) =>
      _button(Axis.horizontal, _style(context));

  /// One option per 48 tall line. The edge is a rounded rectangle: a stadium
  /// round a tall column would bulge.
  Widget _stacked(BuildContext context) {
    final tokens = ThemeTokens.of(context);
    return SizedBox(
      width: double.infinity,
      child: _button(
        Axis.vertical,
        _style(
          context,
          shape: segmentedButtonShape(
            tokens,
            RoundedRectangleBorder(
              borderRadius: tokens.radius(tokens.dimens.radiusMd),
            ),
          ),
        ),
      ),
    );
  }

  /// The theme's segmented button, with the wide padding when asked.
  ButtonStyle _style(
    BuildContext context, {
    WidgetStateProperty<OutlinedBorder>? shape,
  }) => ButtonStyle(
    shape: shape,
    padding: isWide
        ? WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: _padding(context)),
          )
        : null,
  );

  Widget _button(Axis direction, ButtonStyle style) => SegmentedButton<T>(
    direction: direction,
    style: style,
    emptySelectionAllowed: true,
    segments: [
      for (final segment in segments)
        ButtonSegment(
          value: segment.value,
          label: Text(segment.label, maxLines: 1, softWrap: false),
        ),
    ],
    selected: selected == null ? const {} : {selected as T},
    onSelectionChanged: onSelected == null ? null : _report,
  );
}
