import 'package:flutter/widgets.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/core/theme/theme_context.dart';

/// Two footer actions: side by side when both labels fit their share on one
/// line, otherwise stacked full width, [leading] on top. The choice is the
/// available width, measured by a [LayoutBuilder], so it follows the window, the
/// text scale and the label length alike. A paired label never wraps or
/// ellipsizes, so its icon stays on the line. Both buttons are built with
/// `isBlock: true, isSingleLine: true`.
class MxActionPair extends StatelessWidget {
  const MxActionPair({
    super.key,
    this.leading,
    required this.trailing,
    this.leadingFlex = 1,
    this.trailingFlex = 1,
  });

  /// Optional; without it [trailing] stands alone at full width.
  final MxButton? leading;
  final MxButton trailing;

  /// The shares of the side-by-side layout.
  final int leadingFlex;
  final int trailingFlex;

  @override
  Widget build(BuildContext context) {
    final leading = this.leading;
    assert(
      [?leading, trailing].every((b) => b.isBlock && b.isSingleLine),
      'a paired button is block and single-line',
    );
    if (leading == null) return trailing;
    return LayoutBuilder(
      builder: (context, constraints) {
        final shared = constraints.maxWidth - context.dimens.space8;
        final leadingShare =
            shared * leadingFlex / (leadingFlex + trailingFlex);
        final trailingShare = shared - leadingShare;
        final fits =
            leading.naturalWidth(context) <= leadingShare &&
            trailing.naturalWidth(context) <= trailingShare;
        if (!fits) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            spacing: context.dimens.space8,
            children: [leading, trailing],
          );
        }
        return Row(
          spacing: context.dimens.space8,
          children: [
            Expanded(flex: leadingFlex, child: leading),
            Expanded(flex: trailingFlex, child: trailing),
          ],
        );
      },
    );
  }
}
