import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The on/off switch (Settings, Reminder): ForUI's [FSwitch], in a 48 touch
/// box. A tap anywhere in the box flips it, ForUI draws its focus outline,
/// and the box is one TalkBack node with the label and the toggled state.
class MxToggle extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    final flip = onChanged == null ? null : () => onChanged(!isOn);
    return Semantics(
      container: true,
      label: semanticLabel,
      toggled: isOn,
      enabled: onChanged != null,
      onTap: flip,
      excludeSemantics: true,
      // The switch paints under 48; the box around it takes the rest of the
      // target. A tap on the switch itself is the switch's, so it flips once.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: flip,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: context.dimens.sizeControl,
            minHeight: context.dimens.sizeControl,
          ),
          // Both factors: the box is as small as the target allows, also
          // under a bounded height (a row of fixed height).
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            // A disabled switch gives up focus, and with it ForUI's outline:
            // the Cupertino switch inside stays focusable otherwise.
            child: ExcludeFocus(
              excluding: onChanged == null,
              child: FSwitch(
                value: isOn,
                onChange: onChanged,
                enabled: onChanged != null,
                semanticsLabel: semanticLabel,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
