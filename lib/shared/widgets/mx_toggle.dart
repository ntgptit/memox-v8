import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/primitives/mx_focus_ring.dart';
import 'package:memox/shared/widgets/primitives/mx_tap_target.dart';

/// An on/off switch: a 44×26 pill track and a 20 thumb (DESIGN.md, Inputs),
/// `primary` with an `on-primary` thumb when on, the highest container with
/// an `outline` edge and thumb when off.
class MxToggle extends StatefulWidget {
  const MxToggle({
    required this.isOn,
    required this.onChanged,
    this.semanticLabel,
    super.key,
  });

  final bool isOn;

  /// `null` disables the toggle, drawn at `AppOpacity.disabled`.
  final ValueChanged<bool>? onChanged;

  /// The setting it switches; `null` when a row around it already says so.
  final String? semanticLabel;

  @override
  State<MxToggle> createState() => _MxToggleState();
}

class _MxToggleState extends State<MxToggle> {
  bool _isHighlighted = false;

  @override
  Widget build(BuildContext context) {
    final bool isOn = widget.isOn;
    final ValueChanged<bool>? change = widget.onChanged;
    final ColorScheme colors = context.colors;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final AppShadow? whisper = isDark
        ? AppShadows.whisperDark
        : AppShadows.whisperLight;
    final Widget track = AnimatedContainer(
      duration: AppDurations.toggle,
      width: AppSize.toggleWidth,
      height: AppSize.toggleHeight,
      padding: const EdgeInsets.all(
        (AppSize.toggleHeight - AppSize.toggleThumb) / 2,
      ),
      alignment: isOn
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      decoration: BoxDecoration(
        color: isOn ? colors.primary : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: isOn
            ? null
            : Border.all(color: colors.outline, width: AppStroke.hairline),
      ),
      child: Container(
        width: AppSize.toggleThumb,
        height: AppSize.toggleThumb,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isOn ? colors.onPrimary : colors.outline,
          boxShadow: [?whisper?.on(colors.shadow)],
        ),
      ),
    );
    final Widget control = Semantics(
      toggled: isOn,
      enabled: change != null,
      label: widget.semanticLabel,
      onTap: change == null ? null : () => change(!isOn),
      child: FocusableActionDetector(
        enabled: change != null,
        onShowFocusHighlight: (shown) => setState(() => _isHighlighted = shown),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => change?.call(!isOn),
          ),
        },
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: change == null ? null : () => change(!isOn),
          child: MxTapTarget(
            child: MxFocusRing(
              borderRadius: BorderRadius.circular(AppRadius.full),
              isShown: _isHighlighted,
              child: track,
            ),
          ),
        ),
      ),
    );
    if (change != null) {
      return control;
    }
    return Opacity(opacity: AppOpacity.disabled, child: control);
  }
}
