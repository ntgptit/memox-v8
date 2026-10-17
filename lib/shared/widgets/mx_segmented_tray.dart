import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';

/// One option of an MxSegmentedTray.
@immutable
final class MxSegment<T> {
  const MxSegment({required this.value, required this.label});

  final T value;
  final String label;
}

/// A two- or three-option exclusive switch, drawn as ForUI's tab list: the
/// options on the muted ground, the chosen one raised on the background with
/// a check before its label, each a 48 [FTappable] with ForUI's focus
/// outline. When the labels stop fitting on one line (long copy, large
/// text), the options stack, one per line (FE-A3 ruling). Beyond three
/// options, use MxOptionRow instead. ForUI has no segmented control; its
/// `FTabs` owns a content pane, so the tray composes ForUI's primitives.
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

  /// Null disables the tray: no option takes a tap, and ForUI dims it.
  final ValueChanged<T>? onSelected;

  /// The Progress range tray's wider option padding (16 instead of 12).
  final bool isWide;

  static const int _minSegments = 2;
  static const int _maxSegments = 3;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final natural = _naturalWidth(context);
      final isStacked = natural > constraints.maxWidth;
      final colors = context.colors;
      final inner = context.dimens.space4;
      final options = [
        for (final segment in segments)
          _Option<T>(
            segment: segment,
            isSelected: segment.value == selected,
            padding: _padding(context),
            onSelected: onSelected,
          ),
      ];
      final tray = DecoratedBox(
        decoration: BoxDecoration(
          color: colors.muted,
          borderRadius: context.radii.lg,
        ),
        child: Padding(
          padding: EdgeInsets.all(inner),
          child: isStacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: inner,
                  children: options,
                )
              : IntrinsicHeight(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: inner,
                    children: [
                      for (final option in options) Expanded(child: option),
                    ],
                  ),
                ),
        ),
      );
      // Inline, every option takes the widest one's width, as the tray
      // measured; stacked, the tray fills the column.
      return isStacked ? tray : SizedBox(width: natural, child: tray);
    },
  );

  double _padding(BuildContext context) =>
      isWide ? context.dimens.space16 : context.dimens.space12;

  /// The one-line width: the widest option's label, padding and check slot,
  /// times the options (each option takes the widest width), with the tray's
  /// own insets. The check is counted for every option so the choice never
  /// changes the layout between inline and stacked.
  double _naturalWidth(BuildContext context) {
    final dimens = context.dimens;
    final textScaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    var widest = 0.0;
    for (final segment in segments) {
      final painter = TextPainter(
        text: TextSpan(text: segment.label, style: context.texts.label),
        textDirection: direction,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();
      widest = math.max(widest, painter.width);
      painter.dispose();
    }
    final check = dimens.sizeIconInline + dimens.space4;
    final option = widest + _padding(context) * 2 + check;
    return option * segments.length + dimens.space4 * (segments.length + 1);
  }
}

/// One option: a 48 tappable, raised on the background when chosen.
class _Option<T> extends StatelessWidget {
  const _Option({
    required this.segment,
    required this.isSelected,
    required this.padding,
    required this.onSelected,
  });

  final MxSegment<T> segment;
  final bool isSelected;
  final double padding;
  final ValueChanged<T>? onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final onSelected = this.onSelected;
    final isEnabled = onSelected != null;
    final foreground = switch ((isEnabled, isSelected)) {
      (false, _) => colors.disable(colors.mutedForeground),
      (_, true) => colors.foreground,
      _ => colors.mutedForeground,
    };
    return FTappable.static(
      // Tapping the chosen option reports it again, as a radio.
      onPress: isEnabled ? () => onSelected(segment.value) : null,
      selected: isSelected,
      semanticsInMutuallyExclusiveGroup: true,
      focusedOutlineStyle: FFocusedOutlineStyleDelta.delta(
        borderRadius: context.radii.md,
      ),
      builder: (context, _, child) => DecoratedBox(
        decoration: BoxDecoration(
          color: isSelected ? colors.background : null,
          borderRadius: context.radii.md,
          boxShadow: isSelected ? FTheme.of(context).style.shadow : null,
        ),
        child: child,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: context.dimens.sizeControl),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: context.dimens.space4,
            children: [
              if (isSelected)
                Icon(
                  AppIcons.check,
                  size: context.dimens.sizeIconInline,
                  color: foreground,
                ),
              Flexible(
                child: Text(
                  segment.label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.label.copyWith(color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
