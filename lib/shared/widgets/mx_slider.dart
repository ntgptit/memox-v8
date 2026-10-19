import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/theme_context.dart';

/// A seek bar (the TOPIK audio player, spec §13.8): ForUI's [FSlider].
/// [value] and [max] share one unit (milliseconds for audio); a value past
/// [max] is drawn at [max]. A [max] of 0 (nothing loaded yet) is a disabled
/// slider.
class MxSlider extends StatelessWidget {
  const MxSlider({
    super.key,
    required this.value,
    required this.max,
    required this.onChanged,
    this.onChangeEnd,
    required this.semanticLabel,
    this.semanticFormatter,
  });

  final double value;
  final double max;

  /// Null disables the slider.
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final String semanticLabel;

  /// How TalkBack reads the value, for example as a time.
  final String Function(double value)? semanticFormatter;

  @override
  Widget build(BuildContext context) {
    final hasRange = max > 0;
    final onChanged = this.onChanged;
    final onChangeEnd = this.onChangeEnd;
    final formatter = semanticFormatter;
    final isEnabled = hasRange && onChanged != null;
    // ForUI's slider runs on the fraction of the track; the caller's unit is
    // the fraction times [max].
    final fraction = hasRange ? (value / max).clamp(0.0, 1.0) : 0.0;
    final slider = FSlider(
      // ForUI's inactive track is `secondary`, which equals the `muted` pane
      // the TOPIK player sits on, so the track after the thumb vanished
      // there. `mutedForeground` after the thumb holds 3:1 on `muted` in both
      // modes; the played part keeps ForUI's primary (audit 2026-10-19, G2;
      // follow-ups spec S1).
      style: FSliderStyleDelta.delta(
        // The base only: ForUI's disabled variants stay (final review).
        inactiveColor: FVariantsValueDelta.delta([
          FVariantValueDeltaOperation.base(context.colors.mutedForeground),
        ]),
      ),
      control: FSliderControl.liftedContinuous(
        value: FSliderValue(max: fraction),
        onChange: (next) {
          if (hasRange) onChanged?.call(next.max * max);
        },
      ),
      enabled: isEnabled,
      onEnd: !hasRange || onChangeEnd == null
          ? null
          : (end) => onChangeEnd(end.max * max),
      // The value TalkBack reads, and the values it offers next, in the
      // caller's unit.
      semanticFormatterCallback: formatter == null
          ? null
          : (current) => formatter(current.max * max),
      semanticValueFormatterCallback: formatter == null
          ? FSlider.defaultSemanticValueFormatter
          : (next) => formatter(next * max),
      // The tooltip over the thumb says the same, not ForUI's percentage.
      tooltipBuilder: formatter == null
          ? FSlider.defaultTooltipBuilder
          : (_, fraction) => Text(formatter(fraction * max)),
    );
    // One node for TalkBack: the label merged with the slider's value and
    // actions, as MxToggle does.
    return MergeSemantics(
      child: Semantics(
        label: semanticLabel,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: context.dimens.sizeControl),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isEnabled)
                Positioned.fill(child: _margins(context, onChanged)),
              slider,
            ],
          ),
        ),
      ),
    );
  }

  /// ForUI's track takes touches across its thumb's height only; the rest of
  /// the 48 target, above and below it, seeks the same way.
  Widget _margins(BuildContext context, ValueChanged<double> onChanged) {
    final style = FTheme.of(context).sliderStyles
        .resolve({FSliderAxisVariant.horizontal, context.platformVariant});
    final insets = style.childPadding.resolve(Directionality.of(context));
    final onChangeEnd = this.onChangeEnd;
    return LayoutBuilder(
      builder: (context, constraints) {
        final start = insets.left + style.thumbSize / 2;
        final extent =
            constraints.maxWidth - insets.horizontal - style.thumbSize;
        double valueAt(Offset local) {
          final offset = local.dx - start;
          final share = extent > 0 ? (offset / extent).clamp(0.0, 1.0) : 0.0;
          final directed = Directionality.of(context) == TextDirection.rtl
              ? 1 - share
              : share;
          return directed * max;
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          // The slider's own node carries the actions.
          excludeFromSemantics: true,
          onTapUp: (details) {
            final next = valueAt(details.localPosition);
            onChanged(next);
            onChangeEnd?.call(next);
          },
          onHorizontalDragUpdate: (details) =>
              onChanged(valueAt(details.localPosition)),
          onHorizontalDragEnd: onChangeEnd == null
              ? null
              : (details) => onChangeEnd(valueAt(details.localPosition)),
        );
      },
    );
  }
}
