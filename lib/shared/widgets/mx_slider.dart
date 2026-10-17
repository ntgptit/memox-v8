import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

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
    // ForUI's slider runs on the fraction of the track; the caller's unit is
    // the fraction times [max].
    final fraction = hasRange ? (value / max).clamp(0.0, 1.0) : 0.0;
    // One node for TalkBack: the label merged with the slider's value and
    // actions, as MxToggle does.
    return MergeSemantics(
      child: Semantics(
        label: semanticLabel,
        child: FSlider(
          control: FSliderControl.liftedContinuous(
            value: FSliderValue(max: fraction),
            onChange: (next) {
              if (hasRange) onChanged?.call(next.max * max);
            },
          ),
          enabled: hasRange && onChanged != null,
          onEnd: !hasRange || onChangeEnd == null
              ? null
              : (end) => onChangeEnd(end.max * max),
          semanticValueFormatterCallback: formatter == null
              ? FSlider.defaultSemanticValueFormatter
              : (next) => formatter(next * max),
        ),
      ),
    );
  }
}
