import 'package:flutter/material.dart';

/// A seek bar (the TOPIK audio player, spec §13.8): Material 3's `Slider`,
/// styled by the theme's `sliderTheme`. [value] and [max] share one unit
/// (milliseconds for audio); a value past [max] is drawn at [max]. A [max]
/// of 0 (nothing loaded yet) is a disabled slider.
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
  final SemanticFormatterCallback? semanticFormatter;

  @override
  Widget build(BuildContext context) {
    final hasRange = max > 0;
    // One node for TalkBack: the label merged with the slider's value and
    // actions, as MxToggle does.
    return MergeSemantics(
      child: Semantics(
        label: semanticLabel,
        child: Slider(
          value: hasRange ? value.clamp(0, max).toDouble() : 0,
          max: hasRange ? max : 1,
          onChanged: hasRange ? onChanged : null,
          onChangeEnd: hasRange ? onChangeEnd : null,
          semanticFormatterCallback: semanticFormatter,
        ),
      ),
    );
  }
}
