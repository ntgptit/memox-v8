import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_component_themes.dart';
import 'package:memox/core/theme/focus_ring_border.dart';

/// The on/off switch (Settings, Reminder): Material 3's `Switch`, styled by
/// the theme's `switchTheme`. A 52×32 track in a 48 tall touch box; the handle
/// is 16 off, 24 on and 28 while pressed. A focused one also draws the focus
/// ring round the track, as the buttons and chips do.
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
  /// Material's M3 switch track, which the focus ring has to hug. The Switch
  /// owns these numbers and exposes no focus indicator of its own.
  static const _track = Size(52, 32);

  var _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    final t = ThemeTokens.of(context);
    return MergeSemantics(
      child: Semantics(
        label: widget.semanticLabel,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // The Switch dims itself when disabled: no Opacity here.
            Switch(
              value: widget.isOn,
              onChanged: widget.onChanged,
              onFocusChange: (hasFocus) => setState(() => _hasFocus = hasFocus),
            ),
            if (_hasFocus)
              IgnorePointer(
                child: DecoratedBox(
                  key: const ValueKey('mx-toggle-focus-ring'),
                  decoration: ShapeDecoration(
                    shape: MxFocusRingBorder(
                      base: const StadiumBorder(),
                      ring: BorderSide(
                        color: t.scheme.primary,
                        width: t.dimens.strokeFocus,
                      ),
                      gap: t.dimens.strokeFocusGap,
                    ),
                  ),
                  child: SizedBox.fromSize(size: _track),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
