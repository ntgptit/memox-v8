import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The on/off switch (Settings, Reminder). One size ships; the thumb slides,
/// it does not resize. Its 44×26 track sits inside a 48 touch area.
class MxToggle extends StatefulWidget {
  const MxToggle({
    super.key,
    required this.isOn,
    required this.onChanged,
    required this.semanticLabel,
  });

  final bool isOn;

  /// Receives the flipped value. Null disables the toggle.
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;

  @override
  State<MxToggle> createState() => _MxToggleState();
}

class _MxToggleState extends State<MxToggle> {
  static const double _trackWidth = 44;
  static const double _trackHeight = 26;
  static const double _thumbSize = 20;
  static const double _thumbInset = 3;

  var _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final onChanged = widget.onChanged;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppDurations.toggle;
    final track = AnimatedContainer(
      key: const ValueKey('mx-toggle-track'),
      duration: duration,
      curve: Easing.standard,
      width: _trackWidth,
      height: _trackHeight,
      padding: const EdgeInsets.all(_thumbInset),
      decoration: BoxDecoration(
        color: widget.isOn ? colors.primary : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      // A foreground ring, so focus never pads the thumb (ruling R5).
      foregroundDecoration: _hasFocus
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(
                color: context.derivedColors.primaryInk,
                width: AppStroke.focus,
              ),
            )
          : null,
      child: AnimatedAlign(
        duration: duration,
        curve: Easing.standard,
        alignment: widget.isOn
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: DecoratedBox(
          key: const ValueKey('mx-toggle-thumb'),
          decoration: BoxDecoration(
            color: colors.surfaceBright,
            shape: BoxShape.circle,
            boxShadow: AppShadows.whisper(colors),
          ),
          child: const SizedBox.square(dimension: _thumbSize),
        ),
      ),
    );
    final control = MergeSemantics(
      child: Semantics(
        toggled: widget.isOn,
        label: widget.semanticLabel,
        child: InkWell(
          onTap: onChanged == null ? null : () => onChanged(!widget.isOn),
          onFocusChange: (hasFocus) => setState(() => _hasFocus = hasFocus),
          customBorder: const StadiumBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppSize.touchTarget,
              minHeight: AppSize.touchTarget,
            ),
            child: Center(widthFactor: 1, heightFactor: 1, child: track),
          ),
        ),
      ),
    );
    if (onChanged != null) return control;
    return Opacity(opacity: AppOpacity.disabled, child: control);
  }
}
