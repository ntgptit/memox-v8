import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/theme_context.dart';

/// One spinner revolution.
const Duration _cycle = Duration(milliseconds: 800);

/// The icon step a spinner is drawn at, so it drops into a button, a row or a
/// card without a new number.
enum MxSpinnerSize { inline, compact, standard, large }

/// The indeterminate spinner: ForUI's `FCircularProgress`, one turn every
/// 0.8s, sized off the icon scale. It keeps turning under reduced motion
/// (ruling O1), because it is the only sign that work is in flight.
/// `FCircularProgress` stands still only under the platform's
/// `disableAnimations` (Android's "Remove animations"), so it is drawn inside
/// an [FAccessibilityScope] that never reports that setting.
class MxSpinner extends StatelessWidget {
  const MxSpinner({
    super.key,
    this.size = MxSpinnerSize.inline,
    this.color,
    this.semanticLabel,
  });

  final MxSpinnerSize size;

  /// The glyph colour. Null is the brand's ink, for a spinner on a surface; a
  /// spinner on a fill passes the foreground that fill is read with, so it
  /// keeps its contrast (M3F-02).
  final Color? color;

  /// What is in flight, for a screen reader (§9 row 61). Null keeps the
  /// spinner silent, as inside a button that already names its work.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final dimension = switch (size) {
      MxSpinnerSize.inline => context.dimens.sizeIconInline,
      MxSpinnerSize.compact => context.dimens.sizeIconCompact,
      MxSpinnerSize.standard => context.dimens.sizeIcon,
      MxSpinnerSize.large => context.dimens.sizeIconTile,
    };
    final accessibility = context.accessibility;
    final spinner = FAccessibilityScope(
      // An explicit scope is not overwritten by platform changes; the rest of
      // the platform's features pass through.
      data: FAccessibility(
        accessibleNavigation: accessibility.accessibleNavigation,
        motion: accessibility.motion == FAccessibilityMotion.disabled
            ? FAccessibilityMotion.reduced
            : accessibility.motion,
        focusHighlight: accessibility.focusHighlight,
      ),
      child: FCircularProgress(
        semanticsLabel: semanticLabel,
        style: FCircularProgressStyleDelta.delta(
          iconStyle: IconThemeDataDelta.delta(
            size: dimension,
            color: color ?? context.status.primaryInk,
          ),
          motion: const FCircularProgressMotion(duration: _cycle),
        ),
      ),
    );
    if (semanticLabel == null) return ExcludeSemantics(child: spinner);
    return spinner;
  }
}
