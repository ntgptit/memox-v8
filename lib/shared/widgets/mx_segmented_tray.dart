import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// One option of an MxSegmentedTray.
@immutable
final class MxSegment<T> {
  const MxSegment({required this.value, required this.label});

  final T value;
  final String label;
}

/// A two- or three-option exclusive switch: a recessed tray with a raised
/// thumb behind the active option. When the labels stop fitting on one line
/// (long copy, large text), the options stack, one per line (FE-A3 ruling).
/// Beyond three options, use MxOptionRow instead.
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
  final T selected;
  final ValueChanged<T> onSelected;

  /// The Progress range tray's wider option padding (16 instead of 12).
  final bool isWide;

  static const int _minSegments = 2;
  static const int _maxSegments = 3;
  static const double _thumbHeight = 32;
  static const double _segmentGap = 2;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) =>
        _naturalWidth(context) > constraints.maxWidth
        ? _stacked(context)
        : _inline(context),
  );

  double get _padding => isWide ? AppSpacing.gutter : AppSpacing.grouped;

  /// The one-line width: each option its label and padding, at least a
  /// touch target, plus the gaps and the tray's inset.
  double _naturalWidth(BuildContext context) {
    final style = context.textStyles.trayLabel(isSelected: true);
    final textScaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    var width = AppSpacing.micro * 2 + _segmentGap * (segments.length - 1);
    for (final segment in segments) {
      final painter = TextPainter(
        text: TextSpan(text: segment.label, style: style),
        textDirection: direction,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();
      width += math.max(AppSize.touchTarget, painter.width + _padding * 2);
      painter.dispose();
    }
    return width;
  }

  Widget _stacked(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.colors.surfaceContainer,
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.micro),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: _segmentGap,
        children: [
          for (final segment in segments)
            _Segment(
              label: segment.label,
              isSelected: segment.value == selected,
              padding: _padding,
              isStretched: true,
              onTap: () => onSelected(segment.value),
            ),
        ],
      ),
    ),
  );

  Widget _inline(BuildContext context) {
    // Ruling I4: the tray paints 40 tall inside a 48 layout band.
    const trayHeight = _thumbHeight + AppSpacing.micro + AppSpacing.micro;
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: Center(
            child: SizedBox(
              height: trayHeight,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.micro),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: _segmentGap,
            children: [
              for (final segment in segments)
                _Segment(
                  label: segment.label,
                  isSelected: segment.value == selected,
                  padding: _padding,
                  onTap: () => onSelected(segment.value),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.isSelected,
    required this.padding,
    required this.onTap,
    this.isStretched = false,
  });

  final String label;
  final bool isSelected;
  final double padding;
  final VoidCallback onTap;

  /// Stacked: the thumb spans the tray's width.
  final bool isStretched;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(AppRadius.sm);
    return MergeSemantics(
      child: Semantics(
        selected: isSelected,
        button: true,
        inMutuallyExclusiveGroup: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppSize.touchTarget,
              minHeight: AppSize.touchTarget,
            ),
            child: Center(
              heightFactor: 1,
              widthFactor: isStretched ? null : 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isSelected ? colors.surfaceContainerLowest : null,
                  borderRadius: radius,
                  boxShadow: isSelected ? AppShadows.whisper(colors) : null,
                ),
                child: SizedBox(
                  height: MxSegmentedTray._thumbHeight,
                  width: isStretched ? double.infinity : null,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        style: context.textStyles.trayLabel(
                          isSelected: isSelected,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
